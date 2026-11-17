import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/data/ligament_stability_workout_exercises.dart';
import 'package:kaizen/navigation/app_tab_navigation.dart';
import 'package:kaizen/screens/workout_hub_screen.dart';
import 'package:kaizen/screens/category_detail_screen.dart';
import 'package:kaizen/screens/morning_workout_detail_screen.dart';
import 'package:kaizen/screens/wakeup_workout_detail_screen.dart';
import 'package:kaizen/screens/timed_workout_detail_screen.dart';
import 'package:kaizen/screens/workout_player_screen.dart';
import 'package:kaizen/widgets/app_back_button.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/widgets/preset_strength_workout_detail.dart';

void main() {
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp(
      'kaizen_workout_navigation_',
    );
    await ProgressStore.init(storageRootPath: storage.path);
    AppTabNavigation.selectedTab.value = AppTabNavigation.profile;
  });
  tearDown(() async {
    AppTabNavigation.selectedTab.value = AppTabNavigation.home;
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });

  Future<GlobalKey<NavigatorState>> openWorkout(
    WidgetTester tester,
    Widget workout,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: AppTabNavigation.selectedTab,
            builder: (_, tab, _) => Text(
              tab == AppTabNavigation.home
                  ? 'Home destination'
                  : 'Profile destination',
            ),
          ),
        ),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Workout list')),
      ),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => workout),
    );
    await tester.pumpAndSettle();
    return navigator;
  }

  Future<void> finishSave(WidgetTester tester, Finder button) async {
    await tester.runAsync(() async {
      await tester.tap(button);
      // Hive writes must start and complete outside the fake widget clock.
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (AppTabNavigation.selectedTab.value == AppTabNavigation.home) break;
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'existing workout back arrows return to the list without saving',
    (tester) async {
      for (final screen in [
        const CategoryDetailScreen(title: '9 min', categoryId: '9min'),
        const CategoryDetailScreen(
          title: 'Warm-up',
          categoryId: 'only_stretch',
        ),
        const WakeupWorkoutDetailScreen(),
        const TimedWorkoutDetailScreen(
          title: 'Bänder Stabilität',
          exercises: ligamentStabilityWorkoutExercises,
          workoutType: 'ligament_stability',
        ),
        const MorningWorkoutDetailScreen(),
      ]) {
        await openWorkout(tester, screen);
        final back = find.byType(AppBackButton);
        expect(back, findsOneWidget);
        await tester.tap(back);
        await tester.pumpAndSettle();
        expect(find.text('Workout list'), findsOneWidget);
        expect(ProgressStore.workoutEvents, isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets(
    'stability workout opens from hub and starts the ordered timed routine',
    (tester) async {
      await tester.runAsync(() => ProgressStore.setWorkoutVoiceEnabled(false));
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WorkoutHubScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Bänder Stabilität'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Bänder Stabilität'));
      await tester.pumpAndSettle();
      expect(
        find.text('20 Übungen · 13:23 min · 7 Sek. Pause'),
        findsOneWidget,
      );
      await tester.tap(find.text('Workout starten'));
      await tester.pumpAndSettle();
      final player = tester.widget<WorkoutPlayerScreen>(
        find.byType(WorkoutPlayerScreen),
      );
      expect(player.workoutType, 'ligament_stability');
      expect(player.workoutName, 'Bänder Stabilität');
      expect(player.showInstructions, isTrue);
      expect(player.exercises.map((e) => e.name), [
        'Auf Zehenspitzen springen',
        'Plank',
        'Standwaage / Krieger III (Rechts)',
        'Reverse Plank',
        'Standwaage / Krieger III (Links)',
        'Side Plank mit Bein auf dem Bett (Rechts)',
        'Wall Angel',
        'Side Plank mit Bein auf dem Bett (Links)',
        'Deep Squat Hold',
        'Liegestütze mit Drehung',
        'Bauchrolle (Ab Wheel Rollout)',
        "World's Greatest Stretch (Rechts)",
        "World's Greatest Stretch (Links)",
        'Feet Curls mit Handtuch',
        'Pigeon Stretch (Rechts)',
        'Pigeon Stretch (Links)',
        'Couch Stretch (Rechts)',
        'Couch Stretch (Links)',
        'Toe Touch (beide Beine)',
        'Cobra Stretch',
      ]);
      expect(player.exercises[1].workSeconds, 60);
      expect(player.exercises[3].workSeconds, 60);
      expect(
        player.exercises.indexed
            .where((e) => e.$1 != 1 && e.$1 != 3)
            .map((e) => e.$2.workSeconds),
        everyElement(30),
      );
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Auf Zehenspitzen springen'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'invalid sport stays open; saved sport returns through all routes to Home',
    (tester) async {
      final navigator = await openWorkout(tester, const SportActivityScreen());
      final save = find.text('Save workout');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(SportActivityScreen), findsOneWidget);
      expect(ProgressStore.workoutEvents, isEmpty);
      expect(AppTabNavigation.selectedTab.value, AppTabNavigation.profile);

      await tester.enterText(find.byType(TextField).at(0), 'Swimming');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.ensureVisible(save);
      await finishSave(tester, save);
      expect(ProgressStore.workoutEvents, hasLength(1));
      expect(ProgressStore.workoutEvents.single['workoutName'], 'Swimming');
      expect(find.text('Home destination'), findsOneWidget);
      expect(navigator.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'preset completion saves first then returns to Home after mood prompt',
    (tester) async {
      final navigator = await openWorkout(
        tester,
        const PresetStrengthWorkoutDetailScreen(
          name: 'Test strength session',
          presetId: 'test_strength',
          workoutType: 'gym',
          initialExercises: [
            {'name': 'Push-up', 'mainGroup': 'Brust', 'sets': 6, 'reps': 10},
          ],
        ),
      );
      await tester.runAsync(
        () => tester.tap(find.byIcon(Icons.check_circle_outline)),
      );
      await tester.pumpAndSettle();
      expect(ProgressStore.workoutEvents, isEmpty);
      await finishSave(tester, find.text('Skip'));
      expect(ProgressStore.workoutEvents, hasLength(1));
      expect(ProgressStore.workoutEvents.single['exercises'], [
        {'name': 'Push-up', 'mainGroup': 'Brust', 'sets': 6, 'reps': 10},
      ]);
      expect(find.text('Home destination'), findsOneWidget);
      expect(navigator.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
