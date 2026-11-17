enum RouteActivityType {
  jogging,
  walking,
  cycling,
  hiking,
  other;

  static RouteActivityType parse(Object? value) =>
      values.firstWhere((type) => type.name == value, orElse: () => jogging);

  String label(bool german) => switch (this) {
    jogging => german ? 'Joggen' : 'Jogging',
    walking => german ? 'Gehen' : 'Walking',
    cycling => german ? 'Radfahren' : 'Cycling',
    hiking => german ? 'Wandern' : 'Hiking',
    other => german ? 'Sonstiges' : 'Other',
  };
}

/// Measured session data travels alongside a reusable route, never as a workout
/// reward when someone imports a friend's activity.
class RouteActivity {
  const RouteActivity({
    this.type = RouteActivityType.jogging,
    this.durationSeconds = 0,
    this.descentMeters = 0,
    this.maxSpeedKmh = 0,
    this.calories = 0,
    this.elevationRecorded = false,
    this.recordedAt,
  });
  final RouteActivityType type;
  final int durationSeconds, calories;
  final double descentMeters, maxSpeedKmh;
  final bool elevationRecorded;
  final DateTime? recordedAt;

  factory RouteActivity.fromJson(Map data) => RouteActivity(
    type: RouteActivityType.parse(data['type']),
    durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
    descentMeters: (data['descentMeters'] as num?)?.toDouble() ?? 0,
    maxSpeedKmh: (data['maxSpeedKmh'] as num?)?.toDouble() ?? 0,
    calories: (data['calories'] as num?)?.toInt() ?? 0,
    elevationRecorded: data['elevationRecorded'] == true,
    recordedAt: DateTime.tryParse(data['recordedAt']?.toString() ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'durationSeconds': durationSeconds,
    'descentMeters': descentMeters,
    'maxSpeedKmh': maxSpeedKmh,
    'calories': calories,
    'elevationRecorded': elevationRecorded,
    if (recordedAt != null) 'recordedAt': recordedAt!.toIso8601String(),
  };

  double averageSpeed(double meters) =>
      durationSeconds > 0 ? meters / durationSeconds * 3.6 : 0;

  String pace(double meters) {
    if (meters <= 0 || durationSeconds <= 0) return '—';
    final seconds = (durationSeconds / (meters / 1000)).round();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} /km';
  }

  String get duration {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
  }
}

/// Deadband prevents vertical GPS jitter from counting every small fluctuation.
class RunElevationAccumulator {
  double? _anchor;
  bool _hasData = false;
  double ascent = 0, descent = 0;
  bool get hasData => _hasData;

  void resetSegment() => _anchor = null;

  void add(double altitude, double accuracy) {
    if (!altitude.isFinite ||
        !accuracy.isFinite ||
        accuracy <= 0 ||
        accuracy > 20) {
      return;
    }
    _hasData = true;
    final previous = _anchor;
    _anchor ??= altitude;
    if (previous == null) return;
    final delta = altitude - previous;
    if (delta.abs() < 5) return;
    // Reject abrupt vertical jumps, but establish a fresh baseline.
    _anchor = altitude;
    if (delta.abs() > 50) return;
    if (delta > 0) {
      ascent += delta;
    } else {
      descent -= delta;
    }
  }
}
