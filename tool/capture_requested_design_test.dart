// Synthetic UI previews with isolated storage. Map tiles are not fetched.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/screens/category_detail_screen.dart';
import 'package:kaizen/screens/wakeup_workout_detail_screen.dart';
import 'package:kaizen/screens/morning_workout_detail_screen.dart';
import 'package:kaizen/widgets/preset_strength_workout_detail.dart';
import 'package:kaizen/data/strength_preset_workouts.dart';
import 'package:kaizen/screens/running_screen.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/theme/app_theme.dart';

void main() {
  testWidgets('capture requested running and workout layouts', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late Directory storage;
    await tester.runAsync(() async {
      final sdk = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter';
      for (final font in {
        'Roboto': 'roboto-regular.ttf',
        'Ahem': 'roboto-regular.ttf',
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
      'nine-minutes': const CategoryDetailScreen(
        title: '9 min',
        categoryId: '9min',
      ),
      'wakeup': const WakeupWorkoutDetailScreen(),
      'morning': const MorningWorkoutDetailScreen(),
      'push': PresetStrengthWorkoutDetailScreen(
        name: 'Push',
        presetId: 'gym_push',
        workoutType: 'gym',
        initialExercises: resolvePresetWorkoutExercises(
          gymPresetWorkouts.first,
        ),
      ),
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
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/running_welcome.png'),
          tester.element(find.byType(Scaffold).first),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/requested-design-preview/${entry.key}.png');
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
