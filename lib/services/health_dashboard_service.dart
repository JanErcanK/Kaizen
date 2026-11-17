import 'dart:io';

import 'package:health/health.dart';
import 'package:flutter/services.dart';

import '../models/health_dashboard.dart';
import 'progress_store.dart';

enum HealthConnectionStatus {
  ready,
  unavailable,
  updateRequired,
  unsupported,
  failed,
}

abstract class HealthDashboardGateway {
  bool get supported;
  String get platform;
  Future<HealthConnectionStatus> prepare();
  Future<void> authorize();
  Future<bool?> permission(HealthMetric metric);
  Future<List<HealthImportRecord>> read(
    HealthMetric metric,
    DateTime start,
    DateTime end,
  );
  Future<void> install();
}

class NativeHealthDashboardGateway implements HealthDashboardGateway {
  final Health health = Health();
  @override
  bool get supported => Platform.isAndroid || Platform.isIOS;
  @override
  String get platform => Platform.isIOS ? 'Apple Health' : 'Health Connect';

  List<HealthDataType> types(HealthMetric metric) => (switch (metric) {
    HealthMetric.sleep => [
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_REM,
      HealthDataType.SLEEP_AWAKE,
      if (Platform.isAndroid) HealthDataType.SLEEP_AWAKE_IN_BED,
      if (Platform.isAndroid) HealthDataType.SLEEP_OUT_OF_BED,
      if (Platform.isAndroid) HealthDataType.SLEEP_SESSION,
    ],
    HealthMetric.steps => [HealthDataType.STEPS],
    HealthMetric.activeEnergy => [HealthDataType.ACTIVE_ENERGY_BURNED],
    HealthMetric.workouts => [HealthDataType.WORKOUT],
    HealthMetric.restingHeartRate => [HealthDataType.RESTING_HEART_RATE],
    HealthMetric.hrv => [
      Platform.isIOS
          ? HealthDataType.HEART_RATE_VARIABILITY_SDNN
          : HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    ],
    HealthMetric.weight => [HealthDataType.WEIGHT],
  }).where(health.isDataTypeAvailable).toList();

  @override
  Future<HealthConnectionStatus> prepare() async {
    if (!supported) return HealthConnectionStatus.unsupported;
    if (Platform.isAndroid) {
      final status = await health.getHealthConnectSdkStatus();
      if (status ==
          HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
        return HealthConnectionStatus.updateRequired;
      }
      if (status != HealthConnectSdkStatus.sdkAvailable) {
        return HealthConnectionStatus.unavailable;
      }
    }
    await health.configure();
    return HealthConnectionStatus.ready;
  }

  @override
  Future<void> authorize() async {
    final requested = HealthMetric.values.expand(types).toSet().toList();
    final permissions = List.filled(requested.length, HealthDataAccess.READ);
    if (await health.hasPermissions(requested, permissions: permissions) !=
        true) {
      // A partial grant must not prevent reading the other categories.
      await health.requestAuthorization(requested, permissions: permissions);
    }
  }

  @override
  Future<bool?> permission(HealthMetric metric) async {
    if (Platform.isIOS) return null; // Apple deliberately hides read grants.
    final requested = types(metric);
    return health.hasPermissions(
      requested,
      permissions: List.filled(requested.length, HealthDataAccess.READ),
    );
  }

  @override
  Future<void> install() => health.installHealthConnect();

  @override
  Future<List<HealthImportRecord>> read(
    HealthMetric metric,
    DateTime start,
    DateTime end,
  ) async {
    if (Platform.isAndroid && metric == HealthMetric.workouts) {
      final records =
          await const MethodChannel(
            'de.jankilic.kaizen/health_dashboard',
          ).invokeListMethod<dynamic>('readWorkouts', {
            'start': start.millisecondsSinceEpoch,
            'end': end.millisecondsSinceEpoch,
          });
      return [
        for (final r in records ?? [])
          if (r is Map)
            HealthImportRecord(
              id: r['id'] as String,
              sourceId: r['sourceId'] as String,
              source: r['source'] as String,
              start: DateTime.fromMillisecondsSinceEpoch(
                (r['start'] as num).toInt(),
              ),
              end: DateTime.fromMillisecondsSinceEpoch(
                (r['end'] as num).toInt(),
              ),
              value: 0,
            ),
      ];
    }
    if (metric == HealthMetric.steps) {
      final result = <HealthImportRecord>[];
      for (
        var day = start;
        day.isBefore(end);
        day = DateTime(day.year, day.month, day.day + 1)
      ) {
        final next = DateTime(day.year, day.month, day.day + 1);
        final until = next.isAfter(end) ? end : next;
        // Read the all-source aggregate directly: Health Connect's built-in
        // phone steps may be present here without visible raw source records.
        // Native priorities handle phone/watch overlap; never add raw totals.
        final total = await health.getTotalStepsInInterval(day, until);
        // The plugin also returns zero for absent data. Without evidence of
        // coverage, do not present that as a measured inactive day.
        if (total == null || total <= 0) continue;
        result.add(
          HealthImportRecord(
            id: healthDayKey(day),
            sourceId: 'platform-steps',
            source: platform,
            start: day,
            end: until,
            value: total.toDouble(),
            method: 'platform',
          ),
        );
      }
      return result;
    }
    final points = await health.getHealthDataFromTypes(
      types: types(metric),
      startTime: metric == HealthMetric.sleep
          ? DateTime(start.year, start.month, start.day - 1)
          : start,
      endTime: end,
    );
    return [
      for (final p in points)
        if (_record(metric, p) case final HealthImportRecord record) record,
    ];
  }

