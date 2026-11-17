import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/health_dashboard.dart';
import 'package:kaizen/navigation/app_tab_navigation.dart';
import 'package:kaizen/services/health_dashboard_service.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/theme/app_theme.dart';
import 'package:kaizen/widgets/profile_health_card.dart';

class FakeHealthGateway implements HealthDashboardGateway {
  @override
  bool supported = true;
  @override
  String platform = 'Apple Health';
  HealthConnectionStatus status = HealthConnectionStatus.ready;
  final permissions = <HealthMetric, bool?>{};
  final records = <HealthMetric, List<HealthImportRecord>>{};
  final failures = <HealthMetric>{};
  final reads = <HealthMetric>[];
  int authorizations = 0;
  Completer<void>? waitForRead;
  @override
  Future<HealthConnectionStatus> prepare() async => status;
  @override
  Future<void> authorize() async {
    authorizations++;
  }

  @override
  Future<bool?> permission(HealthMetric metric) async => permissions[metric];
  @override
  Future<void> install() async {}
  @override
  Future<List<HealthImportRecord>> read(
    HealthMetric metric,
    DateTime start,
    DateTime end,
  ) async {
    reads.add(metric);
    await waitForRead?.future;
    if (failures.contains(metric)) throw StateError('read failed');
    return records[metric] ?? [];
  }
}

