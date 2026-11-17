import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/route_activity.dart';
import 'progress_store.dart';

/// A fixed, fully fitted route image, independent of the tracking camera's zoom.
/// PNGs live beside Hive; route data allows them to be rebuilt after a restore.
class RunSnapshotService {
  static const width = 900, height = 1040;

  static File file(String id) {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
      throw const FormatException('Invalid snapshot ID');
    }
    return File('${ProgressStore.storageDirectory}/run_snapshots/$id.png');
  }

  static Future<File> save(
    Map<String, dynamic> route, {
    required String id,
    required bool german,
    bool mapTiles = true,
  }) async {
    final bytes = await render(route, german: german, mapTiles: mapTiles);
    final target = file(id);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(bytes, flush: true);
    return target;
  }

  static Future<Uint8List> render(
    Map<String, dynamic> route, {
    required bool german,
    bool mapTiles = true,
  }) async {
    final points = (route['points'] as List? ?? const [])
        .whereType<List>()
        .where((p) => p.length >= 2 && p[0] is num && p[1] is num)
        .map((p) => Offset((p[1] as num).toDouble(), (p[0] as num).toDouble()))
        .where(
          (p) =>
              p.dx.isFinite &&
              p.dy.isFinite &&
              p.dx.abs() <= 180 &&
              p.dy.abs() <= 90,
        )
        .toList();
    final activity = RouteActivity.fromJson(
      route['activity'] as Map? ?? const {},
    );
    final meters = (route['distanceMeters'] as num?)?.toDouble() ?? 0;
    final ascent = (route['ascentMeters'] as num?)?.toDouble() ?? 0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xFFF7F8F5), BlendMode.src);
    void text(
      String value,
      Offset at,
      double size, {
      Color color = const Color(0xFF23321B),
      bool bold = false,
      double maxWidth = 804,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: color,
            fontSize: size,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);
      painter.paint(canvas, at);
    }

    text(
      'KAIZEN   /   ${activity.type.label(german).toUpperCase()}',
      const Offset(48, 32),
      22,
      color: const Color(0xFF608D22),
      bold: true,
    );
    text(
      route['name']?.toString() ?? 'Route',
      const Offset(48, 72),
      34,
      bold: true,
    );
    final at = activity.recordedAt;
    if (at != null) {
      text(
        '${at.day.toString().padLeft(2, '0')}.${at.month.toString().padLeft(2, '0')}.${at.year}  ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
        const Offset(48, 120),
        20,
      );
    }

    const mapRect = Rect.fromLTWH(32, 164, 836, 470);
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(mapRect, const Radius.circular(24)),
    );
    canvas.drawRect(mapRect, Paint()..color = const Color(0xFFEDF2E7));
    var loadedTiles = 0;
    if (points.isNotEmpty) {
      // Web Mercator coordinates, unwrapped across the date line.
      final projected = <Offset>[];
      for (final p in points) {
        var x = (p.dx + 180) / 360;
        if (projected.isNotEmpty) {
          while (x - projected.last.dx > .5) {
            x -= 1;
          }
          while (x - projected.last.dx < -.5) {
            x += 1;
          }
        }
        final lat = p.dy.clamp(-85.0511, 85.0511) * math.pi / 180;
        final y =
            (1 - math.log(math.tan(lat) + 1 / math.cos(lat)) / math.pi) / 2;
        projected.add(Offset(x, y));
      }
      final xs = projected.map((p) => p.dx), ys = projected.map((p) => p.dy);
      final minX = xs.reduce(math.min), maxX = xs.reduce(math.max);
      final minY = ys.reduce(math.min), maxY = ys.reduce(math.max);
      final scale = math.min(
        (mapRect.width - 96) / math.max(maxX - minX, 1e-8),
        (mapRect.height - 96) / math.max(maxY - minY, 1e-8),
      );
      final zoom = (math.log(scale / 256) / math.ln2).floor().clamp(0, 17);
      final world = scale.clamp(256.0, 256.0 * math.pow(2, 17));
      final tileSize = world / (1 << zoom);
      final center = Offset((minX + maxX) / 2, (minY + maxY) / 2);
      Offset screen(Offset p) => mapRect.center + (p - center) * world;
      final origin = screen(Offset.zero);
      if (mapTiles) {
        final client = http.Client();
        final futures = <Future<void>>[];
        final n = 1 << zoom;
        for (
          var x = ((mapRect.left - origin.dx) / tileSize).floor();
          x <= ((mapRect.right - origin.dx) / tileSize).floor();
          x++
        ) {
          for (
            var y = ((mapRect.top - origin.dy) / tileSize).floor();
            y <= ((mapRect.bottom - origin.dy) / tileSize).floor();
            y++
          ) {
            if (y < 0 || y >= n) continue;
            final tx = x, ty = y;
            futures.add(() async {
              try {
                final response = await client
                    .get(
                      Uri.parse(
                        'https://tile.openstreetmap.org/$zoom/${tx % n}/$ty.png',
                      ),
                      headers: {
                        'User-Agent':
                            'de.jankilic.kaizen/1.1 (saved activity preview)',
                      },
                    )
                    .timeout(const Duration(seconds: 4));
                if (response.statusCode != 200 ||
                    response.bodyBytes.length > 1000000) {
                  return;
                }
                final codec = await ui.instantiateImageCodec(
                  response.bodyBytes,
                );
                final frame = await codec.getNextFrame();
                canvas.drawImageRect(
                  frame.image,
                  Rect.fromLTWH(
                    0,
                    0,
                    frame.image.width.toDouble(),
                    frame.image.height.toDouble(),
                  ),
                  Rect.fromLTWH(
                    origin.dx + tx * tileSize,
                    origin.dy + ty * tileSize,
                    tileSize,
                    tileSize,
                  ),
                  Paint(),
                );
                frame.image.dispose();
                codec.dispose();
                loadedTiles++;
              } catch (_) {
                /* The entire route remains available offline. */
              }
            }());
          }
        }
        await Future.wait(futures);
        client.close();
      }
      final path = Path()
        ..moveTo(screen(projected.first).dx, screen(projected.first).dy);
      for (final p in projected.skip(1)) {
        final s = screen(p);
        path.lineTo(s.dx, s.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF6FAE00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      for (final p in [projected.first, projected.last]) {
        canvas.drawCircle(screen(p), 12, Paint()..color = Colors.white);
        canvas.drawCircle(
          screen(p),
          8,
          Paint()
            ..color = p == projected.first
                ? const Color(0xFF6FAE00)
                : const Color(0xFF30471E),
        );
      }
    }
    canvas.restore();
    text(
      loadedTiles > 0
          ? '© OpenStreetMap contributors'
          : (german
                ? 'Routenübersicht · ohne Kartenhintergrund'
                : 'Route overview · map background unavailable'),
      const Offset(48, 640),
      16,
    );

    final metrics = <(String, String)>[
      (
        german ? 'DISTANZ' : 'DISTANCE',
        '${(meters / 1000).toStringAsFixed(2)} km',
      ),
      ('Ø PACE', activity.pace(meters)),
      (
        german ? 'DAUER' : 'DURATION',
        activity.durationSeconds > 0 ? activity.duration : '—',
      ),
      (
        german ? 'Ø GESCHWINDIGKEIT' : 'AVG SPEED',
        activity.durationSeconds > 0
            ? '${activity.averageSpeed(meters).toStringAsFixed(1)} km/h'
            : '—',
      ),
      (
        german ? 'AUFSTIEG' : 'ASCENT',
        activity.elevationRecorded ? '${ascent.round()} m' : '—',
      ),
      (
        german ? 'ABSTIEG' : 'DESCENT',
        activity.elevationRecorded
            ? '${activity.descentMeters.round()} m'
            : '—',
      ),
      (
        german ? 'MAX. GESCHWINDIGKEIT' : 'MAX SPEED',
        activity.maxSpeedKmh > 0
            ? '${activity.maxSpeedKmh.toStringAsFixed(1)} km/h'
            : '—',
      ),
      (
        german ? 'KALORIEN (GESCHÄTZT)' : 'CALORIES (ESTIMATED)',
        activity.calories > 0 ? '${activity.calories} kcal' : '—',
      ),
    ];
    for (var i = 0; i < metrics.length; i++) {
      final x = 48.0 + (i % 2) * 422, y = 686.0 + (i ~/ 2) * 80;
      text(
        metrics[i].$1,
        Offset(x, y),
        16,
        color: const Color(0xFF6D7668),
        maxWidth: 390,
      );
      text(metrics[i].$2, Offset(x, y + 25), 28, bold: true, maxWidth: 390);
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return bytes!.buffer.asUint8List();
  }
}
