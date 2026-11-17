// Regenerate the packaged Android rank badges with the same painter as the
// live widget: flutter test tool/generate_launcher_badges_test.dart
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/services/achievements_catalog.dart';
import 'package:kaizen/services/launcher_icon_service.dart';
import 'package:kaizen/services/launcher_level_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('generate Android rank badges', () async {
    // flutter_tester lives under the SDK cache alongside material_fonts.
    var dir = File(Platform.resolvedExecutable).parent;
    while (!Directory('${dir.path}/material_fonts').existsSync()) {
      if (dir.parent.path == dir.path) {
        throw StateError('Flutter material_fonts not found');
      }
      dir = dir.parent;
    }
    final loader = FontLoader('Roboto');
    for (final weight in ['bold', 'black']) {
      final bytes = File(
        '${dir.path}/material_fonts/roboto-$weight.ttf',
      ).readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
    await (FontLoader('KaizenJapanese')
          ..addFont(rootBundle.load('assets/fonts/KaizenJapanese-Medium.ttf')))
        .load();
    const main = 'android/app/src/main';
    final german = lookupAppLocalizations(const Locale('de'));
    await File('assets/app_icon.png').writeAsBytes(
      await renderLauncherRankBadge(
        AchievementsCatalog.rankTitleForLevel(0, german),
        adaptive: false,
        pixelSize: 1024,
      ),
    );
    for (final (file, level) in [('zero', 0), ('preview', 100)]) {
      final rank = AchievementsCatalog.rankTitleForLevel(level, german);
      final bitmap = await renderLauncherRankBadge(rank, adaptive: false);
      await File(
        '$main/res/drawable-nodpi/kaizen_widget_$file.png',
      ).writeAsBytes(bitmap);
    }
    final aliases = <String, String>{};
    for (final level in AchievementsCatalog.levelMilestones) {
      for (final language in ['de', 'en']) {
        final l10n = lookupAppLocalizations(Locale(language));
        final alias = LauncherIconService.launcherAlias(level, l10n);
        if (aliases.containsKey(alias)) continue;
        final resource =
            'kaizen_level_$level${alias.endsWith('En') ? '_en' : ''}';
        aliases[alias] = resource;
        final rank = AchievementsCatalog.rankTitleForLevel(level, l10n);
        final png = await renderLauncherRankBadge(rank);
        await File('$main/res/drawable-nodpi/$resource.png').writeAsBytes(png);
        await File('$main/res/mipmap-anydpi-v26/$resource.xml').writeAsString(
          '''
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/level_icon_green" />
    <foreground android:drawable="@drawable/$resource" />
</adaptive-icon>
''',
        );
      }
    }
    // Older installations can still have one of these aliases enabled.
    aliases['LauncherLevel5'] = aliases['LauncherLevel1']!;
    aliases['LauncherLevel200'] = aliases['LauncherLevel100']!;
    final blocks = aliases.entries.map(
      (entry) =>
          '''
        <activity-alias
            android:name=".${entry.key}"
            android:enabled="${entry.key == 'LauncherLevel1'}"
            android:exported="true"
            android:icon="@mipmap/${entry.value}"
            android:roundIcon="@mipmap/${entry.value}"
            android:label="Kaizen"
            android:targetActivity=".LauncherActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity-alias>''',
    );
    final manifest = File('$main/AndroidManifest.xml');
    final xml = await manifest.readAsString();
    final marker = xml.indexOf('<!-- Launcher badges:');
    final end = xml.indexOf('        <!-- End launcher badges.');
    if (marker < 0 || end < marker) {
      throw StateError('Missing launcher section in manifest');
    }
    final start = xml.indexOf('-->', marker) + 3;
    await manifest.writeAsString(
      xml.replaceRange(start, end, '\n${blocks.join('\n')}\n'),
    );
  });
}
