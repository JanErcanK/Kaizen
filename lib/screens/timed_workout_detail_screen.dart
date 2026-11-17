import 'package:flutter/material.dart';
import '../widgets/app_back_button.dart';

import '../l10n/l10n_extension.dart';
import '../l10n/catalog_localizations.dart';
import '../services/progress_store.dart';
import '../widgets/workout_muscle_map.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header_logo.dart';
import 'category_detail_screen.dart';
import 'workout_player_screen.dart';

class TimedWorkoutDetailScreen extends StatelessWidget {
  const TimedWorkoutDetailScreen({
    super.key,
    required this.title,
    required this.exercises,
    required this.workoutType,
    this.levelPoints = 3,
    this.restSeconds = 7,
    this.showInstructions = false,
    this.infoText,
    this.onAddExercise,
    this.onRemoveExercise,
  });

  final VoidCallback? onAddExercise;
  final ValueChanged<WorkoutExercise>? onRemoveExercise;
  final String? infoText;
  final String title;
  final List<WorkoutExercise> exercises;
  final String workoutType;
  final int levelPoints;
  final int restSeconds;
  final bool showInstructions;

  int _totalSeconds(List<WorkoutExercise> exercises) {
    final work = exercises.fold<int>(0, (s, e) => s + e.workSeconds);
    final rests =
        (exercises.length - 1).clamp(0, exercises.length) * restSeconds;
    return work + rests + 10; // +10 prep
  }

  String _durationLabel(List<WorkoutExercise> exercises) {
    final total = _totalSeconds(exercises);
    final m = total ~/ 60;
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s min';
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: ProgressStore.listenable(),
    builder: (context, _, _) => _build(
      context,
      exercises
          .map(
            (e) => WorkoutExercise(
              name: e.name,
              benefit: e.benefit,
              workSeconds: ProgressStore.workoutExerciseSeconds(
                workoutType: workoutType,
                exerciseName: e.name,
                defaultSeconds: e.workSeconds,
              ),
              assetPath: e.assetPath,
              animationAssetPaths: e.animationAssetPaths,
            ),
          )
          .toList(),
    ),
  );

  Widget _build(BuildContext context, List<WorkoutExercise> exercises) {
    final l10n = context.l10n;
    final isGerman = l10n.localeName.startsWith('de');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: const AppBackButton(),
        leadingWidth: 48,
        centerTitle: true,
        toolbarHeight: 52,
        title: const AppHeaderLogo(),
        actions: [
          if (infoText != null)
            IconButton(
              onPressed: () =>
                  CategoryDetailScreen.showWorkoutInfo(context, infoText!),
              icon: const Icon(Icons.info_outline),
            ),
        ],
      ),
      bottomNavigationBar: categoryDetailCompactNavBar(context),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              // Title & summary
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isGerman
                    ? '${exercises.length} Übungen · ${_durationLabel(exercises)} · $restSeconds Sek. Pause'
                    : '${exercises.length} exercises · ${_durationLabel(exercises)} · $restSeconds s rest',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              WorkoutMuscleMap(
                exercises: [
                  for (final e in exercises) {'name': e.name},
                ],
              ),
              const SizedBox(height: 20),
              if (onAddExercise != null) ...[
                OutlinedButton.icon(
                  onPressed: onAddExercise,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(context.l10n.morningWorkout_addExercise),
                ),
                const SizedBox(height: 12),
              ],
              // Full plan list
              Text(
                isGerman ? 'Übungsplan' : 'Exercise Plan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),

              for (var i = 0; i < exercises.length; i++) ...[
                TimedExerciseRow(
                  index: i + 1,
                  exercise: exercises[i],
                  trailing: onRemoveExercise == null
                      ? null
                      : IconButton(
                          tooltip: context.l10n.morningWorkout_removeExercise,
                          onPressed: () => onRemoveExercise!(exercises[i]),
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 20,
                          ),
                        ),
                  onEditTime: () => CategoryDetailScreen.editExerciseSeconds(
                    context,
                    workoutType: workoutType,
                    exercise: exercises[i],
                  ),
                ),
                if (i < exercises.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 36),
                        Icon(
                          Icons.pause_circle_outline,
                          size: 12,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isGerman
                              ? '$restSeconds Sek. Pause'
                              : '$restSeconds s rest',
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),

          // Start button pinned at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.actionBackground,
                      foregroundColor: AppColors.onAction,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    onPressed: exercises.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => WorkoutPlayerScreen(
                                  exercises: exercises,
                                  levelPoints: levelPoints,
                                  workoutType: workoutType,
                                  workoutName: title,
                                  restSeconds: restSeconds,
                                  showInstructions: showInstructions,
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(isGerman ? 'Workout starten' : 'Start Workout'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimedExerciseRow extends StatelessWidget {
  const TimedExerciseRow({
    super.key,
    required this.index,
    required this.exercise,
    this.onEditTime,
    this.trailing,
  });

  final VoidCallback? onEditTime;
  final Widget? trailing;
  final int index;
  final WorkoutExercise exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stroke.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number badge
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                color: AppColors.accentText,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + benefit + duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        CatalogLocalizations.anyExerciseName(exercise.name),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onEditTime,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${exercise.workSeconds}s',
                          style: TextStyle(
                            color: AppColors.accentText,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  CatalogLocalizations.workoutExerciseBenefit(exercise.benefit),
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
