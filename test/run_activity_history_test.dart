import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/route_activity.dart';
import 'package:kaizen/models/shared_content.dart';
import 'package:kaizen/models/social_models.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/services/run_snapshot_service.dart';
import 'package:kaizen/widgets/run_share_sheet.dart';

Map<String, dynamic> route() => {
  'name': 'Runde am See',
  'distanceMeters': 5430.0,
  'ascentMeters': 123.0,
  'descentMeters': 118.0,
  'points': <List<double>>[
    [52.50, 13.40],
    [52.51, 13.39],
    [52.52, 13.405],
    [52.512, 13.42],
    [52.50, 13.40],
  ],
  'activity': RouteActivity(
    durationSeconds: 1800,
    descentMeters: 118,
    maxSpeedKmh: 16.2,
    calories: 354,
    elevationRecorded: true,
    recordedAt: DateTime(2026, 11, 10, 16, 30),
  ).toJson(),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Roboto');
    for (final weight in ['regular', 'bold']) {
      font.addFont(
        File(
          'C:/src/flutter/bin/cache/artifacts/material_fonts/roboto-$weight.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    }
    await font.load();
  });
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('run_history_');
    await ProgressStore.init(storageRootPath: temp.path);
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await temp.delete(recursive: true);
  });

  test('pace, speed and elevation distinguish missing fixes and GPS noise', () {
    const activity = RouteActivity(durationSeconds: 1800);
    expect(activity.pace(5000), '6:00 /km');
    expect(activity.averageSpeed(5000), 10);
    expect(activity.pace(0), '—');
    final elevation = RunElevationAccumulator();
    elevation.add(100, 50);
    elevation.add(double.nan, 5);
    expect(elevation.hasData, false);
    for (final altitude in <double>[100, 102, 101, 106, 104, 99]) {
      elevation.add(altitude, 5);
    }
    expect(elevation.ascent, 6);
    expect(elevation.descent, 7);
    elevation.resetSegment();
    elevation.add(200, 5);
    expect(elevation.ascent, 6);
  });

  test(
    'recorded route persists with event and survives deleting planned route',
    () async {
      final data = route();
      final plannedId = await ProgressStore.saveRunningRoute(
        name: 'Planned',
        distanceMeters: 9000,
        ascentMeters: 0,
        descentMeters: 0,
        points: [
          [0, 0],
          [1, 1],
        ],
        waypoints: [],
      );
      await ProgressStore.addWorkoutEvent(
        type: 'run',
        recordedAt: DateTime.now(),
        runMeters: 5430,
        durationSeconds: 1800,
        workoutId: plannedId,
        runRecord: data,
      );
      await ProgressStore.deleteRunningRoute(plannedId);
      await ProgressStore.closeForTesting();
      await ProgressStore.init(storageRootPath: temp.path);
      expect(ProgressStore.runEvents.single['runRecord'], data);
    },
  );

  test(
    'friend import retains activity metrics without recording own workout',
    () async {
      final payload = normalizeSharedContent(
        ShareContentType.runningRoute,
        route(),
      );
      final id = await ProgressStore.importSharedRunningRoute(payload);
      expect(
        ProgressStore.runningRouteById(id)!['activity'],
        route()['activity'],
      );
      expect(ProgressStore.runEvents, isEmpty);
      for (final invalid in [
        {'type': 'spaceship'},
        {'durationSeconds': -1},
        {'maxSpeedKmh': 501},
        {'elevationRecorded': 'yes'},
      ]) {
        expect(
          () => normalizeSharedContent(ShareContentType.runningRoute, {
            ...route(),
            'activity': {...route()['activity'], ...invalid},
          }),
          throwsA(isA<FormatException>()),
        );
      }
    },
  );

  test(
    'offline PNG saves complete wide, tall and date-line routes without clipping',
    () async {
      for (final points in [
        route()['points'],
        [
          [0.0, -10.0],
          [0.0, 10.0],
        ],
        [
          [-10.0, 0.0],
          [10.0, 0.0],
        ],
        [
          [50.0, 179.99],
          [50.01, -179.99],
        ],
      ]) {
        final file = await RunSnapshotService.save(
          {...route(), 'points': points},
          id: 'test',
          german: true,
          mapTiles: false,
        );
        final codec = await ui.instantiateImageCodec(await file.readAsBytes());
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 900);
        expect(frame.image.height, 1040);
        final pixels = (await frame.image.toByteData())!.buffer.asUint8List();
        var routePixels = 0;
        for (var y = 160; y < 638; y++) {
          for (var x = 0; x < 900; x++) {
            final i = (y * 900 + x) * 4;
            if (pixels[i] == 111 &&
                pixels[i + 1] == 174 &&
                pixels[i + 2] == 0) {
              routePixels++;
              expect(x, inInclusiveRange(55, 845));
              expect(y, inInclusiveRange(187, 610));
            }
          }
        }
        expect(routePixels, greaterThan(10));
        frame.image.dispose();
        codec.dispose();
      }
      final image = await RunSnapshotService.render(
        route(),
        german: true,
        mapTiles: false,
      );
      final preview = File('build/green-screen-preview/run-history-card.png');
      await preview.parent.create(recursive: true);
      await preview.writeAsBytes(image);
    },
  );

  testWidgets(
    'sharing offers activity choices before sending on narrow display',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showRunShareSheet(context: context, route: route()),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byType(DropdownButtonFormField<RouteActivityType>));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Radfahren'), findsOneWidget);
      expect(find.text('Wandern'), findsOneWidget);
      await tester.tap(find.text('Radfahren'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Radfahren'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
