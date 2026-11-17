import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/screens/running_screen.dart';
import 'package:kaizen/screens/run_tracking_screen.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/widgets/running_welcome.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('running_welcome_');
    await ProgressStore.init(storageRootPath: storage.path);
    await ProgressStore.setUseGerman(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (_) async => 1,
        );
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });
  Widget host({double scale = 1}) => MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: const RunningScreen(),
  );

  for (final width in [320.0, 390.0]) {
    testWidgets(
      'welcome fits at $width and only user map movement dismisses it',
      (tester) async {
        tester.view.physicalSize = Size(width, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(host(scale: 1.3));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.widget<RunningWelcome>(find.byType(RunningWelcome)).visible,
          isTrue,
        );
        final map = tester.widget<FlutterMap>(find.byType(FlutterMap).first);
        map.options.onPositionChanged!(map.mapController!.camera, false);
        await tester.pumpAndSettle();
        expect(
          tester.widget<RunningWelcome>(find.byType(RunningWelcome)).visible,
          isTrue,
        );
        map.options.onPositionChanged!(map.mapController!.camera, true);
        await tester.pumpAndSettle();
        expect(
          tester.widget<RunningWelcome>(find.byType(RunningWelcome)).visible,
          isFalse,
        );
        expect(
          find.byKey(const Key('running-start')).hitTestable(),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'map buttons dismiss the welcome and start opens active tracking',
    (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kartenebenen'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<RunningWelcome>(find.byType(RunningWelcome)).visible,
        isFalse,
      );
      Navigator.of(tester.element(find.byType(RunningScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('running-start')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RunTrackingScreen>(find.byType(RunTrackingScreen))
            .startImmediately,
        isTrue,
      );
      expect(find.byIcon(Icons.pause_rounded), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
