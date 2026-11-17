/// Imported health data stays separate from Kaizen's workout and calorie logs.
/// A missing day is absent, never represented as a zero measurement.
enum HealthMetric {
  sleep,
  steps,
  activeEnergy,
  workouts,
  restingHeartRate,
  hrv,
  weight,
}

enum HealthReadState { available, empty, denied, failed, unsupported }

DateTime healthDay(DateTime date) => DateTime(date.year, date.month, date.day);
String healthDayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class HealthDayValue {
  const HealthDayValue({
    required this.day,
    required this.value,
    required this.recordedAt,
    this.count = 1,
    this.estimated = false,
  });
  final DateTime day;
  final double value;
  final DateTime recordedAt;
  final int count;
  final bool estimated;

  Map<String, dynamic> toJson() => {
    'day': healthDayKey(day),
    'value': value,
    'recordedAt': recordedAt.toIso8601String(),
    'count': count,
    'estimated': estimated,
  };
  factory HealthDayValue.fromJson(Map data) => HealthDayValue(
    day: DateTime.parse(data['day'] as String),
    value: (data['value'] as num).toDouble(),
    recordedAt: DateTime.parse(data['recordedAt'] as String),
    count: (data['count'] as num?)?.toInt() ?? 1,
    estimated: data['estimated'] == true,
  );
}

