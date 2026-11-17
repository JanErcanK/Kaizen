import '../data/calisthenics_exercise_catalog.dart';
import '../data/gym_exercise_catalog.dart';
import '../models/body_muscle_group.dart';
import '../widgets/muscle_segment_labels.dart';

/// Maps mannequin muscle segments to gym/calisthenics catalog filters.
class MuscleExerciseFilter {
  MuscleExerciseFilter._();

  // Existing rotation/anti-rotation entries predate the catalog's oblique tag.
  static const _obliqueGymExercises = {
    'Russian Twists (mit Gewicht)',
    'Pallof Press',
  };

  static String? mainGroupGermanForSlug(String slug) {
    final group = _slugToGroup(slug);
    if (group == null) return null;
    return switch (group) {
      BodyMuscleGroup.chest => 'Brust',
      BodyMuscleGroup.back => 'Rücken',
      BodyMuscleGroup.shoulders => 'Schultern',
      BodyMuscleGroup.biceps => 'Bizeps',
      BodyMuscleGroup.triceps => 'Trizeps',
      BodyMuscleGroup.abs => 'Bauch',
      BodyMuscleGroup.legs => 'Beine',
      BodyMuscleGroup.forearms => 'Unterarme',
      BodyMuscleGroup.neck => 'Nacken',
    };
  }

  static List<String> _segmentTags(String slug) {
    return switch (slug) {
      'upper-back' => const ['oberer Rücken', 'breiter Rücken'],
      'lower-back' => const ['unterer Rücken'],
      'trapezius' => const ['Nacken', 'hintere Schulter', 'oberer Rücken'],
      'obliques' => const ['schräge Bauchmuskeln'],
      'abs' => const ['obere Bauchmuskeln', 'untere Bauchmuskeln'],
      // Catalog training emphases, not anatomically separate muscles.
      'abs-upper' => const ['obere Bauchmuskeln'],
      'abs-lower' => const ['untere Bauchmuskeln'],
      'quadriceps' => const ['oberer Oberschenkel', 'Quadrizeps'],
      'hamstring' => const ['hinterer Oberschenkel'],
      'gluteal' => const ['Hintern'],
      'calves' => const ['Waden'],
      'tibialis' => const ['Schienbein'],
      'adductors' => const ['Adduktoren'],
      'deltoids' => const [
        'vordere Schulter',
        'mittlere Schulter',
        'hintere Schulter',
      ],
      'deltoids-anterior' => const ['vordere Schulter'],
      'deltoids-lateral' => const ['mittlere Schulter'],
      'deltoids-posterior' => const ['hintere Schulter'],
      _ => const [],
    };
  }

  static String selectionLabel(String slug) {
    if (slug != 'abs' && slug != 'deltoids') {
      final tags = _segmentTags(slug);
      if (tags.isNotEmpty) return tags.first;
    }
    return mainGroupGermanForSlug(slug) ?? slug;
  }

  /// Include secondary muscles when the catalog explicitly tags them.
  static bool coversSelection({
    required String mainGroup,
    required List<String> tags,
    required String name,
    required Set<String> selected,
  }) {
    final effectiveTags = [
      ...tags,
      if (_obliqueGymExercises.contains(name)) 'schräge Bauchmuskeln',
    ];
    return selected.every((slug) {
      final group = mainGroupGermanForSlug(slug);
      if (group == null) return false;
      final regional = _segmentTags(slug);
      if (regional.isNotEmpty && regional.any(effectiveTags.contains)) {
        return true;
      }
      if (regional.isNotEmpty && slug != 'deltoids' && slug != 'abs') {
        return false;
      }
      return mainGroup == group || effectiveTags.contains(group);
    });
  }

  static bool _matches({
    required String mainGroup,
    required List<String> tags,
    required MuscleSegmentHit segment,
  }) {
    final expectedMain = mainGroupGermanForSlug(segment.slug);
    final segmentTags = _segmentTags(segment.slug);
    if (expectedMain == null) return false;
    // Shoulder-region picks may include compound pushing/pulling exercises
    // catalogued under chest/back when that exact shoulder tag is present.
    if (segment.slug.startsWith('deltoids-')) {
      return tags.any(segmentTags.contains);
    }
    if (segment.slug == 'trapezius' &&
        mainGroup == 'Nacken' &&
        tags.contains('oberer Rücken')) {
      return true;
    }
    if (mainGroup != expectedMain) return false;
    if (segmentTags.isEmpty) return true;
    if (tags.isEmpty) return true;
    return tags.any(segmentTags.contains);
  }

  static List<GymCatalogExercise> gymExercisesFor(MuscleSegmentHit segment) {
    return gymCatalogExercises
        .where(
          (e) => _matches(
            mainGroup: e.mainGroup,
            tags: [
              ...e.tags,
              if (_obliqueGymExercises.contains(e.name)) 'schräge Bauchmuskeln',
            ],
            segment: segment,
          ),
        )
        .toList();
  }

  static List<CalisthenicsCatalogExercise> calisthenicsExercisesFor(
    MuscleSegmentHit segment,
  ) {
    return calisthenicsCatalogExercises
        .where(
          (e) =>
              _matches(mainGroup: e.mainGroup, tags: e.tags, segment: segment),
        )
        .toList();
  }
}

BodyMuscleGroup? _slugToGroup(String slug) {
  switch (slug) {
    case 'chest':
      return BodyMuscleGroup.chest;
    case 'abs':
    case 'abs-upper':
    case 'abs-lower':
    case 'obliques':
      return BodyMuscleGroup.abs;
    case 'biceps':
      return BodyMuscleGroup.biceps;
    case 'triceps':
      return BodyMuscleGroup.triceps;
    case 'neck':
      return BodyMuscleGroup.neck;
    case 'trapezius':
    case 'upper-back':
    case 'lower-back':
      return BodyMuscleGroup.back;
    case 'deltoids':
    case 'deltoids-anterior':
    case 'deltoids-lateral':
    case 'deltoids-posterior':
      return BodyMuscleGroup.shoulders;
    case 'forearm':
      return BodyMuscleGroup.forearms;
    case 'quadriceps':
    case 'legs':
    case 'adductors':
    case 'hamstring':
    case 'gluteal':
    case 'calves':
    case 'tibialis':
    case 'knees':
      return BodyMuscleGroup.legs;
    default:
      return null;
  }
}
