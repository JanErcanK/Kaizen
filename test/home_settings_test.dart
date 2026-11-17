import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/navigation/app_tab_navigation.dart';
import 'package:kaizen/screens/profile_screen.dart';
import 'package:kaizen/screens/root_shell.dart';
import 'package:kaizen/screens/start_screen.dart';
import 'package:kaizen/screens/workout_hub_screen.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/theme/app_colors.dart';
import 'package:kaizen/theme/app_theme.dart';
import 'package:kaizen/widgets/home_fasting_hud.dart';
import 'package:kaizen/widgets/recovery_body_map.dart';

Widget host(Widget child) => MaterialApp(
  theme: AppTheme.build(light: ProgressStore.useLightTheme),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('kaizen_home_settings_');
    await ProgressStore.init(storageRootPath: storage.path);
    await ProgressStore.saveEatingWindow(
      startMinutes: 720,
      endMinutes: 1200,
      remindersEnabled: false,
    );
    AppTabNavigation.selectedTab.value = 0;
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });

  test(
    'new installs default to light and English; saved choices survive restart',
    () async {
      expect(ProgressStore.useLightTheme, isTrue);
      expect(ProgressStore.appLocaleCode, 'en');
      await ProgressStore.closeForTesting();
      await ProgressStore.init(storageRootPath: storage.path);
      expect(ProgressStore.appLocaleCode, 'en');
      await ProgressStore.setUseLightTheme(false);
      await ProgressStore.setUseGerman(true);
      await ProgressStore.closeForTesting();
      await ProgressStore.init(storageRootPath: storage.path);
      expect(ProgressStore.useLightTheme, isFalse);
      expect(ProgressStore.appLocaleCode, 'de');
      // A pre-update installation without an explicit language keeps German.
      await Hive.box<dynamic>(
        'fitflow_progress',
      ).delete(ProgressStore.keyAppLocale);
      await ProgressStore.closeForTesting();
      await ProgressStore.init(storageRootPath: storage.path);
      expect(ProgressStore.appLocaleCode, 'de');
    },
  );

  testWidgets(
    'home centers names in the right column and anchors the left card',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(host(const Scaffold(body: StartScreen())));
      final heading = find.byKey(const Key('home-profile-name'));

      await tester.runAsync(() => ProgressStore.setProfileName('Alex'));
      await tester.pumpAndSettle();
      final singleLineHeight = tester.getSize(heading).height;
      expect(tester.widget<Text>(heading).data, 'Alex');
      final dashboard = find.byType(RecoveryBodyCard);
      final card = find.byWidget(
        tester.widget<RecoveryBodyCard>(dashboard).compactSidePanel!,
      );
      final cardRect = tester.getRect(card);
      final rightCenter =
          (cardRect.right + tester.getRect(dashboard).right) / 2;
      expect(cardRect.top, closeTo(34, 1));
      expect(tester.getTopLeft(heading).dy, cardRect.top);
      expect(tester.getCenter(heading).dx, closeTo(rightCenter, 1));
      expect(
        tester.widget<Text>(heading).style!.fontSize,
        greaterThanOrEqualTo(30),
      );

      await tester.runAsync(
        () => ProgressStore.setProfileName('Alexandra Marie von Winterfeld'),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(heading).textAlign, TextAlign.center);
      expect(tester.getSize(heading).height, greaterThan(singleLineHeight));
      expect(tester.getTopLeft(heading).dy, cardRect.top);
      expect(tester.getCenter(heading).dx, closeTo(rightCenter, 1));
      expect(
        tester.getRect(
          find.byWidget(
            tester.widget<RecoveryBodyCard>(dashboard).compactSidePanel!,
          ),
        ),
        cardRect,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dashboard cards and labels follow the active theme', (
    tester,
  ) async {
    await tester.pumpWidget(host(const Scaffold(body: StartScreen())));
    for (final light in [true, false]) {
      await tester.runAsync(() => ProgressStore.setUseLightTheme(light));
      await tester.pumpAndSettle();
      final palette = AppColors.paletteFor(light);
      for (final label in ['Burned', 'Streak']) {
        final text = find.text(label);
        expect(tester.widget<Text>(text).style?.color, palette.muted);
        final card = find.ancestor(
          of: text,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color == palette.surface,
          ),
        );
        expect(card, findsWidgets);
      }
      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    }
  });

  testWidgets('settings toggles hide and restore water and fasting on Home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await ProgressStore.setFastingHudEnabled(true);
      await tester.pumpWidget(host(const RootShell()));
      await tester.pumpAndSettle();
      expect(find.text('Water'), findsNothing);
      expect(find.byType(HomeFastingHud), findsOneWidget);
      expect(find.text('Burned'), findsOneWidget);
      expect(find.text('Consumed'), findsOneWidget);
      AppTabNavigation.selectedTab.value = 1;
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      final title = find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Settings'),
      );
      expect(tester.getCenter(title).dx, closeTo(210, 1));
      Future<void> toggle(String label) async {
        final tile = find.widgetWithText(SwitchListTile, label);
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
      }

      await toggle('Water tracking');
      await toggle('Intermittent fasting');
      expect(ProgressStore.waterTrackingEnabled, isTrue);
      expect(ProgressStore.fastingHudEnabled, isFalse);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      AppTabNavigation.selectedTab.value = 0;
      await tester.pumpAndSettle();
      expect(find.text('Water'), findsOneWidget);
      expect(find.byType(HomeFastingHud), findsNothing);
      AppTabNavigation.selectedTab.value = 1;
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await toggle('Water tracking');
      await toggle('Intermittent fasting');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      AppTabNavigation.selectedTab.value = 0;
      await tester.pumpAndSettle();
      expect(find.text('Water'), findsNothing);
      expect(ProgressStore.fastingHudEnabled, isTrue);
      expect(find.byType(HomeFastingHud), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      // UI callbacks write Hive data; let those run on the real I/O clock.
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
      await ProgressStore.closeForTesting();
    });
  });

  for (final swipe in [false, true]) {
    testWidgets(
      'Home info does not restore the hidden chat keyboard after ${swipe ? 'swiping' : 'tapping Home'}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(() async {
          // Exercise keyboard restoration after the first-visit coach sheet.
          await ProgressStore.saveChatSettings({'coachIntroSeen': true});
          AppTabNavigation.selectedTab.value = AppTabNavigation.chat;
          await tester.pumpWidget(host(const RootShell()));
          await tester.pumpAndSettle();
          final input = find.byKey(const Key('chat-input'));
          await tester.enterText(input, 'Unsent draft');
          await tester.pumpAndSettle();
          expect(tester.testTextInput.isVisible, true);
          if (swipe) {
            await tester.drag(
              find.byType(PageView).first,
              const Offset(-360, 0),
            );
          } else {
            await tester.tap(find.text('Home').last);
          }
          await tester.pumpAndSettle();
          expect(AppTabNavigation.selectedTab.value, AppTabNavigation.home);
          // Reproduce the reported route pop, including tapping outside the card.
          for (final dismissOutside in [false, true]) {
            await tester.tap(
              find.byIcon(Icons.info_outline_rounded).hitTestable().first,
            );
            await tester.pumpAndSettle();
            expect(find.byType(Dialog), findsOneWidget);
            if (dismissOutside) {
              await tester.tapAt(const Offset(5, 100));
            } else {
              await tester.tap(find.widgetWithText(TextButton, 'Close'));
            }
            await tester.pumpAndSettle();
            expect(find.byType(Dialog), findsNothing);
            expect(tester.testTextInput.isVisible, false);
          }
          await tester.tap(find.text('Chat').last);
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(input).controller!.text,
            'Unsent draft',
          );
          expect(tester.testTextInput.isVisible, false);
          await tester.tap(input);
          await tester.pumpAndSettle();
          expect(tester.testTextInput.isVisible, true);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      },
    );
  }

  testWidgets('Profile starts at the top each time the tab opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AppTabNavigation.selectedTab.value = 1;
    await tester.pumpWidget(host(const Scaffold(body: ProfileScreen())));
    await tester.pumpAndSettle();
    final scroll = find.byType(SingleChildScrollView).first;
    final controller = tester.widget<SingleChildScrollView>(scroll).controller!;
    expect(controller.offset, 0);
    await tester.drag(scroll, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    AppTabNavigation.selectedTab.value = 0;
    AppTabNavigation.selectedTab.value = 1;
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
    expect(find.byIcon(Icons.settings_outlined).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Workout on the go sits centered below Create new workout', (
    tester,
  ) async {
    await tester.pumpWidget(host(const WorkoutHubScreen()));
    await tester.pumpAndSettle();
    final create = tester.getRect(find.byType(OutlinedButton).first);
    final onTheGo = tester.getRect(
      find.widgetWithText(InkWell, 'Workout on the go').first,
    );
    expect(onTheGo.top, closeTo(create.bottom + 12, 0.01));
    expect(onTheGo.center.dx, closeTo(create.center.dx, 0.01));
  });

  testWidgets(
    'existing workouts omit runners preset and rename calisthenics abs',
    (tester) async {
      await tester.pumpWidget(host(const WorkoutHubScreen()));
      await tester.pumpAndSettle();
      final search = find.byType(TextField).first;
      await tester.enterText(search, 'Abs');
      await tester.pumpAndSettle();
      expect(find.text('Abs Calisthenics'), findsOneWidget);
      expect(find.text('Abs Workout'), findsNothing);
      await tester.enterText(search, 'Optimized for runners');
      await tester.pumpAndSettle();
      expect(
        find
            .text('Optimized for runners', findRichText: false)
            .evaluate()
            .where((e) => e.widget is Text),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
