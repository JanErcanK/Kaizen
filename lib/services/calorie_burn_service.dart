import '../data/sport_catalog.dart';
import 'progress_store.dart';
import '../l10n/catalog_localizations.dart';
import '../utils/strength_exercise_config.dart';

/// ACSM standard: kcal = MET × weight(kg) × duration(hours)
class CalorieBurnResult {
  const CalorieBurnResult({
    required this.totalKcal,
    required this.durationSeconds,
    this.breakdown = const [],
  });

  final int totalKcal;
  final int durationSeconds;
  final List<CalorieBurnLine> breakdown;
}

class CalorieBurnLine {
  const CalorieBurnLine({
    required this.label,
    required this.seconds,
    required this.met,
    required this.kcal,
  });

  final String label;
  final int seconds;
  final double met;
  final int kcal;
}

class TimedExerciseInput {
  const TimedExerciseInput({
    required this.name,
    required this.workSeconds,
    this.assetPath,
  });

  final String name;
  final int workSeconds;
  final String? assetPath;
}

class CalorieBurnService {
  CalorieBurnService._();

  static const int _defaultMinutesPerStrengthExercise = 4;

  static double _weightKg() {
    final saved = ProgressStore.currentWeightKg;
    if (saved != null && saved > 0) return saved;

    final heightCm = ProgressStore.profileHeightCm;
    if (heightCm != null && heightCm > 0) {
      // Rough lean estimate when weight is missing.
      final heightM = heightCm / 100;
      return 22 * heightM * heightM;
    }
    return 70;
  }

  static double _metKcal({
    required double met,
    required int seconds,
    required double weightKg,
  }) {
    if (seconds <= 0 || weightKg <= 0) return 0;
    return met * weightKg * (seconds / 3600);
  }

  static int _roundKcal(double value) => value.round().clamp(0, 100000);

  static int durationBurn({required double met, required int durationSeconds}) {
    if (durationSeconds <= 0) return 0;
    return _roundKcal(
      _metKcal(met: met, seconds: durationSeconds, weightKg: _weightKg()),
    );
  }

  /// Estimates calories for common sports from their average MET intensity
  /// and the user's current or height-estimated body weight.
  static CalorieBurnResult sportSession({
    required String sportName,
    required int durationSeconds,
  }) {
    final met = SportActivity.find(sportName)?.met ?? 5.0;
    final seconds = durationSeconds.clamp(1, 86400);
    final kcal = _metKcal(met: met, seconds: seconds, weightKg: _weightKg());
    return CalorieBurnResult(
      totalKcal: _roundKcal(kcal),
      durationSeconds: seconds,
      breakdown: [
        CalorieBurnLine(
          label: sportName.trim(),
          seconds: seconds,
          met: met,
          kcal: _roundKcal(kcal),
        ),
      ],
    );
  }

  /// Estimates timer-workout calories from active training time and effort.
  /// The middle level uses 8 MET, a typical moderate-running estimate.
  static CalorieBurnResult timerWorkoutSession({
    required int durationSeconds,
    required int intensity,
  }) {
    final met = switch (intensity) {
      1 => 6.0,
      2 => 8.0,
      3 => 10.0,
      _ => throw ArgumentError.value(intensity, 'intensity', 'Expected 1–3'),
    };
    final seconds = durationSeconds.clamp(1, 86400);
    final kcal = _roundKcal(
      _metKcal(met: met, seconds: seconds, weightKg: _weightKg()),
    );
    return CalorieBurnResult(
      totalKcal: kcal,
      durationSeconds: seconds,
      breakdown: [
        CalorieBurnLine(
          label: ProgressStore.useGerman ? 'Workout-Timer' : 'Workout Timer',
          seconds: seconds,
          met: met,
          kcal: kcal,
        ),
      ],
    );
  }

  static double metForWorkoutType(String type) {
    return switch (type) {
      'stretch' => 2.5,
      'nine_min' => 5.0,
      'hercules' => 5.5,
      'gym' => 5.5,
      'calisthenics' => 5.5,
      'run' => 8.0,
      _ => 5.0,
    };
  }

