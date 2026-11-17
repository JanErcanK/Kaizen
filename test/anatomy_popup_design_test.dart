import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/l10n/catalog_localizations.dart';
import 'package:kaizen/models/body_map_view_mode.dart';
import 'package:kaizen/services/anatomy_tips.dart';
import 'package:kaizen/services/muscle_exercise_filter.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/theme/app_colors.dart';
import 'package:kaizen/widgets/body_map_tab_intro_dialog.dart';
import 'package:kaizen/widgets/muscle_exercise_popup.dart';
import 'package:kaizen/widgets/muscle_segment_labels.dart';

const _segment = MuscleSegmentHit(
  slug: 'abs-upper',
  pathIndex: -1,
  front: true,
);
const _description =
    'Region des geraden Bauchmuskels. Die Übungen setzen unterschiedliche '
    'Schwerpunkte; der gesamte Muskel arbeitet mit.';

Widget _host(
  Widget child, {
  required bool dark,
  double textScale = 1,
  Locale locale = const Locale('de'),
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(body: child),
);

void _smallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(379, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('kaizen_popup_design_');
    await ProgressStore.init(storageRootPath: storage.path);
    await ProgressStore.setUseGerman(true);
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('exercise popup fits 379 px in $mode and retains actions', (
      tester,
    ) async {
      _smallViewport(tester);
      await tester.runAsync(() => ProgressStore.setUseLightTheme(!dark));
      var closeCount = 0;
      await tester.pumpWidget(
        _host(
          MuscleExercisePopup(
            segment: _segment,
            bodySize: const Size(379, 760),
            titleOverride: 'Obere Bauchregion',
            descriptionOverride: _description,
            onClose: () => closeCount++,
          ),
          dark: dark,
          textScale: 1.15,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final tabs = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabs.indicator, isA<UnderlineTabIndicator>());
      expect(tabs.labelColor, AppColors.textPrimary);
      final tabRect = tester.getRect(find.byType(TabBar));
      expect(tabRect.width, greaterThan(240));
      expect(
        tester.getSize(find.byKey(const ValueKey('anatomy-muscle-card'))).width,
        lessThanOrEqualTo(379 * .76),
      );
      expect(tabRect.left, greaterThanOrEqualTo(12));
      expect(tabRect.right, lessThanOrEqualTo(367));
      final title = tester.widget<Text>(find.text('Obere Bauchregion'));
      expect(title.style?.color, AppColors.textPrimary);
      final gym = MuscleExerciseFilter.gymExercisesFor(_segment).first;
      expect(
        find.text(CatalogLocalizations.gymExerciseName(gym.name)),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Hinzufügen').first);
      await tester.pumpAndSettle();
      expect(find.text('Zeit'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byType(Dialog))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Körpergewicht'));
      await tester.pumpAndSettle();
      final cali = MuscleExerciseFilter.calisthenicsExercisesFor(
        _segment,
      ).first;
      expect(
        find.text(CatalogLocalizations.calisthenicsExerciseName(cali.name)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Schließen'));
      expect(closeCount, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'all four tips lists scroll at 379 px in $mode; close stays reachable',
      (tester) async {
        _smallViewport(tester);
        await tester.runAsync(() => ProgressStore.setUseLightTheme(!dark));
        for (final category in [
          BodyMapViewMode.recovery,
          BodyMapViewMode.skeleton,
          BodyMapViewMode.connective,
          BodyMapViewMode.organs,
        ]) {
          await tester.pumpWidget(
            _host(
              Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      BodyMapTabIntroDialog.show(context, category),
                  child: const Text('Open intro'),
                ),
              ),
              dark: dark,
              textScale: 1.3,
            ),
          );
          await tester.tap(find.text('Open intro'));
          await tester.pumpAndSettle();
          expect(find.byType(FilledButton), findsNothing);
          expect(find.textContaining('Z-Anatomy / BodyParts3D'), findsNothing);
          expect(find.byType(ExpansionTile), findsNothing);
          expect(
            find.text(BodyMapTabIntroDialog.legend(true, category)),
            findsOneWidget,
          );
          final tips = AnatomyTips.forMode(category);
          expect(find.text(tips.first.titleDe), findsOneWidget);
          final last = find.byKey(ValueKey('anatomy-tip-${tips.last.id}'));
          await tester.scrollUntilVisible(
            last,
            200,
            scrollable: find.descendant(
              of: find.byKey(const ValueKey('anatomy-tips-list')),
              matching: find.byType(Scrollable),
            ),
          );
          expect(find.text(tips.last.descriptionDe), findsOneWidget);
          expect(tester.takeException(), isNull);
          final close = find.widgetWithText(TextButton, 'Schließen');
          expect(tester.getRect(close).bottom, lessThan(760));
          await tester.tap(close);
          await tester.pumpAndSettle();
          expect(find.byType(Dialog), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
    );
  }

  testWidgets('English organ tips use translated copy at small width', (
    tester,
  ) async {
    _smallViewport(tester);
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                BodyMapTabIntroDialog.show(context, BodyMapViewMode.organs),
            child: const Text('Open tips'),
          ),
        ),
        dark: false,
        locale: const Locale('en'),
      ),
    );
    await tester.tap(find.text('Open tips'));
    await tester.pumpAndSettle();
    expect(find.text('Organs'), findsOneWidget);
    expect(find.text('10 practical tips for everyday life'), findsOneWidget);
    final tip = AnatomyTips.forMode(BodyMapViewMode.organs).first;
    expect(find.text(tip.titleEn), findsOneWidget);
    expect(find.text(tip.descriptionEn), findsOneWidget);
    expect(find.text(tip.titleDe), findsNothing);
    expect(find.text('Gold: selected'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
