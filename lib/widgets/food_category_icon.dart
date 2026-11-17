import 'package:flutter/material.dart';

import '../theme/green_screen_style.dart';

/// Quiet outline illustrations, matching the food catalog reference.
class FoodCategoryIcon extends StatelessWidget {
  const FoodCategoryIcon({super.key, required this.name, this.tags = const []});
  final String name;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final words = '$name ${tags.join(' ')}'.toLowerCase();
    final egg = name.toLowerCase().contains('eier');
    final fish =
        tags.contains('fisch') ||
        [
          'lachs',
          'kabeljau',
          'zander',
          'scholle',
          'hering',
          'forelle',
          'makrele',
          'sardine',
          'thunfisch',
          'hecht',
          'saibling',
          'aal',
        ].any(name.toLowerCase().contains);
    IconData icon = Icons.eco_outlined;
    if (RegExp(
      'schokol|kakao|keks|kuchen|waffel|zucker|honig',
    ).hasMatch(words)) {
      icon = Icons.cookie_outlined;
    } else if (RegExp(
      'milch|joghurt|quark|skyr|käse|kefir|sahne',
    ).hasMatch(words)) {
      icon = Icons.water_drop_outlined;
    } else if (RegExp(
      'brot|reis|mehl|nudel|hafer|getreide|müsli|flocken',
    ).hasMatch(words)) {
      icon = Icons.grass_outlined;
    } else if (RegExp(
      'fleisch|hähnchen|pute|rind|schwein|wurst',
    ).hasMatch(words)) {
      icon = Icons.restaurant_outlined;
    } else if (RegExp('kaffee|tee|saft|drink').hasMatch(words)) {
      icon = Icons.local_cafe_outlined;
    } else if (RegExp('öl|butter|margarine').hasMatch(words)) {
      icon = Icons.water_drop_outlined;
    }
    return ExcludeSemantics(
      child: Container(
        width: 46,
        height: 48,
        decoration: BoxDecoration(
          color: GreenScreenStyle.soft,
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: egg || fish
            ? CustomPaint(
                size: const Size(34, 34),
                painter: _FoodOutlinePainter(
                  fish: fish,
                  quail: name == 'Wachteleier',
                  color: GreenScreenStyle.accent,
                ),
              )
            : Icon(icon, color: GreenScreenStyle.accent, size: 28),
      ),
    );
  }
}

class _FoodOutlinePainter extends CustomPainter {
  const _FoodOutlinePainter({
    required this.fish,
    required this.quail,
    required this.color,
  });
  final bool fish;
  final bool quail;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 40, size.height / 40);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (fish) {
      canvas.drawPath(
        Path()
          ..moveTo(8, 18)
          ..quadraticBezierTo(24, 6, 38, 20)
          ..quadraticBezierTo(24, 33, 8, 23)
          ..lineTo(2, 27)
          ..lineTo(4, 20)
          ..lineTo(2, 15)
          ..close(),
        pen,
      );
      canvas.drawPath(
        Path()
          ..moveTo(27, 13)
          ..quadraticBezierTo(24, 20, 29, 27),
        pen,
      );
      canvas.drawPath(
        Path()
          ..moveTo(18, 12)
          ..lineTo(20, 9)
          ..lineTo(24, 12),
        pen,
      );
      canvas.drawCircle(const Offset(32, 19), 1, Paint()..color = color);
      return;
    }
    void egg(double x, double y, double scale) {
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(scale);
      canvas.drawPath(
        Path()
          ..moveTo(20, 5)
          ..cubicTo(13, 5, 8, 20, 8, 26)
          ..cubicTo(8, 40, 32, 40, 32, 26)
          ..cubicTo(32, 20, 27, 5, 20, 5),
        pen,
      );
      if (quail) {
        for (final dot in [
          const Offset(18, 17),
          const Offset(24, 24),
          const Offset(16, 28),
        ]) {
          canvas.drawCircle(dot, 1.3, Paint()..color = color);
        }
      }
      canvas.restore();
    }

    if (quail) {
      egg(10, -1, 0.5);
      egg(-1, 16, 0.5);
      egg(20, 16, 0.5);
    } else {
      egg(0, -2, 1);
    }
  }

  @override
  bool shouldRepaint(_FoodOutlinePainter oldDelegate) =>
      oldDelegate.fish != fish ||
      oldDelegate.quail != quail ||
      oldDelegate.color != color;
}
