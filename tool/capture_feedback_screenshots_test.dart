// Synthetic UI previews with isolated storage. Map tiles are not fetched.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/screens/chat_screen.dart';
import 'package:kaizen/screens/running_screen.dart';
import 'package:kaizen/screens/workout_hub_screen.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/theme/app_theme.dart';

void main() {
  testWidgets('capture screenshot feedback layouts', (tester) async {
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
      storage = await Directory.systemTemp.createTemp('feedback_preview_');
      await ProgressStore.init(storageRootPath: storage.path);
      await ProgressStore.setUseGerman(true);
      await ProgressStore.saveChatSettings({'coachIntroSeen': true});
    });
    for (final entry in <String, Widget>{
      'running': const RunningScreen(),
      'sports': const SportActivityScreen(),
      'workouts': const WorkoutHubScreen(),
      'history': Scaffold(body: ChatScreen(keyReader: (_) async => null)),
    }.entries) {
      final boundary = GlobalKey();
      final theme = AppTheme.build(light: true);
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme.copyWith(
              appBarTheme: theme.appBarTheme.copyWith(
                titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                  fontFamily: 'Roboto',
                ),
              ),
              chipTheme: theme.chipTheme.copyWith(
                labelStyle: (theme.chipTheme.labelStyle ?? const TextStyle())
                    .copyWith(fontFamily: 'Roboto'),
              ),
            ),
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: entry.value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (entry.key == 'workouts') {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
        await tester.pumpAndSettle();
      }
      if (entry.key == 'history') {
        await tester.tap(find.byTooltip('Chatverlauf'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/feedback-preview/${entry.key}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    }
    await tester.runAsync(() async {
      // ignore: invalid_use_of_visible_for_testing_member
      await ProgressStore.closeForTesting();
      await storage.delete(recursive: true);
    });
  });
}
