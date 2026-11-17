import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import '../utils/strength_exercise_config.dart';

enum StrengthWorkoutKind { gym, calisthenics }

/// Shared bottom sheets for adding catalog exercises to gym/calisthenics workouts.
class StrengthAddExerciseFlow {
  StrengthAddExerciseFlow._();

  static Map<String, dynamic> exerciseMap({
    required String name,
    required String description,
    required String mainGroup,
    required List<String> tags,
  }) {
    return StrengthExerciseConfig.applyDefaults({
      'name': name,
      'description': description,
      'mainGroup': mainGroup,
      'tags': tags,
    });
  }

  static Future<void> showAddOptions({
    required BuildContext context,
    required StrengthWorkoutKind kind,
    required String displayName,
    required Map<String, dynamic> exercise,
  }) async {
    final configured = await StrengthExerciseConfig.edit(context, exerciseName: displayName, exercise: exercise);
    if (configured == null || !context.mounted) return;
    final lastId = kind == StrengthWorkoutKind.gym
        ? ProgressStore.lastGymWorkoutId
        : ProgressStore.lastCalisthenicsWorkoutId;
    final last = lastId == null
        ? null
        : (kind == StrengthWorkoutKind.gym
            ? ProgressStore.gymWorkoutById(lastId)
            : ProgressStore.calisthenicsWorkoutById(lastId));

    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) {
        final l10n = ctx.l10n;
        return Dialog(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (last != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.history, color: AppColors.secondary),
                        title: Text(
                          l10n.gym_addToLastWorkout,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          (last['name'] ?? '').toString(),
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        onTap: () async {
                          Navigator.of(ctx).pop();
                          await _addToLast(
                            context: context,
                            kind: kind,
                            exercise: configured,
                          );
                        },
                      )
                    else
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.history, color: AppColors.textMuted),
                        title: Text(
                          l10n.gym_addToLastWorkout,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          l10n.gym_noWorkoutYet,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.playlist_add, color: AppColors.secondary),
                      title: Text(
                        l10n.gym_addWorkout,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await _openChooseWorkout(
                          context: context,
                          kind: kind,
                          exercise: configured,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _addToLast({
    required BuildContext context,
    required StrengthWorkoutKind kind,
    required Map<String, dynamic> exercise,
  }) async {
    if (kind == StrengthWorkoutKind.gym) {
      final lastId = ProgressStore.lastGymWorkoutId;
      if (lastId == null) return;
      if (ProgressStore.gymWorkoutById(lastId) == null) return;
      await ProgressStore.addExerciseToGymWorkout(
        workoutId: lastId,
        exercise: exercise,
      );
    } else {
      final lastId = ProgressStore.lastCalisthenicsWorkoutId;
      if (lastId == null) return;
      if (ProgressStore.calisthenicsWorkoutById(lastId) == null) return;
      await ProgressStore.addExerciseToCalisthenicsWorkout(
        workoutId: lastId,
        exercise: exercise,
      );
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.gym_exerciseAdded),
        backgroundColor: AppColors.card,
      ),
    );
  }

  static Future<void> _openChooseWorkout({
    required BuildContext context,
    required StrengthWorkoutKind kind,
    required Map<String, dynamic> exercise,
  }) async {
    final workouts = kind == StrengthWorkoutKind.gym
        ? ProgressStore.gymWorkouts
        : ProgressStore.calisthenicsWorkouts;
    String? selectedId =
        workouts.isNotEmpty ? workouts.first['id']?.toString() : null;

    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final l10n = ctx.l10n;
            final currentWorkouts = kind == StrengthWorkoutKind.gym
                ? ProgressStore.gymWorkouts
                : ProgressStore.calisthenicsWorkouts;
            if (selectedId == null && currentWorkouts.isNotEmpty) {
              selectedId = currentWorkouts.first['id']?.toString();
            }
            return Dialog(
              backgroundColor: AppColors.card,
              surfaceTintColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SafeArea(
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      16 + MediaQuery.of(ctx).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.gym_addToWorkoutTitle,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (currentWorkouts.isEmpty)
                          Text(
                            l10n.gym_noWorkoutsCreated,
                            style: TextStyle(color: AppColors.textMuted),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.stroke),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedId,
                                isExpanded: true,
                                dropdownColor: AppColors.card,
                                items: currentWorkouts.map((w) {
                                  final id = w['id']?.toString() ?? '';
                                  final name =
                                      (w['name'] ?? l10n.strength_workoutFallback)
                                          .toString();
                                  return DropdownMenuItem<String>(
                                    value: id,
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) =>
                                    setSheetState(() => selectedId = v),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: BorderSide(color: AppColors.stroke),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  final id = await _promptCreateWorkout(ctx, kind);
                                  if (id == null) return;
                                  setSheetState(() => selectedId = id);
                                },
                                child: Text(l10n.gym_createNewWorkout),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.actionBackground,
                                  foregroundColor: AppColors.onAction,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed:
                                    currentWorkouts.isEmpty || selectedId == null
                                    ? null
                                    : () async {
                                        final id = selectedId!;
                                        if (kind == StrengthWorkoutKind.gym) {
                                          await ProgressStore
                                              .addExerciseToGymWorkout(
                                                workoutId: id,
                                                exercise: exercise,
                                              );
                                        } else {
                                          await ProgressStore
                                              .addExerciseToCalisthenicsWorkout(
                                                workoutId: id,
                                                exercise: exercise,
                                              );
                                        }
                                        if (!ctx.mounted) return;
                                        Navigator.of(ctx).pop();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    l10n.gym_exerciseAdded,
                                                  ),
                                                  backgroundColor: AppColors.card,
                                                ),
                                              );
                                        }
                                      },
                                child: Text(l10n.common_add),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Future<String?> _promptCreateWorkout(
    BuildContext sheetContext,
    StrengthWorkoutKind kind,
  ) async {
    final l10n = sheetContext.l10n;
    final controller = TextEditingController(text: l10n.gym_defaultWorkoutName);
    final id = await showDialog<String?>(
      context: sheetContext,
      useRootNavigator: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.transparent,
          title: Text(
            l10n.gym_newWorkout,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.common_name,
              hintStyle: TextStyle(color: AppColors.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(
                l10n.common_cancel,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text;
                final newId = kind == StrengthWorkoutKind.gym
                    ? await ProgressStore.createGymWorkout(name)
                    : await ProgressStore.createCalisthenicsWorkout(name);
                if (ctx.mounted) Navigator.of(ctx).pop(newId);
              },
              child: Text(
                l10n.common_create,
                style: TextStyle(color: AppColors.accentText),
              ),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return id;
  }
}
