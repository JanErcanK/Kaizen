import 'package:flutter/material.dart';

import '../data/wakeup_workout_exercises.dart';
import '../l10n/l10n_extension.dart';
import 'timed_workout_detail_screen.dart';

class WakeupWorkoutDetailScreen extends StatelessWidget {
  const WakeupWorkoutDetailScreen({super.key});

  static const String workoutType = 'wakeup_workout';
  static const int levelPoints = 3;

  @override
  Widget build(BuildContext context) => TimedWorkoutDetailScreen(
    title: context.l10n.localeName.startsWith('de')
        ? 'Ganzkörper Wake-Up'
        : 'Full-Body Wake-Up',
    exercises: wakeupWorkoutExercises,
    workoutType: workoutType,
    levelPoints: levelPoints,
  );
}
