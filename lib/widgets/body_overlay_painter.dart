import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../services/joint_activity_service.dart';
import '../services/organ_health_service.dart';
import '../theme/app_colors.dart';
import 'body_muscle_paths.dart';
import 'body_muscle_paths_female.dart';
import 'male_mannequin_generated_paths.dart';

// ─── Shared body silhouette layout ──────────────────────────────────────────

/// Screen-space placement of the body silhouette inside a paint area.
class BodyLayout {
  const BodyLayout(this.bounds);

  /// The body's bounding box in screen coordinates.
  final Rect bounds;

  /// Maps a fractional body coordinate (0..1) to a screen point.
  Offset frac(double fx, double fy) =>
      Offset(bounds.left + fx * bounds.width, bounds.top + fy * bounds.height);
}

const double _padX = 14;
const double _padY = 6;

/// Extra space below the silhouette so the green stage oval is fully visible.
double bodyStageBottomReserve(Size size) {
  final approxW = math.max(40.0, size.width - _padX * 2);
  return (approxW * 0.24 + 24).clamp(48.0, 96.0);
}

/// Small bump over the exact-fit scale so the silhouette reads a bit larger;
/// safe because the surrounding Stack paints with Clip.none.
const double _bodyScaleBoost = 1.08;

/// Set true to preview the separately authored male mannequin. The original
/// male geometry and renderer are active by default.
const bool useGeneratedMaleMannequin = false;

({double scale, double dx, double dy}) bodyFitTransform(
  Size size,
  Rect bounds, {
  bool reserveStage = true,
  double? scaleBoost,
}) {
  final bottomReserve = reserveStage ? bodyStageBottomReserve(size) : 0.0;
  final usableH = math.max(1.0, size.height - _padY - bottomReserve);
  final scale =
      (scaleBoost ?? (reserveStage ? _bodyScaleBoost : 1.0)) *
      math.min(
        (size.width - _padX * 2) / bounds.width,
        usableH / bounds.height,
      );
  final dx = (size.width - bounds.width * scale) / 2 - bounds.left * scale;
  // Center in the full height (not just usableH) so the gap above the
  // silhouette matches the gap below it, including the reserved stage space.
  final dy = (size.height - bounds.height * scale) / 2 - bounds.top * scale;
  return (scale: scale, dx: dx, dy: dy);
}

Rect? _localBoundsFrontCache;
Path? _shellFrontCache;
Rect? _localBoundsFemaleCache;
Path? _shellFemaleCache;

final Map<String, Path> _parseCache = {};
final Map<bool, Map<String, List<Path>>> _femaleBodyPathCache = {};
final Map<bool, Map<String, List<Path>>> _generatedMalePathCache = {};
final Map<String, Path> _bodySilhouetteCache = {};

Path _parsed(String d) {
  return _parseCache[d] ??= () {
    try {
      return parseSvgPathData(d);
    } catch (_) {
      return Path();
    }
  }();
}

/// Returns one coherent set of body paths for both drawing and hit testing.
/// Female paths share a continuous waist-to-hip warp so neighboring muscle
/// regions stay aligned instead of shifting independently at their seams.
Map<String, List<Path>> bodyMusclePathsForView({
  required bool front,
  bool female = false,
}) {
  if (!female && useGeneratedMaleMannequin) {
    return _generatedMalePathCache.putIfAbsent(front, () {
      final source = front
          ? GeneratedMaleMannequinPaths.front
          : GeneratedMaleMannequinPaths.back;
      final paths = <String, List<Path>>{};
      source.forEach((slug, strings) {
        final parsed = [for (final d in strings) _parsed(d)];
        if (GeneratedMaleMannequinPaths.mirroredRegions.contains(slug)) {
          parsed.addAll([for (final path in parsed) _mirrorMalePath(path)]);
        }
        paths[slug] = parsed;
      });
      return paths;
    });
  }

  final source = female
      ? (front ? BodyMusclePathsFemale.front : BodyMusclePathsFemale.back)
      : (front ? BodyMusclePaths.front : BodyMusclePaths.back);
  if (!female) {
    return source.map(
      (slug, paths) => MapEntry(slug, [for (final d in paths) _parsed(d)]),
    );
  }

  return _femaleBodyPathCache.putIfAbsent(front, () {
    final raw = source.map(
      (slug, paths) => MapEntry(slug, [for (final d in paths) _parsed(d)]),
    );
    Rect? bounds;
    for (final paths in raw.values) {
      for (final path in paths) {
        final pathBounds = path.getBounds();
        bounds = bounds == null
            ? pathBounds
            : bounds.expandToInclude(pathBounds);
      }
    }
    if (bounds == null || bounds.height <= 0) return raw;

    final bodyBounds = bounds;
    return raw.map(
      (slug, paths) => MapEntry(slug, [
        for (final path in paths) _warpFemalePath(path, bodyBounds),
      ]),
    );
  });
}

Path _mirrorMalePath(Path path) => path.transform(
  (Matrix4.identity()
        ..setEntry(0, 0, -1)
        ..setEntry(0, 3, GeneratedMaleMannequinPaths.viewWidth))
      .storage,
);

/// Newly authored continuous form painted underneath the muscle regions.
Path maleMannequinBase({required bool front}) {
  Path? union;
  final data = front
      ? GeneratedMaleMannequinPaths.frontBase
      : GeneratedMaleMannequinPaths.backBase;
  for (final d in data) {
    final path = _parsed(d);
    union = union == null
        ? path
        : Path.combine(PathOperation.union, union, path);
  }
  return union ?? Path();
}

