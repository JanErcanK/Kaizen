import 'package:flutter/material.dart';

import '../services/progress_store.dart';

/// Semantic UI colors. Values depend on [ProgressStore.useLightTheme]
/// Shared surfaces and accents for the home dashboard and the rest of the app.
class AppColors {
  AppColors._();

  static const Color darkPrimary = Color(0xFFCCFF00);
  static const Color lightPrimary = Color(0xFF6FAE00);
  // Brighter leaf green for white launcher text. Keep Android's
  // level_icon_green and pubspec's adaptive_icon_background in sync.
  static const Color launcherBackground = Color(0xFFA8D878);
  static const Color babyBlue = Color(0xFFBFE4FA);

  static const Color secondary = babyBlue;
  static const Color tertiary = Color(0xFFFF3D00);

  static const Color _darkBackground = Color(0xFF0A0A0A);
  static const Color _darkCard = Color(0xFF1C1C1E);
  static const Color _darkTextPrimary = Color(0xFFF2F2F2);
  static const Color _darkTextMuted = Color(0xFF9A9A9A);
  static const Color _darkStroke = Color(0xFF343434);

  /// Barely off-white canvas; white cards float above it.
  static const Color _lightBackground = Color(0xFFFAFAFA);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF1C1C1E);
  static const Color _lightTextMuted = Color(0xFF636366);
  static const Color _lightStroke = Color(0xFFE8E8ED);

  static bool get _light => ProgressStore.useLightTheme;

  static Color get primary => _light ? lightPrimary : darkPrimary;

  /// Bright brand colours belong on accents and fills; text keeps its contrast.
  static Color get accentText => paletteFor(_light).accentText;

  static Color get actionBackground => paletteFor(_light).actionBackground;
  static Color get onAction => paletteFor(_light).onAction;
  static Color get softSurface => paletteFor(_light).softSurface;
  static Color get selectedBackground => paletteFor(_light).selectedBackground;
  static Color get onSelected => paletteFor(_light).onSelected;

  /// Pure palette access also lets previews/tests build both themes without
  /// changing the user's stored theme preference.
  static KaizenPalette paletteFor(bool light) => light
      ? const KaizenPalette(
          background: _lightBackground,
          surface: _lightCard,
          text: _lightTextPrimary,
          muted: _lightTextMuted,
          stroke: _lightStroke,
          accent: lightPrimary,
          accentText: Color(0xFF293743),
          secondary: babyBlue,
          actionBackground: babyBlue,
          onAction: Color(0xFF203442),
          softSurface: Color(0xFFF1F6FA),
          selectedBackground: Color(0xFFE9F5CF),
          onSelected: Color(0xFF293743),
        )
      : const KaizenPalette(
          background: _darkBackground,
          surface: _darkCard,
          text: _darkTextPrimary,
          muted: _darkTextMuted,
          stroke: _darkStroke,
          accent: darkPrimary,
          accentText: darkPrimary,
          secondary: babyBlue,
          actionBackground: babyBlue,
          onAction: Color(0xFF203442),
          softSurface: Color(0xFF252A31),
          selectedBackground: Color(0xFFCCFF00),
          onSelected: Color(0xFF252A31),
        );

  /// Category accents — one color per domain, used on home, calendar, and screens.
  static Color get workout => primary;
  static const Color nutrition = Color(0xFF4DA3FF);
  static const Color burn = Color(0xFFFF8C42);
  static const Color running = Color(0xFF8E5BFF);

  static Color get background => _light ? _lightBackground : _darkBackground;

  static Color get card => _light ? _lightCard : _darkCard;

  static Color get textPrimary => _light ? _lightTextPrimary : _darkTextPrimary;

  static Color get textMuted => _light ? _lightTextMuted : _darkTextMuted;

  static Color get stroke => _light ? _lightStroke : _darkStroke;

  /// Canvas behind the interactive mannequin — matches the app background so
  /// the figure blends into the screen instead of sitting in a visible box.
  static Color get bodyMapBackground =>
      _light ? _lightBackground : _darkBackground;

  /// Card / panel decoration. Light: soft shadow, no border. Dark: stroke border.
  static BoxDecoration surfaceDecoration({
    BorderRadiusGeometry borderRadius = const BorderRadius.all(
      Radius.circular(12),
    ),
    Color? color,
  }) {
    if (_light) {
      return BoxDecoration(
        color: color ?? _lightCard,
        borderRadius: borderRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      );
    }

    return BoxDecoration(
      color: color ?? _darkCard,
      borderRadius: borderRadius,
      border: Border.all(color: _darkStroke),
    );
  }

  /// Theme-aware card decoration; rebuilds when [Theme] brightness changes.
  static BoxDecoration themedCardDecoration(
    BuildContext context, {
    BorderRadiusGeometry borderRadius = const BorderRadius.all(
      Radius.circular(12),
    ),
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final surface = Theme.of(context).colorScheme.surface;
    if (isLight) {
      return BoxDecoration(
        color: surface,
        borderRadius: borderRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      );
    }

    return BoxDecoration(
      color: surface,
      borderRadius: borderRadius,
      border: Border.all(color: stroke),
    );
  }

  /// Day-cell styling for the profile workout calendar.
  /// Empty days stay clean (no grey boxes); active / today get soft accents.
  static BoxDecoration calendarDayDecoration(
    BuildContext context, {
    bool isToday = false,
    bool hasWorkouts = false,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final radius = BorderRadius.circular(14);

    if (isToday && hasWorkouts) {
      return BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: isLight ? 0.22 : 0.28),
            primary.withValues(alpha: isLight ? 0.10 : 0.12),
          ],
        ),
        border: Border.all(
          color: primary.withValues(alpha: isLight ? 0.55 : 0.65),
          width: 1.4,
        ),
      );
    }

    if (isToday) {
      return BoxDecoration(
        borderRadius: radius,
        color: primary.withValues(alpha: isLight ? 0.10 : 0.14),
        border: Border.all(
          color: primary.withValues(alpha: isLight ? 0.70 : 0.80),
          width: 1.4,
        ),
      );
    }

    if (hasWorkouts) {
      return BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isLight
              ? [
                  primary.withValues(alpha: 0.12),
                  secondary.withValues(alpha: 0.06),
                ]
              : [primary.withValues(alpha: 0.16), Color(0xFF1A1A1C)],
        ),
        border: Border.all(
          color: primary.withValues(alpha: isLight ? 0.18 : 0.22),
        ),
      );
    }

    // Rest / empty days: no grey tile — keep the grid airy.
    return BoxDecoration(borderRadius: radius);
  }

  /// For Material shapes (dialogs, chips) that use [RoundedRectangleBorder.side].
  static BorderSide surfaceBorderSide({Color? color}) {
    if (_light) return BorderSide.none;
    return BorderSide(color: color ?? _darkStroke);
  }
}

@immutable
class KaizenPalette {
  const KaizenPalette({
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.stroke,
    required this.accent,
    required this.accentText,
    required this.secondary,
    required this.actionBackground,
    required this.onAction,
    required this.softSurface,
    required this.selectedBackground,
    required this.onSelected,
  });

  final Color background,
      surface,
      text,
      muted,
      stroke,
      accent,
      accentText,
      secondary;
  final Color actionBackground,
      onAction,
      softSurface,
      selectedBackground,
      onSelected;
}
