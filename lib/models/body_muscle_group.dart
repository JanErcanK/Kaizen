/// Canonical muscle groups shown on the home recovery body map.
enum BodyMuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  abs,
  legs,
  forearms,
  neck,
}

extension BodyMuscleGroupX on BodyMuscleGroup {
  /// Matches gym/calisthenics [mainGroup] storage keys.
  static BodyMuscleGroup? fromMainGroup(String? raw) {
    switch (raw?.trim()) {
      case 'Brust':
        return BodyMuscleGroup.chest;
      case 'Rücken':
        return BodyMuscleGroup.back;
      case 'Schultern':
        return BodyMuscleGroup.shoulders;
      case 'Bizeps':
        return BodyMuscleGroup.biceps;
      case 'Trizeps':
        return BodyMuscleGroup.triceps;
      case 'Bauch':
        return BodyMuscleGroup.abs;
      case 'Beine':
        return BodyMuscleGroup.legs;
      case 'Unterarme':
        return BodyMuscleGroup.forearms;
      case 'Nacken':
        return BodyMuscleGroup.neck;
      default:
        return null;
    }
  }

  /// Regional exercise tags use the same groups as the recovery map.
  static BodyMuscleGroup? fromTrainingTag(String? raw) => switch (raw?.trim()) {
    'obere Brust' ||
    'mittlere Brust' ||
    'untere Brust' => BodyMuscleGroup.chest,
    'vordere Schulter' ||
    'mittlere Schulter' ||
    'hintere Schulter' => BodyMuscleGroup.shoulders,
    'oberer Rücken' ||
    'unterer Rücken' ||
    'breiter Rücken' => BodyMuscleGroup.back,
    'obere Bauchmuskeln' ||
    'untere Bauchmuskeln' ||
    'schräge Bauchmuskeln' => BodyMuscleGroup.abs,
    'langer Trizepskopf' ||
    'großer Trizepskopf' ||
    'kleiner Trizepskopf' => BodyMuscleGroup.triceps,
    'langer Bizepskopf' ||
    'kurzer Bizepskopf' ||
    'Brachialis' => BodyMuscleGroup.biceps,
    'oberer Oberschenkel' ||
    'hinterer Oberschenkel' ||
    'Quadrizeps' ||
    'Hintern' ||
    'Waden' ||
    'Schienbein' ||
    'Adduktoren' ||
    'Abduktoren' ||
    'Hüftabduktoren' ||
    'Hüftbeuger' => BodyMuscleGroup.legs,
    _ => fromMainGroup(raw),
  };
}

/// Recovery highlight for muscles trained recently.
enum MuscleRecoveryHighlight {
  none,
  recent, // accumulated training load, qualifying session <24h ago — red
  almostReady, // trained <48h ago; includes high load after its first 24h — yellow
  lightCircuit, // short 9 min circuit <24h ago — soft yellow
}

extension MuscleRecoveryLoad on MuscleRecoveryHighlight {
  /// Product heuristic, not a measurement of tissue damage. One unit is a
  /// recently hard-trained group; lighter/recovering groups count less.
  double get load => switch (this) {
    MuscleRecoveryHighlight.recent => 1.0,
    MuscleRecoveryHighlight.almostReady => 0.4,
    MuscleRecoveryHighlight.lightCircuit => 0.15,
    MuscleRecoveryHighlight.none => 0.0,
  };
}

/// Passive afterburn (EPOC) window still active for a muscle group.
class MuscleAfterburnState {
  const MuscleAfterburnState({required this.active, this.remaining});

  final bool active;
  final Duration? remaining;

  @override
  bool operator ==(Object other) =>
      other is MuscleAfterburnState &&
      other.active == active &&
      other.remaining == remaining;

  @override
  int get hashCode => Object.hash(active, remaining);
}

class MuscleRecoverySnapshot {
  const MuscleRecoverySnapshot({
    required this.recovery,
    required this.afterburn,
    required this.trainedThisWeek,
  });

  final Map<BodyMuscleGroup, MuscleRecoveryHighlight> recovery;
  final Map<BodyMuscleGroup, MuscleAfterburnState> afterburn;
  final Set<BodyMuscleGroup> trainedThisWeek;

  /// Equal contribution per canonical muscle group; each group counts once.
  int get recoveryPercent {
    final load = BodyMuscleGroup.values.fold<double>(
      0,
      (sum, group) => sum + (recovery[group]?.load ?? 0),
    );
    return (100 * (1 - load / BodyMuscleGroup.values.length)).round().clamp(
      0,
      100,
    );
  }

  int get heavilyTrainedGroups => recovery.values
      .where((state) => state == MuscleRecoveryHighlight.recent)
      .length;

  List<BodyMuscleGroup> get stillToTrainThisWeek {
    return BodyMuscleGroup.values
        .where((g) => !trainedThisWeek.contains(g))
        .toList();
  }

  /// Value equality over the fixed, small set of muscle groups, so a freshly
  /// computed snapshot with unchanged data compares equal to the previous
  /// one. Without this, CustomPainter.shouldRepaint sees a "new" object on
  /// every unrelated app-wide store change and repaints the body map even
  /// when it's off-screen.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MuscleRecoverySnapshot) return false;
    if (trainedThisWeek.length != other.trainedThisWeek.length) return false;
    for (final group in BodyMuscleGroup.values) {
      if (recovery[group] != other.recovery[group]) return false;
      if (afterburn[group] != other.afterburn[group]) return false;
      if (trainedThisWeek.contains(group) !=
          other.trainedThisWeek.contains(group)) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    for (final group in BodyMuscleGroup.values) ...[
      recovery[group],
      afterburn[group],
      trainedThisWeek.contains(group),
    ],
  ]);
}