  static double _metForTimedExercise(String name, String? assetPath) {
    final n = name.toLowerCase();
    final path = (assetPath ?? '').toLowerCase();

    if (path.contains('only_stretch') ||
        n.contains('stretch') ||
        n.contains('dehn') ||
        n.contains('pigeon') ||
        n.contains('cobra') ||
        n.contains('kindstellung') ||
        n.contains('hipflexor') ||
        n.contains('hamstring hold')) {
      return 2.3;
    }
    if (n.contains('hampelmann')) return 8.0;
    if (n.contains('knie hoch')) return 6.5;
    if (n.contains('liegestütz') || n.contains('push')) return 3.8;
    if (n.contains('ausfallschritt') ||
        n.contains('lunge') ||
        n.contains('step-up') ||
        n.contains('step up')) {
      return 6.0;
    }
    if (n.contains('kniebeug') ||
        n.contains('squat') ||
        n.contains('wandsitz') ||
        n.contains('deep squat')) {
      return 5.0;
    }
    if (n.contains('plank') ||
        n.contains('stütz') ||
        n.contains('hold') ||
        n.contains('bridge')) {
      return 3.3;
    }
    if (n.contains('dip')) return 3.5;
    if (n.contains('handstand')) return 6.0;
    if (n.contains('waden') || n.contains('calf') || n.contains('tibialis')) {
      return 3.5;
    }
    if (n.contains('neck') || n.contains('foot')) return 2.8;
    return 5.0;
  }

  static double _metForStrengthExercise(
    String name,
    String? mainGroup,
    List<String> tags,
  ) {
    final n = name.toLowerCase();
    final groupMet = _metForStrengthGroup(mainGroup, tags);

    double? nameMet;
    if (n.contains('bankdrück') ||
        n.contains('bench') ||
        n.contains('kniebeug') ||
        n.contains('squat') ||
        n.contains('kreuzheb') ||
        n.contains('deadlift') ||
        n.contains('rudern') ||
        n.contains('row')) {
      nameMet = 6.0;
    } else if (n.contains('ausfallschritt') ||
        n.contains('lunge') ||
        n.contains('beinpresse') ||
        n.contains('leg press') ||
        n.contains('step-up') ||
        n.contains('step up')) {
      nameMet = 6.0;
    } else if (n.contains('liegestütz') ||
        n.contains('push-up') ||
        n.contains('push up') ||
        n.contains('pull-up') ||
        n.contains('pull up') ||
        n.contains('klimmzug') ||
        n.contains('dip')) {
      nameMet = 4.0;
    } else if (n.contains('plank') ||
        n.contains('stütz') ||
        n.contains('hold') ||
        n.contains('bridge')) {
      nameMet = 3.5;
    } else if (n.contains('curl') ||
        n.contains('trizeps') ||
        n.contains('triceps') ||
        n.contains('bizeps') ||
        n.contains('biceps') ||
        n.contains('raise') ||
        n.contains('heben')) {
      nameMet = 3.5;
    } else if (n.contains('stretch') ||
        n.contains('dehn') ||
        n.contains('mobility')) {
      nameMet = 2.5;
    } else {
      final timedMet = _metForTimedExercise(name, null);
      if (timedMet != 5.0) nameMet = timedMet;
    }

    if (nameMet == null) return groupMet;
    return nameMet > groupMet ? nameMet : groupMet;
  }

  static double _metForStrengthGroup(String? mainGroup, List<String> tags) {
    final group = (mainGroup ?? '').toLowerCase();
    final tagText = tags.join(' ').toLowerCase();
    final haystack = '$group $tagText';

    if (haystack.contains('stretch') ||
        haystack.contains('mobility') ||
        haystack.contains('dehn')) {
      return 2.5;
    }
    if (haystack.contains('core') ||
        haystack.contains('bauch') ||
        haystack.contains('abs')) {
      return 4.5;
    }
    if (haystack.contains('bein') ||
        haystack.contains('leg') ||
        haystack.contains('rücken') ||
        haystack.contains('back') ||
        haystack.contains('brust') ||
        haystack.contains('chest') ||
        haystack.contains('schulter') ||
        haystack.contains('shoulder')) {
      return 6.0;
    }
    if (haystack.contains('arm') ||
        haystack.contains('bizeps') ||
        haystack.contains('trizeps')) {
      return 5.0;
    }
    return 5.5;
  }

  static String _burnLabelPrep() =>
      ProgressStore.useGerman ? 'Vorbereitung' : 'Preparation';

  static String _burnLabelRest() => ProgressStore.useGerman ? 'Pause' : 'Rest';

  static String _burnLabelTraining() =>
      ProgressStore.useGerman ? 'Training' : 'Workout';

  static String _burnLabelRun() => ProgressStore.useGerman ? 'Lauf' : 'Run';