  HealthImportRecord? _record(HealthMetric metric, HealthDataPoint p) {
    final amount = p.value is NumericHealthValue
        ? (p.value as NumericHealthValue).numericValue.toDouble()
        : 0.0;
    final model = p.deviceModel;
    final source = p.sourceName.isEmpty ? platform : p.sourceName;
    return HealthImportRecord(
      id: p.uuid,
      sourceId: '${p.sourceId}|${model ?? ''}',
      source: model == null || model.isEmpty ? source : '$source · $model',
      start: p.dateFrom.toLocal(),
      end: p.dateTo.toLocal(),
      value: amount,
      kind: metric != HealthMetric.sleep
          ? ''
          : p.type == HealthDataType.SLEEP_SESSION
          ? 'session'
          : p.type == HealthDataType.SLEEP_AWAKE ||
                p.type == HealthDataType.SLEEP_AWAKE_IN_BED ||
                p.type == HealthDataType.SLEEP_OUT_OF_BED
          ? 'awake'
          : 'asleep',
      method: metric == HealthMetric.hrv
          ? (Platform.isIOS ? 'SDNN' : 'RMSSD')
          : '',
    );
  }
}

class HealthDashboardService {
  HealthDashboardService({required this.gateway});
  static final instance = HealthDashboardService(
    gateway: NativeHealthDashboardGateway(),
  );
  final HealthDashboardGateway gateway;
  Future<HealthConnectionStatus>? _running;
  int _generation = 0;

  Future<HealthConnectionStatus> sync({
    bool requestPermission = false,
    DateTime? now,
  }) {
    return _running ??= _sync(
      requestPermission,
      now ?? DateTime.now(),
    ).whenComplete(() => _running = null);
  }

  Future<HealthConnectionStatus> _sync(
    bool requestPermission,
    DateTime now,
  ) async {
    final generation = _generation;
    if (!gateway.supported) return HealthConnectionStatus.unsupported;
    if (!requestPermission && !ProgressStore.healthDashboardConnected) {
      return HealthConnectionStatus.ready;
    }
    try {
      final status = await gateway.prepare();
      if (status != HealthConnectionStatus.ready) return status;
      if (requestPermission) {
        await gateway.authorize();
        if (generation != _generation) return HealthConnectionStatus.ready;
        await ProgressStore.setHealthDashboardConnected(true);
      }
      final start = DateTime(now.year, now.month, now.day - 27);
      final values = <HealthMetric, HealthMetricData>{};
      final previous = ProgressStore.healthDashboard;
      for (final metric in HealthMetric.values) {
        if (generation != _generation) return HealthConnectionStatus.ready;
        try {
          if (await gateway.permission(metric) == false) {
            values[metric] = HealthMetricData(
              state: HealthReadState.denied,
              checkedAt: now,
            );
            continue;
          }
          final records = await gateway.read(metric, start, now);
          final series = aggregateHealthRecords(metric, records, start, now);
          values[metric] = HealthMetricData(
            state: series.isEmpty
                ? HealthReadState.empty
                : HealthReadState.available,
            series: series,
            checkedAt: now,
          );
        } catch (_) {
          final old = previous.data(metric);
          // Preserve the last successful snapshot on a read failure, with an
          // explicit stale status. An empty successful read replaces old data.
          values[metric] = HealthMetricData(
            state: HealthReadState.failed,
            series: old.series,
            checkedAt: old.checkedAt,
          );
        }
      }
      if (generation != _generation) return HealthConnectionStatus.ready;
      await ProgressStore.saveHealthDashboard(
        HealthDashboardSnapshot(
          metrics: values,
          syncedAt: now,
          platform: gateway.platform,
        ),
      );
      return values.values.every((v) => v.state == HealthReadState.failed)
          ? HealthConnectionStatus.failed
          : HealthConnectionStatus.ready;
    } catch (_) {
      return HealthConnectionStatus.failed;
    }
  }

  Future<void> disconnect() async {
    _generation++; // A late native response must not resurrect cleared data.
    await ProgressStore.clearHealthDashboard();
  }
}
