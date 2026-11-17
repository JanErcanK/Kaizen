import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../theme/app_colors.dart';

/// Shared rank artwork for the Android launcher and the home-screen widget.
Future<Uint8List> renderLauncherRankBadge(
  String rank, {
  bool adaptive = true,
  int? pixelSize,
}) async {
  final size = pixelSize ?? (adaptive ? 432 : 192);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(size / (adaptive ? 108 : 72));
  if (adaptive) {
    canvas.drawColor(AppColors.launcherBackground, ui.BlendMode.src);
  } else {
    canvas.translate(-18, -18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 18, 72, 72),
        const Radius.circular(12),
      ),
      Paint()..color = AppColors.launcherBackground,
    );
  }

  _brushStroke(
    canvas,
    start: 2.88,
    sweep: 3.21,
    pigment: const Color(0xFF376FAE),
    highlight: const Color(0xFF9BD4F4),
    seed: 7,
  );
  _brushStroke(
    canvas,
    start: -.16,
    sweep: 3.13,
    pigment: const Color(0xFFC24A47),
    highlight: const Color(0xFFF49B87),
    seed: 23,
  );

  final title = TextPainter(
    text: TextSpan(
      text: rank,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: -.55,
        color: Color(0xFF17231A),
        height: 1,
      ),
    ),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  final signature = TextPainter(
    text: const TextSpan(
      text: '改善',
      style: TextStyle(
        fontFamily: 'KaizenJapanese',
        fontSize: 11.5,
        letterSpacing: .6,
        fontWeight: FontWeight.w500,
        color: Color(0xFF17231A),
        height: 1,
      ),
    ),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  final scale = math.min(1.0, 48 / title.width);
  canvas.save();
  canvas.translate(54, 48.5);
  canvas.scale(scale);
  title.paint(canvas, Offset(-title.width / 2, -title.height / 2));
  canvas.restore();
  title.dispose();
  signature.paint(
    canvas,
    Offset(54 - signature.width / 2, 63 - signature.height / 2),
  );
  signature.dispose();

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  picture.dispose();
  try {
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
  } finally {
    image.dispose();
  }
}

/// Pools of pigment along the stroke, with a few bristle marks and loose drops.
void _brushStroke(
  Canvas canvas, {
  required double start,
  required double sweep,
  required Color pigment,
  required Color highlight,
  required int seed,
}) {
  final random = math.Random(seed);
  canvas.save();
  canvas.translate(54, 54);
  canvas.rotate(-.14);
  Offset point(double t, double offset) {
    final angle = start + sweep * t;
    final edge = offset + .85 * math.sin(3 * angle + seed);
    return Offset(
      (30 + edge) * math.cos(angle),
      (26.5 + edge) * math.sin(angle),
    );
  }

  void dab(double t, double offset, double length, double depth, Color color) {
    final center = point(t, offset);
    final edge = List.generate(12, (i) {
      final angle = i * math.pi / 6;
      final radius = .72 + random.nextDouble() * .48;
      return Offset(
        length * radius * math.cos(angle),
        depth * radius * math.sin(angle),
      );
    });
    final first = (edge.last + edge.first) / 2;
    final path = Path()..moveTo(first.dx, first.dy);
    for (var i = 0; i < edge.length; i++) {
      final mid = (edge[i] + edge[(i + 1) % edge.length]) / 2;
      path.quadraticBezierTo(edge[i].dx, edge[i].dy, mid.dx, mid.dy);
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(start + sweep * t + math.pi / 2);
    canvas.drawPath(path..close(), Paint()..color = color);
    canvas.restore();
  }

  for (var i = 0; i < 17; i++) {
    final t = (i + random.nextDouble() * .5) / 17;
    final pressure = .42 + .58 * math.sin(math.pi * t);
    final tone = Color.lerp(pigment, highlight, random.nextDouble() * .42)!;
    dab(
      t,
      random.nextDouble() * 2 - 1,
      3.5 + random.nextDouble() * 2.8,
      (2.5 + random.nextDouble() * 2.5) * pressure,
      tone,
    );
  }
  for (var i = 0; i < 6; i++) {
    final offset = -2.3 + i * .85;
    final begin = random.nextDouble() * .10;
    final end = 1 - random.nextDouble() * .13;
    final width = .26 + random.nextDouble() * .37;
    final path = Path();
    for (final side in [1, -1]) {
      for (var j = 0; j <= 40; j++) {
        final u = (side == 1 ? j : 40 - j) / 40;
        final t = begin + (end - begin) * u;
        final p = point(t, offset + side * width * math.sin(math.pi * u));
        if (side == 1 && j == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
    }
    final color = Color.lerp(pigment, highlight, random.nextDouble() * .78)!;
    canvas.drawPath(path..close(), Paint()..color = color);
  }
  // Loose splashes cluster near the loaded end of each brush.
  for (final t in [.18, .55, .88]) {
    final size = 1.1 + random.nextDouble();
    dab(t, 4.3, size * 1.35, size, pigment);
    dab(t + .045, 5.9, size * .6, size * .5, pigment);
    dab(t - .033, 6.6, .55, .5, pigment);
  }
  canvas.restore();
}
