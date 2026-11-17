// Synthetic visual fixture, isolated from the user's health data and storage.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/health_dashboard.dart';
import 'package:kaizen/screens/profile_screen.dart';
import 'package:kaizen/services/health_dashboard_service.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/theme/app_theme.dart';
import 'package:kaizen/widgets/profile_health_card.dart';
import '../test/health_dashboard_test.dart' show FakeHealthGateway, record;
import '../test/profile_health_data_test.dart' show seedLocalHealth;

void main() {
  testWidgets('capture profile health with synthetic readings', (tester) async {
    tester.view.physicalSize = const Size(390, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final sdk = Platform.environment['FLUTTER_ROOT']!;
      for (final font in {
        'Roboto': 'roboto-regular.ttf',
        'MaterialIcons': 'MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(font.key)..addFont(
              File(
                '$sdk/bin/cache/artifacts/material_fonts/${font.value}',
              ).readAsBytes().then(ByteData.sublistView),
            ))
            .load();
      }
      final storage = await Directory.systemTemp.createTemp(
        'kaizen_health_preview_',
      );
      await ProgressStore.init(storageRootPath: storage.path);
      await ProgressStore.setUseGerman(true);
      final gateway = FakeHealthGateway();
      final now = DateTime.now();
      for (final metric in HealthMetric.values) {
        gateway.records[metric] = [
          for (var i = 1; i < 28; i++)
            if (i != 3 && i != 9)
              record(
                DateTime(
                  now.year,
                  now.month,
                  now.day - i,
                  metric == HealthMetric.sleep ? 0 : 9,
                ),
                DateTime(
                  now.year,
                  now.month,
                  now.day - i,
                  metric == HealthMetric.sleep ? 7 : 10,
                  i % 4 * 8,
                ),
                switch (metric) {
                  HealthMetric.sleep => 0,
                  HealthMetric.steps => 6000.0 + i % 5 * 840,
                  HealthMetric.activeEnergy => 350.0 + i % 5 * 45,
                  HealthMetric.workouts => 0,
                  HealthMetric.restingHeartRate => 54.0 + i % 4,
                  HealthMetric.hrv => 42.0 + i % 5 * 4,
                  HealthMetric.weight => 76.0 + i * .03,
                },
                kind: metric == HealthMetric.sleep ? 'asleep' : '',
                method: metric == HealthMetric.hrv ? 'SDNN' : '',
                source: 'Apple Watch',
              ),
        ];
      }
      final service = HealthDashboardService(gateway: gateway);
      await service.sync(requestPermission: true, now: now);
      final boundary = GlobalKey();
      Widget host({bool fullProfile = false}) => RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.build(light: ProgressStore.useLightTheme),
          home: Scaffold(
            body: SafeArea(
              child: fullProfile
                  ? const ProfileScreen()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ProfileHealthCard(service: service),
                    ),
            ),
          ),
        ),
      );
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final picture = await render.toImage(pixelRatio: 2);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/health-preview/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(host());
      await capture('sleep-light');
      await tester.tap(find.byKey(const ValueKey('health-metric-hrv')));
      await capture('hrv-light');
      await tester.tap(find.text('28 Tage'));
      await capture('hrv-28days');
      await tester.pumpWidget(const SizedBox.shrink());
      await ProgressStore.setUseLightTheme(false);
      await tester.pumpWidget(host());
      await capture('sleep-dark');
      await tester.pumpWidget(const SizedBox.shrink());
      await service.disconnect();
      await ProgressStore.setUseLightTheme(true);
      await tester.pumpWidget(host());
      await capture('connect');
      await tester.pumpWidget(const SizedBox.shrink());
      gateway.platform = 'Health Connect';
      gateway.records.clear();
      gateway.records[HealthMetric.steps] = [
        for (var i = 0; i < 7; i++)
          record(
            DateTime(now.year, now.month, now.day - i),
            DateTime(now.year, now.month, now.day - i, 10),
            2700.0 + i * 430,
            source: 'Health Connect',
          ),
      ];
      await service.sync(requestPermission: true, now: now);
      await tester.pumpWidget(host());
      await capture('phone-steps');
      await tester.tap(find.byKey(const ValueKey('health-metric-hrv')));
      await capture('phone-missing-hrv');
      await tester.pumpWidget(const SizedBox.shrink());
      await service.disconnect();
      await seedLocalHealth();
      await tester.pumpWidget(host());
      await tester.tap(find.byKey(const ValueKey('health-metric-protein')));
      await capture('local-protein');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(host(fullProfile: true));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('profile-edit')));
      await capture('profile-health-bottom');
      await tester.pumpWidget(const SizedBox.shrink());
      // This Flutter test lives in tool/ so it is run only for visual checks.
      // ignore: invalid_use_of_visible_for_testing_member
      await ProgressStore.closeForTesting();
      await storage.delete(recursive: true);
    });
  });
}
