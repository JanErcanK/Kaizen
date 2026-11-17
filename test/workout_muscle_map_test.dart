import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/wakeup_workout_exercises.dart';
import 'package:kaizen/data/ligament_stability_workout_exercises.dart';
import 'package:kaizen/data/yoga_stretch_exercises.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/body_muscle_group.dart';
import 'package:kaizen/services/muscle_activity_service.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/widgets/workout_muscle_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('workout_targets_');
    await ProgressStore.init(storageRootPath: storage.path);
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });
  test('all fixed timed exercises resolve locally to muscle groups', () {
    for (final exercise in [
      ...wakeupWorkoutExercises,
      ...ligamentStabilityWorkoutExercises,
      ...yogaStretchExercises,
    ]) {
      expect(
        MuscleActivityService.plannedMuscles([
          {'name': exercise.name},
        ]),
        isNotEmpty,
        reason: exercise.name,
      );
    }
  });

  test('explicit targets win over name guesses and ignore completed sets', () {
    expect(
      MuscleActivityService.plannedMuscles([
        {
          'name': 'Pike Push-Ups',
          'mainGroup': 'Schultern',
          'tags': ['Trizeps'],
          'sets': 0,
          'reps': 0,
        },
      ]),
      {BodyMuscleGroup.shoulders, BodyMuscleGroup.triceps},
    );
    expect(
      MuscleActivityService.plannedMuscles([
        {'name': 'Bankdrücken (Langhantel)'},
      ]),
      {
        BodyMuscleGroup.chest,
        BodyMuscleGroup.shoulders,
        BodyMuscleGroup.triceps,
      },
    );
    expect(
      MuscleActivityService.plannedMuscles([
        {'name': 'Unknown movement'},
      ]),
      isEmpty,
    );
  });

  testWidgets(
    'editing a plan replaces its highlighted muscles without a saved image',
    (tester) async {
      Widget host(String group) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WorkoutMuscleMap(
            exercises: [
              {'name': 'Custom', 'mainGroup': group},
            ],
          ),
        ),
      );
      WorkoutMusclePainter painter() => tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<WorkoutMusclePainter>()
          .single;
      await tester.pumpWidget(host('Brust'));
      expect(painter().groups, {BodyMuscleGroup.chest});
      await tester.pumpWidget(host('Beine'));
      expect(painter().groups, {BodyMuscleGroup.legs});
      expect(tester.takeException(), isNull);
    },
  );
}
