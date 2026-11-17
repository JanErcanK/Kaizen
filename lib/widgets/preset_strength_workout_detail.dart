import 'package:flutter/material.dart';
import 'workout_muscle_map.dart';

import '../l10n/catalog_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../navigation/app_tab_navigation.dart';
import '../services/calorie_burn_service.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import '../utils/strength_exercise_config.dart';

class PresetStrengthWorkoutDetailScreen extends StatefulWidget {
  const PresetStrengthWorkoutDetailScreen({
    super.key,
    required this.name,
    required this.presetId,
    required this.workoutType,
    required this.initialExercises,
  });

  final String name;
  final String presetId;
  final String workoutType;
  final List<Map<String, dynamic>> initialExercises;

  @override
  State<PresetStrengthWorkoutDetailScreen> createState() =>
      _PresetStrengthWorkoutDetailScreenState();
}

class _PresetStrengthWorkoutDetailScreenState
    extends State<PresetStrengthWorkoutDetailScreen> {
  late List<Map<String, dynamic>> _exercises;

  @override
  void initState() {
    super.initState();
    _exercises = widget.initialExercises
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _completeWorkout() async {
    final mood = await _promptMood(context);
    if (!mounted) return;
    final burn = CalorieBurnService.strengthSession(exercises: _exercises);
    await ProgressStore.applyWorkoutRewards(
      workoutType: widget.workoutType,
      mood: mood,
      caloriesBurned: burn.totalKcal,
      durationSeconds: burn.durationSeconds,
      workoutName: widget.name,
      workoutId: widget.presetId,
      exercises: _exercises,
      calorieBreakdown: CalorieBurnService.breakdownToMaps(burn.breakdown),
    );
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.strength_workoutCompleteSnack('${burn.totalKcal}')),
        backgroundColor: AppColors.card,
      ),
    );
    AppTabNavigation.returnHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final burn = CalorieBurnService.strengthSession(exercises: _exercises);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          widget.name,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.strength_workoutComplete,
            icon: Icon(Icons.check_circle_outline, color: AppColors.primary),
            onPressed: _completeWorkout,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_exercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.strength_estimatedBurn,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${burn.totalKcal} kcal · ${CalorieBurnService.formatDuration(burn.durationSeconds)}',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _exercises.length + 1,
              itemBuilder: (context, position) {
                if (position == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: WorkoutMuscleMap(exercises: _exercises),
                  );
                }
                final index = position - 1;
                final ex = _exercises[index];
                final rawName = (ex['name'] ?? l10n.strength_exerciseFallback)
                    .toString();
                final exName = CatalogLocalizations.anyExerciseName(rawName);
                final exDesc = widget.workoutType == 'calisthenics'
                    ? CatalogLocalizations.calisthenicsDescription(rawName)
                    : CatalogLocalizations.gymDescription(rawName);
                final tagsRaw = ex['tags'];
                final tags = tagsRaw is List
                    ? tagsRaw.map((e) => e.toString()).toList()
                    : const <String>[];
                final line = burn.breakdown.length > index
                    ? burn.breakdown[index]
                    : CalorieBurnService.strengthExerciseLine(ex);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final updated = await StrengthExerciseConfig.edit(
                        context,
                        exerciseName: rawName,
                        exercise: ex,
                      );
                      if (updated == null) return;
                      setState(() {
                        _exercises[index] = updated;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: AppColors.surfaceDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  exName,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                StrengthExerciseConfig.formatShort(ex),
                                style: TextStyle(
                                  color: AppColors.accentText,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.strength_exerciseKcalDuration(
                              '${line.kcal}',
                              CalorieBurnService.formatDuration(line.seconds),
                            ),
                            style: TextStyle(
                              color: AppColors.accentText,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          if (exDesc.isNotEmpty && exDesc != rawName) ...[
                            const SizedBox(height: 6),
                            Text(
                              exDesc,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                          if (tags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: tags.map((t) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    CatalogLocalizations.muscleTag(t),
                                    style: TextStyle(
                                      color: AppColors.accentText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<int?> _promptMood(BuildContext context) async {
  final l10n = context.l10n;
  return showDialog<int?>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      Widget moodButton(int value, IconData icon, String label) {
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(ctx).pop(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.textPrimary, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.mood_title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Row(
          children: [
            moodButton(1, Icons.sentiment_very_dissatisfied, l10n.mood_veryBad),
            moodButton(2, Icons.sentiment_dissatisfied, l10n.mood_bad),
            moodButton(3, Icons.sentiment_neutral, l10n.mood_neutral),
            moodButton(4, Icons.sentiment_satisfied, l10n.mood_good),
            moodButton(5, Icons.sentiment_very_satisfied, l10n.mood_veryGood),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(
              l10n.common_skip,
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );
}
