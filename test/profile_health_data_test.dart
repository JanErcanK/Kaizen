import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/health_dashboard.dart';
import 'package:kaizen/models/profile_health_metric.dart';
import 'package:kaizen/navigation/app_tab_navigation.dart';
import 'package:kaizen/screens/profile_screen.dart';
import 'package:kaizen/services/health_dashboard_service.dart';
import 'package:kaizen/services/profile_health_data.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/theme/app_theme.dart';
import 'package:kaizen/widgets/profile_analytics_chart.dart';
import 'package:kaizen/widgets/profile_health_card.dart';

import 'health_dashboard_test.dart' show FakeHealthGateway, record;

Future<void> seedLocalHealth() async {
  final now = DateTime.now();
  await ProgressStore.setWeightForToday(74.2);
  await ProgressStore.setStepsForDay(now, 2300);
  await ProgressStore.setTodayWaterMl(750);
  await ProgressStore.addFoodIntakeFood(
    name: 'Test meal',
    grams: 100,
    proteinG: 20,
    carbsG: 30,
    fatsG: 10,
  );
  await ProgressStore.addWorkoutEvent(
    type: 'gym',
    recordedAt: now.subtract(const Duration(hours: 1)),
    caloriesBurned: 300,
    durationSeconds: 600,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('kaizen_unified_health_');
    await ProgressStore.init(storageRootPath: storage.path);
    AppTabNavigation.selectedTab.value = AppTabNavigation.home;
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });

  test(
    'all former local categories retain values and missing days stay absent',
    () async {
      await seedLocalHealth();
      final expected = {
        ProfileHealthMetric.steps: 2300.0,
        ProfileHealthMetric.weight: 74.2,
        ProfileHealthMetric.water: 750.0,
        ProfileHealthMetric.workouts: 1.0,
        ProfileHealthMetric.calorieIntake: 290.0,
        ProfileHealthMetric.protein: 20.0,
        ProfileHealthMetric.fat: 10.0,
        ProfileHealthMetric.carbs: 30.0,
      };
      for (final item in expected.entries) {
        final series = profileHealthData(item.key).series.single;
        expect(series.sourceId, kaizenHealthSourceId);
        expect(series.days.single.value, item.value);
        expect(
          series.on(DateTime.now().subtract(const Duration(days: 2))),
          isNull,
        );
      }
      expect(
        profileHealthData(
          ProfileHealthMetric.calorieBurn,
        ).series.single.days.single.value,
        greaterThan(300),
      );
      expect(
        profileHealthData(
          ProfileHealthMetric.afterburn,
        ).series.single.days.single.value,
        greaterThan(0),
      );
      final earlier = DateTime.now().subtract(const Duration(days: 12));
      await ProgressStore.addFoodIntakeFood(
        name: 'Earlier meal',
        grams: 100,
        proteinG: 0,
        carbsG: 15,
        fatsG: 0,
        at: earlier,
      );
      expect(
        profileHealthData(
          ProfileHealthMetric.protein,
        ).series.single.on(earlier)!.value,
        0,
        reason: 'A recorded zero macro is a value, not a missing day',
      );
    },
  );

  test(
    'imports and Kaizen stay separate; counts are not treated as minutes',
    () async {
      await seedLocalHealth();
      final now = DateTime.now();
      final gateway = FakeHealthGateway()
        ..records[HealthMetric.steps] = [
          record(now.subtract(const Duration(hours: 1)), now, 9000),
        ]
        ..records[HealthMetric.weight] = [
          record(now.subtract(const Duration(minutes: 1)), now, 73.5),
        ]
        ..records[HealthMetric.workouts] = [
          record(now.subtract(const Duration(minutes: 30)), now, 0),
        ];
      final service = HealthDashboardService(gateway: gateway);
      await service.sync(requestPermission: true, now: now);
      expect(gateway.reads.toSet(), HealthMetric.values.toSet());
      final steps = profileHealthData(ProfileHealthMetric.steps).series;
      expect(steps.map((s) => s.days.single.value), [9000, 2300]);
      final weight = profileHealthData(ProfileHealthMetric.weight).series;
      expect(weight.map((s) => s.days.single.value), [74.2, 73.5]);
      final workouts = profileHealthData(ProfileHealthMetric.workouts).series;
      expect(workouts.first.method, 'workoutCount');
      expect(workouts.map((s) => s.days.single.value), [1, 30]);
      await service.disconnect();
      expect(
        profileHealthData(
          ProfileHealthMetric.weight,
        ).series.single.days.single.value,
        74.2,
      );
      expect(
        profileHealthData(
          ProfileHealthMetric.steps,
        ).series.single.days.single.value,
        2300,
      );
    },
  );

  Widget host(Widget child, {bool german = false, double scale = 1}) =>
      MaterialApp(
        locale: Locale(german ? 'de' : 'en'),
        theme: AppTheme.build(light: ProgressStore.useLightTheme),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: child),
      );

  testWidgets(
    'all categories work offline in one card, including narrow large-text layouts',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(seedLocalHealth);
      final gateway = FakeHealthGateway()..supported = false;
      for (final light in [true, false]) {
        await tester.runAsync(() => ProgressStore.setUseLightTheme(light));
        await tester.pumpWidget(
          host(
            SingleChildScrollView(
              child: ProfileHealthCard(
                service: HealthDashboardService(gateway: gateway),
              ),
            ),
            german: !light,
            scale: 1.5,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ChoiceChip), findsNWidgets(14));
        for (final metric in ProfileHealthMetric.values.where(
          (m) => m.importedMetric == null,
        )) {
          final chip = find.byKey(ValueKey('health-metric-${metric.name}'));
          await tester.ensureVisible(chip);
          await tester.tap(chip);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('health-trend-chart')),
            findsOneWidget,
          );
          expect(
            find.textContaining(light ? 'Source: Kaizen' : 'Quelle: Kaizen'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
      }
      expect(gateway.reads, isEmpty);
      expect(gateway.authorizations, 0);
    },
  );

  testWidgets(
    'Profile ends with health, add weight and edit; a saved weight reaches the same chart',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await tester.pumpWidget(host(const ProfileScreen()));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileAnalyticsChartCard), findsNothing);
        expect(find.text('Your Kaizen tracking'), findsNothing);
        expect(find.byType(ProfileHealthCard), findsOneWidget);
        final add = find.byKey(const ValueKey('profile-add-weight'));
        final edit = find.byKey(const ValueKey('profile-edit'));
        await tester.ensureVisible(edit);
        await tester.pumpAndSettle();
        expect(
          tester.getBottomLeft(find.byType(ProfileHealthCard)).dy,
          lessThan(tester.getTopLeft(add).dy),
        );
        expect(
          tester.getBottomLeft(add).dy,
          lessThan(tester.getTopLeft(edit).dy),
        );
        expect(
          tester.getTopLeft(edit).dy - tester.getBottomLeft(add).dy,
          lessThan(40),
        );
        await tester.tap(add);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '75.6');
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(ProgressStore.currentWeightKg, 75.6);
        final chip = find.byKey(const ValueKey('health-metric-weight'));
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('health-trend-chart')),
          findsOneWidget,
        );
        expect(
          profileHealthData(
            ProfileHealthMetric.weight,
          ).series.single.days.single.value,
          75.6,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await ProgressStore.closeForTesting();
      });
    },
  );
}
