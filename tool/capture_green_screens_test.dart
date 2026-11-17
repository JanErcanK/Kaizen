// Isolated design previews; run with flutter test tool/capture_green_screens_test.dart.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/screens/food_screen.dart';
import 'package:kaizen/screens/running_screen.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/theme/app_theme.dart';

void main() {
  testWidgets(
    'preview green food, dish and running screens and keyboard layout',
    (tester) async {
      final oldShadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = oldShadows);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.view.resetPadding);
      late Directory storage;
      await tester.runAsync(() async {
        final fontRoot =
            '${Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter'}/bin/cache/artifacts/material_fonts';
        final roboto = FontLoader('Roboto');
        for (final name in ['regular', 'medium', 'bold']) {
          roboto.addFont(
            File(
              '$fontRoot/roboto-$name.ttf',
            ).readAsBytes().then(ByteData.sublistView),
          );
        }
        await roboto.load();
        await (FontLoader('MaterialIcons')..addFont(
              File(
                '$fontRoot/MaterialIcons-Regular.otf',
              ).readAsBytes().then(ByteData.sublistView),
            ))
            .load();
        storage = await Directory.systemTemp.createTemp('green_screens_');
        await ProgressStore.init(storageRootPath: storage.path);
        await ProgressStore.setUseGerman(false);
        await ProgressStore.setUseLightTheme(true);
      });
      final boundary = GlobalKey();
      Future<void> mount(
        Widget home, {
        bool light = true,
        double scale = 1,
      }) async {
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.build(light: light),
              locale: Locale(ProgressStore.appLocaleCode),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: home,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name) async {
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/green-screen-preview/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await mount(const FoodScreen());
      final panel = find.byKey(const Key('food-search-panel'));
      expect(tester.getBottomRight(panel).dy, lessThanOrEqualTo(820));
      await capture('foods');
      tester.view.padding = const FakeViewPadding(bottom: 24);
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(panel).dy, lessThanOrEqualTo(796));
      tester.view.resetPadding();
      await tester.tap(find.text('Dishes'));
      await tester.pumpAndSettle();
      await capture('dishes');
      await tester.tap(find.text('Foods'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.enterText(find.byType(TextField).first, 'chocolate');
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(panel).dy, lessThanOrEqualTo(544));
      expect(find.text('Milk chocolate'), findsOneWidget);
      await capture('food-keyboard');
      tester.view.resetViewInsets();
      await tester.pumpWidget(const SizedBox());
      tester.view.physicalSize = const Size(320, 640);
      await tester.runAsync(() async {
        await ProgressStore.setUseGerman(true);
        await ProgressStore.setUseLightTheme(false);
      });
      await mount(const FoodScreen(), light: false, scale: 1.3);
      await capture('foods-narrow-dark');
      await tester.tap(find.text('Gerichte'));
      await tester.pumpAndSettle();
      await capture('dishes-narrow-dark');
      await tester.pumpWidget(const SizedBox());
      tester.view.physicalSize = const Size(390, 844);
      await tester.runAsync(() => ProgressStore.setUseLightTheme(true));
      await mount(const RunningScreen());
      await capture('running');
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        // ignore: invalid_use_of_visible_for_testing_member
        await ProgressStore.closeForTesting();
        await storage.delete(recursive: true);
      });
      debugDisableShadows = oldShadows;
    },
  );
}