List<Path> maleMannequinDetails({required bool front}) {
  final data = front
      ? GeneratedMaleMannequinPaths.frontDetails
      : GeneratedMaleMannequinPaths.backDetails;
  return [for (final d in data) _parsed(d)];
}

Rect bodyMuscleBounds({required bool front, bool female = false}) {
  if (!female && useGeneratedMaleMannequin) {
    return maleMannequinBase(front: front).getBounds();
  }
  Rect? bounds;
  for (final paths in bodyMusclePathsForView(
    front: front,
    female: female,
  ).values) {
    for (final path in paths) {
      final pathBounds = path.getBounds();
      bounds = bounds == null ? pathBounds : bounds.expandToInclude(pathBounds);
    }
  }
  return bounds ?? Rect.zero;
}

/// Merges adjacent body regions into one outer silhouette for soft rendering.
Path bodyMuscleSilhouette({required bool front, bool female = false}) {
  if (!female && useGeneratedMaleMannequin) {
    return maleMannequinBase(front: front);
  }
  final key = '${female ? 'female' : 'male'}-${front ? 'front' : 'back'}';
  return _bodySilhouetteCache.putIfAbsent(key, () {
    Path? union;
    for (final paths in bodyMusclePathsForView(
      front: front,
      female: female,
    ).values) {
      for (final path in paths) {
        union = union == null
            ? path
            : Path.combine(PathOperation.union, union, path);
      }
    }
    return union ?? Path();
  });
}

Path _warpFemalePath(Path path, Rect bodyBounds) {
  const profile = <(double, double)>[
    (0.00, 1.00),
    (0.08, 0.98),
    (0.15, 0.88),
    (0.23, 0.84),
    (0.32, 0.88),
    (0.42, 0.81),
    (0.50, 0.80),
    (0.59, 0.96),
    (0.70, 0.93),
    (0.84, 0.88),
    (1.00, 0.91),
  ];

  double widthFactor(double y) {
    final t = ((y - bodyBounds.top) / bodyBounds.height).clamp(0.0, 1.0);
    for (var i = 0; i < profile.length - 1; i++) {
      final a = profile[i];
      final b = profile[i + 1];
      if (t <= b.$1) {
        final u = ((t - a.$1) / (b.$1 - a.$1)).clamp(0.0, 1.0);
        final eased = u * u * (3 - 2 * u);
        return a.$2 + (b.$2 - a.$2) * eased;
      }
    }
    return profile.last.$2;
  }

  final warped = Path()..fillType = path.fillType;
  for (final metric in path.computeMetrics()) {
    if (metric.length <= 0) continue;
    // Keep the curve smooth at fullscreen scale while caching the result once.
    final samples = (metric.length / 2.5).ceil().clamp(12, 800);
    for (var i = 0; i <= samples; i++) {
      final tangent = metric.getTangentForOffset(metric.length * i / samples);
      if (tangent == null) continue;
      final point = tangent.position;
      final x =
          bodyBounds.center.dx +
          (point.dx - bodyBounds.center.dx) * widthFactor(point.dy);
      if (i == 0) {
        warped.moveTo(x, point.dy);
      } else {
        warped.lineTo(x, point.dy);
      }
    }
    if (metric.isClosed) warped.close();
  }
  return warped;
}

/// Union of all front muscle paths → one closed body silhouette ("hull").
Path _shellPath({bool female = false}) {
  if (female) {
    if (_shellFemaleCache != null) return _shellFemaleCache!;
    _shellFemaleCache = bodyMuscleSilhouette(front: true, female: true);
    return _shellFemaleCache!;
  }
  if (_shellFrontCache != null) return _shellFrontCache!;
  if (useGeneratedMaleMannequin) {
    _shellFrontCache = bodyMuscleSilhouette(front: true);
    return _shellFrontCache!;
  }
  Path? union;
  BodyMusclePaths.front.forEach((slug, list) {
    for (final d in list) {
      final p = _parsed(d);
      union = union == null ? p : Path.combine(PathOperation.union, union!, p);
    }
  });
  _shellFrontCache = union ?? Path();
  return _shellFrontCache!;
}

Rect _localBounds({bool female = false}) {
  if (female) {
    if (_localBoundsFemaleCache != null) return _localBoundsFemaleCache!;
    return _localBoundsFemaleCache = _shellPath(female: true).getBounds();
  }
  if (_localBoundsFrontCache != null) return _localBoundsFrontCache!;
  return _localBoundsFrontCache = _shellPath().getBounds();
}

BodyLayout computeBodyLayout(
  Size size, {
  bool female = false,
  bool reserveStage = true,
  double? scaleBoost,
}) {
  final b = _localBounds(female: female);
  if (b.width <= 0 || b.height <= 0) {
    return BodyLayout(Offset.zero & size);
  }
  final t = bodyFitTransform(
    size,
    b,
    reserveStage: reserveStage,
    scaleBoost: scaleBoost,
  );
  final w = b.width * t.scale;
  final h = b.height * t.scale;
  final left = (size.width - w) / 2;
  final top = t.dy + b.top * t.scale;
  return BodyLayout(Rect.fromLTWH(left, top, w, h));
}

/// Screen Y where the mannequin head top starts.
double bodyHeadTopY(Size size, {bool female = false}) {
  final layout = computeBodyLayout(size, female: female);
  final headTopLocalY = !female && useGeneratedMaleMannequin ? 14.0 : 167.0;
  final b = _localBounds(female: female);
  final scale = layout.bounds.width / b.width;
  final localTop = b.top;
  return layout.bounds.top + (headTopLocalY - localTop) * scale;
}

