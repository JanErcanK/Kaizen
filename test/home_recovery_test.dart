import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/models/body_muscle_group.dart';
import 'package:kaizen/services/home_weekly_summary_service.dart';
import 'package:kaizen/services/muscle_activity_service.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/widgets/home_activity_panel.dart';

MuscleRecoverySnapshot recoveryWith(
  Map<BodyMuscleGroup, MuscleRecoveryHighlight> states,
) => MuscleRecoverySnapshot(
  recovery: states,
  afterburn: const {},
  trainedThisWeek: const {},
);

void main() {
  test('recovery covers rested, two hard groups, and full body training', () {
    expect(recoveryWith({}).recoveryPercent, 100);
    expect(
      recoveryWith({
        BodyMuscleGroup.chest: MuscleRecoveryHighlight.recent,
        BodyMuscleGroup.back: MuscleRecoveryHighlight.recent,
      }).recoveryPercent,
      78,
    );
    expect(
      recoveryWith({
        for (final group in BodyMuscleGroup.values)
          group: MuscleRecoveryHighlight.recent,
      }).recoveryPercent,
      0,
    );
    expect(
      recoveryWith({
        for (final group in BodyMuscleGroup.values)
          group: MuscleRecoveryHighlight.almostReady,
      }).recoveryPercent,
      60,
    );
    expect(
      recoveryWith({
        for (final group in BodyMuscleGroup.values)
          group: MuscleRecoveryHighlight.lightCircuit,
      }).recoveryPercent,
      85,
    );
  });

  test(
    'light sessions cannot mask hard training; load expires and ignores future logs',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'kaizen_recovery_test_',
      );
      await ProgressStore.init(storageRootPath: root.path);
      try {
        final now = DateTime(2026, 9, 16, 12);
        await ProgressStore.addWorkoutEvent(
          type: 'gym',
          recordedAt: now.subtract(const Duration(hours: 23)),
          workoutIntensity: 3,
          exercises: [
            {'name': 'Push-up', 'mainGroup': 'Brust', 'sets': 6, 'reps': 10},
          ],
          calorieBreakdown: [
            {'label': 'Push-up', 'kcal': 100},
          ],
        );
        await ProgressStore.addWorkoutEvent(
          type: 'nine_min',
          recordedAt: now,
          calorieBreakdown: [
            {'label': 'Push-up', 'kcal': 20},
          ],
        );
        await ProgressStore.addWorkoutEvent(
          type: 'gym',
          recordedAt: now.add(const Duration(days: 10)),
          calorieBreakdown: [
            {'label': 'Squat', 'kcal': 100},
          ],
        );
        final current = MuscleActivityService.snapshot(now: now);
        expect(
          current.recovery[BodyMuscleGroup.chest],
          MuscleRecoveryHighlight.recent,
        );
        expect(
          current.recovery[BodyMuscleGroup.legs],
          MuscleRecoveryHighlight.none,
        );
        expect(current.heavilyTrainedGroups, 1);
        final rested = MuscleActivityService.snapshot(
          now: now.add(const Duration(days: 3)),
        );
        expect(rested.recoveryPercent, 100);
      } finally {
        await ProgressStore.closeForTesting();
        await root.delete(recursive: true);
      }
    },
  );

  for (final german in [false, true]) {
    testWidgets(
      'narrow ${german ? 'German' : 'English'} panel fits and water responds',
      (tester) async {
        var waterTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 136,
                  child: SingleChildScrollView(
                    child: HomeActivityPanel(
                      isGerman: german,
                      snapshot: const HomeHudSnapshot(
                        tip: '',
                        steps: 12345,
                        stepsGoal: 10000,
                        availableKcal: null,
                        calorieTarget: null,
                        burnedKcal: 1250,
                        eatenKcal: 1840,
                        waterMl: 1800,
                        waterEnabled: true,
                      ),
                      recovery: recoveryWith({}),
                      streakDays: 4,
                      onWaterTap: () => waterTaps++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final labels = german
            ? ['Verbrannt', 'Eingenommen', 'Schritte', 'Wasser', 'Erholung']
            : ['Burned', 'Intake', 'Steps', 'Hydration', 'Recovery'];
        for (var i = 1; i < labels.length; i++) {
          expect(
            tester.getTopLeft(find.text(labels[i])).dy,
            greaterThan(tester.getTopLeft(find.text(labels[i - 1])).dy),
          );
        }
        expect(find.text('STREAK'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text('250%'), findsOneWidget);
        await tester.tap(find.text(german ? 'Wasser' : 'Hydration'));
        expect(waterTaps, 1);
      },
    );
  }
}
