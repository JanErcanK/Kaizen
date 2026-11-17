import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/strength_preset_workouts.dart';
import 'package:kaizen/models/body_muscle_group.dart';
import 'package:kaizen/services/muscle_activity_service.dart';
import 'package:kaizen/services/progress_store.dart';

void main() {
  final trainedAt = DateTime(2026, 10, 19, 12); // Monday.
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('kaizen_atlas_load_');
    await ProgressStore.init(storageRootPath: storage.path);
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });

  Future<void> log({int? intensity, String type = 'gym', DateTime? at}) =>
      ProgressStore.addWorkoutEvent(
        type: type,
        recordedAt: at ?? trainedAt,
        workoutIntensity: intensity,
        caloriesBurned: 300,
        durationSeconds: 30,
        calorieBreakdown: [
          {'label': 'Atlas activity', 'mainGroup': 'Bauch'},
        ],
      );

  for (final rating in <int?>[null, 1, 2, 3]) {
    test(
      'effort rating $rating alone does not imply intense muscle load',
      () async {
        await log(intensity: rating);
        const expected = MuscleRecoveryHighlight.almostReady;
        for (final days in [0, 1]) {
          final state = MuscleActivityService.snapshot(
            now: trainedAt.add(Duration(days: days)),
          );
          expect(state.recovery[BodyMuscleGroup.abs], expected);
          expect(state.heavilyTrainedGroups, 0);
          expect(
            state.recovery[BodyMuscleGroup.legs],
            MuscleRecoveryHighlight.none,
          );
        }
        expect(
          MuscleActivityService.snapshot(
            now: trainedAt.add(const Duration(days: 2)),
          ).recovery[BodyMuscleGroup.abs],
          MuscleRecoveryHighlight.none,
        );
        final expired = MuscleActivityService.snapshot(
          now: trainedAt.add(const Duration(days: 3)),
        );
        expect(
          expired.recovery[BodyMuscleGroup.abs],
          MuscleRecoveryHighlight.none,
        );
        expect(expired.trainedThisWeek, {BodyMuscleGroup.abs});
        expect(
          MuscleActivityService.snapshot(
            now: trainedAt.add(const Duration(days: 7)),
          ).trainedThisWeek,
          isEmpty,
        );
        // The visual load rating does not alter existing afterburn math.
        final hourLater = trainedAt.add(const Duration(hours: 1));
        expect(
          MuscleActivityService.snapshot(
            now: hourLater,
          ).afterburn[BodyMuscleGroup.abs]?.remaining,
          const Duration(hours: 35),
        );
        expect(
          MuscleActivityService.afterburnKcalAccumulatedSoFar(now: hourLater),
          closeTo(300 * .14 / 36, 1e-9),
        );
      },
    );
  }

  for (final type in ['nine_min', 'hercules']) {
    test('$type only accumulates sessions of at least moderate load', () async {
      await log(type: type);
      final baseline = MuscleActivityService.snapshot(now: trainedAt);
      expect(baseline.heavilyTrainedGroups, 0);
      expect(
        baseline.recovery[BodyMuscleGroup.abs],
        type == 'nine_min'
            ? MuscleRecoveryHighlight.lightCircuit
            : MuscleRecoveryHighlight.almostReady,
      );
      await log(type: type, intensity: 3);
      expect(
        MuscleActivityService.snapshot(
          now: trainedAt,
        ).recovery[BodyMuscleGroup.abs],
        type == 'nine_min'
            ? MuscleRecoveryHighlight.lightCircuit
            : MuscleRecoveryHighlight.recent,
      );
    });
  }

  Future<void> gym({
    required DateTime at,
    int sets = 6,
    String group = 'Bizeps',
    List<int>? setReps,
  }) => ProgressStore.addWorkoutEvent(
    type: 'gym',
    recordedAt: at,
    exercises: [
      {
        'name': 'Bizepscurls (Langhantel)',
        'mainGroup': group,
        'tags': ['Unterarme'],
        'sets': sets,
        'reps': 10,
        'setReps': ?setReps,
      },
    ],
  );

  test('direct Gym volume is red <24h, yellow <48h, then clears', () async {
    // The clock crosses midnight after only one minute, not one day.
    final at = DateTime(2026, 10, 19, 23, 59);
    await gym(at: at);
    for (final sample in [
      (age: Duration.zero, state: MuscleRecoveryHighlight.recent),
      (age: const Duration(minutes: 2), state: MuscleRecoveryHighlight.recent),
      (
        age: const Duration(hours: 24) - const Duration(microseconds: 1),
        state: MuscleRecoveryHighlight.recent,
      ),
      (
        age: const Duration(hours: 24),
        state: MuscleRecoveryHighlight.almostReady,
      ),
      (
        age: const Duration(hours: 48) - const Duration(microseconds: 1),
        state: MuscleRecoveryHighlight.almostReady,
      ),
      (age: const Duration(hours: 48), state: MuscleRecoveryHighlight.none),
    ]) {
      final snapshot = MuscleActivityService.snapshot(now: at.add(sample.age));
      expect(
        snapshot.recovery[BodyMuscleGroup.biceps],
        sample.state,
        reason: 'Age ${sample.age}',
      );
      expect(
        snapshot.recovery[BodyMuscleGroup.forearms],
        sample.age < const Duration(hours: 48)
            ? MuscleRecoveryHighlight.almostReady
            : MuscleRecoveryHighlight.none,
        reason: 'Secondary participation never becomes red',
      );
      expect(
        snapshot.recovery[BodyMuscleGroup.legs],
        MuscleRecoveryHighlight.none,
      );
    }
    expect(
      MuscleActivityService.nextRecoveryChange(now: at),
      at.add(const Duration(hours: 24)),
    );
    expect(
      MuscleActivityService.nextRecoveryChange(
        now: at.add(const Duration(hours: 24)),
      ),
      at.add(const Duration(hours: 36)),
    );
    expect(
      MuscleActivityService.nextRecoveryChange(
        now: at.add(const Duration(hours: 36)),
      ),
      at.add(const Duration(hours: 48)),
    );
    expect(
      MuscleActivityService.nextRecoveryChange(
        now: at.add(const Duration(hours: 48)),
      ),
      isNull,
    );
  });

  test(
    'multiple Gym sessions add direct sets within a rolling 24h window',
    () async {
      await gym(at: trainedAt, sets: 3);
      final later = trainedAt.add(const Duration(hours: 8));
      expect(
        MuscleActivityService.snapshot(now: trainedAt).heavilyTrainedGroups,
        0,
      );
      await gym(at: later, sets: 3);
      expect(
        MuscleActivityService.snapshot(
          now: later,
        ).recovery[BodyMuscleGroup.biceps],
        MuscleRecoveryHighlight.recent,
      );
      expect(
        MuscleActivityService.snapshot(
          now: later.add(const Duration(hours: 24)),
        ).recovery[BodyMuscleGroup.biceps],
        MuscleRecoveryHighlight.almostReady,
      );
    },
  );

  test(
    'sets separated by 24h and unrelated muscles do not add together',
    () async {
      await gym(at: trainedAt, sets: 3);
      await gym(at: trainedAt, sets: 3, group: 'Brust');
      final later = trainedAt.add(const Duration(hours: 24));
      await gym(at: later, sets: 3);
      expect(
        MuscleActivityService.snapshot(now: later).heavilyTrainedGroups,
        0,
      );
    },
  );

  test('per-set reps take precedence over stale set totals', () async {
    await gym(at: trainedAt, sets: 100, setReps: [10, 10, 10, 0, 0, 0]);
    expect(
      MuscleActivityService.snapshot(now: trainedAt).heavilyTrainedGroups,
      0,
    );
    await gym(at: trainedAt, setReps: [8, 8, 8]);
    expect(
      MuscleActivityService.snapshot(
        now: trainedAt,
      ).recovery[BodyMuscleGroup.biceps],
      MuscleRecoveryHighlight.recent,
    );
  });

  test('a timer without muscle targets cannot create muscle load', () async {
    for (var i = 0; i < 3; i++) {
      await ProgressStore.addWorkoutEvent(
        type: 'sport',
        recordedAt: trainedAt,
        workoutIntensity: 3,
        calorieBreakdown: [
          {'label': 'Workout-Timer'},
        ],
      );
    }
    expect(
      MuscleActivityService.snapshot(now: trainedAt).heavilyTrainedGroups,
      0,
    );
  });

  Future<void> preset(
    String id,
    int hour, {
    bool legacy = false,
    int? intensity,
  }) {
    final preset = findPresetWorkoutById(id)!;
    return ProgressStore.addWorkoutEvent(
      type: preset.kind,
      recordedAt: trainedAt.add(Duration(hours: hour)),
      workoutId: id,
      workoutIntensity: intensity,
      exercises: legacy ? null : resolvePresetWorkoutExercises(preset),
    );
  }

  MuscleRecoveryHighlight? loadAt(BodyMuscleGroup group, int hour) =>
      MuscleActivityService.snapshot(
        now: trainedAt.add(Duration(hours: hour)),
      ).recovery[group];

  test(
    'four alternating Handstand and Chest completions count once per affected muscle',
    () async {
      const hard = MuscleRecoveryHighlight.recent;
      const yellow = MuscleRecoveryHighlight.almostReady;
      await preset('cali_handstand', 0);
      expect(loadAt(BodyMuscleGroup.shoulders, 0), yellow);
      expect(loadAt(BodyMuscleGroup.chest, 0), MuscleRecoveryHighlight.none);
      await preset('cali_chest', 1, intensity: 2);
      expect(loadAt(BodyMuscleGroup.chest, 1), yellow);
      expect(loadAt(BodyMuscleGroup.shoulders, 1), yellow);
      await preset('cali_handstand', 2);
      expect(loadAt(BodyMuscleGroup.shoulders, 2), hard);
      expect(loadAt(BodyMuscleGroup.triceps, 2), hard);
      expect(loadAt(BodyMuscleGroup.chest, 2), yellow);
      await preset('cali_chest', 3);
      expect(loadAt(BodyMuscleGroup.chest, 3), hard);
      expect(loadAt(BodyMuscleGroup.legs, 3), MuscleRecoveryHighlight.none);
      expect(loadAt(BodyMuscleGroup.biceps, 3), MuscleRecoveryHighlight.none);
      expect(loadAt(BodyMuscleGroup.chest, 26), hard);
      expect(loadAt(BodyMuscleGroup.chest, 27), yellow);
      expect(loadAt(BodyMuscleGroup.chest, 51), MuscleRecoveryHighlight.none);
    },
  );

  test(
    'legacy Chest presets qualify directly on the second session and indirectly on the third',
    () async {
      await preset('cali_chest', 0, legacy: true);
      await preset('cali_chest', 3, legacy: true);
      expect(loadAt(BodyMuscleGroup.chest, 3), MuscleRecoveryHighlight.recent);
      expect(
        loadAt(BodyMuscleGroup.shoulders, 3),
        MuscleRecoveryHighlight.almostReady,
      );
      await preset('cali_chest', 5);
      expect(
        loadAt(BodyMuscleGroup.shoulders, 5),
        MuscleRecoveryHighlight.recent,
      );
    },
  );

  test(
    'light sessions and workouts 24 hours apart do not trigger accumulated red',
    () async {
      await preset('cali_handstand', 0);
      await preset('cali_handstand', 22, intensity: 1);
      await preset('cali_handstand', 23, intensity: 1);
      await preset('cali_handstand', 24, intensity: 2);
      expect(
        loadAt(BodyMuscleGroup.shoulders, 24),
        MuscleRecoveryHighlight.almostReady,
      );
    },
  );

  test('saved exercise snapshots survive edits and app restart', () async {
    final reps = [10, 10, 10, 10, 10, 10];
    final exercises = <Map<String, dynamic>>[
      {
        'name': 'Curls',
        'mainGroup': 'Bizeps',
        'setReps': reps,
        'tags': ['Unterarme'],
      },
    ];
    final workoutId = await ProgressStore.createGymWorkout('Arms');
    await ProgressStore.setGymWorkoutExercises(
      workoutId: workoutId,
      exercises: exercises,
    );
    await ProgressStore.addWorkoutEvent(
      type: 'gym',
      recordedAt: trainedAt,
      workoutId: workoutId,
      exercises: exercises,
    );
    reps.clear();
    exercises.single['mainGroup'] = 'Beine';
    await ProgressStore.setGymWorkoutExercises(
      workoutId: workoutId,
      exercises: exercises,
    );
    await ProgressStore.closeForTesting();
    await ProgressStore.init(storageRootPath: storage.path);
    final state = MuscleActivityService.snapshot(now: trainedAt);
    expect(
      state.recovery[BodyMuscleGroup.biceps],
      MuscleRecoveryHighlight.recent,
    );
    expect(state.recovery[BodyMuscleGroup.legs], MuscleRecoveryHighlight.none);
  });
}
