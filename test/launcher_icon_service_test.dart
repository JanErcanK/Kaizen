import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/services/achievements_catalog.dart';
import 'package:kaizen/services/launcher_icon_service.dart';
import 'package:kaizen/services/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every rank has a packaged launcher alias in both app languages', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    for (final language in ['de', 'en']) {
      final l10n = lookupAppLocalizations(Locale(language));
      for (final level in [
        0,
        1,
        19,
        21,
        49,
        ...AchievementsCatalog.levelMilestones,
      ]) {
        final alias = LauncherIconService.launcherAlias(level, l10n);
        final block = RegExp(
          '<activity-alias\\s+android:name="\\.$alias"[^>]*>',
        ).firstMatch(manifest)!.group(0)!;
        final milestone = AchievementsCatalog.previousLevelMilestone(level);
        final resource =
            '@mipmap/kaizen_level_$milestone${alias.endsWith('En') ? '_en' : ''}';
        expect(block, contains('android:icon="$resource"'));
        expect(block, contains('android:roundIcon="$resource"'));
      }
    }
  });

  test(
    'restores Student, updates at rank boundaries and localizes higher ranks',
    () async {
      final storage = await Directory.systemTemp.createTemp(
        'kaizen_level_icon_',
      );
      await ProgressStore.init(storageRootPath: storage.path);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const channel = MethodChannel('de.jankilic.kaizen/launcher_icon');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });
      addTearDown(() async {
        messenger.setMockMethodCallHandler(channel, null);
        debugDefaultTargetPlatformOverride = null;
        await ProgressStore.closeForTesting();
        await storage.delete(recursive: true);
      });
      await ProgressStore.setAppLocaleCode('de');
      for (final level in [27, 19, 20, 49, 50, 100, 101, 1000]) {
        await ProgressStore.setUserLevel(level);
        await LauncherIconService.sync();
      }
      expect(calls.map((c) => c.arguments['rank']), [
        'Student',
        'Rookie',
        'Student',
        'Trainee',
        'Performer',
        'Krieger',
      ]);
      expect(calls.first.arguments['alias'], 'LauncherLevel30');
      // flutter_test defaults to Ahem; different characters can share glyphs.
      expect(calls.last.arguments['badge'], isA<Uint8List>());
      await LauncherIconService.sync();
      expect(calls, hasLength(6));
      await ProgressStore.setAppLocaleCode('en');
      await LauncherIconService.sync();
      expect(calls.last.arguments['rank'], 'Warrior');
      expect(await LauncherIconService.pinLevelIcon(), isTrue);
      expect(calls.last.method, 'pinLevelIcon');
      expect(calls.last.arguments['rank'], 'Warrior');
    },
  );
}
