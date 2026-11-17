import '../data/strength_preset_workouts.dart';
import '../data/gym_exercise_catalog.dart';
import '../data/calisthenics_exercise_catalog.dart';
import '../models/body_muscle_group.dart';
import '../utils/strength_exercise_config.dart';
import 'calorie_burn_service.dart';
import 'progress_store.dart';

/// Derives muscle recovery + afterburn (EPOC) states from workout history.
class MuscleActivityService {
  MuscleActivityService._();

  /// Targets of a planned workout, independent of completed sets and history.
  static Set<BodyMuscleGroup> plannedMuscles(
    Iterable<Map<String, dynamic>> exercises,
  ) {
    final result = <BodyMuscleGroup>{};
    for (final exercise in exercises) {
      final name = exercise['name']?.toString() ?? '';
      var mainGroup = exercise['mainGroup']?.toString();
      var tags =
          (exercise['tags'] as List?)?.map((e) => e.toString()).toList() ??
          <String>[];
      if (mainGroup == null && tags.isEmpty) {
        for (final entry in gymCatalogExercises) {
          if (entry.name == name) {
            mainGroup = entry.mainGroup;
            tags = entry.tags;
            break;
          }
        }
        if (mainGroup == null) {
          for (final entry in calisthenicsCatalogExercises) {
            if (entry.name == name) {
              mainGroup = entry.mainGroup;
              tags = entry.tags;
              break;
            }
          }
        }
      }
      final assigned = <BodyMuscleGroup>{
        ?BodyMuscleGroupX.fromMainGroup(mainGroup),
        for (final tag in tags) ?BodyMuscleGroupX.fromTrainingTag(tag),
      };
      result.addAll(assigned.isEmpty ? _plannedTimedMuscles(name) : assigned);
    }
    return result;
  }

  static Set<BodyMuscleGroup> _plannedTimedMuscles(String name) {
    final n = _normalizeExerciseName(
      name,
    ).replaceAll("'", '').replaceAll('-', ' ');
    if (n.contains('handstand')) {
      return {
        BodyMuscleGroup.shoulders,
        BodyMuscleGroup.triceps,
        BodyMuscleGroup.abs,
      };
    }
    if (n.contains('wall angel')) {
      return {BodyMuscleGroup.shoulders, BodyMuscleGroup.back};
    }
    if (n.contains('wirbelsaeule drehen')) {
      return {BodyMuscleGroup.abs, BodyMuscleGroup.back};
    }
    if (n.contains('chest and arm')) {
      return {
        BodyMuscleGroup.chest,
        BodyMuscleGroup.shoulders,
        BodyMuscleGroup.biceps,
      };
    }
    if (n.contains('cobra')) return {BodyMuscleGroup.abs, BodyMuscleGroup.back};
    if (n.contains('worlds greatest')) {
      return {BodyMuscleGroup.legs, BodyMuscleGroup.back, BodyMuscleGroup.abs};
    }
    if ([
      'zehenspitzen',
      'standwaage',
      'feet curl',
      'toe touch',
      'knie strecker',
      'seated forward',
      'couch stretch',
      'pigeon',
      'hipflexor',
    ].any(n.contains)) {
      return {BodyMuscleGroup.legs};
    }
    return _musclesFromExerciseName(name);
  }

  /// Estimated extra kcal burned **after** workouts (EPOC only), accumulated
  /// until [now] for every workout still inside its afterburn window.
  /// EPOC kcal accumulated since each workout ended (fractional; do not round per event).
  static double afterburnKcalAccumulatedSoFar({DateTime? now}) {
    final clock = now ?? DateTime.now();
    var total = 0.0;

    for (final event in ProgressStore.workoutEvents) {
      final at = DateTime.tryParse(event['recordedAt']?.toString() ?? '');
      if (at == null) continue;

      final type = (event['type'] ?? '').toString();
      final epocDuration = _epocDurationForType(type);
      final epocEnd = at.add(epocDuration);
      if (!clock.isBefore(epocEnd)) continue;

      final elapsed = clock.difference(at);
      if (elapsed <= Duration.zero) continue;

      final workoutKcal = _workoutKcalForEpoc(event, type);
      if (workoutKcal <= 0) continue;

      final epocTotal = workoutKcal * _epocBonusFraction(type);
      final progress = (elapsed.inMicroseconds / epocDuration.inMicroseconds)
          .clamp(0.0, 1.0);
      total += epocTotal * progress;
    }

    return total.clamp(0.0, 5000.0);
  }

