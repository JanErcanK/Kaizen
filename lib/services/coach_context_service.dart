import 'dart:convert';

import '../models/health_dashboard.dart';
import 'coach_training_analysis.dart';
import 'muscle_activity_service.dart';
import 'progress_store.dart';

/// Only fitness records are exposed. Never exports keys, photos, chats, friends,
/// addresses, route coordinates or arbitrary Hive settings.
class CoachContextService {
  static bool get enabled =>
      ProgressStore.chatSettings['shareFitnessContext'] == true;
  static List<String> get memories =>
      (ProgressStore.chatSettings['coachMemories'] as List? ?? [])
          .whereType<String>()
          .toList();

  static Future<void> saveMemories(List<String> notes) =>
      ProgressStore.saveChatSettings({
        ...ProgressStore.chatSettings,
        'coachMemories': notes
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .take(30)
            .toList(),
      });

  static String snapshot() {
    if (!enabled) {
      return 'Fitness context is disabled. Do not claim access to profile, history or memories.';
    }
    final today = DateTime.now();
    final training = CoachTrainingAnalysis.current(now: today);
    final trends = training['exerciseTrends'] as List;
    final recovery = MuscleActivityService.snapshot(now: today);
    return jsonEncode({
      'asOf': today.toIso8601String(),
      'profile': {
        'name': ProgressStore.profileName,
        'age': ProgressStore.profileAge,
        'heightCm': ProgressStore.profileHeightCm,
        'gender': ProgressStore.profileGender,
        'weightKg': ProgressStore.currentWeightKg,
        'bodyFatPercent': ProgressStore.profileBodyFatPercent,
        'muscleMassKg': ProgressStore.profileMuscleMassKg,
        'boneMassKg': ProgressStore.profileBoneMassKg,
        'activityLevel': ProgressStore.profileActivityLevel,
        'goal': ProgressStore.profileGoal,
      },
      'confirmedCoachNotes': memories,
      'trainingAnalysis': {
        ...training,
        'exerciseTrends': trends.take(8).toList(),
        'exerciseTrendCount': trends.length,
        'omittedExerciseTrends': (trends.length - 8).clamp(0, trends.length),
        'moreDetails':
            'Query trainingAnalysis with an exercise name for other trends.',
      },
      'recoveryEstimate': {
        'asOf': today.toIso8601String(),
        'method':
            'Same time/load heuristic as the body map; not measured recovery or a medical assessment. none means no current highlight, not proven recovery.',
        'muscles': recovery.recovery.map(
          (group, state) => MapEntry(group.name, state.name),
        ),
      },
      'healthTrends': _healthTrends(today),
      'weeklySchedule': ProgressStore.weeklyTrainingSchedule.toJsonList(),
      'waterGoalMl': ProgressStore.waterGoalMl,
      'eatingWindow': ProgressStore.eatingWindowConfigured
          ? {
              'startMinutes': ProgressStore.eatingWindowStartMinutes,
              'endMinutes': ProgressStore.eatingWindowEndMinutes,
            }
          : null,
      'last14Days': List.generate(14, (i) {
        final day = DateTime(today.year, today.month, today.day - i);
        final totals = ProgressStore.foodTotalsForDay(day);
        return {
          'day': healthDayKey(day),
          'steps': ProgressStore.stepsForDay(day),
          'waterMl': ProgressStore.waterMlForDay(day),
          'foodLogged': ProgressStore.foodIntakeForDay(day).isNotEmpty,
          'kcal': totals.kcal,
          'proteinG': totals.p,
          'carbsG': totals.c,
          'fatG': totals.f,
          'workoutCount': ProgressStore.workoutEventsForDay(day).length,
        };
      }),
      'datasets': {
        for (final section in sections)
          section: section == 'trainingAnalysis'
              ? trends.length + 1
              : _records(section).length,
      },
      'access':
          'Use read_fitness_data to look up records, including older dates. Pages are bounded and may be incomplete. Missing records are unknown, not proof of inactivity. Health sources must not be summed together.',
    });
  }

