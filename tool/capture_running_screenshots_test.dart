// Synthetic route preview; no provider key, GPS data or production storage.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/screens/running_screen.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/services/routing_service.dart';
import 'package:kaizen/theme/app_theme.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets('capture calculated running route in both themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late Directory storage;
    await tester.runAsync(() async {
      final sdk = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter';
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
      storage = await Directory.systemTemp.createTemp('running_preview_');
      await ProgressStore.init(storageRootPath: storage.path);
      await ProgressStore.setUseGerman(true);
    });
    final boundary = GlobalKey();
    const points = [
      LatLng(48.135, 11.570),
      LatLng(48.139, 11.572),
      LatLng(48.141, 11.580),
      LatLng(48.145, 11.581),
      LatLng(48.148, 11.589),
      LatLng(48.144, 11.593),
    ];
    for (final light in [true, false]) {
      await tester.runAsync(() => ProgressStore.setUseLightTheme(light));
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.build(light: light),
            home: RunningScreen(
              routeCalculator: (_) async => RouteResult(
                points: points,
                elevations: const [],
                distanceMeters: 8430,
                ascentMeters: 128,
                descentMeters: 96,
                steps: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (light) {
        final map = tester.widget<FlutterMap>(find.byType(FlutterMap).first);
        for (final point in [points.first, points[2], points.last]) {
          map.options.onTap!(
            const TapPosition(Offset.zero, Offset.zero),
            point,
          );
        }
        await tester.pumpAndSettle();
        await tester.tap(find.text('Route berechnen'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          'build/running-preview/${light ? 'light' : 'dark'}.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      // This capture runs under flutter_test with an isolated temporary store.
      // ignore: invalid_use_of_visible_for_testing_member
      await ProgressStore.closeForTesting();
      await storage.delete(recursive: true);
    });
  });
}
