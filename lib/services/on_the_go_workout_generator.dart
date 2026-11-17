import 'muscle_exercise_filter.dart';
import '../utils/strength_exercise_config.dart';

/// Builds a local, repeatable plan and balances coverage across selected muscles.
class OnTheGoWorkoutGenerator {
  OnTheGoWorkoutGenerator._();

  static int exerciseCount(int muscleCount) =>
      muscleCount == 0 ? 0 : (5 + (muscleCount - 1) * 2).clamp(5, 15);

  static String exerciseKey(Map<String, dynamic> exercise) =>
      exercise['name'].toString().trim().toLowerCase();

  static bool matches(Map<String, dynamic> exercise, String region) =>
      MuscleExerciseFilter.coversSelection(
        mainGroup: exercise['mainGroup'] as String,
        tags: List<String>.from(exercise['tags'] as List),
        name: exercise['name'] as String,
        selected: {region},
      );

  static List<Map<String, dynamic>> generate({
    required List<Map<String, dynamic>> catalog,
    required Set<String> regions,
  }) {
    if (regions.isEmpty) return [];
    final unique = <String, Map<String, dynamic>>{};
    for (final exercise in catalog) {
      unique.putIfAbsent(exerciseKey(exercise), () => exercise);
    }
    final candidates = unique.values
        .where((exercise) => regions.any((region) => matches(exercise, region)))
        .toList();
    final counts = {for (final region in regions) region: 0};
    final plan = <Map<String, dynamic>>[];
    final target = exerciseCount(regions.length);

    while (plan.length < target && candidates.isNotEmpty) {
      // Prefer the least-covered muscle, then exercises covering other
      // underrepresented selections. Stable catalog order breaks ties.
      final availableRegions =
          regions
              .where((region) => candidates.any((e) => matches(e, region)))
              .toList()
            ..sort((a, b) {
              final comparison = counts[a]!.compareTo(counts[b]!);
              return comparison == 0 ? a.compareTo(b) : comparison;
            });
      final region = availableRegions.first;
      Map<String, dynamic>? best;
      double bestScore = -1;
      for (final exercise in candidates) {
        if (!matches(exercise, region)) continue;
        final score = regions
            .where((r) => matches(exercise, r))
            .fold(0.0, (sum, r) => sum + 1 / (counts[r]! + 1));
        if (score > bestScore) {
          best = exercise;
          bestScore = score;
        }
      }
      final chosen = best!;
      candidates.remove(chosen);
      plan.add(StrengthExerciseConfig.applyDefaults(chosen));
      for (final region in regions) {
        if (matches(chosen, region)) counts[region] = counts[region]! + 1;
      }
    }

    // Small catalog sections (e.g. shins) get complementary exercises from
    // the same body area, explicitly marked for the review screen.
    final groups = regions
        .map(MuscleExerciseFilter.mainGroupGermanForSlug)
        .whereType<String>()
        .toSet();
    final selectedKeys = plan.map(exerciseKey).toSet();
    for (final exercise in unique.values) {
      if (plan.length >= target) break;
      if (!groups.contains(exercise['mainGroup']) ||
          selectedKeys.contains(exerciseKey(exercise))) {
        continue;
      }
      plan.add(
        StrengthExerciseConfig.applyDefaults({
          ...exercise,
          'onTheGoComplement': true,
        }),
      );
      selectedKeys.add(exerciseKey(exercise));
    }
    return plan;
  }
}
