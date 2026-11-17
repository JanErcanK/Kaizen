import '../models/health_dashboard.dart';
import 'progress_store.dart';

/// Aggregates recorded sessions; never fills missing sets or loads with defaults.
class CoachTrainingAnalysis {
  static Map<String, dynamic> current({DateTime? now}) {
    final clock = now ?? DateTime.now();
    return analyze(
      ProgressStore.workoutEvents,
      now: clock,
      nutrition: List.generate(56, (i) {
        final day = DateTime(clock.year, clock.month, clock.day - i);
        final totals = ProgressStore.foodTotalsForDay(day);
        return {
          'day': healthDayKey(day),
          'logged': ProgressStore.foodIntakeForDay(day).isNotEmpty,
          'kcal': totals.kcal,
          'proteinG': totals.p,
        };
      }),
      weights: ProgressStore.weightEntries,
    );
  }

  static Map<String, dynamic> analyze(
    List<Map<String, dynamic>> events, {
    required DateTime now,
    List<Map<String, dynamic>> nutrition = const [],
    List<Map<String, dynamic>> weights = const [],
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(today.year, today.month, today.day - 55);
    final weeks = List.generate(
      8,
      (i) => _TrainingPeriod(
        DateTime(start.year, start.month, start.day + i * 7),
        DateTime(start.year, start.month, start.day + i * 7 + 6),
      ),
    );
    final previous = _TrainingPeriod(start, weeks[3].end);
    final recent = _TrainingPeriod(weeks[4].start, today);
    final exercises = <String, _ExerciseTrend>{};
    final valid = <({DateTime at, Map<String, dynamic> event})>[];
    var invalidDates = 0;
    for (final event in events) {
      final at = DateTime.tryParse(
        event['recordedAt']?.toString() ?? '',
      )?.toLocal();
      if (at == null) {
        invalidDates++;
        continue;
      }
      if (at.isBefore(start) || at.isAfter(now)) continue;
      valid.add((at: at, event: event));
    }
    valid.sort((a, b) => a.at.compareTo(b.at));
    for (final item in valid) {
      // UTC date ordinals keep calendar bins stable across daylight saving time.
      final ordinal = DateTime.utc(
        item.at.year,
        item.at.month,
        item.at.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
      final week = weeks[ordinal ~/ 7];
      final period = ordinal < 28 ? previous : recent;
      week.add(item.event, item.at);
      period.add(item.event, item.at);
      final rawExercises = item.event['exercises'];
      if (rawExercises is! List) continue;
      // One observation per exercise/session, even if the exercise is split.
      final observations = <String, _ExerciseObservation>{};
      for (final raw in rawExercises.whereType<Map>()) {
        final name = (raw['name'] ?? raw['label'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final category =
            (item.event['workoutCategory'] ?? item.event['type'] ?? '')
                .toString();
        final group = (raw['mainGroup'] ?? '').toString();
        final key = '$category|${name.toLowerCase()}|$group';
        final observation = observations.putIfAbsent(
          key,
          () => _ExerciseObservation(item.at, item.event['id']?.toString()),
        );
        observation.add(raw);
        exercises.putIfAbsent(key, () => _ExerciseTrend(name, category, group));
      }
      for (final entry in observations.entries) {
        exercises[entry.key]!.observations.add(entry.value);
      }
    }
    for (final day in nutrition.where((d) => d['logged'] == true)) {
      final date = DateTime.tryParse(day['day']?.toString() ?? '');
      if (date == null || date.isBefore(start) || date.isAfter(today)) continue;
      for (final period in [...weeks, previous, recent]) {
        if (period.contains(date)) period.food.add(day);
      }
    }
    for (final weight in weights) {
      final date = DateTime.tryParse(weight['date']?.toString() ?? '');
      final kg = _positive(weight['weight']);
      if (date == null || date.isAfter(today) || kg == null) continue;
      for (final period in [...weeks, previous, recent]) {
        if (period.contains(date)) period.weights.add(kg);
      }
    }
    final trends = exercises.values.toList()
      ..sort((a, b) {
        final byCount = b.observations.length.compareTo(a.observations.length);
        return byCount != 0 ? byCount : a.name.compareTo(b.name);
      });
    return {
      'from': healthDayKey(start),
      'through': healthDayKey(today),
      'asOf': now.toIso8601String(),
      'windowDays': 56,
      'todayIncomplete': true,
      'recordedSessions': valid.length,
      'excludedUndatedRecords': invalidDates,
      'interpretation':
          'Eight consecutive 7-calendar-day windows, oldest first. '
          'Counts describe logs, not all activity. Missing logs are unknown. '
          'Exercise sets/reps/load are saved session snapshots, not independently '
          'verified completed sets. Direct muscle sets exclude secondary muscles. '
          'Load volume is reps × recorded external kg; bodyweight and missing loads '
          'are excluded. Do not compare different exercises/variants or infer strength '
          'from load volume alone. Nutrition means cover logged days only and may '
          'include partially logged days. No automatic memory is created.',
      'weeks': weeks.map((w) => w.toJson()).toList(),
      'fourWeekComparison': {
        'previous': previous.toJson(),
        'recent': recent.toJson(),
        'sessionChange': recent.sessions - previous.sessions,
        'sessionChangePercent': previous.sessions == 0
            ? null
            : _round(
                100 * (recent.sessions - previous.sessions) / previous.sessions,
              ),
      },
      'exerciseTrends': trends.map((e) => e.toJson()).toList(),
    };
  }
}

double? _positive(dynamic value) {
  final number = value is num ? value.toDouble() : double.tryParse('$value');
  return number != null && number.isFinite && number > 0 ? number : null;
}

double _round(num n) => (n * 10).round() / 10;

int _sets(Map exercise) => exercise['setSeconds'] is List
    ? (exercise['setSeconds'] as List).where((s) => _positive(s) != null).length
    : _reps(exercise).length;

List<int> _reps(Map exercise) {
  if (exercise['setReps'] is List) {
    // Preserve explicit zero reps as unperformed rather than inventing defaults.
    return (exercise['setReps'] as List)
        .take(100)
        .map((r) => (_positive(r) ?? 0).toInt().clamp(0, 999))
        .where((r) => r > 0)
        .toList();
  }
  final sets = _positive(exercise['sets'])?.toInt();
  final reps = _positive(exercise['reps'])?.toInt();
  if (sets == null || reps == null) return [];
  return List.filled(
    sets.clamp(0, 100),
    reps.clamp(0, 999),
  ).where((r) => r > 0).toList();
}

class _TrainingPeriod {
  _TrainingPeriod(this.start, this.end);
  final DateTime start, end;
  int sessions = 0, durationRecords = 0, exerciseRecords = 0;
  double seconds = 0, runMeters = 0;
  int runDurationRecords = 0;
  double runSecondsWithDistance = 0, runMetersWithDuration = 0;
  final days = <String>{};
  final types = <String, int>{};
  final muscleSets = <String, int>{};
  final muscleDates = <String, Set<String>>{};
  final food = <Map<String, dynamic>>[];
  final weights = <double>[];

  bool contains(DateTime day) =>
      !day.isBefore(start) &&
      day.isBefore(DateTime(end.year, end.month, end.day + 1));

  void add(Map<String, dynamic> event, DateTime at) {
    sessions++;
    final day = healthDayKey(at);
    days.add(day);
    final type = (event['workoutCategory'] ?? event['type'] ?? 'unknown')
        .toString();
    types.update(type, (v) => v + 1, ifAbsent: () => 1);
    final duration = _positive(event['durationSeconds']);
    if (duration != null) {
      seconds += duration;
      durationRecords++;
    }
    final distance = _positive(event['runMeters']);
    if (distance != null) {
      runMeters += distance;
      if (duration != null) {
        runDurationRecords++;
        runSecondsWithDistance += duration;
        runMetersWithDuration += distance;
      }
    }
    final exercises = event['exercises'];
    if (exercises is! List || exercises.isEmpty) return;
    exerciseRecords++;
    for (final exercise in exercises.whereType<Map>()) {
      final group = (exercise['mainGroup'] ?? '').toString().trim();
      final sets = _sets(exercise);
      if (group.isEmpty || sets == 0) continue;
      muscleSets.update(group, (v) => v + sets, ifAbsent: () => sets);
      muscleDates.putIfAbsent(group, () => {}).add(day);
    }
  }

  Map<String, dynamic> toJson() => {
    'from': healthDayKey(start),
    'through': healthDayKey(end),
    'sessions': sessions,
    'loggedTrainingDays': days.length,
    'durationMinutes': durationRecords == 0 ? null : _round(seconds / 60),
    'sessionsWithDuration': durationRecords,
    'sessionsWithExerciseDetails': exerciseRecords,
    'categories': types,
    'directMuscleSets': muscleSets,
    'muscleTrainingDays': muscleDates.map((k, v) => MapEntry(k, v.length)),
    'runKm': _round(runMeters / 1000),
    'runPaceMinPerKm': runMetersWithDuration == 0
        ? null
        : _round(runSecondsWithDistance / 60 / (runMetersWithDuration / 1000)),
    'runsWithDistanceAndDuration': runDurationRecords,
    'nutritionLoggedDays': food.length,
    'meanLoggedKcal': food.isEmpty
        ? null
        : _round(
            food.fold<double>(
                  0,
                  (sum, d) => sum + (d['kcal'] as num).toDouble(),
                ) /
                food.length,
          ),
    'meanLoggedProteinG': food.isEmpty
        ? null
        : _round(
            food.fold<double>(
                  0,
                  (sum, d) => sum + (d['proteinG'] as num).toDouble(),
                ) /
                food.length,
          ),
    'weightMeasurements': weights.length,
    'meanWeightKg': weights.isEmpty
        ? null
        : _round(weights.reduce((a, b) => a + b) / weights.length),
  };
}

class _ExerciseObservation {
  _ExerciseObservation(this.at, this.eventId);
  final DateTime at;
  final String? eventId;
  int sets = 0, reps = 0, loadedSets = 0;
  double volumeKg = 0;
  final loads = <double>{};
  void add(Map exercise) {
    final counts = _reps(exercise);
    final count = counts.fold(0, (a, b) => a + b);
    sets += _sets(exercise);
    reps += count;
    final load = _positive(exercise['weight']);
    if (load != null && counts.isNotEmpty) {
      loads.add(load);
      loadedSets += counts.length;
      volumeKg += count * load;
    }
  }

  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'eventId': eventId,
    'recordedSets': sets,
    'recordedReps': reps,
    'externalLoadKg': loads.length == 1 ? loads.single : null,
    'setsWithRecordedExternalLoad': loadedSets,
    'externalLoadVolumeKg': loadedSets == 0 ? null : _round(volumeKg),
  };
}

class _ExerciseTrend {
  _ExerciseTrend(this.name, this.category, this.group);
  final String name, category, group;
  final observations = <_ExerciseObservation>[];
  Map<String, dynamic> toJson() {
    final first = observations.first;
    final last = observations.last;
    final comparable =
        observations.length >= 2 &&
        first.loads.length == 1 &&
        last.loads.length == 1 &&
        first.loads.single == last.loads.single &&
        first.loadedSets == first.sets &&
        last.loadedSets == last.sets &&
        first.sets == last.sets &&
        first.sets > 0 &&
        !(first.at.year == last.at.year &&
            first.at.month == last.at.month &&
            first.at.day == last.at.day);
    return {
      'name': name,
      'category': category,
      'mainGroup': group,
      'recordedSessions': observations.length,
      'first': first.toJson(),
      'latest': last.toJson(),
      'sameLoadAndSetCount': comparable,
      'repChangeAtSameLoadAndSets': comparable ? last.reps - first.reps : null,
      'recentObservations': observations.reversed
          .take(4)
          .map((o) => o.toJson())
          .toList(),
    };
  }
}
