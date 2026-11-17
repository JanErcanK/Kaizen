import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import '../models/training_schedule.dart';
import 'progress_store.dart';

class TrainingNotificationService {
  TrainingNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static var _initialized = false;

  static FlutterLocalNotificationsPlugin get pluginForFasting => _plugin;

  static bool get _supported => Platform.isAndroid || Platform.isIOS;

  static Future<void> init() async {
    if (_initialized) return;
    if (!_supported) {
      _initialized = true;
      return;
    }

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.local);
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    if (!_supported) return false;
    if (!_initialized) await init();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  static Future<void> syncFromStore({AppLocalizations? l10n}) async {
    if (!_supported) return;
    if (!_initialized) await init();
    await _cancelAllTraining();
    if (!ProgressStore.trainingNotificationsEnabled) return;

    final schedule = ProgressStore.weeklyTrainingSchedule;
    for (final slot in schedule.enabledSlots()) {
      if (!slot.hasTime) continue;
      await _scheduleSlot(slot, l10n: l10n);
    }
  }

  static Future<void> _cancelAllTraining() async {
    final schedule = ProgressStore.weeklyTrainingSchedule;
    for (final slot in schedule.slots) {
      await _plugin.cancel(_notificationId(slot));
    }
  }

  static Future<void> _scheduleSlot(
    TrainingScheduleSlot slot, {
    AppLocalizations? l10n,
  }) async {
    final hour = slot.hour!;
    final minute = slot.minute!;
    final notifyMinute = minute - 15;
    var notifyHour = hour;
    var notifyMin = notifyMinute;
    if (notifyMin < 0) {
      notifyMin += 60;
      notifyHour -= 1;
    }
    if (notifyHour < 0) notifyHour = 23;

    final title = l10n?.notification_trainingReminderTitle ??
        'Training in 15 minutes';
    final body = _bodyFor(slot, l10n);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      notifyHour,
      notifyMin,
    );

    while (scheduled.weekday != slot.weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final id = _notificationId(slot);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'training_reminders',
          l10n?.notification_trainingChannelName ?? 'Training reminders',
          channelDescription:
              l10n?.notification_trainingChannelDesc ??
                  'Reminders before scheduled workouts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static int _notificationId(TrainingScheduleSlot slot) {
    return Object.hash(slot.activity.storageKey, slot.weekday);
  }

  static String _bodyFor(TrainingScheduleSlot slot, AppLocalizations? l10n) {
    if (l10n == null) {
      return '${slot.activity.storageKey} · ${_formatTime(slot)}';
    }
    final label = switch (slot.activity) {
      TrainingActivity.gym => l10n.schedule_activityGym,
      TrainingActivity.calisthenics => l10n.schedule_activityCalisthenics,
      TrainingActivity.nineMin => l10n.schedule_activityNineMin,
      TrainingActivity.morning => l10n.schedule_activityMorning,
      TrainingActivity.running => l10n.schedule_activityRunning,
      TrainingActivity.stretch => l10n.schedule_activityStretch,
    };
    return l10n.notification_trainingReminderBody(label, _formatTime(slot));
  }

  static String _formatTime(TrainingScheduleSlot slot) {
    final h = slot.hour!.toString().padLeft(2, '0');
    final m = slot.minute!.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
