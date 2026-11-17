import 'package:flutter/material.dart';

import 'app_colors.dart';
import '../widgets/app_back_button.dart';

/// Baby-blue actions and fresh Kaizen-green accents, with readable text in both themes.
class AppTheme {
  AppTheme._();

  static ThemeData build({required bool light}) {
    final p = AppColors.paletteFor(light);
    final brightness = light ? Brightness.light : Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.accent,
          brightness: brightness,
        ).copyWith(
          // Filled actions use baby blue; selected controls use Kaizen green.
          primary: p.actionBackground,
          onPrimary: p.onAction,
          primaryContainer: p.selectedBackground,
          onPrimaryContainer: p.onSelected,
          secondary: p.secondary,
          onSecondary: p.onAction,
          secondaryContainer: p.softSurface,
          onSecondaryContainer: p.text,
          tertiary: p.accent,
          onTertiary: p.onSelected,
          tertiaryContainer: p.selectedBackground,
          onTertiaryContainer: p.onSelected,
          surface: p.surface,
          onSurface: p.text,
          onSurfaceVariant: p.muted,
          surfaceContainerLowest: p.background,
          surfaceContainerLow: p.surface,
          surfaceContainer: p.softSurface,
          surfaceContainerHigh: p.softSurface,
          surfaceContainerHighest: p.selectedBackground,
          outline: p.stroke,
          outlineVariant: p.stroke,
          surfaceTint: Colors.transparent,
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    const buttonText = TextStyle(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w700,
      fontSize: 14,
    );
    final baseButton = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(44, 46)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      textStyle: const WidgetStatePropertyAll(buttonText),
      shape: WidgetStatePropertyAll(shape),
      elevation: const WidgetStatePropertyAll(0),
    );
    Color enabledOr(Set<WidgetState> states, Color enabled) =>
        states.contains(WidgetState.disabled)
        ? p.muted.withValues(alpha: .45)
        : enabled;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: p.stroke),
    );
    return ThemeData(
      useMaterial3: true,
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const AppBackIcon(),
      ),
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      dividerColor: p.stroke,
      disabledColor: p.muted.withValues(alpha: .45),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accentText,
        selectionColor: p.accent.withValues(alpha: .22),
        selectionHandleColor: p.accentText,
      ),
      appBarTheme: AppBarTheme(
        leadingWidth: 44,
        backgroundColor: p.background,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: p.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: baseButton),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseButton.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? p.softSurface
                : p.actionBackground,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => enabledOr(states, p.onAction),
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: baseButton.copyWith(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => enabledOr(states, p.text),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: p.stroke)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: baseButton.copyWith(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => enabledOr(states, p.accentText),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(shape: WidgetStatePropertyAll(shape)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.actionBackground,
        foregroundColor: p.onAction,
        elevation: 0,
        shape: shape,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: baseButton.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? p.selectedBackground
                : p.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => enabledOr(
              states,
              states.contains(WidgetState.selected) ? p.onSelected : p.text,
            ),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: p.stroke)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.softSurface,
        selectedColor: p.selectedBackground,
        secondarySelectedColor: p.selectedBackground,
        disabledColor: p.softSurface,
        labelStyle: TextStyle(color: p.text, fontWeight: FontWeight.w600),
        secondaryLabelStyle: TextStyle(
          color: p.onSelected,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: p.onSelected,
        side: BorderSide(color: p.stroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: p.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(color: p.muted, fontSize: 14, height: 1.45),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: p.muted,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: p.text),
        shape: shape,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: p.softSurface,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: p.accent, width: 1.5),
        ),
        hintStyle: TextStyle(color: p.muted),
        labelStyle: TextStyle(color: p.muted),
        floatingLabelStyle: TextStyle(color: p.accentText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.text,
        unselectedLabelColor: p.muted,
        indicatorColor: p.accent,
        dividerColor: p.stroke,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.accent
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(p.onSelected),
        side: BorderSide(color: p.muted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : p.muted,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : p.softSurface,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.onSelected : p.muted,
        ),
        trackOutlineColor: WidgetStatePropertyAll(p.stroke),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.accent,
        thumbColor: p.accent,
        inactiveTrackColor: p.softSurface,
        overlayColor: p.accent.withValues(alpha: .12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.softSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.selectedBackground,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: p.text, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? p.accentText
                : p.muted,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.accentText,
        unselectedItemColor: p.muted,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surface,
        contentTextStyle: TextStyle(color: p.text),
        actionTextColor: p.accentText,
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.surface,
        headerForegroundColor: p.text,
        shape: shape,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.surface,
        hourMinuteColor: p.softSurface,
        hourMinuteTextColor: p.text,
        dayPeriodColor: p.selectedBackground,
        dayPeriodTextColor: p.onSelected,
        dialBackgroundColor: p.softSurface,
        dialHandColor: p.actionBackground,
        shape: shape,
      ),
    );
  }
}
