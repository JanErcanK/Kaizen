import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/screens/running_screen.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/services/routing_service.dart';
import 'package:kaizen/theme/app_theme.dart';
import 'package:kaizen/widgets/run_route_visuals.dart';
import 'package:latlong2/latlong.dart';

RouteResult route(List<LatLng> points) => RouteResult(
  points: points,
  elevations: const [500, 628],
  distanceMeters: 8430,
  ascentMeters: 128,
  descentMeters: 96,
  steps: const [],
);

Widget host(
  Widget child, {
  bool dark = false,
  String language = 'de',
  double scale = 1,
}) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.build(light: !dark),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(body: child),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('running_design_');
    await ProgressStore.init(storageRootPath: temp.path);
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await temp.delete(recursive: true);
  });

  for (final dark in [false, true]) {
    testWidgets('route metrics and markers fit a narrow screen, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          Center(
            child: SizedBox(
              width: 222,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RunRouteSummary(route: route(const [])),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final kind in RunWaypointKind.values)
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: RunWaypointMarker(kind: kind, label: '2'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          dark: dark,
          scale: 1.4,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aufstieg'), findsOneWidget);
      expect(find.textContaining('Abstieg'), findsOneWidget);
      final text = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((w) => w.text.toPlainText())
          .join(' ');
      expect(text, contains('8,43 km'));
      expect(text, contains('128 hm'));
    });
  }

  testWidgets(
    'calculated metrics appear and are cleared when waypoints change',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(RunningScreen(routeCalculator: (points) async => route(points))),
      );
      await tester.pumpAndSettle();
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap).first);
      map.options.onTap!(
        const TapPosition(Offset.zero, Offset.zero),
        const LatLng(48.13, 11.57),
      );
      map.options.onTap!(
        const TapPosition(Offset.zero, Offset.zero),
        const LatLng(48.15, 11.59),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Route berechnen'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('run-route-summary')), findsOneWidget);
      expect(find.text('Aufstieg'), findsOneWidget);
      map.options.onTap!(
        const TapPosition(Offset.zero, Offset.zero),
        const LatLng(48.16, 11.60),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('run-route-summary')), findsNothing);

      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'a late route response cannot restore metrics for changed waypoints',
    (tester) async {
      final response = Completer<RouteResult>();
      await tester.pumpWidget(
        host(RunningScreen(routeCalculator: (_) => response.future)),
      );
      await tester.pumpAndSettle();
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap).first);
      const points = [LatLng(48.13, 11.57), LatLng(48.15, 11.59)];
      for (final point in points) {
        map.options.onTap!(const TapPosition(Offset.zero, Offset.zero), point);
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Route berechnen'));
      await tester.pump();
      map.options.onTap!(
        const TapPosition(Offset.zero, Offset.zero),
        const LatLng(48.16, 11.60),
      );
      response.complete(route(points));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('run-route-summary')), findsNothing);

      await tester.pumpWidget(const SizedBox());
    },
  );
}
