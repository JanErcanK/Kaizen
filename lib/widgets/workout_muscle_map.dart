import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../l10n/catalog_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../models/body_muscle_group.dart';
import '../services/muscle_activity_service.dart';
import '../services/muscle_exercise_filter.dart';
import '../theme/app_colors.dart';
import 'body_muscle_paths.dart';

/// A local vector illustration, derived anew from the current exercise plan.
/// No image generation, network request, or stale saved thumbnail is involved.
class WorkoutMuscleMap extends StatelessWidget {
  const WorkoutMuscleMap({super.key, required this.exercises});

  final List<Map<String, dynamic>> exercises;

  @override
  Widget build(BuildContext context) {
    final german = context.l10n.localeName.startsWith('de');
    final groups = MuscleActivityService.plannedMuscles(exercises);
    final labels = BodyMuscleGroup.values.where(groups.contains).map((group) {
      final label = switch (group) {
        BodyMuscleGroup.chest => 'Brust',
        BodyMuscleGroup.back => 'Rücken',
        BodyMuscleGroup.shoulders => 'Schultern',
        BodyMuscleGroup.biceps => 'Bizeps',
        BodyMuscleGroup.triceps => 'Trizeps',
        BodyMuscleGroup.abs => 'Bauch',
        BodyMuscleGroup.legs => 'Beine',
        BodyMuscleGroup.forearms => 'Unterarme',
        BodyMuscleGroup.neck => 'Nacken',
      };
      return CatalogLocalizations.muscleGroup(label);
    }).toList();
    return Container(
      key: const Key('workout-muscle-map'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            german ? 'Dein Muskelfokus' : 'Your muscle focus',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            german
                ? 'Grün zeigt die beanspruchten Muskelgruppen.'
                : 'Green shows the muscle groups involved.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Semantics(
            image: true,
            label: labels.join(', '),
            child: SizedBox(
              height: 205,
              child: CustomPaint(
                painter: WorkoutMusclePainter(
                  groups: groups,
                  neutral: AppColors.textMuted.withValues(alpha: .22),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                german ? 'Vorne' : 'Front',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              Text(
                german ? 'Hinten' : 'Back',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            labels.isEmpty
                ? (german
                      ? 'Noch keine Muskelgruppen zugeordnet.'
                      : 'No muscle groups assigned yet.')
                : labels.join(' · '),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.accentText,
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutMusclePainter extends CustomPainter {
  WorkoutMusclePainter({
    required Set<BodyMuscleGroup> groups,
    required this.neutral,
  }) : groups = Set.unmodifiable(groups);

  final Set<BodyMuscleGroup> groups;
  final Color neutral;
  static final _front = _parse(BodyMusclePaths.front);
  static final _back = _parse(BodyMusclePaths.back);
  static Map<String, List<Path>> _parse(Map<String, List<String>> data) =>
      data.map(
        (slug, paths) => MapEntry(slug, paths.map(parseSvgPathData).toList()),
      );

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.height / BodyMusclePaths.viewHeight,
      size.width / (BodyMusclePaths.viewWidth * 2),
    );
    for (final (index, paths) in [_front, _back].indexed) {
      canvas.save();
      canvas.translate(
        size.width * (index + .5) / 2 - BodyMusclePaths.viewWidth * scale / 2,
        0,
      );
      canvas.scale(scale);
      if (index == 1) canvas.translate(-BodyMusclePaths.backOffsetX, 0);
      for (final entry in paths.entries) {
        final group = BodyMuscleGroupX.fromMainGroup(
          MuscleExerciseFilter.mainGroupGermanForSlug(entry.key),
        );
        final paint = Paint()
          ..color = groups.contains(group) ? const Color(0xFF68B875) : neutral;
        for (final path in entry.value) {
          canvas.drawPath(path, paint);
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(WorkoutMusclePainter oldDelegate) =>
      !setEquals(groups, oldDelegate.groups) || neutral != oldDelegate.neutral;
}
