import 'package:flutter/material.dart';

import '../l10n/catalog_localizations.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../services/morning_workout_service.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import 'timed_workout_detail_screen.dart';
import 'workout_player_screen.dart';

class MorningWorkoutDetailScreen extends StatelessWidget {
  const MorningWorkoutDetailScreen({super.key});

  static const String workoutType = 'hercules';
  static const int levelPoints = 3;
  String _sourceLabel(
    AppLocalizations l10n,
    MorningWorkoutExerciseSource source,
  ) {
    return switch (source) {
      MorningWorkoutExerciseSource.morning => l10n.morningWorkout_sourceMorning,
      MorningWorkoutExerciseSource.yoga => l10n.morningWorkout_sourceYoga,
      MorningWorkoutExerciseSource.gym => l10n.morningWorkout_sourceGym,
      MorningWorkoutExerciseSource.calisthenics =>
        l10n.morningWorkout_sourceCalisthenics,
    };
  }

  Future<void> _pickExercise(BuildContext context) async {
    final l10n = context.l10n;
    final order = ProgressStore.morningWorkoutExerciseOrder();
    final pickable = MorningWorkoutService.pickableNotInWorkout(order);
    if (pickable.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.morningWorkout_allExercisesAdded)),
      );
      return;
    }

    final query = ValueNotifier<String>('');
    final selected = await showModalBottomSheet<MorningWorkoutCatalogEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: ValueListenableBuilder<String>(
              valueListenable: query,
              builder: (context, search, _) {
                final needle = search.trim().toLowerCase();
                final filtered = pickable.where((entry) {
                  if (needle.isEmpty) return true;
                  return CatalogLocalizations.matchesExerciseQuery(
                    entry.name,
                    needle,
                  );
                }).toList();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.stroke,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.morningWorkout_pickExercise,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => query.value = value,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: l10n.common_search,
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.stroke),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          return Material(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.of(ctx).pop(entry),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            CatalogLocalizations.anyExerciseName(
                                              entry.name,
                                            ),
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _sourceLabel(l10n, entry.source),
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${MorningWorkoutService.addedExerciseDefaultSeconds}s',
                                      style: TextStyle(
                                        color: AppColors.accentText,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    query.dispose();

    if (selected == null) return;
    await ProgressStore.addMorningWorkoutExercise(selected.name);
  }

  Future<void> _removeExercise(
    BuildContext context,
    WorkoutExercise exercise,
  ) async {
    final l10n = context.l10n;
    final order = ProgressStore.morningWorkoutExerciseOrder();
    if (order.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.morningWorkout_cannotRemoveLast)),
      );
      return;
    }
    await ProgressStore.removeMorningWorkoutExercise(exercise.name);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: ProgressStore.listenable(),
    builder: (context, _, _) => TimedWorkoutDetailScreen(
      title: context.l10n.categoryDetail_headingHercules,
      exercises: MorningWorkoutService.currentExercises(),
      workoutType: workoutType,
      levelPoints: levelPoints,
      restSeconds: 10,
      infoText: context.l10n.categoryDetail_infoMorning,
      onAddExercise: () => _pickExercise(context),
      onRemoveExercise: (exercise) => _removeExercise(context, exercise),
    ),
  );
}
