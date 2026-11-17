import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/services/muscle_exercise_filter.dart';
import 'package:kaizen/widgets/muscle_segment_labels.dart';

MuscleSegmentHit hit(String slug) =>
    MuscleSegmentHit(slug: slug, pathIndex: -1, front: true);
Set<String> gym(String slug) =>
    MuscleExerciseFilter.gymExercisesFor(hit(slug)).map((e) => e.name).toSet();
Set<String> cali(String slug) => MuscleExerciseFilter.calisthenicsExercisesFor(
  hit(slug),
).map((e) => e.name).toSet();

void main() {
  test('anatomy picks bridge existing oblique and trapezius catalog tags', () {
    expect(
      gym('obliques'),
      containsAll(['Russian Twists (mit Gewicht)', 'Pallof Press']),
    );
    expect(gym('obliques'), isNot(contains('Leg Raises (hängend)')));
    expect(gym('trapezius'), contains('Shrugs (Langhantel)'));
    expect(gym('trapezius'), isNot(contains('Neck Curls (liegend)')));
  });
  test(
    'upper and lower abdominal picks distinguish catalog training emphases',
    () {
      expect(gym('abs-upper'), contains('Decline Crunches'));
      expect(gym('abs-upper'), isNot(contains('Leg Raises (hängend)')));
      expect(gym('abs-lower'), contains('Leg Raises (hängend)'));
      expect(gym('abs-lower'), isNot(contains('Decline Crunches')));
      expect(cali('abs-upper'), contains('Crunches'));
      expect(cali('abs-upper'), isNot(contains('Reverse Crunch')));
      expect(cali('abs-lower'), contains('Reverse Crunch'));
      expect(cali('abs-lower'), isNot(contains('Crunches')));
    },
  );

  test(
    'shared abdominal exercises and existing whole-muscle selection remain',
    () {
      expect(gym('abs-upper'), contains('Plank'));
      expect(gym('abs-lower'), contains('Plank'));
      expect(
        gym('abs'),
        containsAll(['Plank', 'Decline Crunches', 'Leg Raises (hängend)']),
      );
      expect(cali('abs'), containsAll(['Crunches', 'Reverse Crunch']));
    },
  );

  test('shoulder regions include explicitly tagged compound exercises', () {
    expect(
      gym('deltoids-posterior'),
      contains('Reverse Fly (hintere Schulter)'),
    );
    expect(
      cali('deltoids-posterior'),
      contains('Klimmzüge mit weitem Griff (Wide Pull-Ups)'),
    );
    expect(
      gym('deltoids-lateral'),
      isNot(contains('Reverse Fly (hintere Schulter)')),
    );
    expect(gym('deltoids-anterior'), isNotEmpty);
    expect(cali('deltoids-anterior'), isNotEmpty);
    expect(
      MuscleExerciseFilter.mainGroupGermanForSlug('deltoids-posterior'),
      'Schultern',
    );
  });

  test('existing broad groups and unknown groups keep their contracts', () {
    for (final slug in [
      'chest',
      'upper-back',
      'lower-back',
      'biceps',
      'triceps',
      'quadriceps',
      'hamstring',
      'gluteal',
      'calves',
      'forearm',
    ]) {
      expect(gym(slug), isNotEmpty, reason: slug);
    }
    expect(gym('unknown'), isEmpty);
    expect(cali('unknown'), isEmpty);
  });
}
