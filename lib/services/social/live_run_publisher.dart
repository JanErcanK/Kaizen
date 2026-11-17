import 'dart:async';

class LiveRunUpdate {
  const LiveRunUpdate({
    required this.routeId,
    required this.routeName,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.startedAt,
    required this.positionUpdatedAt,
    required this.paused,
    required this.recordedPoints,
    required this.plannedPoints,
    this.recordedPointTimestamps = const [],
    this.currentPaceSecPerKm,
    this.avgPaceSecPerKm,
  });
  final String routeId, routeName;
  final double latitude, longitude, distanceMeters;
  final double? currentPaceSecPerKm, avgPaceSecPerKm;
  final DateTime startedAt, positionUpdatedAt;
  final bool paused;
  final List<List<double>> recordedPoints, plannedPoints;
  final List<int> recordedPointTimestamps;
}

List<int> boundedRunPointIndices(List<List<double>> points, int limit) {
  final validIndices = <int>[];
  for (var index = 0; index < points.length; index++) {
    final point = points[index];
    if (point.length == 2 &&
        point[0].isFinite &&
        point[1].isFinite &&
        point[0].abs() <= 90 &&
        point[1].abs() <= 180) {
      validIndices.add(index);
    }
  }
  if (validIndices.length <= limit) return validIndices;
  if (limit <= 1) return [validIndices.last];
  return List.generate(
    limit,
    (i) => validIndices[(i * (validIndices.length - 1) / (limit - 1)).round()],
  );
}

List<List<double>> boundedRunPoints(List<List<double>> points, int limit) {
  return boundedRunPointIndices(
    points,
    limit,
  ).map((index) => points[index]).toList(growable: false);
}

/// One in-flight write and one newest pending snapshot. Stopping discards queued
/// positions and deletes only after the in-flight write, so it cannot resurrect
/// a stopped run. Callbacks report actual transport completion, not enqueueing.
class LiveRunPublisher<T> {
  LiveRunPublisher({required this.send, required this.clear, this.onResult});
  final Future<void> Function(T) send;
  final Future<void> Function() clear;
  final void Function(bool success)? onResult;
  T? _pending;
  bool _active = false;
  Future<void>? _draining;
  Future<void>? _stopping;

  void start() {
    if (_stopping != null) throw StateError('Previous run is still stopping');
    _active = true;
  }

  void update(T snapshot) {
    if (!_active) return;
    _pending = snapshot;
    _draining ??= _drain();
  }

  Future<void> _drain() async {
    try {
      while (_active && _pending != null) {
        final snapshot = _pending as T;
        _pending = null;
        try {
          await send(snapshot);
          onResult?.call(true);
        } catch (_) {
          onResult?.call(false);
        }
      }
    } finally {
      _draining = null;
    }
  }

  Future<void> stop() {
    if (_stopping != null) return _stopping!;
    if (!_active) return Future.value();
    _active = false;
    _pending = null;
    return _stopping = _stop().whenComplete(() => _stopping = null);
  }

  Future<void> _stop() async {
    await _draining;
    try {
      await clear();
      onResult?.call(true);
    } catch (_) {
      onResult?.call(false);
      rethrow;
    }
  }
}