  /// EPOC kcal that accrued on [day] (midnight–midnight, capped at [now] for today).
  static double afterburnKcalDuringDay(DateTime day, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final dayStart = _dateOnly(day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final windowEnd = _dateOnly(clock) == dayStart ? clock : dayEnd;
    if (!windowEnd.isAfter(dayStart)) return 0;

    var total = 0.0;
    for (final event in ProgressStore.workoutEvents) {
      final at = DateTime.tryParse(event['recordedAt']?.toString() ?? '');
      if (at == null) continue;

      final type = (event['type'] ?? '').toString();
      final epocDuration = _epocDurationForType(type);
      final epocEnd = at.add(epocDuration);

      final overlapStart = at.isAfter(dayStart) ? at : dayStart;
      final overlapEnd = epocEnd.isBefore(windowEnd) ? epocEnd : windowEnd;
      if (!overlapStart.isBefore(overlapEnd)) continue;

      final workoutKcal = _workoutKcalForEpoc(event, type);
      if (workoutKcal <= 0) continue;

      final epocTotal = workoutKcal * _epocBonusFraction(type);
      final overlapMicros = overlapEnd.difference(overlapStart).inMicroseconds;
      if (overlapMicros <= 0 || epocDuration.inMicroseconds <= 0) continue;
      total +=
          epocTotal *
          (overlapMicros / epocDuration.inMicroseconds).clamp(0.0, 1.0);
    }
    return total;
  }

  static List<({DateTime day, double value})> afterburnAnalyticsSeries({
    DateTime? now,
  }) {
    final count = ProgressStore.profileAnalyticsVisibleDayCount;
    if (count <= 0) return const [];
    final start = ProgressStore.profileAnalyticsRangeStart;
    return List.generate(count, (i) {
      final day = DateTime(start.year, start.month, start.day + i);
      return (day: day, value: afterburnKcalDuringDay(day, now: now));
    });
  }

  static int _workoutKcalForEpoc(Map<String, dynamic> event, String type) {
    final stored = ProgressStore.workoutEventBurnKcal(event);
    if (stored > 0) return stored;

    final durationSeconds =
        int.tryParse(event['durationSeconds']?.toString() ?? '') ?? 0;
    if (durationSeconds <= 0) return 0;

    return CalorieBurnService.durationBurn(
      met: CalorieBurnService.metForWorkoutType(type),
      durationSeconds: durationSeconds,
    );
  }

  /// Share of session kcal typically burned during the EPOC window (not in-session).
  static double _epocBonusFraction(String type) {
    return switch (type) {
      'gym' => 0.14,
      'calisthenics' => 0.12,
      'hercules' => 0.11,
      'nine_min' => 0.09,
      'run' => 0.07,
      'stretch' => 0.04,
      _ => 0.08,
    };
  }

  static MuscleRecoverySnapshot snapshot({DateTime? now}) {
    final clock = now ?? DateTime.now();
    final recovery = <BodyMuscleGroup, MuscleRecoveryHighlight>{};
    final lastAfterburnEnd = <BodyMuscleGroup, DateTime>{};
    final sessions = <BodyMuscleGroup, List<_MuscleSession>>{};
    final trainedThisWeek = <BodyMuscleGroup>{};
    final weekStart = _weekStart(clock);

    for (final event in ProgressStore.workoutEvents) {
      final at = DateTime.tryParse(event['recordedAt']?.toString() ?? '');
      if (at == null || at.isAfter(clock)) continue;
      final elapsed = clock.difference(at);
      final thisWeek = !at.isBefore(weekStart);
      if (!thisWeek && elapsed >= const Duration(hours: 48)) continue;
      final type = (event['type'] ?? '').toString();
      final recorded = _recordedMuscles(event, type);
      final muscles = recorded?.involved ?? _fallbackMuscles(event, type);
      if (thisWeek) trainedThisWeek.addAll(muscles);
      if (elapsed >= const Duration(hours: 48)) continue;

      // Preset completions have no effort rating. A completed strength
      // session counts as moderate unless it was explicitly logged as light.
      final intensity = int.tryParse(event['workoutIntensity'].toString());
      final moderate = intensity == null
          ? type == 'gym' || type == 'calisthenics' || type == 'hercules'
          : intensity >= 2 && type != 'stretch';
      final state = _recoveryHighlight(elapsed: elapsed, lastWorkoutType: type);
      final epocEnd = at.add(_epocDurationForType(type));

      for (final muscle in muscles) {
        final sets = recorded?.directGymSets[muscle] ?? 0;
        if (recorded != null && (moderate || sets > 0)) {
          (sessions[muscle] ??= []).add((
            at: at,
            gymSets: sets,
            moderate: moderate,
            primary: moderate && recorded.primary.contains(muscle),
          ));
        }
        if (state.load > (recovery[muscle]?.load ?? -1)) {
          recovery[muscle] = state;
        }

        final prevEnd = lastAfterburnEnd[muscle];
        if (prevEnd == null || epocEnd.isAfter(prevEnd)) {
          lastAfterburnEnd[muscle] = epocEnd;
        }
      }
    }

    final afterburn = <BodyMuscleGroup, MuscleAfterburnState>{};

    for (final muscle in BodyMuscleGroup.values) {
      recovery.putIfAbsent(muscle, () => MuscleRecoveryHighlight.none);
      final history = sessions[muscle];
      if (history != null && _hasRecentHighLoad(history, clock)) {
        recovery[muscle] = MuscleRecoveryHighlight.recent;
      }

      final end = lastAfterburnEnd[muscle];
      if (end != null && clock.isBefore(end)) {
        afterburn[muscle] = MuscleAfterburnState(
          active: true,
          remaining: end.difference(clock),
        );
      } else {
        afterburn[muscle] = const MuscleAfterburnState(active: false);
      }
    }

    return MuscleRecoverySnapshot(
      recovery: recovery,
      afterburn: afterburn,
      trainedThisWeek: trainedThisWeek,
    );
  }

  static DateTime _weekStart(DateTime day) {
    final d = _dateOnly(day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static const intenseGymSets = 6;

  /// Count each completion once per muscle. Red lasts 24 hours from a
  /// qualifying session, even when an earlier contributor has since expired.
  static bool _hasRecentHighLoad(List<_MuscleSession> history, DateTime clock) {
    const day = Duration(hours: 24);
    history.sort((a, b) => a.at.compareTo(b.at));
    var start = 0, sets = 0, primarySessions = 0, involvedSessions = 0;
    for (final current in history) {
      while (current.at.difference(history[start].at) >= day) {
        final expired = history[start++];
        sets -= expired.gymSets;
        if (expired.primary) primarySessions--;
        if (expired.moderate) involvedSessions--;
      }
      sets += current.gymSets;
      if (current.primary) primarySessions++;
      if (current.moderate) involvedSessions++;
      if (clock.difference(current.at) >= day) continue;
      if ((current.gymSets > 0 && sets >= intenseGymSets) ||
          (current.primary && primarySessions >= 2) ||
          (current.moderate && involvedSessions >= 3)) {
        return true;
      }
    }
    return false;
  }

  /// Time of the next age-based recovery transition, for mounted body views.
  static DateTime? nextRecoveryChange({DateTime? now}) {
    final clock = now ?? DateTime.now();
    DateTime? next;
    for (final event in ProgressStore.workoutEvents) {
      final at = DateTime.tryParse(event['recordedAt']?.toString() ?? '');
      if (at == null || at.isAfter(clock)) continue;
      for (final duration in [
        const Duration(hours: 24),
        const Duration(hours: 48),
        _epocDurationForType(event['type']?.toString() ?? ''),
      ]) {
        final boundary = at.add(duration);
        if (boundary.isAfter(clock) &&
            (next == null || boundary.isBefore(next))) {
          next = boundary;
        }
      }
    }
    return next;
  }

  static MuscleRecoveryHighlight _recoveryHighlight({
    required Duration elapsed,
    required String lastWorkoutType,
  }) {
    if (elapsed >= const Duration(hours: 48)) {
      return MuscleRecoveryHighlight.none;
    }
    return lastWorkoutType == 'nine_min' && elapsed < const Duration(hours: 24)
        ? MuscleRecoveryHighlight.lightCircuit
        : MuscleRecoveryHighlight.almostReady;
  }

  /// Longest EPOC window used for gym workouts (shown in HUD copy).
  static int get maxEpocHours => _epocDurationForType('gym').inHours;

  static Duration _epocDurationForType(String type) {
    return switch (type) {
      'gym' => const Duration(hours: 36),
      'calisthenics' => const Duration(hours: 32),
      'hercules' => const Duration(hours: 20),
      'nine_min' => const Duration(hours: 14),
      'run' => const Duration(hours: 10),
      'stretch' => const Duration(hours: 5),
      _ => const Duration(hours: 8),
    };
  }

  static _WorkoutMuscles? _recordedMuscles(
    Map<String, dynamic> event,
    String type,
  ) {
    final exercises = event['exercises'];
    if (exercises is List && exercises.isNotEmpty) {
      return _exerciseMuscles(exercises, countGymSets: type == 'gym');
    }

    // Older strength completions can contain just the ID of a built-in
    // preset. Its muscle targets are known, but its historical set counts aren't.
    final workoutId = event['workoutId']?.toString().trim();
    final preset = workoutId == null ? null : findPresetWorkoutById(workoutId);
    if (preset != null && preset.kind == type) {
      return _exerciseMuscles(resolvePresetWorkoutExercises(preset));
    }

    final breakdown = event['calorieBreakdown'];
    if (breakdown is List) {
      final result = _exerciseMuscles(breakdown, breakdown: true);
      if (result.involved.isNotEmpty) return result;
    }
    if (type == 'run') {
      return _WorkoutMuscles()
        ..primary.add(BodyMuscleGroup.legs)
        ..involved.add(BodyMuscleGroup.legs);
    }
    return null;
  }

  static Set<BodyMuscleGroup> _fallbackMuscles(
    Map<String, dynamic> event,
    String type,
  ) {
    final workoutId = event['workoutId']?.toString().trim();
    if (workoutId != null && workoutId.isNotEmpty) {
      final fromCustom = _musclesFromStoredWorkout(workoutId);
      if (fromCustom.isNotEmpty) return fromCustom;
    }
    return _musclesForWorkoutType(type);
  }

  /// Older timed-circuit events without per-exercise breakdown (no arm detail).
  static Set<BodyMuscleGroup> _musclesForTimedCircuitFallback() {
    return {
      BodyMuscleGroup.legs,
      BodyMuscleGroup.abs,
      BodyMuscleGroup.back,
      BodyMuscleGroup.chest,
      BodyMuscleGroup.shoulders,
    };
  }

  static _WorkoutMuscles _exerciseMuscles(
    List<dynamic> exercises, {
    bool countGymSets = false,
    bool breakdown = false,
  }) {
    final result = _WorkoutMuscles();
    for (final item in exercises) {
      if (item is! Map) continue;
      final label = item[breakdown ? 'label' : 'name']?.toString() ?? '';
      if (breakdown && _isCircuitMetaLabel(label)) continue;
      final sets = _completedSets(item);
      if (sets == 0) continue;
      final group = BodyMuscleGroupX.fromMainGroup(
        item['mainGroup']?.toString(),
      );
      if (group != null) {
        result.primary.add(group);
        result.involved.add(group);
        if (countGymSets && sets != null) {
          result.directGymSets.update(
            group,
            (sum) => sum + sets,
            ifAbsent: () => sets,
          );
        }
      }
      final tags = item['tags'];
      if (tags is List) {
        for (final tag in tags) {
          final taggedGroup = BodyMuscleGroupX.fromTrainingTag(tag?.toString());
          if (taggedGroup != null) result.involved.add(taggedGroup);
        }
      }
      // Catalog targets take precedence over guesses from names such as
      // "Pike Push-Ups", whose main target is the shoulders.
      if (group == null || tags is! List || tags.isEmpty) {
        result.involved.addAll(_musclesFromExerciseName(label));
      }
    }
    return result;
  }

  static int? _completedSets(Map<dynamic, dynamic> exercise) {
    final perSet = exercise['setSeconds'] ?? exercise['setReps'];
    if (perSet is List && perSet.isNotEmpty) {
      return perSet
          .take(StrengthExerciseConfig.maxSets)
          .where((reps) => (int.tryParse(reps.toString()) ?? 0) > 0)
          .length;
    }
    if (exercise['sets'] == null || exercise['reps'] == null) return null;
    final reps = int.tryParse(exercise['reps'].toString()) ?? 0;
    final sets = int.tryParse(exercise['sets'].toString()) ?? 0;
    return reps > 0 ? sets.clamp(0, StrengthExerciseConfig.maxSets) : 0;
  }

  static bool _isCircuitMetaLabel(String label) {
    final l = label.toLowerCase();
    return l == 'vorbereitung' ||
        l == 'preparation' ||
        l == 'pause' ||
        l == 'rest' ||
        l == 'training' ||
        l == 'lauf' ||
        l == 'run' ||
        l.startsWith('km ');
  }

  static String _normalizeExerciseName(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
  }

  static Set<BodyMuscleGroup> _musclesFromExerciseName(String name) {
    final n = _normalizeExerciseName(name);
    final fromTimedCircuit = _musclesFromTimedCircuitExerciseName(n);
    if (fromTimedCircuit != null) return fromTimedCircuit;
    return _musclesFromExerciseNameHeuristic(n);
  }

  /// Explicit mapping for 9-Min / Hercules labels (no biceps in either program).
  /// Longer keys are checked first to avoid partial matches (e.g. Liegestuetz vs Handstandliegestuetz).
  static const List<({List<String> keys, Set<BodyMuscleGroup> muscles})>
  _timedCircuitMuscleRules = [
    (
      keys: ['handstandliegestuetz', 'handstand push'],
      muscles: {
        BodyMuscleGroup.shoulders,
        BodyMuscleGroup.triceps,
        BodyMuscleGroup.abs,
      },
    ),
    (
      keys: ['liegestuetz mit drehen', 'push-up with rotation'],
      muscles: {
        BodyMuscleGroup.chest,
        BodyMuscleGroup.shoulders,
        BodyMuscleGroup.triceps,
        BodyMuscleGroup.abs,
      },
    ),
    (
      keys: ['liegestuetz', 'liegestütz', 'push-up', 'pushup'],
      muscles: {
        BodyMuscleGroup.chest,
        BodyMuscleGroup.shoulders,
        BodyMuscleGroup.triceps,
      },
    ),
    (
      keys: ['trizeps-dip', 'trizeps dip', 'triceps dip'],
      muscles: {
        BodyMuscleGroup.triceps,
        BodyMuscleGroup.chest,
        BodyMuscleGroup.shoulders,
      },
    ),
    (
      keys: [
        'seitliche unterarmstuetz',
        'seitlicher unterarmstuetz',
        'side plank',
      ],
      muscles: {BodyMuscleGroup.forearms, BodyMuscleGroup.abs},
    ),
    (
      keys: ['unterarmstuetz', 'unterarmstütz', 'forearm plank'],
      muscles: {BodyMuscleGroup.forearms, BodyMuscleGroup.abs},
    ),
    (
      keys: ['wandhaltung mit chin tuck', 'chin tuck'],
      muscles: {BodyMuscleGroup.neck, BodyMuscleGroup.shoulders},
    ),
    (
      keys: ['neck curl', 'neck curls', 'neck extension'],
      muscles: {BodyMuscleGroup.neck},
    ),
    (keys: ['bauchpresse', 'bauch rolle'], muscles: {BodyMuscleGroup.abs}),
    (
      keys: [
        'reverse plank',
        'l-sit',
        'l sit',
        'knieuebung im knien',
        'kneeling lean',
      ],
      muscles: {BodyMuscleGroup.abs, BodyMuscleGroup.triceps},
    ),
    (keys: ['hampelmann', 'jumping jack'], muscles: {BodyMuscleGroup.legs}),
    (keys: ['wandsitzen', 'wall sit'], muscles: {BodyMuscleGroup.legs}),
    (keys: ['deep squat hold'], muscles: {BodyMuscleGroup.legs}),
    (
      keys: ['stuhl step', 'stuhl-step', 'step-up', 'step up'],
      muscles: {BodyMuscleGroup.legs},
    ),
    (keys: ['kniebeug', 'squat'], muscles: {BodyMuscleGroup.legs}),
    (
      keys: ['knie hoch', 'knien hoch', 'high knee'],
      muscles: {BodyMuscleGroup.legs, BodyMuscleGroup.abs},
    ),
    (keys: ['ausfallschritt', 'lunge'], muscles: {BodyMuscleGroup.legs}),
    (
      keys: ['calf raise', 'wadenheben', 'soleus', 'tibialis'],
      muscles: {BodyMuscleGroup.legs},
    ),
    (keys: ['poliquin'], muscles: {BodyMuscleGroup.legs}),
    (
      keys: ['glute bridge'],
      muscles: {BodyMuscleGroup.legs, BodyMuscleGroup.back},
    ),
    (keys: ['short foot'], muscles: {BodyMuscleGroup.legs}),
    (
      keys: [
        'hipflexor stretch',
        'pigeon stretch',
        'cobra stretch',
        'kindstellung',
        'child pose',
        'worlds greatest',
        'hamstring hold',
        'beinsehne hold',
      ],
      muscles: {BodyMuscleGroup.back, BodyMuscleGroup.legs},
    ),
  ];

  static Set<BodyMuscleGroup>? _musclesFromTimedCircuitExerciseName(String n) {
    for (final rule in _timedCircuitMuscleRules) {
      if (rule.keys.any(n.contains)) return rule.muscles;
    }
    return null;
  }

  /// Heuristics for gym/calisthenics/run labels (and unknown circuit labels).
  static Set<BodyMuscleGroup> _musclesFromExerciseNameHeuristic(String n) {
    final out = <BodyMuscleGroup>{};
    bool has(List<String> keys) => keys.any(n.contains);

    if (has(['trizeps', 'triceps', 'skull crusher', 'kickback'])) {
      out.add(BodyMuscleGroup.triceps);
    }
    if (has(['dip']) && !has(['hip'])) out.add(BodyMuscleGroup.triceps);
    if (has(['bizeps', 'biceps']) ||
        has([
          'hammer curl',
          'preacher curl',
          'concentration curl',
          'biceps curl',
          'bizepscurl',
        ]) ||
        (has(['klimmzug', 'pull-up', 'pullup', 'chin-up', 'chin up']) &&
            !has(['chin tuck', 'tuck']))) {
      out.add(BodyMuscleGroup.biceps);
    }
    if (has(['liegestuetz', 'liegestütz', 'push-up', 'pushup', 'handstand'])) {
      out.addAll({
        BodyMuscleGroup.chest,
        BodyMuscleGroup.shoulders,
        BodyMuscleGroup.triceps,
      });
    }
    if (has(['unterarm', 'forearm', 'wrist curl', 'handgelenk'])) {
      out.add(BodyMuscleGroup.forearms);
    }
    if (has(['plank']) ||
        (has(['stuetz', 'stütz', 'stutz']) &&
            has(['unterarm', 'seitlich', 'side']))) {
      out.add(BodyMuscleGroup.abs);
      if (has(['unterarm', 'forearm', 'seitlich', 'side'])) {
        out.add(BodyMuscleGroup.forearms);
      }
    }
    if (has(['bauch', 'presse', 'l-sit', 'l sit', 'reverse plank', 'hollow'])) {
      out.add(BodyMuscleGroup.abs);
    }
    if (has([
          'neck curl',
          'neck curls',
          'neck extension',
          'neck harness',
          'nacken',
        ]) ||
        has(['chin tuck'])) {
      out.add(BodyMuscleGroup.neck);
    }
    if (has([
      'kniebeug',
      'squat',
      'ausfall',
      'lunge',
      'step-up',
      'step up',
      'wandsitz',
      'hampelmann',
      'waden',
      'calf',
      'tibialis',
      'glute',
      'soleus',
      'poliquin',
      'deep squat',
      'beinsehne',
    ])) {
      out.add(BodyMuscleGroup.legs);
    }
    if (has([
      'stretch',
      'dehn',
      'pigeon',
      'hipflexor',
      'cobra',
      'kindstellung',
      'worlds greatest',
      'hamstring hold',
    ])) {
      out.addAll({BodyMuscleGroup.back, BodyMuscleGroup.legs});
    }
    if (has(['rudern', 'row', 'lat pull', 'latzug', 'klimmzug'])) {
      out.addAll({BodyMuscleGroup.back, BodyMuscleGroup.biceps});
    }
    if (has(['schulter', 'shoulder', 'wandhaltung']) && !has(['chin tuck'])) {
      out.add(BodyMuscleGroup.shoulders);
    }
    return out;
  }

  static Set<BodyMuscleGroup> _musclesFromStoredWorkout(String workoutId) {
    final muscles = <BodyMuscleGroup>{};
    for (final source in [
      ProgressStore.gymWorkoutById(workoutId),
      ProgressStore.calisthenicsWorkoutById(workoutId),
    ]) {
      if (source == null) continue;
      final exercises = source['exercises'];
      if (exercises is List) {
        muscles.addAll(_exerciseMuscles(exercises).involved);
      }
    }
    return muscles;
  }

  static Set<BodyMuscleGroup> _musclesForWorkoutType(String type) {
    return switch (type) {
      'gym' => {
        BodyMuscleGroup.chest,
        BodyMuscleGroup.back,
        BodyMuscleGroup.shoulders,
        BodyMuscleGroup.biceps,
        BodyMuscleGroup.triceps,
        BodyMuscleGroup.abs,
      },
      'calisthenics' => {
        BodyMuscleGroup.chest,
        BodyMuscleGroup.back,
        BodyMuscleGroup.shoulders,
        BodyMuscleGroup.abs,
        BodyMuscleGroup.triceps,
      },
      'hercules' => _musclesForTimedCircuitFallback(),
      'nine_min' => _musclesForTimedCircuitFallback(),
      'stretch' => {
        BodyMuscleGroup.abs,
        BodyMuscleGroup.back,
        BodyMuscleGroup.legs,
        BodyMuscleGroup.shoulders,
      },
      'run' => {BodyMuscleGroup.legs},
      _ => const {},
    };
  }
}

class _WorkoutMuscles {
  final involved = <BodyMuscleGroup>{};
  final primary = <BodyMuscleGroup>{};
  final directGymSets = <BodyMuscleGroup, int>{};
}

typedef _MuscleSession = ({
  DateTime at,
  int gymSets,
  bool moderate,
  bool primary,
});
