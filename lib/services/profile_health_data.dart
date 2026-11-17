import '../models/health_dashboard.dart';
import '../models/profile_health_metric.dart';
import 'muscle_activity_service.dart';
import 'progress_store.dart';

const kaizenHealthSourceId = 'kaizen-local';

/// Displays local logs beside imports as separate sources, never summing them.
HealthMetricData profileHealthData(
  ProfileHealthMetric metric, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final imported = metric.importedMetric;
  final remote = imported == null
      ? const HealthMetricData(state: HealthReadState.empty)
      : ProgressStore.healthDashboard.data(imported);
  final local = _localSeries(metric, clock);
  if (local == null) return remote;
  final preferLocal =
      metric == ProfileHealthMetric.weight ||
      metric == ProfileHealthMetric.workouts;
  return HealthMetricData(
    state: HealthReadState.available,
    checkedAt: remote.checkedAt,
    series: preferLocal ? [local, ...remote.series] : [...remote.series, local],
  );
}

HealthSeries? _localSeries(ProfileHealthMetric metric, DateTime now) {
  if ({
    ProfileHealthMetric.sleep,
    ProfileHealthMetric.activeEnergy,
    ProfileHealthMetric.restingHeartRate,
    ProfileHealthMetric.hrv,
  }.contains(metric)) {
    return null;
  }
  final today = healthDay(now);
  final first = DateTime(today.year, today.month, today.day - 27);
  final weights = <DateTime, HealthDayValue>{};
  if (metric == ProfileHealthMetric.weight) {
    for (final entry in ProgressStore.weightEntries) {
      final recorded = DateTime.tryParse(
        (entry['recordedAt'] ?? entry['date'])?.toString() ?? '',
      );
      final weight = double.tryParse(entry['weight']?.toString() ?? '');
      if (recorded == null ||
          recorded.isAfter(now) ||
          weight == null ||
          !weight.isFinite ||
          weight <= 0) {
        continue;
      }
      final day = healthDay(recorded);
      if (day.isBefore(first)) continue;
      final previous = weights[day];
      if (previous == null || !recorded.isBefore(previous.recordedAt)) {
        weights[day] = HealthDayValue(
          day: day,
          value: weight,
          recordedAt: recorded,
        );
      }
    }
  }
  final days = <HealthDayValue>[];
  for (var i = 0; i < 28; i++) {
    final day = DateTime(first.year, first.month, first.day + i);
    double? value;
    switch (metric) {
      case ProfileHealthMetric.weight:
        final weight = weights[day];
        if (weight != null) days.add(weight);
        continue;
      case ProfileHealthMetric.steps:
        value = ProgressStore.stepsForDay(day)?.toDouble();
      case ProfileHealthMetric.workouts:
        final sessions = ProgressStore.workoutSessionsForDay(day);
        if (sessions.isNotEmpty) value = sessions.length.toDouble();
      case ProfileHealthMetric.calorieBurn:
        final kcal = ProgressStore.totalBurnKcalForDay(day);
        if (kcal > 0) value = kcal.toDouble();
      case ProfileHealthMetric.water:
        final ml = ProgressStore.waterMlForDay(day);
        if (ml > 0) value = ml.toDouble();
      case ProfileHealthMetric.afterburn:
        final kcal = MuscleActivityService.afterburnKcalDuringDay(
          day,
          now: now,
        );
        if (kcal > 0) value = kcal;
      case ProfileHealthMetric.calorieIntake ||
          ProfileHealthMetric.protein ||
          ProfileHealthMetric.fat ||
          ProfileHealthMetric.carbs:
        if (ProgressStore.foodIntakeForDay(day).isEmpty) {
          continue;
        }
        final totals = ProgressStore.foodTotalsForDay(day);
        value = switch (metric) {
          ProfileHealthMetric.calorieIntake => totals.kcal.toDouble(),
          ProfileHealthMetric.protein => totals.p,
          ProfileHealthMetric.fat => totals.f,
          _ => totals.c,
        };
      default:
        continue;
    }
    if (value != null && value.isFinite && value >= 0) {
      days.add(HealthDayValue(day: day, value: value, recordedAt: day));
    }
  }
  if (days.isEmpty) return null;
  return HealthSeries(
    sourceId: kaizenHealthSourceId,
    source: 'Kaizen',
    method: metric == ProfileHealthMetric.workouts ? 'workoutCount' : '',
    days: days,
  );
}
