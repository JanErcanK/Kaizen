import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import 'progress_store.dart';
import 'training_notification_service.dart';

enum FastingPhase { fasting, eating }

class FastingStatus {
  const FastingStatus({
    required this.phase,
    required this.remaining,
    required this.startMinutes,
    required this.endMinutes,
  });

  final FastingPhase phase;
  final Duration remaining;
  final int startMinutes;
  final int endMinutes;
}

class IntermittentFastingService {
  IntermittentFastingService._();

  static const int _openReminderId = 910001;
  static const int _closeReminderId = 910002;

  static bool get _supported => Platform.isAndroid || Platform.isIOS;

  static FastingStatus currentStatus({DateTime? now}) {
    final clock = now ?? DateTime.now();
    final minutes = clock.hour * 60 + clock.minute;
    final start = ProgressStore.eatingWindowStartMinutes;
    final end = ProgressStore.eatingWindowEndMinutes;

    if (minutes >= start && minutes < end) {
      final endClock = DateTime(
        clock.year,
        clock.month,
        clock.day,
        end ~/ 60,
        end % 60,
      );
      return FastingStatus(
        phase: FastingPhase.eating,
        remaining: endClock.difference(clock),
        startMinutes: start,
        endMinutes: end,
      );
    }

    DateTime nextStart;
    if (minutes < start) {
      nextStart = DateTime(
        clock.year,
        clock.month,
        clock.day,
        start ~/ 60,
        start % 60,
      );
    } else {
      final tomorrow = clock.add(const Duration(days: 1));
      nextStart = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        start ~/ 60,
        start % 60,
      );
    }

    return FastingStatus(
      phase: FastingPhase.fasting,
      remaining: nextStart.difference(clock),
      startMinutes: start,
      endMinutes: end,
    );
  }

  static String formatDuration(Duration duration, {bool includeSeconds = false}) {
    final totalSeconds = duration.inSeconds.clamp(0, 24 * 3600);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (includeSeconds && hours == 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m';
  }

  /// Length of the eating window in minutes (handles overnight windows).
  static int eatingWindowMinutes(int startMinutes, int endMinutes) {
    if (endMinutes > startMinutes) return endMinutes - startMinutes;
    return (24 * 60 - startMinutes) + endMinutes;
  }

  /// Length of the fasting stretch outside the eating window.
  static int fastingWindowMinutes(int startMinutes, int endMinutes) {
    return (24 * 60) - eatingWindowMinutes(startMinutes, endMinutes);
  }

  /// 1 → just entered phase, 0 → phase ending. Depletes as [remaining] shrinks.
  static double phaseProgress(FastingStatus status) {
    final totalMinutes = status.phase == FastingPhase.eating
        ? eatingWindowMinutes(status.startMinutes, status.endMinutes)
        : fastingWindowMinutes(status.startMinutes, status.endMinutes);
    if (totalMinutes <= 0) return 0;
    return (status.remaining.inSeconds / (totalMinutes * 60))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  /// Red while fasting, orange in the last 30 minutes, green while eating.
  static Color phaseColor(FastingStatus status) {
    if (status.phase == FastingPhase.eating) {
      return const Color(0xFF43B86B);
    }
    if (status.remaining <= const Duration(minutes: 30)) {
      return const Color(0xFFE89A3A);
    }
    return const Color(0xFFE05A5A);
  }

  static String formatMinutesOfDay(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static Future<void> syncNotifications({AppLocalizations? l10n}) async {
    if (!_supported) return;
    try {
      await TrainingNotificationService.init();

      final plugin = _notificationsPlugin;
      await plugin.cancel(_openReminderId);
      await plugin.cancel(_closeReminderId);

      if (!ProgressStore.fastingRemindersEnabled ||
          !ProgressStore.eatingWindowConfigured) {
        return;
      }

      final start = ProgressStore.eatingWindowStartMinutes;
      final end = ProgressStore.eatingWindowEndMinutes;
      await _scheduleDaily(
        id: _openReminderId,
        atMinutes: _wrapMinutes(start - 15),
        title: l10n?.fasting_notificationOpenTitle ?? 'Eating window soon',
        body: l10n?.fasting_notificationOpenBody(
              formatMinutesOfDay(start),
            ) ??
            'You can eat at ${formatMinutesOfDay(start)}',
        channelName:
            l10n?.fasting_notificationChannelName ?? 'Fasting reminders',
        channelDesc: l10n?.fasting_notificationChannelDesc ??
            'Reminders before your eating window opens and closes',
      );
      await _scheduleDaily(
        id: _closeReminderId,
        atMinutes: _wrapMinutes(end - 30),
        title: l10n?.fasting_notificationCloseTitle ?? 'Eating window ending',
        body: l10n?.fasting_notificationCloseBody(
              formatMinutesOfDay(end),
            ) ??
            'Eating window closes at ${formatMinutesOfDay(end)}',
        channelName:
            l10n?.fasting_notificationChannelName ?? 'Fasting reminders',
        channelDesc: l10n?.fasting_notificationChannelDesc ??
            'Reminders before your eating window opens and closes',
      );
    } catch (_) {
      // Notification sync must never block or crash the app.
    }
  }

  static int _wrapMinutes(int value) {
    var v = value % (24 * 60);
    if (v < 0) v += 24 * 60;
    return v;
  }

  static FlutterLocalNotificationsPlugin get _notificationsPlugin {
    // Reuse the same initialized plugin via a thin accessor on training service.
    return TrainingNotificationService.pluginForFasting;
  }

  static Future<void> _scheduleDaily({
    required int id,
    required int atMinutes,
    required String title,
    required String body,
    required String channelName,
    required String channelDesc,
  }) async {
    final hour = atMinutes ~/ 60;
    final minute = atMinutes % 60;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'fasting_reminders',
          channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
