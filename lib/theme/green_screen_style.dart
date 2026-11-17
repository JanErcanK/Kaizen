import 'package:flutter/material.dart';

import '../services/progress_store.dart';
import 'app_colors.dart';

/// Reference palette for the food catalog, dishes and running controls.
class GreenScreenStyle {
  GreenScreenStyle._();

  static const accent = AppColors.lightPrimary;
  static const ink = Color(0xFF456D00);
  static Color get soft => ProgressStore.useLightTheme
      ? const Color(0xFFF0F7E3)
      : const Color(0xFF26351B);
  static Color get foreground =>
      ProgressStore.useLightTheme ? ink : const Color(0xFFC6E89A);
  static Color get field => ProgressStore.useLightTheme
      ? const Color(0xFFF0F0F5)
      : const Color(0xFF2C2C2E);
}