HealthImportRecord record(
  DateTime start,
  DateTime end,
  double value, {
  String id = '',
  String source = 'Watch',
  String kind = '',
  String method = '',
}) => HealthImportRecord(
  id: id,
  sourceId: source,
  source: source,
  start: start,
  end: end,
  value: value,
  kind: kind,
  method: method,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 24, 20);
  final start = DateTime(2026, 9, 27);
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('kaizen_health_test_');
    await ProgressStore.init(storageRootPath: storage.path);
    AppTabNavigation.selectedTab.value = AppTabNavigation.home;
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });

  test('native steps include phone aggregates without raw samples', () async {
    const channel = MethodChannel('flutter_health');
    final calls = <MethodCall>[];
    final totals = <int, int?>{20: null, 21: 0, 22: 1420, 23: 4210};
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      // Raw reads must not gate the result: newer Health Connect phone steps
      // can be available only through its unfiltered aggregate.
      expect(call.method, 'getTotalStepsInInterval');
      final args = call.arguments as Map;
      expect(args['recordingMethodsToFilter'], isEmpty);
      final day = DateTime.fromMillisecondsSinceEpoch(args['startTime'] as int);
      final end = DateTime.fromMillisecondsSinceEpoch(args['endTime'] as int);
      expect(end, DateTime(day.year, day.month, day.day + 1));
      return totals[day.day];
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final gateway = NativeHealthDashboardGateway();
    final records = await gateway.read(
      HealthMetric.steps,
      DateTime(2026, 10, 20),
      DateTime(2026, 10, 24),
    );
    expect(calls, hasLength(4)); // No empty range at midnight.
    expect(records.map((r) => r.value), [1420, 4210]);
    expect(records.map((r) => r.sourceId).toSet(), {'platform-steps'});
    final series = aggregateHealthRecords(
      HealthMetric.steps,
      records,
      start,
      now,
    );
    expect(series, hasLength(1));
    expect(series.single.on(DateTime(2026, 10, 21)), isNull);
    // The platform's combined phone/watch total is kept once, not added to raw
    // phone, watch or Kaizen step counts.
    expect(series.single.on(DateTime(2026, 10, 23))!.value, 4210);
  });

  test(
    'overnight stages sharing UUID keep all stages, exclude awake and duplicates',
    () {
      final samples = [
        record(
          DateTime(2026, 10, 23, 22),
          DateTime(2026, 10, 24, 7),
          0,
          kind: 'session',
          id: 'night',
        ),
        record(
          DateTime(2026, 10, 23, 22),
          DateTime(2026, 10, 24, 2),
          0,
          kind: 'asleep',
          id: 'night',
        ),
        record(
          DateTime(2026, 10, 24, 2),
          DateTime(2026, 10, 24, 7),
          0,
          kind: 'asleep',
          id: 'night',
        ),
        record(
          DateTime(2026, 10, 24, 3),
          DateTime(2026, 10, 24, 4),
          0,
          kind: 'awake',
          id: 'night',
        ),
      ];
      final result = aggregateHealthRecords(
        HealthMetric.sleep,
        [...samples, ...samples],
        start,
        now,
      );
      expect(result.single.days.single.day, DateTime(2026, 10, 24));
      expect(result.single.days.single.value, 480);
      expect(result.single.days.single.estimated, isFalse);
      expect(result.single.on(DateTime(2026, 10, 23)), isNull);
    },
  );
  test(
    'session-only sleep is marked as a window, not measured sleep stages',
    () {
      final result = aggregateHealthRecords(
        HealthMetric.sleep,
        [
          record(
            DateTime(2026, 10, 23, 23),
            DateTime(2026, 10, 24, 7),
            0,
            kind: 'session',
          ),
        ],
        start,
        now,
      );
      expect(result.single.days.single.estimated, isTrue);
    },
  );
  test(
    'energy splits at midnight, deduplicates overlaps and keeps providers apart',
    () {
      final samples = [
        record(
          DateTime(2026, 10, 23, 23),
          DateTime(2026, 10, 24, 1),
          200,
          id: 'one',
        ),
        record(
          DateTime(2026, 10, 23, 23),
          DateTime(2026, 10, 24, 1),
          200,
          id: 'copy',
        ),
        record(
          DateTime(2026, 10, 23, 23),
          DateTime(2026, 10, 24, 1),
          300,
          source: 'Other',
        ),
      ];
      final result = aggregateHealthRecords(
        HealthMetric.activeEnergy,
        samples,
        start,
        now,
      );
      expect(result.length, 2);
      final watch = result.firstWhere((s) => s.source == 'Watch');
      expect(watch.days.map((d) => d.value), [100, 100]);
    },
  );
  test('latest daily weight, median vitals and separate HRV methods', () {
    final records = [
      for (var i = 0; i < 3; i++)
        record(
          DateTime(2026, 10, 24, 8 + i),
          DateTime(2026, 10, 24, 8 + i),
          [60.0, 200.0, 70.0][i],
        ),
    ];
    expect(
      aggregateHealthRecords(
        HealthMetric.weight,
        records,
        start,
        now,
      ).single.days.single.value,
      70,
    );
    expect(
      aggregateHealthRecords(
        HealthMetric.restingHeartRate,
        records,
        start,
        now,
      ).single.days.single.value,
      70,
    );
    final hrv = aggregateHealthRecords(
      HealthMetric.hrv,
      [
        record(now.subtract(const Duration(hours: 1)), now, 40, method: 'SDNN'),
        record(
          now.subtract(const Duration(hours: 1)),
          now,
          70,
          method: 'RMSSD',
        ),
      ],
      start,
      now,
    );
    expect(hrv.length, 2);
    expect(hrv.map((s) => s.method).toSet(), {'SDNN', 'RMSSD'});
  });
  test(
    'overlapping workouts count minutes once; missing days remain absent',
    () {
      final values = aggregateHealthRecords(
        HealthMetric.workouts,
        [
          record(DateTime(2026, 10, 24, 9), DateTime(2026, 10, 24, 10), 0),
          record(
            DateTime(2026, 10, 24, 9, 30),
            DateTime(2026, 10, 24, 10, 30),
            0,
          ),
        ],
        start,
        now,
      );
      expect(values.single.days.single.value, 90);
      expect(values.single.on(DateTime(2026, 10, 23)), isNull);
    },
  );
  test(
    'partial grants and iOS unknown permissions do not block other data',
    () async {
      final gateway = FakeHealthGateway()
        ..permissions[HealthMetric.hrv] = false;
      gateway.records[HealthMetric.weight] = [
        record(now.subtract(const Duration(hours: 1)), now, 72),
      ];
      final service = HealthDashboardService(gateway: gateway);
      await service.sync(requestPermission: true, now: now);
      expect(gateway.authorizations, 1);
      expect(gateway.reads, isNot(contains(HealthMetric.hrv)));
      expect(
        ProgressStore.healthDashboard.data(HealthMetric.hrv).state,
        HealthReadState.denied,
      );
      expect(
        ProgressStore.healthDashboard.data(HealthMetric.sleep).state,
        HealthReadState.empty,
      );
      expect(
        ProgressStore.healthDashboard
            .data(HealthMetric.weight)
            .series
            .single
            .days
            .single
            .value,
        72,
      );
      expect(ProgressStore.currentWeightKg, isNull);
      expect(ProgressStore.workoutEvents, isEmpty);
      await service.sync(now: now);
      expect(gateway.authorizations, 1);
      await ProgressStore.closeForTesting();
      await ProgressStore.init(storageRootPath: storage.path);
      expect(
        ProgressStore.healthDashboard
            .data(HealthMetric.weight)
            .series
            .single
            .days
            .single
            .value,
        72,
      );
    },
  );
  test(
    'read failures retain marked old data; deletions/revocation clear it',
    () async {
      final gateway = FakeHealthGateway()
        ..records[HealthMetric.weight] = [
          record(now.subtract(const Duration(hours: 1)), now, 72),
        ];
      final service = HealthDashboardService(gateway: gateway);
      await service.sync(requestPermission: true, now: now);
      gateway.failures.add(HealthMetric.weight);
      await service.sync(now: now.add(const Duration(minutes: 10)));
      expect(
        ProgressStore.healthDashboard.data(HealthMetric.weight).state,
        HealthReadState.failed,
      );
      expect(
        ProgressStore.healthDashboard.data(HealthMetric.weight).checkedAt,
        now,
      );
      gateway.failures.clear();
      gateway.records.clear();
      await service.sync(now: now);
      expect(ProgressStore.healthDashboard.hasData, isFalse);
      gateway.permissions[HealthMetric.weight] = false;
      await service.sync(now: now);
      expect(
        ProgressStore.healthDashboard.data(HealthMetric.weight).state,
        HealthReadState.denied,
      );
    },
  );
  test(
    'no silent connection; unavailable provider and disconnect during sync',
    () async {
      final gateway = FakeHealthGateway();
      final service = HealthDashboardService(gateway: gateway);
      await service.sync(now: now);
      expect(gateway.reads, isEmpty);
      gateway.status = HealthConnectionStatus.updateRequired;
      expect(
        await service.sync(requestPermission: true, now: now),
        HealthConnectionStatus.updateRequired,
      );
      expect(ProgressStore.healthDashboardConnected, isFalse);
      gateway.status = HealthConnectionStatus.ready;
      await ProgressStore.setHealthDashboardConnected(true);
      gateway.waitForRead = Completer<void>();
      final sync = service.sync(now: now);
      while (gateway.reads.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      await service.disconnect();
      gateway.waitForRead!.complete();
      await sync;
      expect(ProgressStore.healthDashboardConnected, isFalse);
      expect(ProgressStore.healthDashboard.hasData, isFalse);
    },
  );

  Future<void> host(
    WidgetTester tester,
    FakeHealthGateway gateway, {
    bool german = true,
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(light: ProgressStore.useLightTheme),
        locale: Locale(german ? 'de' : 'en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileHealthCard(
              service: HealthDashboardService(gateway: gateway),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'connect, select metrics, missing data, permission states and period',
    (tester) async {
      final gateway = FakeHealthGateway()
        ..permissions[HealthMetric.hrv] = false;
      final today = DateTime.now();
      gateway.records[HealthMetric.weight] = [
        record(
          today.subtract(const Duration(minutes: 10)),
          today.subtract(const Duration(minutes: 5)),
          72.3,
        ),
      ];
      await host(tester, gateway);
      expect(find.text('Apple Health verbinden'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('health-connect')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('health-metric-weight')));
      await tester.pumpAndSettle();
      expect(find.text('72,3 kg'), findsOneWidget);
      expect(find.textContaining('Quelle: Watch'), findsOneWidget);
      final chartBottom = tester
          .getBottomLeft(find.byKey(const ValueKey('health-trend-chart')))
          .dy;
      for (final control in [
        find.byKey(const ValueKey('health-connect')),
        find.byType(ChoiceChip).first,
        find.byType(SegmentedButton<int>),
      ]) {
        expect(tester.getTopLeft(control).dy, greaterThan(chartBottom));
      }
      await tester.tap(find.text('28 Tage'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('health-metric-hrv')));
      await tester.pumpAndSettle();
      expect(find.text('Freigabe fehlt'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('health-metric-sleep')));
      await tester.pumpAndSettle();
      expect(find.text('Noch keine Daten für diesen Zeitraum'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'phone-only connection selects steps and explains unavailable sensors',
    (tester) async {
      final gateway = FakeHealthGateway()..platform = 'Health Connect';
      final today = DateTime.now();
      gateway.records[HealthMetric.steps] = [
        record(healthDay(today), today, 2700, source: 'Health Connect'),
      ];
      await host(tester, gateway);
      expect(find.text('Mit Handy und optionaler Uhr'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('health-connect')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('2700'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('health-metric-steps')),
            )
            .selected,
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('health-metric-hrv')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Das Handy allein misst ihn hier nicht.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('health-metric-weight')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Eine Uhr ist nicht nötig.'), findsOneWidget);
      await tester.tap(find.byTooltip('Verbindung & Datenschutz'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Auch ohne Smartwatch:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'small screen, large text, both themes and languages have no overflow',
    (tester) async {
      final gateway = FakeHealthGateway();
      final end = DateTime.now();
      gateway.records[HealthMetric.sleep] = [
        record(
          end.subtract(const Duration(hours: 8)),
          end.subtract(const Duration(minutes: 20)),
          0,
          kind: 'asleep',
        ),
      ];
      await tester.runAsync(
        () => HealthDashboardService(
          gateway: gateway,
        ).sync(requestPermission: true, now: end),
      );
      for (final light in [true, false]) {
        await tester.runAsync(() => ProgressStore.setUseLightTheme(light));
        await host(tester, gateway, german: light, width: 320, scale: 1.5);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
