import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;

import '../l10n/app_localizations.dart';
import 'achievements_catalog.dart';
import 'launcher_level_badge.dart';
import 'progress_store.dart';

/// Keeps the Android launcher icon aligned with the user's Kaizen progress.
class LauncherIconService {
  LauncherIconService._();

  static const MethodChannel _channel = MethodChannel(
    'de.jankilic.kaizen/launcher_icon',
  );

  static AppLifecycleListener? _lifecycle;
  static bool _syncing = false;
  static bool _syncAgain = false;
  static String? _lastSyncedAlias;
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static void start() {
    if (_lifecycle != null || !_isAndroid) return;
    _lifecycle = AppLifecycleListener(onResume: _onProgressChanged);
    ProgressStore.listenable().addListener(_onProgressChanged);
    unawaited(sync());
  }

  static void _onProgressChanged() {
    unawaited(sync());
  }

  /// Historical component names are kept so Android can upgrade existing installs.
  static String launcherAlias(int level, AppLocalizations l10n) {
    final milestone = AchievementsCatalog.previousLevelMilestone(level);
    final component = switch (milestone) {
      0 => 1,
      20 => 30,
      _ => milestone,
    };
    final englishArt =
        l10n.localeName == 'en' &&
        const {300, 500, 1000, 10000}.contains(milestone);
    return 'LauncherLevel$component${englishArt ? 'En' : ''}';
  }

  static Future<Map<String, Object>> _badgeArguments(
    String alias,
    String rank,
  ) async {
    return {
      'alias': alias,
      'rank': rank,
      'badge': await renderLauncherRankBadge(rank, adaptive: false),
    };
  }

  static Future<void> sync() async {
    if (!_isAndroid) return;
    if (_syncing) {
      _syncAgain = true;
      return;
    }

    final level = ProgressStore.userLevel;
    final l10n = lookupAppLocalizations(Locale(ProgressStore.appLocaleCode));
    final alias = launcherAlias(level, l10n);
    if (_lastSyncedAlias == alias) return;

    _syncing = true;
    try {
      final arguments = await _badgeArguments(
        alias,
        AchievementsCatalog.rankTitleForLevel(level, l10n),
      );
      await _channel.invokeMethod<void>('setIcon', arguments);
      _lastSyncedAlias = alias;
    } on PlatformException catch (error) {
      debugPrint('Could not update launcher icon: ${error.message}');
    } finally {
      _syncing = false;
      if (_syncAgain) {
        _syncAgain = false;
        unawaited(sync());
      }
    }
  }

  static Future<bool> pinLevelIcon() async {
    try {
      // Supply the current artwork for the launcher's pin preview as well.
      final level = ProgressStore.userLevel;
      final l10n = lookupAppLocalizations(Locale(ProgressStore.appLocaleCode));
      final arguments = await _badgeArguments(
        launcherAlias(level, l10n),
        AchievementsCatalog.rankTitleForLevel(level, l10n),
      );
      return await _channel.invokeMethod<bool>('pinLevelIcon', arguments) ??
          false;
    } on PlatformException catch (error) {
      debugPrint('Could not pin level icon: ${error.message}');
      return false;
    }
  }
}
