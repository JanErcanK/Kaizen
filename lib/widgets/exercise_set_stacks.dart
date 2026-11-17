import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/strength_exercise_config.dart';

/// Shows set stacks (max 5 per column) on the right of an exercise card.
class ExerciseSetStacks extends StatelessWidget {
  const ExerciseSetStacks({
    super.key,
    required this.setReps,
    this.onTap,
    this.timed = false,
  });

  final List<int> setReps;
  final VoidCallback? onTap;
  final bool timed;

  @override
  Widget build(BuildContext context) {
    final capped = setReps.take(StrengthExerciseConfig.maxSets).toList();
    if (capped.isEmpty) return const SizedBox.shrink();

    final columns = <List<int>>[];
    for (var i = 0; i < capped.length; i += 5) {
      columns.add(capped.sublist(i, (i + 5).clamp(0, capped.length)));
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: (columns.length * 38 + 8).clamp(46, 152).toDouble(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final col in columns) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final reps in col.reversed)
                        Container(
                          width: 34,
                          height: 22,
                          margin: const EdgeInsets.only(bottom: 3),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            timed ? '$reps s' : '$reps',
                            style: TextStyle(
                              color: AppColors.accentText,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