/// Screen Y where the mannequin head ends — anchor for fullscreen HUD chips.
double bodyHeadBottomY(Size size, {bool female = false}) {
  final layout = computeBodyLayout(size, female: female);
  final headEndLocalY = !female && useGeneratedMaleMannequin ? 125.0 : 310.0;
  final b = _localBounds(female: female);
  final scale = layout.bounds.width / b.width;
  final localTop = b.top;
  return layout.bounds.top + (headEndLocalY - localTop) * scale;
}

Float64List _matrixFor(
  Size size, {
  bool female = false,
  bool reserveStage = true,
  double? scaleBoost,
}) {
  final b = _localBounds(female: female);
  final layout = computeBodyLayout(
    size,
    female: female,
    reserveStage: reserveStage,
    scaleBoost: scaleBoost,
  );
  final scale = layout.bounds.width / b.width;
  return (Matrix4.identity()
        ..translateByDouble(
          layout.bounds.left - b.left * scale,
          layout.bounds.top - b.top * scale,
          0,
          1,
        )
        ..scaleByDouble(scale, scale, 1, 1))
      .storage;
}

void _paintShell(
  Canvas canvas,
  Size size, {
  required double fillAlpha,
  bool female = false,
  bool reserveStage = true,
  double? scaleBoost,
}) {
  final shell = _shellPath(female: female).transform(
    _matrixFor(
      size,
      female: female,
      reserveStage: reserveStage,
      scaleBoost: scaleBoost,
    ),
  );
  final isLight = AppColors.bodyMapBackground.computeLuminance() > 0.5;
  final fill = Paint()
    ..style = PaintingStyle.fill
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isLight
          ? [
              const Color(0xFFCDD2DC).withValues(alpha: fillAlpha),
              const Color(0xFFB4BCC8).withValues(alpha: fillAlpha),
            ]
          : [
              const Color(0xFF2A2D33).withValues(alpha: fillAlpha),
              const Color(0xFF12141A).withValues(alpha: fillAlpha),
            ],
    ).createShader(Offset.zero & size);
  canvas.drawPath(shell, fill);
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeJoin = StrokeJoin.round
    ..color = (isLight ? const Color(0xFF8E96A8) : const Color(0xFF4A4E56))
        .withValues(alpha: fillAlpha);
  canvas.drawPath(shell, stroke);
}

/// Transform used by [BodyMuscleMapPainter] so hit-testing matches the paint.
({Float64List matrix, Rect bounds})? _muscleTransform(
  Size size,
  bool front,
  bool female,
  bool reserveStage,
) {
  final bounds = bodyMuscleBounds(front: front, female: female);
  if (bounds.width <= 0 || bounds.height <= 0) return null;
  final t = bodyFitTransform(size, bounds, reserveStage: reserveStage);
  final matrix =
      (Matrix4.identity()
            ..translateByDouble(t.dx, t.dy, 0, 1)
            ..scaleByDouble(t.scale, t.scale, 1, 1))
          .storage;
  return (matrix: matrix, bounds: bounds);
}

/// Muscle paths transformed into the paint area's coordinate space, keyed by
/// slug. Used to detect which muscle a tap landed on.
Map<String, List<Path>> transformedMusclePaths(
  Size size, {
  required bool front,
  bool female = false,
  bool reserveStage = true,
}) {
  final t = _muscleTransform(size, front, female, reserveStage);
  if (t == null) return const {};
  final data = bodyMusclePathsForView(front: front, female: female);
  final out = <String, List<Path>>{};
  data.forEach((slug, list) {
    out[slug] = [for (final path in list) path.transform(t.matrix)];
  });
  return out;
}

Color statusColor(OrganStatus status) {
  return switch (status) {
    OrganStatus.good => const Color(0xFF3FD07A),
    OrganStatus.mixed => const Color(0xFFFFB020),
    OrganStatus.careful => const Color(0xFFFF453A),
    OrganStatus.noData => const Color(0xFF7C8088),
  };
}

// ─── Organ specs ────────────────────────────────────────────────────────────

class OrganSpec {
  const OrganSpec(this.organ, this.fx, this.fy, this.r);
  final Organ organ;
  final double fx;
  final double fy;
  final double r; // tap radius as a fraction of body width
}

const List<OrganSpec> organSpecs = [
  OrganSpec(Organ.brain, 0.50, 0.055, 0.10),
  OrganSpec(Organ.lungs, 0.50, 0.255, 0.13),
  OrganSpec(Organ.heart, 0.455, 0.265, 0.075),
  OrganSpec(Organ.liver, 0.565, 0.345, 0.10),
  OrganSpec(Organ.stomach, 0.435, 0.345, 0.08),
  OrganSpec(Organ.kidneys, 0.50, 0.43, 0.12),
  OrganSpec(Organ.intestines, 0.50, 0.50, 0.13),
];

class OrganMapPainter extends CustomPainter {
  OrganMapPainter({
    required this.statuses,
    this.selected,
    this.female = false,
    this.reserveStage = true,
  });

