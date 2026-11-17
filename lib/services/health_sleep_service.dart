import 'dart:io';

import 'package:health/health.dart';

import 'progress_store.dart';

enum HealthSleepStatus {
  success,
  unsupported,
  permissionDenied,
  unavailable,
  error,
}

class HealthSleepSyncResult {
  const HealthSleepSyncResult({
    required this.status,
    this.minutes,
    this.message,
  });

  final HealthSleepStatus status;
  final int? minutes;
  final String? message;

  bool get isSuccess => status == HealthSleepStatus.success;
}

class HealthSleepService {
  HealthSleepService._();

  static final Health _health = Health();
  static bool _configured = false;

  static const _types = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_SESSION,
  ];
  static const _permissions = [HealthDataAccess.READ];

  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  static String _localized({required String en, required String de}) =>
      ProgressStore.useGerman ? de : en;

  static Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Sleep attributed to the calendar day you wake up on.
  static (DateTime start, DateTime end) sleepWindowForWakeDay(DateTime wakeDay) {
    final day = DateTime(wakeDay.year, wakeDay.month, wakeDay.day);
    final start = day.subtract(const Duration(hours: 12));
    final end = day.add(const Duration(hours: 16));
    return (start, end);
  }

  static int _mergedIntervalMinutes(List<(DateTime, DateTime)> intervals) {
    if (intervals.isEmpty) return 0;
    final sorted = List<(DateTime, DateTime)>.from(intervals)
      ..sort((a, b) => a.$1.compareTo(b.$1));
    var mergedStart = sorted.first.$1;
    var mergedEnd = sorted.first.$2;
    var total = 0;
    for (var i = 1; i < sorted.length; i++) {
      final (start, end) = sorted[i];
      if (start.isBefore(mergedEnd) || start.isAtSameMomentAs(mergedEnd)) {
        if (end.isAfter(mergedEnd)) mergedEnd = end;
      } else {
        total += mergedEnd.difference(mergedStart).inMinutes;
        mergedStart = start;
        mergedEnd = end;
      }
    }
    total += mergedEnd.difference(mergedStart).inMinutes;
    return total.clamp(0, 24 * 60);
  }

  static int _sleepMinutesFromPoints(List<HealthDataPoint> points) {
    if (points.isEmpty) return 0;

    final sessions = points
        .where((p) => p.type == HealthDataType.SLEEP_SESSION)
        .map((p) => (p.dateFrom, p.dateTo))
        .toList();
    if (sessions.isNotEmpty) {
      return _mergedIntervalMinutes(sessions);
    }

    final asleep = points
        .where((p) => p.type == HealthDataType.SLEEP_ASLEEP)
        .map((p) => (p.dateFrom, p.dateTo))
        .toList();
    if (asleep.isNotEmpty) {
      return _mergedIntervalMinutes(asleep);
    }

    final inBed = points
        .where((p) => p.type == HealthDataType.SLEEP_IN_BED)
        .map((p) => (p.dateFrom, p.dateTo))
        .toList();
    return _mergedIntervalMinutes(inBed);
  }

  static Future<int?> _fetchSleepMinutesForWakeDay(DateTime wakeDay) async {
    final (start, end) = sleepWindowForWakeDay(wakeDay);
    final now = DateTime.now();
    final queryEnd = end.isAfter(now) ? now : end;
    if (!queryEnd.isAfter(start)) return 0;

    final points = await _health.getHealthDataFromTypes(
      types: _types,
      startTime: start,
      endTime: queryEnd,
    );
    return _sleepMinutesFromPoints(points);
  }

  static Future<HealthSleepSyncResult> _ensurePermissions({
    required bool requestPermissionIfNeeded,
  }) async {
    final hasPermissions = await _health.hasPermissions(
      _types,
      permissions: _permissions,
    );
    if (hasPermissions == true) {
      return const HealthSleepSyncResult(status: HealthSleepStatus.success);
    }
    if (!requestPermissionIfNeeded) {
      return HealthSleepSyncResult(
        status: HealthSleepStatus.permissionDenied,
        message: _localized(
          en: 'Connect Apple Health or Health Connect to load sleep.',
          de:
              'Verbinde Apple Health oder Health Connect, um Schlafdaten zu laden.',
        ),
      );
    }
    final granted = await _health.requestAuthorization(
      _types,
      permissions: _permissions,
    );
    if (!granted) {
      return HealthSleepSyncResult(
        status: HealthSleepStatus.permissionDenied,
        message: _localized(
          en:
              'Permission denied. You can re-enable Apple Health or Health Connect in system settings.',
          de:
              'Berechtigung abgelehnt. In den System-Einstellungen kannst du '
              'Apple Health bzw. Health Connect erneut freigeben.',
        ),
      );
    }
    return const HealthSleepSyncResult(status: HealthSleepStatus.success);
  }

  static Future<HealthSleepSyncResult> syncRecentSleep({
    int days = 7,
    bool requestPermissionIfNeeded = true,
  }) async {
    if (!isSupported) {
      return HealthSleepSyncResult(
        status: HealthSleepStatus.unsupported,
        message: _localized(
          en: 'Sleep tracking is only available on iPhone and Android.',
          de: 'Schlaftracking ist nur auf iPhone und Android verfügbar.',
        ),
      );
    }

    try {
      await _ensureConfigured();
      final permission = await _ensurePermissions(
        requestPermissionIfNeeded: requestPermissionIfNeeded,
      );
      if (!permission.isSuccess) return permission;

      final now = DateTime.now();
      int? lastNightMinutes;
      for (var i = 0; i < days; i++) {
        final day = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        final minutes = await _fetchSleepMinutesForWakeDay(day) ?? 0;
        if (i == 0) {
          lastNightMinutes = minutes;
          await ProgressStore.setLastNightSleep(minutes, syncedAt: now);
        } else {
          await ProgressStore.setSleepForWakeDay(day, minutes);
        }
      }

      return HealthSleepSyncResult(
        status: HealthSleepStatus.success,
        minutes: lastNightMinutes,
      );
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('health connect') ||
          message.contains('not installed') ||
          message.contains('unavailable')) {
        return HealthSleepSyncResult(
          status: HealthSleepStatus.unavailable,
          message: _localized(
            en:
                'Health Connect is not installed. Install it from the Play Store and connect your sleep tracker there.',
            de:
                'Health Connect ist nicht installiert. Bitte aus dem Play Store '
                'installieren und deinen Schlaf-Tracker dort verbinden.',
          ),
        );
      }
      return HealthSleepSyncResult(
        status: HealthSleepStatus.error,
        message: _localized(
          en: 'Could not load sleep data.',
          de: 'Schlafdaten konnten nicht geladen werden.',
        ),
      );
    }
  }

  static Future<HealthSleepSyncResult> refreshLastNightSleep({
    bool requestPermissionIfNeeded = true,
  }) {
    return syncRecentSleep(
      days: 7,
      requestPermissionIfNeeded: requestPermissionIfNeeded,
    );
  }

  static Future<HealthSleepSyncResult> refreshLastNightSleepIfStale({
    Duration maxAge = const Duration(hours: 3),
  }) async {
    final cached = ProgressStore.lastNightSleepMinutes;
    final syncedAt = ProgressStore.lastNightSleepSyncedAt;
    if (cached != null &&
        syncedAt != null &&
        DateTime.now().difference(syncedAt) < maxAge) {
      return HealthSleepSyncResult(
        status: HealthSleepStatus.success,
        minutes: cached,
      );
    }
    return refreshLastNightSleep(requestPermissionIfNeeded: false);
  }
}
