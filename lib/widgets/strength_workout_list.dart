import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../services/calorie_burn_service.dart';
import '../theme/app_colors.dart';

Widget strengthWorkoutSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w800,
        fontSize: 11,
        letterSpacing: 0.8,
      ),
    ),
  );
}

Widget strengthWorkoutSubtitle({
  required BuildContext context,
  required int exerciseCount,
  required CalorieBurnResult burn,
}) {
  final l10n = context.l10n;
  return Text(
    exerciseCount == 0
        ? l10n.strength_exercisesZero
        : l10n.strength_exercisesSummary(
            '${burn.totalKcal}',
            exerciseCount,
            CalorieBurnService.formatDuration(burn.durationSeconds),
          ),
    style: TextStyle(
      color: AppColors.textMuted,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    ),
  );
}

Widget presetWorkoutListTile({
  required BuildContext context,
  required String name,
  required int exerciseCount,
  required CalorieBurnResult burn,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppColors.surfaceDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  strengthWorkoutSubtitle(
                    context: context,
                    exerciseCount: exerciseCount,
                    burn: burn,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    ),
  );
}
