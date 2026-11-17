import 'package:flutter/material.dart';

/// Full-width training action using the shared app button style.
class OnTheGoGradientButton extends StatelessWidget {
  const OnTheGoGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.bolt_rounded,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}
