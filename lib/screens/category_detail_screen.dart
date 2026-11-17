import 'package:flutter/material.dart';
import '../widgets/app_back_button.dart';

import '../data/yoga_stretch_exercises.dart';
import '../l10n/catalog_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_header_logo.dart';
import 'morning_workout_detail_screen.dart';
import 'root_shell.dart';
import 'workout_player_screen.dart';
import 'timed_workout_detail_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({super.key, required this.title, this.categoryId});

  final String title;
  final String? categoryId;

  static const List<WorkoutExercise> _nineMinExercises = [
    WorkoutExercise(
      name: 'Hampelmann',
      benefit:
          'Bringt den Kreislauf schnell in Schwung und aktiviert den ganzen Körper.',
      assetPath: 'assets/exercises/9min/01_hampelmann.png',
      animationAssetPaths: [
        'assets/exercises/9min/01_hampelmann.png',
        'assets/exercises/9min/01_hampelmann_b.png',
      ],
    ),
    WorkoutExercise(
      name: 'Wandsitzen',
      benefit:
          'Stärkt Oberschenkel und Gesäßmuskeln für mehr Stabilitaet in den Beinen.',
      assetPath: 'assets/exercises/9min/02_wandsitzen.png',
    ),
    WorkoutExercise(
      name: 'Liegestütz',
      benefit:
          'Baut Kraft in Brust, Schultern und Trizeps auf und fordert den Rumpf mit.',
      assetPath: 'assets/exercises/9min/03_liegestuetz.png',
      animationAssetPaths: [
        'assets/exercises/9min/03_liegestuetz.png',
        'assets/exercises/9min/03_liegestuetz_b.png',
      ],
    ),
    WorkoutExercise(
      name: 'Bauchpresse',
      benefit:
          'Trainiert die Bauchmuskulatur und verbessert die Rumpfkontrolle.',
      assetPath: 'assets/exercises/9min/04_bauchpresse.png',
    ),
    WorkoutExercise(
      name: 'Stuhl-Step-Up',
      benefit:
          'Stärkt Sehnen am Bein und das Knie; langsame saubere Ausfuehrung ist wichtig.',
      assetPath: 'assets/exercises/9min/05_stuhl_step_up.png',
      animationAssetPaths: [
        'assets/exercises/9min/05_stuhl_step_up_b.png',
        'assets/exercises/9min/05_stuhl_step_up.png',
        'assets/exercises/9min/05_stuhl_step_up_c.png',
      ],
    ),
    WorkoutExercise(
      name: 'Kniebeugen',
      benefit:
          'Fördert funktionelle Kraft in Beinen und Gesäß für Alltagsbewegungen.',
      assetPath: 'assets/exercises/9min/06_kniebeugen.png',
      animationAssetPaths: [
        'assets/exercises/9min/06_kniebeugen_b.png',
        'assets/exercises/9min/06_kniebeugen.png',
      ],
    ),
    WorkoutExercise(
      name: 'Trizeps-Dip',
      benefit:
          'Kraeftigt die Rueckseite der Arme und verbessert die Druckkraft.',
      assetPath: 'assets/exercises/9min/07_trizeps_dip.png',
      animationAssetPaths: [
        'assets/exercises/9min/07_trizeps_dip_b.png',
        'assets/exercises/9min/07_trizeps_dip.png',
      ],
    ),
    WorkoutExercise(
      name: 'Unterarmstütz',
      benefit:
          'Stärkt den gesamten Core und unterstuetzt eine stabile Haltung.',
      assetPath: 'assets/exercises/9min/08_unterarmstuetz.png',
    ),
    WorkoutExercise(
      name: 'Knien hochziehen',
      benefit:
          'Aktiviert unteren Bauch und Hueftbeuger und fördert Koordination.',
      assetPath: 'assets/exercises/9min/09_knie_hochziehen.png',
      animationAssetPaths: [
        'assets/exercises/9min/09_knie_hochziehen.png',
        'assets/exercises/9min/09_knie_hochziehen_b.png',
      ],
    ),
    WorkoutExercise(
      name: 'Ausfallschritt',
      benefit:
          'Verbessert Gleichgewicht und trainiert Beine einseitig gegen Dysbalancen.',
      assetPath: 'assets/exercises/9min/10_ausfallschritt.png',
    ),
    WorkoutExercise(
      name: 'Liegestütz mit Drehen',
      benefit: 'Kombiniert Oberkoerperkraft mit Rotationsstabilitaet im Rumpf.',
      assetPath: 'assets/exercises/9min/11_liegestuetz_mit_drehen.png',
      animationAssetPaths: [
        'assets/exercises/9min/11_liegestuetz_mit_drehen_b.png',
        'assets/exercises/9min/11_liegestuetz_mit_drehen.png',
        'assets/exercises/9min/11_liegestuetz_mit_drehen_c.png',
      ],
    ),
    WorkoutExercise(
      name: 'Seitlicher Unterarmstütz rechts',
      benefit:
          'Stärkt schraege Bauchmuskeln und die seitliche Rumpfstabilitaet rechts.',
      assetPath: 'assets/exercises/9min/12_side_plank_rechts.png',
    ),
    WorkoutExercise(
      name: 'Seitlicher Unterarmstütz links',
      benefit:
          'Stärkt schraege Bauchmuskeln und die seitliche Rumpfstabilitaet links.',
      assetPath: 'assets/exercises/9min/13_side_plank_links.png',
    ),
  ];

  static Future<void> editExerciseSeconds(
    BuildContext context, {
    required String workoutType,
    required WorkoutExercise exercise,
  }) async {
    final controller = TextEditingController(text: '${exercise.workSeconds}');
    int current = exercise.workSeconds;

    final l10n = context.l10n;
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              surfaceTintColor: Colors.transparent,
              title: Text(
                CatalogLocalizations.workoutExerciseName(exercise.name),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            current = (current - 5).clamp(5, 3600);
                            controller.text = '$current';
                          });
                        },
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            suffixText: 's',
                            suffixStyle: TextStyle(color: AppColors.textMuted),
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
                          onChanged: (raw) {
                            final v = int.tryParse(raw.trim());
                            if (v == null) return;
                            setState(() => current = v.clamp(5, 3600));
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            current = (current + 5).clamp(5, 3600);
                            controller.text = '$current';
                          });
                        },
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.categoryDetail_secondsDefaultHint,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
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
                    await ProgressStore.clearWorkoutExerciseSeconds(
                      workoutType: workoutType,
                      exerciseName: exercise.name,
                    );
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop(null);
                  },
                  child: Text(
                    l10n.common_reset,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.actionBackground,
                    foregroundColor: AppColors.onAction,
                  ),
                  onPressed: () {
                    final v = int.tryParse(controller.text.trim());
                    if (v == null) return;
                    Navigator.of(ctx).pop(v.clamp(5, 3600));
                  },
                  child: Text(l10n.common_save),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    if (result == null) return;
    await ProgressStore.setWorkoutExerciseSeconds(
      workoutType: workoutType,
      exerciseName: exercise.name,
      seconds: result,
    );
  }

  static void showWorkoutInfo(BuildContext context, String text) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        content: Text(
          text,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Roboto',
            height: 1.45,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              ctx.l10n.common_ok,
              style: TextStyle(color: AppColors.accentText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutDetail(
    BuildContext context, {
    required String heading,
    required int levelPoints,
    required List<WorkoutExercise> exercises,
    required String workoutType,
    String? infoText,
  }) {
    return TimedWorkoutDetailScreen(
      title: heading,
      exercises: exercises,
      workoutType: workoutType,
      levelPoints: levelPoints,
      restSeconds: 10,
      infoText: infoText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final normalized = title.trim().toLowerCase();
    if (categoryId == '9min' || normalized == '9 min' || normalized == '9min') {
      return _buildWorkoutDetail(
        context,
        heading: l10n.categoryDetail_heading9min,
        levelPoints: 2,
        exercises: _nineMinExercises,
        workoutType: 'nine_min',
        infoText: l10n.categoryDetail_info9min,
      );
    }

    if (categoryId == 'hercules_workout' ||
        normalized == 'hercules workout' ||
        normalized == 'whole body morning' ||
        normalized == 'morning workout' ||
        normalized == 'morning whole body with focus on legs') {
      return const MorningWorkoutDetailScreen();
    }

    if (categoryId == 'only_stretch' ||
        normalized == 'only stretch' ||
        normalized == 'stretch' ||
        normalized == 'dehnen') {
      return _buildWorkoutDetail(
        context,
        heading: l10n.categoryDetail_headingStretch,
        levelPoints: 1,
        exercises: yogaStretchExercises,
        workoutType: 'stretch',
        infoText: l10n.categoryDetail_infoStretch,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: const AppBackButton(),
        leadingWidth: 48,
        centerTitle: true,
        toolbarHeight: 52,
        title: const AppHeaderLogo(),
      ),
      bottomNavigationBar: categoryDetailCompactNavBar(context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$title screen coming next.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

Widget categoryDetailCompactNavBar(BuildContext context) {
  return AppBottomNavBar(
    selectedIndex: 0,
    onDestinationSelected: (index) {
      if (index == 0) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
        RootShell.selectedTab.value = index;
      }
    },
  );
}
