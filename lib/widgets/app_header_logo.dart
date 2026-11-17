import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppHeaderLogo extends StatelessWidget {
  const AppHeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: Center(
        child: Text(
          'Kaizen',
          style: TextStyle(
            color: AppColors.accentText,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