  final Map<Organ, OrganStatus> statuses;
  final Organ? selected;
  final bool female;
  final bool reserveStage;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.bodyMapBackground,
    );
    _paintShell(
      canvas,
      size,
      fillAlpha: 0.95,
      female: female,
      reserveStage: reserveStage,
    );
    final layout = computeBodyLayout(
      size,
      female: female,
      reserveStage: reserveStage,
    );
    final bw = layout.bounds.width;

    for (final spec in organSpecs) {
      final c = layout.frac(spec.fx, spec.fy);
      final color = statusColor(statuses[spec.organ] ?? OrganStatus.noData);
      final r = spec.r * bw;
      _drawOrgan(
        canvas,
        spec.organ,
        c,
        r,
        color,
        isSelected: selected == spec.organ,
      );
    }
  }

  void _drawOrgan(
    Canvas canvas,
    Organ organ,
    Offset c,
    double r,
    Color color, {
    required bool isSelected,
  }) {
    canvas.drawCircle(
      c,
      r * 1.05,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [Color.lerp(color, Colors.white, 0.25)!, color],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.6 : 1.2
      ..color = isSelected ? Colors.white : const Color(0xFF202227);

    final path = _organPath(organ, c, r);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    _drawOrganDetails(canvas, organ, c, r, color);
  }

  Path _organPath(Organ organ, Offset c, double r) {
    final p = Path();
    switch (organ) {
      case Organ.heart:
        p.moveTo(c.dx, c.dy + r * 0.92);
        p.cubicTo(
          c.dx - r * 0.28,
          c.dy + r * 0.68,
          c.dx - r * 1.04,
          c.dy + r * 0.14,
          c.dx - r * 0.98,
          c.dy - r * 0.42,
        );
        p.cubicTo(
          c.dx - r * 0.94,
          c.dy - r * 0.98,
          c.dx - r * 0.25,
          c.dy - r * 1.05,
          c.dx,
          c.dy - r * 0.50,
        );
        p.cubicTo(
          c.dx + r * 0.36,
          c.dy - r * 1.13,
          c.dx + r * 1.00,
          c.dy - r * 0.86,
          c.dx + r * 0.92,
          c.dy - r * 0.22,
        );
        p.cubicTo(
          c.dx + r * 0.86,
          c.dy + r * 0.30,
          c.dx + r * 0.34,
          c.dy + r * 0.72,
          c.dx,
          c.dy + r * 0.92,
        );
        p.close();
      case Organ.lungs:
        // Separate tapered lobes leave a clear channel for the heart and airway.
        p.moveTo(c.dx - r * 0.12, c.dy - r * 0.95);
        p.cubicTo(
          c.dx - r * 0.44,
          c.dy - r * 1.08,
          c.dx - r * 0.98,
          c.dy - r * 0.77,
          c.dx - r * 0.96,
          c.dy - r * 0.18,
        );
        p.cubicTo(
          c.dx - r * 0.94,
          c.dy + r * 0.43,
          c.dx - r * 0.68,
          c.dy + r * 0.89,
          c.dx - r * 0.30,
          c.dy + r * 0.95,
        );
        p.cubicTo(
          c.dx - r * 0.10,
          c.dy + r * 0.74,
          c.dx - r * 0.34,
          c.dy + r * 0.34,
          c.dx - r * 0.20,
          c.dy - r * 0.02,
        );
        p.cubicTo(
          c.dx - r * 0.12,
          c.dy - r * 0.31,
          c.dx - r * 0.04,
          c.dy - r * 0.62,
          c.dx - r * 0.12,
          c.dy - r * 0.95,
        );
        p.close();
        p.moveTo(c.dx + r * 0.12, c.dy - r * 0.95);
        p.cubicTo(
          c.dx + r * 0.44,
          c.dy - r * 1.08,
          c.dx + r * 0.98,
          c.dy - r * 0.77,
          c.dx + r * 0.96,
          c.dy - r * 0.18,
        );
        p.cubicTo(
          c.dx + r * 0.94,
          c.dy + r * 0.43,
          c.dx + r * 0.68,
          c.dy + r * 0.89,
          c.dx + r * 0.30,
          c.dy + r * 0.95,
        );
        p.cubicTo(
          c.dx + r * 0.10,
          c.dy + r * 0.74,
          c.dx + r * 0.34,
          c.dy + r * 0.34,
          c.dx + r * 0.20,
          c.dy - r * 0.02,
        );
        p.cubicTo(
          c.dx + r * 0.12,
          c.dy - r * 0.31,
          c.dx + r * 0.04,
          c.dy - r * 0.62,
          c.dx + r * 0.12,
          c.dy - r * 0.95,
        );
        p.close();
      case Organ.brain:
        p.moveTo(c.dx, c.dy + r * 0.78);
        p.cubicTo(
          c.dx - r * 0.36,
          c.dy + r * 0.98,
          c.dx - r * 0.52,
          c.dy + r * 0.65,
          c.dx - r * 0.47,
          c.dy + r * 0.42,
        );
        p.cubicTo(
          c.dx - r * 1.02,
          c.dy + r * 0.32,
          c.dx - r * 1.03,
          c.dy - r * 0.22,
          c.dx - r * 0.72,
          c.dy - r * 0.40,
        );
        p.cubicTo(
          c.dx - r * 0.74,
          c.dy - r * 0.98,
          c.dx - r * 0.18,
          c.dy - r * 1.00,
          c.dx,
          c.dy - r * 0.68,
        );
        p.cubicTo(
          c.dx + r * 0.18,
          c.dy - r * 1.00,
          c.dx + r * 0.74,
          c.dy - r * 0.98,
          c.dx + r * 0.72,
          c.dy - r * 0.40,
        );
        p.cubicTo(
          c.dx + r * 1.03,
          c.dy - r * 0.22,
          c.dx + r * 1.02,
          c.dy + r * 0.32,
          c.dx + r * 0.47,
          c.dy + r * 0.42,
        );
        p.cubicTo(
          c.dx + r * 0.52,
          c.dy + r * 0.65,
          c.dx + r * 0.36,
          c.dy + r * 0.98,
          c.dx,
          c.dy + r * 0.78,
        );
        p.close();
      case Organ.liver:
        p.moveTo(c.dx - r * 1.04, c.dy - r * 0.40);
        p.cubicTo(
          c.dx - r * 0.57,
          c.dy - r * 0.94,
          c.dx + r * 0.48,
          c.dy - r * 0.72,
          c.dx + r * 1.02,
          c.dy - r * 0.30,
        );
        p.cubicTo(
          c.dx + r * 0.96,
          c.dy + r * 0.27,
          c.dx + r * 0.48,
          c.dy + r * 0.76,
          c.dx - r * 0.26,
          c.dy + r * 0.62,
        );
        p.cubicTo(
          c.dx - r * 0.72,
          c.dy + r * 0.55,
          c.dx - r * 0.94,
          c.dy + r * 0.12,
          c.dx - r * 1.04,
          c.dy - r * 0.40,
        );
        p.close();
      case Organ.stomach:
        p.moveTo(c.dx - r * 0.58, c.dy - r * 0.94);
        p.cubicTo(
          c.dx - r * 0.78,
          c.dy - r * 0.36,
          c.dx - r * 0.60,
          c.dy - r * 0.04,
          c.dx - r * 0.26,
          c.dy + r * 0.08,
        );
        p.cubicTo(
          c.dx + r * 0.20,
          c.dy + r * 0.20,
          c.dx + r * 0.70,
          c.dy - r * 0.02,
          c.dx + r * 0.76,
          c.dy + r * 0.39,
        );
        p.cubicTo(
          c.dx + r * 0.84,
          c.dy + r * 0.82,
          c.dx + r * 0.34,
          c.dy + r * 1.02,
          c.dx - r * 0.04,
          c.dy + r * 0.75,
        );
        p.cubicTo(
          c.dx - r * 0.34,
          c.dy + r * 0.54,
          c.dx - r * 0.10,
          c.dy + r * 0.34,
          c.dx + r * 0.18,
          c.dy + r * 0.43,
        );
        p.cubicTo(
          c.dx + r * 0.38,
          c.dy + r * 0.49,
          c.dx + r * 0.42,
          c.dy + r * 0.26,
          c.dx + r * 0.12,
          c.dy + r * 0.14,
        );
        p.cubicTo(
          c.dx - r * 0.30,
          c.dy - r * 0.03,
          c.dx - r * 0.64,
          c.dy - r * 0.33,
          c.dx - r * 0.58,
          c.dy - r * 0.94,
        );
        p.close();
      case Organ.kidneys:
        for (final side in const [-1.0, 1.0]) {
          final kx = c.dx + side * r * 0.57;
          p.moveTo(kx + side * r * 0.18, c.dy - r * 0.75);
          p.cubicTo(
            kx + side * r * 0.78,
            c.dy - r * 0.83,
            kx + side * r * 0.66,
            c.dy + r * 0.72,
            kx + side * r * 0.12,
            c.dy + r * 0.77,
          );
          p.cubicTo(
            kx - side * r * 0.25,
            c.dy + r * 0.80,
            kx - side * r * 0.38,
            c.dy + r * 0.24,
            kx - side * r * 0.08,
            c.dy + r * 0.05,
          );
          p.cubicTo(
            kx + side * r * 0.08,
            c.dy - r * 0.12,
            kx - side * r * 0.24,
            c.dy - r * 0.67,
            kx + side * r * 0.18,
            c.dy - r * 0.75,
          );
          p.close();
        }
      case Organ.intestines:
        p.moveTo(c.dx - r * 0.78, c.dy - r * 0.84);
        p.cubicTo(
          c.dx - r * 0.98,
          c.dy - r * 0.68,
          c.dx - r * 0.94,
          c.dy + r * 0.43,
          c.dx - r * 0.72,
          c.dy + r * 0.75,
        );
        p.cubicTo(
          c.dx - r * 0.56,
          c.dy + r * 1.00,
          c.dx + r * 0.54,
          c.dy + r * 1.00,
          c.dx + r * 0.72,
          c.dy + r * 0.75,
        );
        p.cubicTo(
          c.dx + r * 0.94,
          c.dy + r * 0.43,
          c.dx + r * 0.98,
          c.dy - r * 0.68,
          c.dx + r * 0.78,
          c.dy - r * 0.84,
        );
        p.cubicTo(
          c.dx + r * 0.52,
          c.dy - r * 1.02,
          c.dx + r * 0.44,
          c.dy - r * 0.67,
          c.dx + r * 0.51,
          c.dy - r * 0.44,
        );
        p.cubicTo(
          c.dx + r * 0.64,
          c.dy + r * 0.04,
          c.dx + r * 0.59,
          c.dy + r * 0.57,
          c.dx + r * 0.31,
          c.dy + r * 0.60,
        );
        p.cubicTo(
          c.dx + r * 0.02,
          c.dy + r * 0.65,
          c.dx - r * 0.05,
          c.dy + r * 0.29,
          c.dx - r * 0.30,
          c.dy + r * 0.38,
        );
        p.cubicTo(
          c.dx - r * 0.56,
          c.dy + r * 0.49,
          c.dx - r * 0.60,
          c.dy + r * 0.04,
          c.dx - r * 0.47,
          c.dy - r * 0.37,
        );
        p.cubicTo(
          c.dx - r * 0.39,
          c.dy - r * 0.64,
          c.dx - r * 0.55,
          c.dy - r * 1.02,
          c.dx - r * 0.78,
          c.dy - r * 0.84,
        );
        p.close();
    }
    return p;
  }

  void _drawOrganDetails(
    Canvas canvas,
    Organ organ,
    Offset c,
    double r,
    Color color,
  ) {
    final detail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.75, r * 0.045)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Color.lerp(
        color,
        const Color(0xFF321D28),
        0.48,
      )!.withValues(alpha: 0.78);
    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.65, r * 0.035)
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.42);
    final path = Path();
    switch (organ) {
      case Organ.heart:
        path.moveTo(c.dx - r * 0.08, c.dy - r * 0.48);
        path.quadraticBezierTo(
          c.dx - r * 0.10,
          c.dy + r * 0.05,
          c.dx + r * 0.28,
          c.dy + r * 0.58,
        );
        path.moveTo(c.dx + r * 0.03, c.dy - r * 0.48);
        path.cubicTo(
          c.dx + r * 0.07,
          c.dy - r * 0.90,
          c.dx + r * 0.48,
          c.dy - r * 0.83,
          c.dx + r * 0.50,
          c.dy - r * 0.48,
        );
        canvas.drawPath(path, detail);
      case Organ.lungs:
        path.moveTo(c.dx - r * 0.78, c.dy + r * 0.08);
        path.quadraticBezierTo(
          c.dx - r * 0.68,
          c.dy + r * 0.36,
          c.dx - r * 0.38,
          c.dy + r * 0.46,
        );
        path.moveTo(c.dx + r * 0.78, c.dy + r * 0.08);
        path.quadraticBezierTo(
          c.dx + r * 0.68,
          c.dy + r * 0.36,
          c.dx + r * 0.38,
          c.dy + r * 0.46,
        );
        canvas.drawPath(path, detail);
        final airway = Path()
          ..moveTo(c.dx, c.dy - r * 1.08)
          ..lineTo(c.dx, c.dy - r * 0.34)
          ..moveTo(c.dx, c.dy - r * 0.52)
          ..lineTo(c.dx - r * 0.16, c.dy - r * 0.28)
          ..moveTo(c.dx, c.dy - r * 0.52)
          ..lineTo(c.dx + r * 0.16, c.dy - r * 0.28);
        canvas.drawPath(airway, highlight);
      case Organ.brain:
        path.moveTo(c.dx, c.dy - r * 0.68);
        path.quadraticBezierTo(c.dx - r * 0.10, c.dy, c.dx, c.dy + r * 0.72);
        canvas.drawPath(path, detail);
        for (final side in const [-1.0, 1.0]) {
          final folds = Path()
            ..moveTo(c.dx + side * r * 0.20, c.dy - r * 0.48)
            ..quadraticBezierTo(
              c.dx + side * r * 0.58,
              c.dy - r * 0.42,
              c.dx + side * r * 0.34,
              c.dy - r * 0.12,
            )
            ..moveTo(c.dx + side * r * 0.32, c.dy + r * 0.03)
            ..quadraticBezierTo(
              c.dx + side * r * 0.65,
              c.dy + r * 0.22,
              c.dx + side * r * 0.28,
              c.dy + r * 0.46,
            );
          canvas.drawPath(folds, highlight);
        }
      case Organ.liver:
        path.moveTo(c.dx - r * 0.50, c.dy - r * 0.35);
        path.quadraticBezierTo(
          c.dx + r * 0.06,
          c.dy - r * 0.04,
          c.dx + r * 0.48,
          c.dy + r * 0.27,
        );
        canvas.drawPath(path, highlight);
      case Organ.stomach:
        path.moveTo(c.dx - r * 0.34, c.dy - r * 0.63);
        path.cubicTo(
          c.dx - r * 0.54,
          c.dy - r * 0.12,
          c.dx - r * 0.18,
          c.dy + r * 0.10,
          c.dx + r * 0.30,
          c.dy + r * 0.02,
        );
        canvas.drawPath(path, highlight);
      case Organ.kidneys:
        path.moveTo(c.dx - r * 0.10, c.dy - r * 0.08);
        path.lineTo(c.dx + r * 0.10, c.dy + r * 0.08);
        canvas.drawPath(path, detail);
      case Organ.intestines:
        for (var i = -1; i <= 1; i++) {
          path.moveTo(c.dx - r * 0.38, c.dy - r * 0.24 + i * r * 0.28);
          path.cubicTo(
            c.dx - r * 0.10,
            c.dy - r * 0.42 + i * r * 0.22,
            c.dx + r * 0.30,
            c.dy - r * 0.08 + i * r * 0.22,
            c.dx + r * 0.22,
            c.dy + r * 0.08 + i * r * 0.28,
          );
        }
        canvas.drawPath(path, detail);
    }
  }

  @override
  bool shouldRepaint(covariant OrganMapPainter old) =>
      old.statuses != statuses ||
      old.selected != selected ||
      old.female != female ||
      old.reserveStage != reserveStage;
}

