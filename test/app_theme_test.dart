import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/theme/app_colors.dart';
import 'package:kaizen/theme/app_theme.dart';
import 'package:kaizen/widgets/on_the_go_gradient_button.dart';

double contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return (math.max(first, second) + .05) / (math.min(first, second) + .05);
}

void main() {
  for (final light in [true, false]) {
    final name = light ? 'light' : 'dark';
    test('$name semantic text pairs retain readable contrast', () {
      final palette = AppColors.paletteFor(light);
      final theme = AppTheme.build(light: light);
      final scheme = theme.colorScheme;
      for (final pair in [
        [palette.text, palette.surface],
        [palette.muted, palette.surface],
        [palette.text, palette.softSurface],
        [palette.onAction, palette.actionBackground],
        [palette.onSelected, palette.selectedBackground],
        [palette.accentText, palette.surface],
        [scheme.onSecondaryContainer, scheme.secondaryContainer],
      ]) {
        expect(contrast(pair[0], pair[1]), greaterThanOrEqualTo(4.5));
      }
      expect(scheme.brightness, light ? Brightness.light : Brightness.dark);
      expect(scheme.secondaryContainer, palette.softSurface);
      expect(theme.dialogTheme.backgroundColor, palette.surface);
      expect(theme.snackBarTheme.contentTextStyle?.color, palette.text);
      expect(
        contrast(theme.snackBarTheme.contentTextStyle!.color!, palette.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(theme.chipTheme.selectedColor, palette.selectedBackground);
      expect(theme.chipTheme.checkmarkColor, palette.onSelected);
    });

    testWidgets('$name baby-blue actions and tonal surfaces stay distinct', (
      tester,
    ) async {
      final palette = AppColors.paletteFor(light);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(light: light),
          home: Scaffold(
            body: Column(
              children: [
                FilledButton(
                  key: const Key('primary'),
                  onPressed: () {},
                  child: const Text('Save'),
                ),
                FilledButton.tonal(
                  key: const Key('tonal'),
                  onPressed: () {},
                  child: const Text('Details'),
                ),
                const OnTheGoGradientButton(
                  label: 'Unavailable action',
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
      );
      Material materialFor(Key key) => tester.widget<Material>(
        find.descendant(of: find.byKey(key), matching: find.byType(Material)),
      );
      final primary = materialFor(const Key('primary'));
      final tonal = materialFor(const Key('tonal'));
      expect(primary.color, palette.actionBackground);
      expect(primary.textStyle?.color, palette.onAction);
      expect(tonal.color, palette.softSurface);
      expect(tonal.textStyle?.color, palette.text);
      final start = tester.widget<FilledButton>(
        find.descendant(
          of: find.byType(OnTheGoGradientButton),
          matching: find.byType(FilledButton),
        ),
      );
      expect(start.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