class HealthSeries {
  const HealthSeries({
    required this.sourceId,
    required this.source,
    required this.days,
    this.method = '',
  });
  final String sourceId;
  final String source;
  final String method;
  final List<HealthDayValue> days;
  HealthDayValue? on(DateTime day) {
    for (final item in days) {
      if (healthDayKey(item.day) == healthDayKey(day)) return item;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'source': source,
    'method': method,
    'days': days.map((d) => d.toJson()).toList(),
  };
  factory HealthSeries.fromJson(Map data) => HealthSeries(
    sourceId: data['sourceId'] as String,
    source: data['source'] as String,
    method: data['method'] as String? ?? '',
    days: (data['days'] as List)
        .whereType<Map>()
        .map(HealthDayValue.fromJson)
        .toList(),
  );
}

class HealthMetricData {
  const HealthMetricData({
    required this.state,
    this.series = const [],
    this.checkedAt,
  });
  final HealthReadState state;
  final List<HealthSeries> series;
  final DateTime? checkedAt;
  Map<String, dynamic> toJson() => {
    'state': state.name,
    'series': series.map((s) => s.toJson()).toList(),
    'checkedAt': checkedAt?.toIso8601String(),
  };
  factory HealthMetricData.fromJson(Map data) => HealthMetricData(
    state: HealthReadState.values.byName(data['state'] as String),
    series: (data['series'] as List)
        .whereType<Map>()
        .map(HealthSeries.fromJson)
        .toList(),
    checkedAt: DateTime.tryParse(data['checkedAt']?.toString() ?? ''),
  );
}

class HealthDashboardSnapshot {
  const HealthDashboardSnapshot({
    this.metrics = const {},
    this.syncedAt,
    this.platform = '',
  });
  final Map<HealthMetric, HealthMetricData> metrics;
  final DateTime? syncedAt;
  final String platform;
  HealthMetricData data(HealthMetric metric) =>
      metrics[metric] ?? const HealthMetricData(state: HealthReadState.empty);
  bool get hasData =>
      metrics.values.any((m) => m.series.any((s) => s.days.isNotEmpty));
  Map<String, dynamic> toJson() => {
    'platform': platform,
    'syncedAt': syncedAt?.toIso8601String(),
    'metrics': metrics.map((key, value) => MapEntry(key.name, value.toJson())),
  };
  factory HealthDashboardSnapshot.fromJson(Map data) {
    try {
      final raw = data['metrics'] as Map? ?? {};
      return HealthDashboardSnapshot(
        platform: data['platform'] as String? ?? '',
        syncedAt: DateTime.tryParse(data['syncedAt']?.toString() ?? ''),
        metrics: {
          for (final metric in HealthMetric.values)
            if (raw[metric.name] is Map)
              metric: HealthMetricData.fromJson(raw[metric.name] as Map),
        },
      );
    } catch (_) {
      return const HealthDashboardSnapshot();
    }
  }
}

/// Minimal normalized record; no raw HealthKit metadata or routes are persisted.
class HealthImportRecord {
  const HealthImportRecord({
    required this.id,
    required this.sourceId,
    required this.source,
    required this.start,
    required this.end,
    required this.value,
    this.kind = '',
    this.method = '',
  });
  final String id, sourceId, source, kind, method;
  final DateTime start, end;
  final double value;
}

/// Reduces a single provider's records. Never sums different providers together.
List<HealthSeries> aggregateHealthRecords(
  HealthMetric metric,
  List<HealthImportRecord> records,
  DateTime startDay,
  DateTime now,
) {
  final groups = <String, List<HealthImportRecord>>{};
  final seen = <String>{};
  for (final r in records) {
    if (!r.value.isFinite ||
        r.value < 0 ||
        r.end.isBefore(r.start) ||
        r.start.isAfter(now)) {
      continue;
    }
    if (metric == HealthMetric.workouts && r.end.isAfter(now)) continue;
    if ((metric == HealthMetric.weight ||
            metric == HealthMetric.hrv ||
            metric == HealthMetric.restingHeartRate) &&
        r.value <= 0) {
      continue;
    }
    // Health Connect uses the session UUID for every sleep stage, so timestamps
    // must participate in identity even when a UUID is present.
    final unique =
        '${r.sourceId}|${r.kind}|${r.id}|${r.start}|${r.end}|${r.value}';
    if (!seen.add(unique)) continue;
    groups.putIfAbsent('${r.sourceId}|${r.method}', () => []).add(r);
  }
  final result = <HealthSeries>[];
  for (final group in groups.entries) {
    final points = group.value..sort((a, b) => a.start.compareTo(b.start));
    final days = <HealthDayValue>[];
    if (metric == HealthMetric.sleep) {
      // Group overnight stages into an episode; attribute it to the wake-up day.
      // Session-only providers are explicitly labelled as a sleep window.
      final episodes = <List<HealthImportRecord>>[];
      DateTime? latestEnd;
      for (final p in points) {
        if (latestEnd == null ||
            p.start.difference(latestEnd) > const Duration(hours: 3)) {
          episodes.add([]);
        }
        episodes.last.add(p);
        if (latestEnd == null || p.end.isAfter(latestEnd)) latestEnd = p.end;
      }
      final byDay = <DateTime, List<HealthDayValue>>{};
      for (final episode in episodes) {
        final end = episode
            .map((p) => p.end)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        if (end.isAfter(now)) continue;
        final day = healthDay(end);
        if (day.isBefore(startDay)) continue;
        final asleep = episode.where((p) => p.kind == 'asleep').toList();
        final intervals = asleep.isNotEmpty
            ? asleep
            : episode.where((p) => p.kind == 'session').toList();
        if (intervals.isEmpty) continue;
        final minutes = _sleepMinutes(
          intervals,
          episode.where((p) => p.kind == 'awake').toList(),
        );
        if (minutes <= 0) continue;
        byDay
            .putIfAbsent(day, () => [])
            .add(
              HealthDayValue(
                day: day,
                value: minutes,
                recordedAt: end,
                estimated: asleep.isEmpty,
              ),
            );
      }
      for (final entry in byDay.entries) {
        days.add(
          HealthDayValue(
            day: entry.key,
            value: entry.value.fold(0, (a, b) => a + b.value),
            recordedAt: entry.value.last.recordedAt,
            count: entry.value.length,
            estimated: entry.value.any((v) => v.estimated),
          ),
        );
      }
    } else {
      for (
        var day = startDay;
        !day.isAfter(healthDay(now));
        day = DateTime(day.year, day.month, day.day + 1)
      ) {
        final next = DateTime(day.year, day.month, day.day + 1);
        final end = next.isAfter(now) ? now : next;
        final onDay = points
            .where(
              (p) => metric == HealthMetric.activeEnergy
                  ? p.start.isBefore(end) && p.end.isAfter(day)
                  : !p.start.isBefore(day) && p.start.isBefore(end),
            )
            .toList();
        if (onDay.isEmpty) continue;
        double value;
        if (metric == HealthMetric.activeEnergy) {
          value = _energyInWindow(onDay, day, end);
        } else if (metric == HealthMetric.workouts) {
          // Ignore duplicate recordings of the same overlapping session.
          value = _unionMinutes(onDay.map((p) => (p.start, p.end)).toList());
        } else if (metric == HealthMetric.weight) {
          value = onDay.last.value;
        } else {
          final sorted = onDay.map((p) => p.value).toList()..sort();
          value = metric == HealthMetric.steps
              ? sorted.fold(0, (a, b) => a + b)
              : sorted.length.isOdd
              ? sorted[sorted.length ~/ 2]
              : (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) /
                    2;
        }
        days.add(
          HealthDayValue(
            day: day,
            value: value,
            recordedAt: onDay.last.end.isAfter(now) ? now : onDay.last.end,
            count: onDay.length,
          ),
        );
      }
    }
    days.sort((a, b) => a.day.compareTo(b.day));
    if (days.isNotEmpty) {
      result.add(
        HealthSeries(
          sourceId: group.key,
          source: points.first.source,
          method: points.first.method,
          days: days,
        ),
      );
    }
  }
  // A stable default: prefer the provider covering the most days, then its ID.
  result.sort((a, b) {
    final order = b.days.length.compareTo(a.days.length);
    return order == 0 ? a.sourceId.compareTo(b.sourceId) : order;
  });
  return result;
}

double _unionMinutes(List<(DateTime, DateTime)> intervals) {
  if (intervals.isEmpty) return 0;
  intervals.sort((a, b) => a.$1.compareTo(b.$1));
  var start = intervals.first.$1, end = intervals.first.$2;
  var total = 0;
  for (final range in intervals.skip(1)) {
    if (!range.$1.isAfter(end)) {
      if (range.$2.isAfter(end)) end = range.$2;
    } else {
      total += end.difference(start).inMilliseconds;
      start = range.$1;
      end = range.$2;
    }
  }
  return (total + end.difference(start).inMilliseconds) / 60000;
}

double _sleepMinutes(
  List<HealthImportRecord> sleep,
  List<HealthImportRecord> awake,
) {
  final edges = {
    ...sleep.expand((p) => [p.start, p.end]),
    ...awake.expand((p) => [p.start, p.end]),
  }.toList()..sort();
  var total = 0.0;
  for (var i = 1; i < edges.length; i++) {
    final from = edges[i - 1], to = edges[i];
    bool covers(HealthImportRecord r) =>
        !r.start.isAfter(from) && !r.end.isBefore(to);
    if (sleep.any(covers) && !awake.any(covers)) {
      total += to.difference(from).inMilliseconds / 60000;
    }
  }
  return total;
}

double _energyInWindow(
  List<HealthImportRecord> records,
  DateTime start,
  DateTime end,
) {
  final edges = {
    start,
    end,
    ...records.expand(
      (p) => [
        p.start.isBefore(start) ? start : p.start,
        p.end.isAfter(end) ? end : p.end,
      ],
    ),
  }.toList()..sort();
  var total = 0.0;
  for (var i = 1; i < edges.length; i++) {
    final a = edges[i - 1], b = edges[i];
    var rate = 0.0;
    for (final r in records) {
      final duration = r.end.difference(r.start).inMilliseconds;
      if (duration > 0 && !r.start.isAfter(a) && !r.end.isBefore(b)) {
        final candidate = r.value / duration;
        if (candidate > rate) rate = candidate;
      }
    }
    total += rate * b.difference(a).inMilliseconds;
  }
  return total;
}
