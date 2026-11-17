import 'dart:io';

import 'package:health/health.dart';

import 'progress_store.dart';

enum HealthStepsStatus {
  success,
  unsupported,
  permissionDenied,
  unavailable,
  error,
}

class HealthStepsSyncResult {
  const HealthStepsSyncResult({required this.status, this.steps, this.message});

  final HealthStepsStatus status;
  final int? steps;
  final String? message;

  bool get isSuccess => status == HealthStepsStatus.success;
}

class HealthStepsService {
  HealthStepsService._();

  static final Health _health = Health();
  static bool _configured = false;

  static const _types = [HealthDataType.STEPS];
  static const _permissions = [HealthDataAccess.READ];

  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  static String _localized({required String en, required String de}) =>
      ProgressStore.useGerman ? de : en;

  static Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static Future<HealthStepsSyncResult> refreshTodaySteps({
    bool requestPermissionIfNeeded = true,
  }) async {
    if (!isSupported) {
      return HealthStepsSyncResult(
        status: HealthStepsStatus.unsupported,
        message: _localized(
          en: 'Steps are only available on iPhone and Android.',
          de: 'Schritte sind nur auf iPhone und Android verfügbar.',
        ),
      );
    }

    try {
      await _ensureConfigured();

      final hasPermissions = await _health.hasPermissions(
        _types,
        permissions: _permissions,
      );

      if (hasPermissions != true) {
        // HealthKit deliberately hides read grants (null). A silent refresh
        // must still attempt the read, including steps recorded by the iPhone.
        if (!requestPermissionIfNeeded && !Platform.isIOS) {
          return HealthStepsSyncResult(
            status: HealthStepsStatus.permissionDenied,
            message: _localized(
              en: 'Connect Apple Health or Health Connect to load steps.',
              de: 'Verbinde Apple Health oder Health Connect, um Schritte zu laden.',
            ),
          );
        }

        final granted =
            !requestPermissionIfNeeded ||
            await _health.requestAuthorization(
              _types,
              permissions: _permissions,
            );
        if (!granted) {
          return HealthStepsSyncResult(
            status: HealthStepsStatus.permissionDenied,
            message: _localized(
              en: 'Permission denied. You can re-enable Apple Health or Health Connect in system settings.',
              de:
                  'Berechtigung abgelehnt. In den System-Einstellungen kannst du '
                  'Apple Health bzw. Health Connect erneut freigeben.',
            ),
          );
        }
      }

      final now = DateTime.now();
      final start = _startOfDay(now);
      final steps = await _health.getTotalStepsInInterval(start, now);
      if (steps == null || steps <= 0) return _noSteps();
      await ProgressStore.setTodaySteps(steps, syncedAt: now);

      return HealthStepsSyncResult(
        status: HealthStepsStatus.success,
        steps: steps,
      );
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('health connect') ||
          message.contains('not installed') ||
          message.contains('unavailable')) {
        return HealthStepsSyncResult(
          status: HealthStepsStatus.unavailable,
          message: _localized(
            en: 'Set up or update Health Connect on your phone. If your phone does not record steps there itself, enable sharing in a compatible step-counting app. A watch is optional.',
            de: 'Richte Health Connect auf deinem Handy ein oder aktualisiere es. Falls dein Handy dort nicht selbst Schritte erfasst, aktiviere die Weitergabe in einer kompatiblen Schrittzähler-App. Eine Uhr ist optional.',
          ),
        );
      }
      return HealthStepsSyncResult(
        status: HealthStepsStatus.error,
        message: _localized(
          en: 'Could not load steps.',
          de: 'Schritte konnten nicht geladen werden.',
        ),
      );
    }
  }

  static Future<HealthStepsSyncResult> fetchAndCacheStepsForDay(
    DateTime day,
  ) async {
    if (!isSupported) {
      return const HealthStepsSyncResult(status: HealthStepsStatus.unsupported);
    }
    try {
      await _ensureConfigured();
      const types = [HealthDataType.STEPS];
      const permissions = [HealthDataAccess.READ];
      final hasPermissions = await _health.hasPermissions(
        types,
        permissions: permissions,
      );
      if (hasPermissions != true && !Platform.isIOS) {
        return const HealthStepsSyncResult(
          status: HealthStepsStatus.permissionDenied,
        );
      }
      final start = DateTime(day.year, day.month, day.day);
      final next = DateTime(day.year, day.month, day.day + 1);
      final now = DateTime.now();
      final end = next.isAfter(now) ? now : next;
      if (!start.isBefore(end)) return _noSteps();
      final steps = await _health.getTotalStepsInInterval(start, end);
      if (steps == null || steps <= 0) return _noSteps();
      final today = DateTime.now();
      if (_dateKey(day) == _dateKey(today)) {
        await ProgressStore.setTodaySteps(steps, syncedAt: DateTime.now());
      } else {
        await ProgressStore.setStepsForDay(day, steps);
      }
      return HealthStepsSyncResult(
        status: HealthStepsStatus.success,
        steps: steps,
      );
    } catch (_) {
      return HealthStepsSyncResult(
        status: HealthStepsStatus.error,
        message: _localized(
          en: 'Could not load steps.',
          de: 'Schritte konnten nicht geladen werden.',
        ),
      );
    }
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static HealthStepsSyncResult _noSteps() => HealthStepsSyncResult(
    status: HealthStepsStatus.unavailable,
    message: _localized(
      en: 'No steps received for this day yet. Check step recording and read access in Apple Health or Health Connect. A watch is not required.',
      de: 'Für diesen Tag wurden noch keine Schritte übermittelt. Prüfe die Schritterfassung und Lesefreigabe in Apple Health oder Health Connect. Eine Uhr ist nicht erforderlich.',
    ),
  );

  static Future<HealthStepsSyncResult> refreshTodayStepsIfStale({
    Duration maxAge = const Duration(minutes: 3),
  }) async {
    final cached = ProgressStore.todaySteps;
    final syncedAt = ProgressStore.todayStepsSyncedAt;
    if (cached != null &&
        syncedAt != null &&
        DateTime.now().difference(syncedAt) < maxAge) {
      return HealthStepsSyncResult(
        status: HealthStepsStatus.success,
        steps: cached,
      );
    }
    return refreshTodaySteps(requestPermissionIfNeeded: false);
  }
}
