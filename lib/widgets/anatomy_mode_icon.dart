import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/body_map_view_mode.dart';

/// Recognizable anatomy symbols shared by the compact and expanded toolbar.
class AnatomyModeIcon extends StatelessWidget {
  const AnatomyModeIcon({
    super.key,
    required this.mode,
    required this.color,
    required this.size,
  });

  final BodyMapViewMode mode;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (mode == BodyMapViewMode.skeleton) {
      return SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _BonePainter(color)),
      );
    }
    return Icon(
      switch (mode) {
        BodyMapViewMode.connective => Icons.link_rounded,
        BodyMapViewMode.organs => Icons.favorite_rounded,
        _ => Icons.accessibility_new_rounded,
      },
      size: size,
      color: color,
    );
  }
}

class _BonePainter extends CustomPainter {
  const _BonePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / 24, size.height / 24);
    canvas.rotate(-math.pi / 4);
    var bone = Path()..addRect(const Rect.fromLTWH(-7, -1.65, 14, 3.3));
    for (final x in [-7.0, 7.0]) {
      for (final y in [-1.8, 1.8]) {
        bone = Path.combine(
          PathOperation.union,
          bone,
          Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: 2.5)),
        );
      }
    }
    canvas.drawPath(bone, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BonePainter oldDelegate) => oldDelegate.color != color;
}
