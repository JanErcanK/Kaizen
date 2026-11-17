import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';

import 'l10n/app_localizations.dart';
import 'screens/app_bootstrap.dart';
import 'services/progress_store.dart';
import 'services/training_notification_service.dart';
import 'services/intermittent_fasting_service.dart';
import 'services/launcher_icon_service.dart';
import 'services/social/social_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _writeErrorLog('FlutterError', details.exceptionAsString(), details.stack);
  };

  // Show the real exception on screen instead of a blank gray box in release
  // builds, so layout/build errors are diagnosable on physical devices.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    _writeErrorLog('ErrorWidget', details.exceptionAsString(), details.stack);
    return Material(
      color: const Color(0xFF1C1C1E),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            details.exceptionAsString(),
            style: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  };

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      if (Platform.isWindows) {
        WidgetsBinding.instance.platformDispatcher.setSemanticsTreeEnabled(
          false,
        );
      }

      try {
        await ProgressStore.init();
      } catch (error, stack) {
        _writeErrorLog('ProgressStore.init', error.toString(), stack);
      }

      try {
        await TrainingNotificationService.init();
      } catch (error, stack) {
        _writeErrorLog(
          'TrainingNotificationService.init',
          error.toString(),
          stack,
        );
      }

      try {
        await SocialService.instance.init();
      } catch (error, stack) {
        _writeErrorLog('SocialService.init', error.toString(), stack);
      }

      runApp(const KaizenApp());
      LauncherIconService.start();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_syncStartupNotifications());
      });
    },
    (error, stack) {
      _writeErrorLog('UncaughtZoneError', error.toString(), stack);
    },
  );
}

Future<void> _syncStartupNotifications() async {
  try {
    await IntermittentFastingService.syncNotifications();
  } catch (error, stack) {
    _writeErrorLog('IntermittentFastingService.sync', error.toString(), stack);
  }
}

Future<void> _writeErrorLog(
  String tag,
  String message,
  StackTrace? stack,
) async {
  try {
    Directory baseDir;
    if (Platform.isWindows) {
      final base =
          Platform.environment['LOCALAPPDATA'] ??
          Platform.environment['APPDATA'] ??
          Directory.current.path;
      baseDir = Directory('$base/Kaizen');
    } else {
      baseDir = await getApplicationSupportDirectory();
    }
    final logsDir = Directory('${baseDir.path}/logs');
    if (!logsDir.existsSync()) {
      logsDir.createSync(recursive: true);
    }
    final file = File('${logsDir.path}/error_log.txt');
    final timestamp = DateTime.now().toIso8601String();
    final entry = '\n[$timestamp][$tag] $message\n${stack ?? ''}\n';
    await file.writeAsString(entry, mode: FileMode.append, flush: true);
  } catch (_) {
    // Logging must never crash the app.
  }
}

class KaizenApp extends StatelessWidget {
  const KaizenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ProgressStore.listenable(),
      builder: (context, _, child) {
        final light = ProgressStore.useLightTheme;
        final locale = Locale(ProgressStore.appLocaleCode);
        return MaterialApp(
          title: 'Kaizen',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.build(light: light),
          home: const AppBootstrap(),
        );
      },
    );
  }
}
