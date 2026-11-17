import '../data/calisthenics_exercise_catalog.dart';
import '../data/gym_exercise_catalog.dart';
import '../data/hercules_default_exercises.dart';
import '../data/yoga_stretch_exercises.dart';
import '../screens/workout_player_screen.dart';
import 'progress_store.dart';

enum MorningWorkoutExerciseSource { morning, yoga, gym, calisthenics }

class MorningWorkoutCatalogEntry {
  const MorningWorkoutCatalogEntry({
    required this.name,
    required this.benefit,
    required this.source,
    this.assetPath,
    this.animationAssetPaths = const [],
    this.defaultWorkSeconds = 30,
  });

  final String name;
  final String benefit;
  final MorningWorkoutExerciseSource source;
  final String? assetPath;
  final List<String> animationAssetPaths;
  final int defaultWorkSeconds;
}

class MorningWorkoutService {
  MorningWorkoutService._();

  static const int addedExerciseDefaultSeconds = 30;

  static final Map<String, MorningWorkoutCatalogEntry> _catalogByName = {
    for (final e in _allCatalogEntries) e.name: e,
  };

  static List<MorningWorkoutCatalogEntry> get allPickableExercises =>
      _allCatalogEntries;

  static List<String> defaultExerciseOrder() =>
      herculesDefaultExercises.map((e) => e.name).toList();

  static List<WorkoutExercise> currentExercises() {
    final order = ProgressStore.morningWorkoutExerciseOrder();
    return _resolveOrder(order);
  }

  static List<WorkoutExercise> _resolveOrder(List<String> order) {
    final resolved = <WorkoutExercise>[];
    for (final name in order) {
      final entry = _catalogByName[name.trim()];
      if (entry == null) continue;
      resolved.add(
        WorkoutExercise(
          name: entry.name,
          benefit: entry.benefit,
          workSeconds: entry.defaultWorkSeconds,
          assetPath: entry.assetPath,
          animationAssetPaths: entry.animationAssetPaths,
        ),
      );
    }
    if (resolved.isEmpty) {
      return List<WorkoutExercise>.from(herculesDefaultExercises);
    }
    return resolved;
  }

  static List<MorningWorkoutCatalogEntry> pickableNotInWorkout(
    List<String> currentOrder,
  ) {
    final inWorkout = currentOrder.map((n) => n.trim()).toSet();
    return _allCatalogEntries
        .where((e) => !inWorkout.contains(e.name))
        .toList();
  }

  static List<MorningWorkoutCatalogEntry> get _allCatalogEntries {
    final entries = <MorningWorkoutCatalogEntry>[];
    final seen = <String>{};

    void add(MorningWorkoutCatalogEntry entry) {
      if (seen.add(entry.name)) entries.add(entry);
    }

    for (final e in herculesDefaultExercises) {
      add(
        MorningWorkoutCatalogEntry(
          name: e.name,
          benefit: e.benefit,
          source: MorningWorkoutExerciseSource.morning,
          assetPath: e.assetPath,
          animationAssetPaths: e.animationAssetPaths,
          defaultWorkSeconds: e.workSeconds,
        ),
      );
    }

    for (final e in yogaStretchExercises) {
      add(
        MorningWorkoutCatalogEntry(
          name: e.name,
          benefit: e.benefit,
          source: MorningWorkoutExerciseSource.yoga,
          assetPath: e.assetPath,
          animationAssetPaths: e.animationAssetPaths,
          defaultWorkSeconds: addedExerciseDefaultSeconds,
        ),
      );
    }

    for (final e in gymCatalogExercises) {
      add(
        MorningWorkoutCatalogEntry(
          name: e.name,
          benefit: e.description,
          source: MorningWorkoutExerciseSource.gym,
          defaultWorkSeconds: addedExerciseDefaultSeconds,
        ),
      );
    }

    for (final e in calisthenicsCatalogExercises) {
      add(
        MorningWorkoutCatalogEntry(
          name: e.name,
          benefit: e.description,
          source: MorningWorkoutExerciseSource.calisthenics,
          defaultWorkSeconds: addedExerciseDefaultSeconds,
        ),
      );
    }

    entries.sort((a, b) {
      final source = a.source.index.compareTo(b.source.index);
      if (source != 0) return source;
      return a.name.compareTo(b.name);
    });
    return entries;
  }
}