  static CalorieBurnResult timedCircuitWorkout({
    required List<TimedExerciseInput> exercises,
    int prepSeconds = 10,
    int restSeconds = 10,
  }) {
    final weight = _weightKg();
    final lines = <CalorieBurnLine>[];
    var total = 0.0;
    var duration = 0;

    if (prepSeconds > 0) {
      final kcal = _metKcal(met: 2.0, seconds: prepSeconds, weightKg: weight);
      total += kcal;
      duration += prepSeconds;
      lines.add(
        CalorieBurnLine(
          label: _burnLabelPrep(),
          seconds: prepSeconds,
          met: 2.0,
          kcal: _roundKcal(kcal),
        ),
      );
    }

    for (var i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final workSeconds = exercise.workSeconds.clamp(1, 7200);
      final met = _metForTimedExercise(exercise.name, exercise.assetPath);
      final kcal = _metKcal(met: met, seconds: workSeconds, weightKg: weight);
      total += kcal;
      duration += workSeconds;
      lines.add(
        CalorieBurnLine(
          label: CatalogLocalizations.anyExerciseName(exercise.name),
          seconds: workSeconds,
          met: met,
          kcal: _roundKcal(kcal),
        ),
      );

      if (i < exercises.length - 1 && restSeconds > 0) {
        final restKcal = _metKcal(
          met: 1.8,
          seconds: restSeconds,
          weightKg: weight,
        );
        total += restKcal;
        duration += restSeconds;
        lines.add(
          CalorieBurnLine(
            label: _burnLabelRest(),
            seconds: restSeconds,
            met: 1.8,
            kcal: _roundKcal(restKcal),
          ),
        );
      }
    }

    return CalorieBurnResult(
      totalKcal: _roundKcal(total),
      durationSeconds: duration,
      breakdown: lines,
    );
  }

  static CalorieBurnLine strengthExerciseLine(
    Map<String, dynamic> exercise, {
    int minutesPerExercise = _defaultMinutesPerStrengthExercise,
  }) {
    final name =
        exercise['name']?.toString() ?? CatalogLocalizations.exerciseFallback();
    final mainGroup = exercise['mainGroup']?.toString();
    final rawTags = exercise['tags'];
    final tags = rawTags is List
        ? rawTags.map((e) => e.toString()).toList()
        : const <String>[];
    final seconds = _estimatedStrengthSeconds(
      exercise,
      minutesPerExercise: minutesPerExercise,
    );
    final weight = _weightKg();
    final met = _metForStrengthExercise(name, mainGroup, tags);
    final kcal = _metKcal(met: met, seconds: seconds, weightKg: weight);
    return CalorieBurnLine(
      label: CatalogLocalizations.anyExerciseName(name),
      seconds: seconds,
      met: met,
      kcal: _roundKcal(kcal),
    );
  }

