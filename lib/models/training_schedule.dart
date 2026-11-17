enum TrainingActivity {
  gym,
  calisthenics,
  nineMin,
  morning,
  running,
  stretch,
}

const kTrainingScheduleActivities = [
  TrainingActivity.gym,
  TrainingActivity.calisthenics,
  TrainingActivity.running,
  TrainingActivity.stretch,
];

/// Kept for reading legacy stored slots; not shown in the schedule editor.
const kLegacyTrainingScheduleActivities = [
  TrainingActivity.nineMin,
  TrainingActivity.morning,
];

extension TrainingActivityX on TrainingActivity {
  String get storageKey => switch (this) {
        TrainingActivity.gym => 'gym',
        TrainingActivity.calisthenics => 'calisthenics',
        TrainingActivity.nineMin => 'nine_min',
        TrainingActivity.morning => 'morning',
        TrainingActivity.running => 'running',
        TrainingActivity.stretch => 'stretch',
      };

  static TrainingActivity? fromStorageKey(String raw) {
    return switch (raw) {
      'gym' => TrainingActivity.gym,
      'calisthenics' => TrainingActivity.calisthenics,
      'nine_min' => TrainingActivity.nineMin,
      'morning' => TrainingActivity.morning,
      'running' => TrainingActivity.running,
      'stretch' => TrainingActivity.stretch,
      _ => null,
    };
  }
}

class TrainingScheduleSlot {
  const TrainingScheduleSlot({
    required this.activity,
    required this.weekday,
    this.enabled = false,
    this.hour,
    this.minute,
  });

  final TrainingActivity activity;
  /// [DateTime.weekday]: Mon=1 … Sun=7
  final int weekday;
  final bool enabled;
  final int? hour;
  final int? minute;

  bool get hasTime => hour != null && minute != null;

  TrainingScheduleSlot copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    bool clearTime = false,
  }) {
    return TrainingScheduleSlot(
      activity: activity,
      weekday: weekday,
      enabled: enabled ?? this.enabled,
      hour: clearTime ? null : (hour ?? this.hour),
      minute: clearTime ? null : (minute ?? this.minute),
    );
  }

  Map<String, dynamic> toJson() => {
        'activity': activity.storageKey,
        'weekday': weekday,
        'enabled': enabled,
        if (hour != null) 'hour': hour,
        if (minute != null) 'minute': minute,
      };

  factory TrainingScheduleSlot.fromJson(Map<dynamic, dynamic> json) {
    final activity = TrainingActivityX.fromStorageKey(
          json['activity']?.toString() ?? '',
        ) ??
        TrainingActivity.gym;
    return TrainingScheduleSlot(
      activity: activity,
      weekday: (json['weekday'] as num?)?.toInt() ?? 1,
      enabled: json['enabled'] == true ||
          json['enabled'] == 1 ||
          json['enabled']?.toString() == 'true',
      hour: (json['hour'] as num?)?.toInt(),
      minute: (json['minute'] as num?)?.toInt(),
    );
  }

  static String cellKey(TrainingActivity activity, int weekday) =>
      '${activity.storageKey}_$weekday';
}

class WeeklyTrainingSchedule {
  const WeeklyTrainingSchedule(this.slots);

  final List<TrainingScheduleSlot> slots;

  TrainingScheduleSlot slot(TrainingActivity activity, int weekday) {
    return slots.firstWhere(
      (s) => s.activity == activity && s.weekday == weekday,
      orElse: () => TrainingScheduleSlot(
        activity: activity,
        weekday: weekday,
      ),
    );
  }

  WeeklyTrainingSchedule updateSlot(TrainingScheduleSlot updated) {
    final next = slots
        .where(
          (s) =>
              !(s.activity == updated.activity && s.weekday == updated.weekday),
        )
        .toList();
    if (updated.enabled || updated.hasTime) {
      next.add(updated);
    }
    return WeeklyTrainingSchedule(next);
  }

  List<TrainingScheduleSlot> enabledSlots() =>
      slots.where((s) => s.enabled).toList();

  /// Drops 9min / morning slots that are no longer editable.
  WeeklyTrainingSchedule withoutLegacyActivities() {
    return WeeklyTrainingSchedule(
      slots
          .where(
            (s) => !kLegacyTrainingScheduleActivities.contains(s.activity),
          )
          .toList(),
    );
  }

  List<Map<String, dynamic>> toJsonList() =>
      slots.map((s) => s.toJson()).toList();

  factory WeeklyTrainingSchedule.empty() {
    final slots = <TrainingScheduleSlot>[];
    for (final activity in kTrainingScheduleActivities) {
      for (var weekday = 1; weekday <= 7; weekday++) {
        slots.add(TrainingScheduleSlot(activity: activity, weekday: weekday));
      }
    }
    return WeeklyTrainingSchedule(slots);
  }

  factory WeeklyTrainingSchedule.fromStored(List<dynamic>? raw) {
    final base = WeeklyTrainingSchedule.empty();
    if (raw == null || raw.isEmpty) return base;
    var result = base;
    for (final item in raw) {
      if (item is! Map) continue;
      final slot = TrainingScheduleSlot.fromJson(item);
      if (kLegacyTrainingScheduleActivities.contains(slot.activity)) {
        continue;
      }
      result = result.updateSlot(slot.copyWith(enabled: slot.enabled));
    }
    return result;
  }
}
