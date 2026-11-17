import '../l10n/app_localizations.dart';
import '../models/body_map_view_mode.dart';
import '../models/body_muscle_group.dart';
import '../services/joint_activity_service.dart';
import '../services/muscle_activity_service.dart';
import '../services/organ_health_service.dart';

class HomeTabHudService {
  HomeTabHudService._();

  static List<String> detailLines(
    AppLocalizations l10n,
    BodyMapViewMode mode,
  ) {
    return switch (mode) {
      // One view now shows both, so its readout covers both.
      BodyMapViewMode.recovery => [
        ..._recoveryLines(l10n),
        ..._afterburnLines(l10n),
      ],
      BodyMapViewMode.afterburn => _afterburnLines(l10n),
      BodyMapViewMode.trained => _trainedLines(l10n),
      BodyMapViewMode.organs => _organLines(l10n),
      BodyMapViewMode.skeleton => _jointLines(l10n),
      BodyMapViewMode.connective => const [],
    };
  }

  static List<String> _recoveryLines(AppLocalizations l10n) {
    final snapshot = MuscleActivityService.snapshot();
    final resting = BodyMuscleGroup.values
        .where(
          (g) =>
              snapshot.recovery[g] == MuscleRecoveryHighlight.recent,
        )
        .toList();

    if (resting.isEmpty) {
      return const [];
    }

    return [
      l10n.home_hudTabRecoveryRest(
        _joinLabels(resting.map(_muscleLabel(l10n)).toList()),
      ),
    ];
  }

  static List<String> _afterburnLines(AppLocalizations l10n) {
    final lines = <String>[];

    final snapshot = MuscleActivityService.snapshot();
    final kcal = MuscleActivityService.afterburnKcalAccumulatedSoFar();
    Duration? longestRemaining;
    var hasActive = false;

    for (final state in snapshot.afterburn.values) {
      if (!state.active) continue;
      hasActive = true;
      final remaining = state.remaining;
      if (remaining == null) continue;
      if (longestRemaining == null || remaining > longestRemaining) {
        longestRemaining = remaining;
      }
    }

    if (hasActive && kcal > 0) {
      final remainingText = longestRemaining != null
          ? _formatDuration(l10n, longestRemaining)
          : l10n.home_hudTabAfterburnUnknownRemaining;
      lines.add(
        l10n.home_hudTabAfterburnActive(
          kcal.round(),
          remainingText,
        ),
      );
    } else {
      lines.add(l10n.home_hudTabAfterburnNone);
    }

    return lines;
  }

  static List<String> _trainedLines(AppLocalizations l10n) {
    final pending = MuscleActivityService.snapshot().stillToTrainThisWeek;
    if (pending.isEmpty) {
      return [l10n.home_hudTabTrainedComplete];
    }
    return [
      l10n.home_hudTabTrainedOpen(
        _joinLabels(pending.map(_muscleLabel(l10n)).toList()),
      ),
    ];
  }

  static List<String> _organLines(AppLocalizations l10n) {
    final allGood = Organ.values.every(
      (organ) => OrganHealthService.displayStatus(organ) == OrganStatus.good,
    );
    if (allGood) {
      return [l10n.home_hudTabOrgansAllGood];
    }
    return [l10n.home_hudTabOrgansEatToday];
  }

  static List<String> _jointLines(AppLocalizations l10n) {
    final strengthened = JointActivityService.strengthenedThisWeek();
    final pending = BodyJoint.values
        .where((j) => !strengthened.contains(j))
        .toList();

    if (pending.isEmpty) {
      return [l10n.home_hudTabJointsAllDone];
    }

    return [
      l10n.home_hudTabJointsNeed(
        _joinLabels(pending.map(_jointLabel(l10n)).toList()),
      ),
    ];
  }

  static String Function(BodyMuscleGroup) _muscleLabel(AppLocalizations l10n) {
    return (g) => switch (g) {
          BodyMuscleGroup.chest => l10n.home_hudMuscleChest,
          BodyMuscleGroup.back => l10n.home_hudMuscleBack,
          BodyMuscleGroup.shoulders => l10n.home_hudMuscleShoulders,
          BodyMuscleGroup.biceps => l10n.home_hudMuscleBiceps,
          BodyMuscleGroup.triceps => l10n.home_hudMuscleTriceps,
          BodyMuscleGroup.abs => l10n.home_hudMuscleAbs,
          BodyMuscleGroup.legs => l10n.home_hudMuscleLegs,
          BodyMuscleGroup.forearms => l10n.home_hudMuscleForearms,
          BodyMuscleGroup.neck => l10n.home_hudMuscleNeck,
        };
  }

  static String Function(BodyJoint) _jointLabel(AppLocalizations l10n) {
    return (j) => switch (j) {
          BodyJoint.neck => l10n.home_hudJointNeck,
          BodyJoint.shoulders => l10n.home_hudJointShoulders,
          BodyJoint.elbows => l10n.home_hudJointElbows,
          BodyJoint.wrists => l10n.home_hudJointWrists,
          BodyJoint.spine => l10n.home_hudJointSpine,
          BodyJoint.hips => l10n.home_hudJointHips,
          BodyJoint.knees => l10n.home_hudJointKnees,
          BodyJoint.shins => l10n.home_hudJointShins,
          BodyJoint.ankles => l10n.home_hudJointAnkles,
        };
  }

  static String _joinLabels(List<String> labels) => labels.join(', ');

  static String _formatDuration(AppLocalizations l10n, Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return l10n.home_hudTabDurationHoursMinutes(hours, minutes);
    }
    if (hours > 0) {
      return l10n.home_hudTabDurationHours(hours);
    }
    return l10n.home_hudTabDurationMinutes(minutes.clamp(1, 9999));
  }
}