  static String formatDuration(int seconds) {
    if (seconds <= 0) return '0 min';
    final totalMinutes = (seconds / 60).round();
    if (totalMinutes < 60) return '$totalMinutes min';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) return '$hours h';
    return '$hours h $minutes min';
  }

  static List<Map<String, dynamic>> breakdownToMaps(
    List<CalorieBurnLine> lines,
  ) {
    return lines
        .map(
          (line) => {
            'label': line.label,
            'seconds': line.seconds,
            'met': line.met,
            'kcal': line.kcal,
          },
        )
        .toList();
  }

  static CalorieBurnResult strengthSession({
    required List<Map<String, dynamic>> exercises,
    int minutesPerExercise = _defaultMinutesPerStrengthExercise,
  }) {
    final weight = _weightKg();
    final lines = <CalorieBurnLine>[];
    var total = 0.0;
    var duration = 0;

    if (exercises.isEmpty) {
      const fallbackSeconds = 30 * 60;
      const met = 5.5;
      final kcal = _metKcal(
        met: met,
        seconds: fallbackSeconds,
        weightKg: weight,
      );
      return CalorieBurnResult(
        totalKcal: _roundKcal(kcal),
        durationSeconds: fallbackSeconds,
        breakdown: [
          CalorieBurnLine(
            label: _burnLabelTraining(),
            seconds: fallbackSeconds,
            met: met,
            kcal: _roundKcal(kcal),
          ),
        ],
      );
    }

    for (final exercise in exercises) {
      final name =
          exercise['name']?.toString() ??
          CatalogLocalizations.exerciseFallback();
      final mainGroup = exercise['mainGroup']?.toString();
      final rawTags = exercise['tags'];
      final tags = rawTags is List
          ? rawTags.map((e) => e.toString()).toList()
          : const <String>[];
      final seconds = _estimatedStrengthSeconds(
        exercise,
        minutesPerExercise: minutesPerExercise,
      );
      final met = _metForStrengthExercise(name, mainGroup, tags);
      final kcal = _metKcal(met: met, seconds: seconds, weightKg: weight);
      total += kcal;
      duration += seconds;
      lines.add(
        CalorieBurnLine(
          label: CatalogLocalizations.anyExerciseName(name),
          seconds: seconds,
          met: met,
          kcal: _roundKcal(kcal),
        ),
      );
    }

    return CalorieBurnResult(
      totalKcal: _roundKcal(total),
      durationSeconds: duration,
      breakdown: lines,
    );
  }

  static int _estimatedStrengthSeconds(
    Map<String, dynamic> exercise, {
    required int minutesPerExercise,
  }) {
    if (StrengthExerciseConfig.isTimed(exercise))
      return StrengthExerciseConfig.setValues(
        exercise,
      ).fold<int>(0, (a, b) => a + b);
    final setReps = StrengthExerciseConfig.readSetReps(exercise);
    if (setReps.isEmpty) return minutesPerExercise * 60;
    // The previous baseline was four minutes for 3 × 10. Scale that estimate
    // by the actual set/repetition volume, including AI-created 30-round plans.
    final workloadUnits = setReps.fold<int>(
      0,
      (sum, reps) => sum + 50 + reps * 3,
    );
    const baselineUnits = 3 * (50 + 10 * 3);
    return (workloadUnits / baselineUnits * minutesPerExercise * 60)
        .round()
        .clamp(1, 86400);
  }

  static double _metForRunSpeed(double speedKmh) {
    return switch (speedKmh) {
      < 6.4 => 6.0,
      < 8.0 => 8.3,
      < 9.7 => 9.8,
      < 11.3 => 11.0,
      _ => 12.8,
    };
  }

  static CalorieBurnResult runSession({
    required double meters,
    required int durationSeconds,
  }) {
    final weight = _weightKg();
    final seconds = durationSeconds.clamp(1, 86400);
    final hours = seconds / 3600;
    final km = meters / 1000;
    final speedKmh = hours > 0 ? km / hours : 0.0;
    final met = _metForRunSpeed(speedKmh);

    if (meters <= 0) {
      return const CalorieBurnResult(totalKcal: 0, durationSeconds: 0);
    }

    final lines = <CalorieBurnLine>[];
    var total = 0.0;
    final fullKm = km.floor();
    final remainderMeters = meters - fullKm * 1000;

    for (var i = 1; i <= fullKm; i++) {
      final segmentSeconds = (seconds * 1000 / meters).round().clamp(
        1,
        seconds,
      );
      final kcal = _metKcal(
        met: met,
        seconds: segmentSeconds,
        weightKg: weight,
      );
      total += kcal;
      lines.add(
        CalorieBurnLine(
          label: 'Km $i',
          seconds: segmentSeconds,
          met: met,
          kcal: _roundKcal(kcal),
        ),
      );
    }

    if (remainderMeters >= 50) {
      final segmentSeconds = (seconds * remainderMeters / meters).round().clamp(
        1,
        seconds,
      );
      final kcal = _metKcal(
        met: met,
        seconds: segmentSeconds,
        weightKg: weight,
      );
      total += kcal;
      final remainderKm = remainderMeters / 1000;
      lines.add(
        CalorieBurnLine(
          label: remainderKm >= 0.95
              ? 'Km ${fullKm + 1}'
              : 'Rest ${remainderKm.toStringAsFixed(2)} km',
          seconds: segmentSeconds,
          met: met,
          kcal: _roundKcal(kcal),
        ),
      );
    }

    if (lines.isEmpty) {
      final kcal = _metKcal(met: met, seconds: seconds, weightKg: weight);
      return CalorieBurnResult(
        totalKcal: _roundKcal(kcal),
        durationSeconds: seconds,
        breakdown: [
          CalorieBurnLine(
            label: _burnLabelRun(),
            seconds: seconds,
            met: met,
            kcal: _roundKcal(kcal),
          ),
        ],
      );
    }

    return CalorieBurnResult(
      totalKcal: _roundKcal(total),
      durationSeconds: seconds,
      breakdown: lines,
    );
  }

  static int stepsBurn(int steps) {
    if (steps <= 0) return 0;
    final weight = _weightKg();
    final heightCm = ProgressStore.profileHeightCm ?? 170;
    final gender = ProgressStore.profileGender;
    final strideFactor = gender == 'female' ? 0.413 : 0.415;
    final strideM = heightCm * strideFactor / 100;
    final distanceKm = (steps * strideM) / 1000;
    const walkingSpeedKmh = 4.5;
    const walkingMet = 3.5;
    if (distanceKm <= 0) return 0;
    final hours = distanceKm / walkingSpeedKmh;
    return _roundKcal(walkingMet * weight * hours);
  }
}
