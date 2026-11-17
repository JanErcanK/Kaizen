import '../widgets/app_back_button.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../models/training_schedule.dart';
import '../services/progress_store.dart';
import '../services/training_notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/weekly_training_schedule_editor.dart';

class TrainingScheduleEditScreen extends StatefulWidget {
  const TrainingScheduleEditScreen({super.key});

  @override
  State<TrainingScheduleEditScreen> createState() =>
      _TrainingScheduleEditScreenState();
}

class _TrainingScheduleEditScreenState
    extends State<TrainingScheduleEditScreen> {
  late WeeklyTrainingSchedule _schedule = ProgressStore.weeklyTrainingSchedule;
  var _saving = false;

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    await ProgressStore.setWeeklyTrainingSchedule(_schedule);
    await TrainingNotificationService.syncFromStore(l10n: l10n);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        leadingWidth: 44,
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          l10n.schedule_editorTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontFamily: 'Roboto',
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: WeeklyTrainingScheduleEditor(
                  schedule: _schedule,
                  onChanged: (next) => setState(() => _schedule = next),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.actionBackground,
                    foregroundColor: AppColors.onAction,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.common_save,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
