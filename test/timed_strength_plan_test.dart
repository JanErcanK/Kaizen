import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/shared_content.dart';
import 'package:kaizen/models/social_models.dart';
import 'package:kaizen/screens/workout_hub_screen.dart';
import 'package:kaizen/screens/gym_screen.dart';
import 'package:kaizen/services/calorie_burn_service.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/utils/strength_exercise_config.dart';

void main() {
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('kaizen_set_modes');
    await ProgressStore.init(storageRootPath: storage.path);
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });
  testWidgets(
    'new mixed workout retains seconds and reps through saving and sharing',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CreateNewWorkoutScreen(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add_circle_outline).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Time'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), '2');
        await tester.enterText(find.byType(TextFormField).at(1), '45');
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();
        expect(find.text('2 × 45 s'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.add_circle_outline).first);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        for (
          var i = 0;
          i < 100 && find.byType(GymWorkoutDetailScreen).evaluate().isEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pumpAndSettle();
        }
        final workout = ProgressStore.gymWorkouts.single;
        final shared = normalizeSharedContent(
          ShareContentType.gymWorkout,
          workout,
        );
        final exercises = (shared['exercises'] as List)
            .cast<Map<String, dynamic>>();
        expect(exercises.first['setSeconds'], [45, 45]);
        expect(exercises.first.containsKey('reps'), isFalse);
        expect(
          CalorieBurnService.strengthExerciseLine(exercises.first).seconds,
          90,
        );
        expect(StrengthExerciseConfig.formatShort(exercises.last), '3 × 10');
        expect(
          StrengthExerciseConfig.formatShort({'sets': 2, 'reps': 8}),
          '2 × 8',
        );
        expect(tester.takeException(), isNull);
      });
    },
  );
}