  static const sections = [
    'trainingAnalysis',
    'workouts',
    'workoutHistory',
    'dishes',
    'nutrition',
    'weight',
    'shopping',
    'health',
    'routes',
    'supplements',
  ];
  static List<Map<String, dynamic>> _records(String section) =>
      switch (section) {
        'trainingAnalysis' => _trainingRecords(),
        'workouts' => [
          ...ProgressStore.gymWorkouts.map(
            (w) => {
              ..._pick(w, ['id', 'name', 'exercises', 'updatedAt']),
              'category': 'gym',
            },
          ),
          ...ProgressStore.calisthenicsWorkouts.map(
            (w) => {
              ..._pick(w, ['id', 'name', 'exercises', 'updatedAt']),
              'category': 'calisthenics',
            },
          ),
        ],
        'workoutHistory' =>
          ProgressStore.workoutEvents.reversed
              .map(
                (w) => _pick(w, [
                  'id',
                  'type',
                  'recordedAt',
                  'workoutName',
                  'workoutId',
                  'workoutCategory',
                  'durationSeconds',
                  'caloriesBurned',
                  'runMeters',
                  'mood',
                  'workoutIntensity',
                  'exercises',
                ]),
              )
              .toList(),
        'dishes' =>
          ProgressStore.foodDishes
              .map(
                (d) => _pick(d, [
                  'id',
                  'name',
                  'description',
                  'items',
                  'updatedAt',
                ]),
              )
              .toList(),
        'nutrition' =>
          ProgressStore.foodIntake.reversed
              .map(
                (d) => _pick(d, [
                  'id',
                  'recordedAt',
                  'date',
                  'foodName',
                  'grams',
                  'proteinG',
                  'carbsG',
                  'fatsG',
                  'micros',
                  'aminos',
                  'extraNutrients',
                  'name',
                  'dishName',
                  'items',
                  'fiberG',
                  'sugarG',
                  'saturatedFatG',
                  'saltG',
                ]),
              )
              .toList(),
        'weight' => ProgressStore.weightEntries.reversed.toList(),
        'shopping' => [
          ProgressStore.shoppingDraft.toJson(),
          ...ProgressStore.shoppingHistory
              .where((s) => s.id != ProgressStore.shoppingDraft.id)
              .map((s) => s.toJson()),
        ],
        'health' => [
          for (final metric in ProgressStore.healthDashboard.metrics.entries)
            for (final series in metric.value.series)
              for (final day in series.days.reversed)
                {
                  'metric': metric.key.name,
                  'state': metric.value.state.name,
                  'source': series.source,
                  'method': series.method,
                  ...day.toJson(),
                },
        ],
        'routes' =>
          ProgressStore.runningRoutes
              .map(
                (r) => _pick(r, [
                  'id',
                  'name',
                  'distanceMeters',
                  'ascentMeters',
                  'descentMeters',
                  'createdAt',
                ]),
              )
              .toList(),
        'supplements' =>
          ProgressStore.supplementIntake.reversed
              .map(
                (s) => _pick(s, [
                  'id',
                  'name',
                  'supplementName',
                  'recordedAt',
                  'date',
                  'amount',
                  'mg',
                  'slot',
                  'unit',
                  'micros',
                  'nutrients',
                ]),
              )
              .toList(),
        _ => [],
      };

  static List<Map<String, dynamic>> _trainingRecords() {
    final analysis = CoachTrainingAnalysis.current();
    return [
      {
        'kind': 'overview',
        ...Map<String, dynamic>.from(analysis)..remove('exerciseTrends'),
      },
      for (final trend in analysis['exerciseTrends'] as List)
        {'kind': 'exerciseTrend', ...Map<String, dynamic>.from(trend as Map)},
    ];
  }

  static List<Map<String, dynamic>> _healthTrends(DateTime now) => [
    for (final metric in [
      HealthMetric.sleep,
      HealthMetric.restingHeartRate,
      HealthMetric.hrv,
    ])
      for (final series in ProgressStore.healthDashboard.data(metric).series)
        {
          'metric': metric.name,
          'source': series.source,
          'sourceId': series.sourceId,
          'method': series.method,
          'state': ProgressStore.healthDashboard.data(metric).state.name,
          'unit': metric == HealthMetric.sleep
              ? 'minutes'
              : metric == HealthMetric.hrv
              ? 'ms'
              : 'bpm',
          'periods': [
            for (var window = 0; window < 2; window++)
              _healthPeriod(series, now, window),
          ],
        },
  ];

  static Map<String, dynamic> _healthPeriod(
    HealthSeries series,
    DateTime now,
    int window,
  ) {
    final from = DateTime(now.year, now.month, now.day - 13 - 14 * window);
    final through = DateTime(now.year, now.month, now.day - 14 * window);
    final days = series.days
        .where(
          (d) =>
              !d.day.isBefore(from) &&
              d.day.isBefore(
                DateTime(through.year, through.month, through.day + 1),
              ) &&
              !d.recordedAt.isAfter(now) &&
              d.value.isFinite &&
              d.value > 0,
        )
        .toList();
    return {
      'from': healthDayKey(from),
      'through': healthDayKey(through),
      'measuredDays': days.length,
      'mean': days.isEmpty
          ? null
          : (days.fold<double>(0, (sum, d) => sum + d.value) / days.length * 10)
                    .round() /
                10,
      'estimatedDays': days.where((d) => d.estimated).length,
    };
  }

  static Map<String, dynamic> _pick(
    Map<String, dynamic> data,
    List<String> keys,
  ) => {
    for (final k in keys)
      if (data.containsKey(k)) k: data[k],
  };

  static String query(String section, int offset, {String search = ''}) {
    if (!enabled) return '{"error":"Fitness context is disabled"}';
    if (!sections.contains(section) || offset < 0) {
      return '{"error":"Invalid query"}';
    }
    final all = _records(section)
        .where(
          (r) =>
              search.isEmpty ||
              jsonEncode(r).toLowerCase().contains(search.toLowerCase()),
        )
        .toList();
    final page = <Map<String, dynamic>>[];
    var used = 0;
    var next = offset.clamp(0, all.length);
    for (final record in all.skip(next).take(20)) {
      final size = jsonEncode(record).length;
      if (page.isNotEmpty && used + size > 24000) break;
      if (size > 24000) {
        page.add({
          'id': record['id'],
          'name': record['name'],
          'omitted': 'Record exceeds context limit; inspect it in the app.',
        });
      } else {
        page.add(record);
        used += size;
      }
      next++;
    }
    return jsonEncode({
      'section': section,
      'search': search,
      'total': all.length,
      'offset': offset,
      'nextOffset': next < all.length ? next : null,
      'records': page,
    });
  }
}
