import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../models/training_schedule.dart';
import '../theme/app_colors.dart';

String trainingActivityLabel(AppLocalizations l10n, TrainingActivity activity) {
  return switch (activity) {
    TrainingActivity.gym => l10n.schedule_activityGym,
    TrainingActivity.calisthenics => l10n.schedule_activityCalisthenics,
    TrainingActivity.nineMin => l10n.schedule_activityNineMin,
    TrainingActivity.morning => l10n.schedule_activityMorning,
    TrainingActivity.running => l10n.schedule_activityRunning,
    TrainingActivity.stretch => l10n.schedule_activityStretch,
  };
}

String trainingActivityShortLabel(
  AppLocalizations l10n,
  TrainingActivity activity,
) {
  return switch (activity) {
    TrainingActivity.gym => l10n.schedule_activityShortGym,
    TrainingActivity.calisthenics => l10n.schedule_activityShortCalisthenics,
    TrainingActivity.running => l10n.schedule_activityShortRunning,
    TrainingActivity.stretch => l10n.schedule_activityShortStretch,
    TrainingActivity.nineMin => l10n.schedule_activityNineMin,
    TrainingActivity.morning => l10n.schedule_activityMorning,
  };
}

String scheduleTimeLabel(TrainingScheduleSlot slot) {
  if (!slot.hasTime) return '—';
  final h = slot.hour!.toString().padLeft(2, '0');
  final m = slot.minute!.toString().padLeft(2, '0');
  return '$h:$m';
}

List<String> scheduleWeekdayLabels(AppLocalizations l10n) => [
      l10n.weekday_mon,
      l10n.weekday_tue,
      l10n.weekday_wed,
      l10n.weekday_thu,
      l10n.weekday_fri,
      l10n.weekday_sat,
      l10n.weekday_sun,
    ];

Future<WeeklyTrainingSchedule?> showWeeklyScheduleEditorDialog({
  required BuildContext context,
  required WeeklyTrainingSchedule schedule,
}) {
  var draft = schedule.withoutLegacyActivities();
  final l10n = context.l10n;

  return showDialog<WeeklyTrainingSchedule>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            surfaceTintColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            title: Text(
              l10n.schedule_editorTitle,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            content: SizedBox(
              width: MediaQuery.sizeOf(ctx).width,
              child: SingleChildScrollView(
                child: WeeklyTrainingScheduleEditor(
                  schedule: draft,
                  onChanged: (next) => setLocal(() => draft = next),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.common_cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.actionBackground,
                  foregroundColor: AppColors.onAction,
                ),
                onPressed: () => Navigator.of(ctx).pop(draft),
                child: Text(l10n.common_done),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Compact read-only overview; tap opens [showWeeklyScheduleEditorDialog].
class WeeklyTrainingScheduleSummary extends StatelessWidget {
  const WeeklyTrainingScheduleSummary({
    super.key,
    required this.schedule,
    required this.onTap,
  });

  final WeeklyTrainingSchedule schedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = scheduleWeekdayLabels(l10n);
    final hasAny = schedule.enabledSlots().any(
          (s) => kTrainingScheduleActivities.contains(s.activity),
        );

    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.stroke.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.schedule_editorTitle,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!hasAny)
                Text(
                  l10n.schedule_emptySummary,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: _SummaryDayColumn(
                          dayLabel: days[i],
                          lines: _dayLines(l10n, i + 1),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 6),
              Text(
                l10n.schedule_tapToEdit,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _dayLines(AppLocalizations l10n, int weekday) {
    final lines = <String>[];
    for (final activity in kTrainingScheduleActivities) {
      final slot = schedule.slot(activity, weekday);
      if (!slot.enabled) continue;
      final short = trainingActivityShortLabel(l10n, activity);
      lines.add(slot.hasTime ? '$short ${scheduleTimeLabel(slot)}' : short);
    }
    return lines;
  }
}

class _SummaryDayColumn extends StatelessWidget {
  const _SummaryDayColumn({
    required this.dayLabel,
    required this.lines,
  });

  final String dayLabel;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        children: [
          Text(
            dayLabel,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          if (lines.isEmpty)
            Text(
              '·',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            )
          else
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WeeklyTrainingScheduleEditor extends StatelessWidget {
  const WeeklyTrainingScheduleEditor({
    super.key,
    required this.schedule,
    required this.onChanged,
    this.showHint = true,
  });

  final WeeklyTrainingSchedule schedule;
  final ValueChanged<WeeklyTrainingSchedule> onChanged;
  final bool showHint;

  Future<void> _pickTime(
    BuildContext context,
    TrainingScheduleSlot slot,
  ) async {
    final initial = TimeOfDay(
      hour: slot.hour ?? 8,
      minute: slot.minute ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    onChanged(
      schedule.updateSlot(
        slot.copyWith(
          enabled: true,
          hour: picked.hour,
          minute: picked.minute,
        ),
      ),
    );
  }

  void _toggleDay(TrainingScheduleSlot slot, bool enabled) {
    if (!enabled) {
      onChanged(
        schedule.updateSlot(
          slot.copyWith(enabled: false, clearTime: true),
        ),
      );
      return;
    }
    onChanged(schedule.updateSlot(slot.copyWith(enabled: true)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = scheduleWeekdayLabels(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHint) ...[
          Text(
            l10n.schedule_editorHint,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
        ],
        for (final activity in kTrainingScheduleActivities) ...[
          _ActivityScheduleBlock(
            label: trainingActivityLabel(l10n, activity),
            dayLabels: days,
            slots: [
              for (var weekday = 1; weekday <= 7; weekday++)
                schedule.slot(activity, weekday),
            ],
            onToggle: (slot, enabled) => _toggleDay(slot, enabled),
            onPickTime: (slot) => _pickTime(
              context,
              slot.copyWith(enabled: true),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _ActivityScheduleBlock extends StatelessWidget {
  const _ActivityScheduleBlock({
    required this.label,
    required this.dayLabels,
    required this.slots,
    required this.onToggle,
    required this.onPickTime,
  });

  final String label;
  final List<String> dayLabels;
  final List<TrainingScheduleSlot> slots;
  final void Function(TrainingScheduleSlot slot, bool enabled) onToggle;
  final ValueChanged<TrainingScheduleSlot> onPickTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.stroke.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _DayChip(
                    dayLabel: dayLabels[i],
                    slot: slots[i],
                    onToggle: (enabled) => onToggle(slots[i], enabled),
                    onPickTime: () => onPickTime(slots[i]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.dayLabel,
    required this.slot,
    required this.onToggle,
    required this.onPickTime,
  });

  final String dayLabel;
  final TrainingScheduleSlot slot;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final enabled = slot.enabled;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Text(
            dayLabel,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Material(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => onToggle(!enabled),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: enabled
                        ? AppColors.primary
                        : AppColors.stroke.withValues(alpha: 0.75),
                    width: enabled ? 1.5 : 1,
                  ),
                ),
                child: Icon(
                  enabled ? Icons.check_rounded : Icons.add_rounded,
                  size: 16,
                  color: enabled ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 18,
            child: enabled
                ? InkWell(
                    onTap: onPickTime,
                    borderRadius: BorderRadius.circular(4),
                    child: Text(
                      scheduleTimeLabel(slot),
                      style: TextStyle(
                        color: slot.hasTime
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'RobotoMono',
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
