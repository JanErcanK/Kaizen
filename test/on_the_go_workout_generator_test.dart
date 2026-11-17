import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/calisthenics_exercise_catalog.dart';
import 'package:kaizen/data/gym_exercise_catalog.dart';
import 'package:kaizen/services/on_the_go_workout_generator.dart';
import 'package:kaizen/services/muscle_exercise_filter.dart';
import 'package:kaizen/widgets/body_overlay_painter.dart';

void main() {
  final catalog = <Map<String, dynamic>>[
    for (final exercise in gymCatalogExercises)
      {
        'kind': 'gym',
        'name': exercise.name,
        'mainGroup': exercise.mainGroup,
        'tags': exercise.tags,
      },
    for (final exercise in calisthenicsCatalogExercises)
      {
        'kind': 'calisthenics',
        'name': exercise.name,
        'mainGroup': exercise.mainGroup,
        'tags': exercise.tags,
      },
  ];
  final regions =
      {
            ...bodyMusclePathsForView(front: true, female: false).keys,
            ...bodyMusclePathsForView(front: false, female: false).keys,
          }
          .where(
            (slug) => MuscleExerciseFilter.mainGroupGermanForSlug(slug) != null,
          )
          .toSet();

  test(
    'every selectable muscle gets five distinct exercises with defaults',
    () {
      expect(regions, isNotEmpty);
      for (final region in regions) {
        final plan = OnTheGoWorkoutGenerator.generate(
          catalog: catalog,
          regions: {region},
        );
        expect(plan, hasLength(5), reason: region);
        expect(
          plan.map(OnTheGoWorkoutGenerator.exerciseKey).toSet(),
          hasLength(5),
          reason: region,
        );
        expect(
          plan.any(
            (exercise) => OnTheGoWorkoutGenerator.matches(exercise, region),
          ),
          isTrue,
          reason: region,
        );
        for (final exercise in plan) {
          expect(exercise['setReps'], [10, 10, 10]);
          expect(
            OnTheGoWorkoutGenerator.matches(exercise, region) ||
                (exercise['onTheGoComplement'] == true &&
                    exercise['mainGroup'] ==
                        MuscleExerciseFilter.mainGroupGermanForSlug(region)),
            isTrue,
          );
        }
      }
    },
  );

  test(
    'plans grow to fifteen and cover every selected muscle without duplicates',
    () {
      for (final selection in [
        <String>{},
        {'chest', 'calves'},
        {'quadriceps', 'abs', 'forearm'},
        {'chest', 'biceps', 'triceps', 'calves'},
        {'chest', 'biceps', 'triceps', 'calves', 'abs'},
        regions,
      ]) {
        final plan = OnTheGoWorkoutGenerator.generate(
          catalog: catalog,
          regions: selection,
        );
        expect(
          plan.length,
          OnTheGoWorkoutGenerator.exerciseCount(selection.length),
        );
        expect(
          plan.map(OnTheGoWorkoutGenerator.exerciseKey).toSet().length,
          plan.length,
        );
        for (final region in selection) {
          expect(
            plan.any((e) => OnTheGoWorkoutGenerator.matches(e, region)),
            isTrue,
            reason: region,
          );
        }
      }
    },
  );
}