// ─── Skeleton specs ─────────────────────────────────────────────────────────

class JointSpec {
  const JointSpec(this.joint, this.fx, this.fy);
  final BodyJoint joint;
  final double fx;
  final double fy;
}

const List<JointSpec> jointSpecs = [
  JointSpec(BodyJoint.neck, 0.50, 0.115),
  JointSpec(BodyJoint.shoulders, 0.39, 0.165),
  JointSpec(BodyJoint.shoulders, 0.61, 0.165),
  JointSpec(BodyJoint.elbows, 0.33, 0.275),
  JointSpec(BodyJoint.elbows, 0.67, 0.275),
  JointSpec(BodyJoint.wrists, 0.24, 0.46),
  JointSpec(BodyJoint.wrists, 0.76, 0.46),
  JointSpec(BodyJoint.spine, 0.50, 0.33),
  JointSpec(BodyJoint.hips, 0.50, 0.46),
  JointSpec(BodyJoint.knees, 0.44, 0.66),
  JointSpec(BodyJoint.knees, 0.56, 0.66),
  JointSpec(BodyJoint.shins, 0.44, 0.74),
  JointSpec(BodyJoint.shins, 0.56, 0.74),
  JointSpec(BodyJoint.ankles, 0.45, 0.86),
  JointSpec(BodyJoint.ankles, 0.55, 0.86),
];

class SkeletonMapPainter extends CustomPainter {
  SkeletonMapPainter({
    required this.strengthened,
    this.selected,
    this.female = false,
    this.reserveStage = true,
  });

  final Set<BodyJoint> strengthened;
  final BodyJoint? selected;
  final bool female;
  final bool reserveStage;

  static const Color _strong = Color(0xFF3FD07A);
  static const Color _bone = Color(0xFFFFE9C9);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.bodyMapBackground,
    );
    _paintShell(
      canvas,
      size,
      fillAlpha: 0.16,
      female: female,
      reserveStage: reserveStage,
    );
    final layout = computeBodyLayout(
      size,
      female: female,
      reserveStage: reserveStage,
    );
    final bw = layout.bounds.width;

    final bonePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, bw * 0.022)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _bone.withValues(alpha: 0.85);

    Offset f(double x, double y) => layout.frac(x, y);

    // Spine + skull.
    canvas.drawCircle(f(0.50, 0.07), bw * 0.06, bonePaint);
    canvas.drawLine(f(0.50, 0.11), f(0.50, 0.46), bonePaint);
    // Collar bones / shoulders.
    canvas.drawLine(f(0.39, 0.165), f(0.61, 0.165), bonePaint);
    // Rib cage hint.
    for (var i = 0; i < 4; i++) {
      final y = 0.20 + i * 0.035;
      canvas.drawLine(f(0.42, y), f(0.58, y), bonePaint);
    }
    // Pelvis.
    canvas.drawArc(
      Rect.fromCenter(
        center: f(0.50, 0.47),
        width: bw * 0.34,
        height: bw * 0.26,
      ),
      0,
      math.pi,
      false,
      bonePaint,
    );
    // Arms (shoulder → elbow → wrist → hand).
    canvas.drawLine(f(0.39, 0.165), f(0.33, 0.275), bonePaint);
    canvas.drawLine(f(0.33, 0.275), f(0.24, 0.46), bonePaint);
    canvas.drawLine(f(0.24, 0.46), f(0.20, 0.50), bonePaint);
    canvas.drawLine(f(0.61, 0.165), f(0.67, 0.275), bonePaint);
    canvas.drawLine(f(0.67, 0.275), f(0.76, 0.46), bonePaint);
    canvas.drawLine(f(0.76, 0.46), f(0.80, 0.50), bonePaint);
    // Legs.
    canvas.drawLine(f(0.46, 0.47), f(0.44, 0.66), bonePaint);
    canvas.drawLine(f(0.44, 0.66), f(0.44, 0.86), bonePaint);
    canvas.drawLine(f(0.54, 0.47), f(0.56, 0.66), bonePaint);
    canvas.drawLine(f(0.56, 0.66), f(0.56, 0.86), bonePaint);

    // Add bone silhouettes and landmarks over the guide lines so the figure
    // reads as a skeleton at a glance, including the chest and pelvis.
    final edgeWidth = (bw * 0.052).clamp(3.0, 8.0).toDouble();
    final boneEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = edgeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF51483F).withValues(alpha: 0.94);
    final boneFill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = edgeWidth * 0.60
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _bone;
    final fineBone = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, edgeWidth * 0.38)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _bone;

    void bone(Offset a, Offset b, {bool fine = false}) {
      canvas.drawLine(a, b, boneEdge);
      canvas.drawLine(a, b, fine ? fineBone : boneFill);
    }

    final skull = Rect.fromCenter(
      center: f(0.50, 0.075),
      width: bw * 0.12,
      height: bw * 0.15,
    );
    canvas.drawOval(skull, Paint()..color = const Color(0xFF51483F));
    canvas.drawOval(skull.deflate(edgeWidth * 0.34), Paint()..color = _bone);
    final jaw = Path()
      ..moveTo(f(0.455, 0.105).dx, f(0.455, 0.105).dy)
      ..quadraticBezierTo(
        f(0.50, 0.14).dx,
        f(0.50, 0.14).dy,
        f(0.545, 0.105).dx,
        f(0.545, 0.105).dy,
      );
    canvas.drawPath(jaw, boneEdge);
    canvas.drawPath(jaw, fineBone);

    // Curved clavicles and ribs form the familiar chest cage.
    for (final side in const [-1.0, 1.0]) {
      final collar = Path()
        ..moveTo(f(0.50, 0.165).dx, f(0.50, 0.165).dy)
        ..quadraticBezierTo(
          f(0.50 + side * 0.065, 0.145).dx,
          f(0.50 + side * 0.065, 0.145).dy,
          f(0.50 + side * 0.115, 0.17).dx,
          f(0.50 + side * 0.115, 0.17).dy,
        );
      canvas.drawPath(collar, boneEdge);
      canvas.drawPath(collar, boneFill);
      for (var i = 0; i < 5; i++) {
        final y = 0.205 + i * 0.036;
        final rib = Path()
          ..moveTo(f(0.50, y).dx, f(0.50, y).dy)
          ..cubicTo(
            f(0.50 + side * 0.10, y - 0.01).dx,
            f(0.50 + side * 0.10, y - 0.01).dy,
            f(0.50 + side * 0.14, y + 0.032).dx,
            f(0.50 + side * 0.14, y + 0.032).dy,
            f(0.50 + side * 0.085, y + 0.045).dx,
            f(0.50 + side * 0.085, y + 0.045).dy,
          );
        canvas.drawPath(rib, boneEdge);
        canvas.drawPath(rib, fineBone);
      }
    }
    // Individual vertebrae are clearer than a single uninterrupted spine.
    for (var i = 0; i < 10; i++) {
      final center = f(0.50, 0.19 + i * 0.027);
      final vertebra = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: bw * (i < 5 ? 0.052 : 0.043),
          height: bw * 0.028,
        ),
        Radius.circular(edgeWidth),
      );
      canvas.drawRRect(vertebra, Paint()..color = const Color(0xFF51483F));
      canvas.drawRRect(
        vertebra.deflate(edgeWidth * 0.24),
        Paint()..color = _bone,
      );
    }
    final pelvis = Path()
      ..moveTo(f(0.50, 0.415).dx, f(0.50, 0.415).dy)
      ..cubicTo(
        f(0.46, 0.40).dx,
        f(0.46, 0.40).dy,
        f(0.405, 0.415).dx,
        f(0.405, 0.415).dy,
        f(0.385, 0.455).dx,
        f(0.385, 0.455).dy,
      )
      ..cubicTo(
        f(0.41, 0.50).dx,
        f(0.41, 0.50).dy,
        f(0.455, 0.51).dx,
        f(0.455, 0.51).dy,
        f(0.48, 0.475).dx,
        f(0.48, 0.475).dy,
      )
      ..moveTo(f(0.50, 0.415).dx, f(0.50, 0.415).dy)
      ..cubicTo(
        f(0.54, 0.40).dx,
        f(0.54, 0.40).dy,
        f(0.595, 0.415).dx,
        f(0.595, 0.415).dy,
        f(0.615, 0.455).dx,
        f(0.615, 0.455).dy,
      )
      ..cubicTo(
        f(0.59, 0.50).dx,
        f(0.59, 0.50).dy,
        f(0.545, 0.51).dx,
        f(0.545, 0.51).dy,
        f(0.52, 0.475).dx,
        f(0.52, 0.475).dy,
      );
    canvas.drawPath(pelvis, boneEdge);
    canvas.drawPath(pelvis, boneFill);

    // Separate forearm and shin bones, plus small hand and foot landmarks.
    for (final side in const [-1.0, 1.0]) {
      for (final offset in const [-0.012, 0.012]) {
        bone(
          f(0.50 + side * 0.17 + offset, 0.29),
          f(0.50 + side * 0.26 + offset, 0.455),
          fine: true,
        );
        bone(
          f(0.50 + side * 0.055 + offset, 0.67),
          f(0.50 + side * 0.055 + offset, 0.86),
          fine: true,
        );
      }
      bone(
        f(0.50 + side * 0.275, 0.47),
        f(0.50 + side * 0.30, 0.49),
        fine: true,
      );
      for (var finger = -1; finger <= 2; finger++) {
        bone(
          f(0.50 + side * (0.275 + finger * 0.014), 0.48),
          f(0.50 + side * (0.29 + finger * 0.018), 0.515),
          fine: true,
        );
      }
      bone(
        f(0.50 + side * 0.055, 0.86),
        f(0.50 + side * 0.09, 0.89),
        fine: true,
      );
      bone(
        f(0.50 + side * 0.075, 0.87),
        f(0.50 + side * 0.11, 0.895),
        fine: true,
      );
    }

    // Joint markers: a small light surface with an accent outline makes each
    // tappable point legible on both the pale bones and the shaded body, while
    // keeping the markers compact enough not to dominate the skeleton.
    for (final spec in jointSpecs) {
      final c = layout.frac(spec.fx, spec.fy);
      final on = strengthened.contains(spec.joint);
      final isSelected = selected == spec.joint;
      final r = math.max(4.1, bw * 0.024);
      if (on) {
        canvas.drawCircle(
          c,
          r * 1.6,
          Paint()
            ..color = _strong.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
      canvas.drawCircle(
        c,
        r * 1.32,
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
      canvas.drawCircle(
        c,
        r * 1.08,
        Paint()..color = on ? _strong : const Color(0xFFEAF4E2),
      );
      canvas.drawCircle(
        c,
        r * 1.08,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.8 : 1.1
          ..color = isSelected
              ? const Color(0xFF225A3B)
              : const Color(0xFF6D9D4C),
      );
      canvas.drawCircle(
        c,
        r * 0.48,
        Paint()..color = on ? Colors.white : const Color(0xFF5E9D35),
      );
      if (isSelected) {
        canvas.drawCircle(
          c,
          r * 1.62,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xFF225A3B).withValues(alpha: 0.72),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SkeletonMapPainter old) =>
      old.strengthened != strengthened ||
      old.selected != selected ||
      old.female != female ||
      old.reserveStage != reserveStage;
}
