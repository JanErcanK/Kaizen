import 'progress_store.dart';

/// Joints / tendon areas shown on the home body "Skeleton" tab.
enum BodyJoint { neck, shoulders, elbows, wrists, spine, hips, knees, shins, ankles }

/// Derives which joints/tendons were strengthened in the last 7 days from the
/// workout history (preset circuits, runs and custom gym/cali workouts).
class JointActivityService {
  JointActivityService._();

  static const int windowDays = 7;

  static Set<BodyJoint> strengthenedThisWeek() {
    final events = ProgressStore.workoutEventsLastDays(windowDays);
    final joints = <BodyJoint>{};

    for (final event in events) {
      final type = (event['type'] ?? '').toString();
      final workoutId = event['workoutId']?.toString().trim();

      // Custom gym / calisthenics workouts: inspect their exercises.
      if (workoutId != null && workoutId.isNotEmpty) {
        final fromCustom = _jointsFromStoredWorkout(workoutId);
        if (fromCustom.isNotEmpty) {
          joints.addAll(fromCustom);
          continue;
        }
      }
      joints.addAll(_jointsForType(type));
    }
    return joints;
  }

  static Set<BodyJoint> _jointsFromStoredWorkout(String workoutId) {
    final joints = <BodyJoint>{};
    for (final source in [
      ProgressStore.gymWorkoutById(workoutId),
      ProgressStore.calisthenicsWorkoutById(workoutId),
    ]) {
      if (source == null) continue;
      final raw = source['exercises'];
      if (raw is! List) continue;
      for (final ex in raw) {
        if (ex is! Map) continue;
        joints.addAll(_jointsForExerciseName(ex['name']?.toString() ?? ''));
        joints.addAll(_jointsForMainGroup(ex['mainGroup']?.toString()));
      }
    }
    return joints;
  }

  static Set<BodyJoint> _jointsForExerciseName(String name) {
    final n = name.toLowerCase();
    final out = <BodyJoint>{};
    bool has(List<String> keys) => keys.any(n.contains);

    if (has(['squat', 'kniebeug', 'lunge', 'ausfall', 'step up', 'step-up',
        'beinpresse', 'leg press', 'wandsitz', 'pistol', 'wall sit'])) {
      out.addAll({BodyJoint.knees, BodyJoint.hips});
    }
    if (has(['calf', 'wade', 'soleus', 'calf raise', 'wadenheben'])) {
      out.add(BodyJoint.ankles);
    }
    if (has(['tibialis', 'shin', 'schienbein'])) {
      out.add(BodyJoint.shins);
    }
    if (has(['neck', 'nacken', 'chin tuck'])) {
      out.add(BodyJoint.neck);
    }
    if (has(['deadlift', 'kreuzheben', 'hyperextension', 'back ext',
        'ruecken', 'rücken', 'reverse plank', 'good morning', 'hip hinge'])) {
      out.addAll({BodyJoint.spine, BodyJoint.hips});
    }
    if (has(['glute', 'bridge', 'huefte', 'hüfte', 'hip thrust',
        'hipflexor', 'pigeon'])) {
      out.add(BodyJoint.hips);
    }
    if (has(['shoulder', 'schulter', 'press', 'overhead', 'handstand',
        'pike', 'lateral raise', 'face pull'])) {
      out.add(BodyJoint.shoulders);
    }
    if (has(['curl', 'wrist', 'unterarm', 'forearm', 'grip', 'dip',
        'liegestuetz', 'liegestütz', 'push up', 'push-up', 'pushup'])) {
      out.addAll({BodyJoint.wrists, BodyJoint.elbows});
    }
    return out;
  }

  static Set<BodyJoint> _jointsForMainGroup(String? group) {
    return switch (group?.trim()) {
      'Beine' => {BodyJoint.knees, BodyJoint.hips, BodyJoint.ankles},
      'Schultern' => {BodyJoint.shoulders},
      'Rücken' => {BodyJoint.spine},
      'Unterarme' => {BodyJoint.wrists, BodyJoint.elbows},
      'Brust' => {BodyJoint.shoulders, BodyJoint.elbows},
      'Bizeps' || 'Trizeps' => {BodyJoint.elbows},
      'Nacken' => {BodyJoint.neck},
      _ => const <BodyJoint>{},
    };
  }

  /// Preset circuits / runs cover a fixed set of joints based on their
  /// known exercise list.
  static Set<BodyJoint> _jointsForType(String type) {
    return switch (type) {
      // Tendon/joint focused full body program.
      'hercules' => {
          BodyJoint.knees,
          BodyJoint.shins,
          BodyJoint.ankles,
          BodyJoint.neck,
          BodyJoint.hips,
          BodyJoint.spine,
          BodyJoint.shoulders,
          BodyJoint.wrists,
        },
      'nine_min' => {
          BodyJoint.knees,
          BodyJoint.hips,
          BodyJoint.wrists,
          BodyJoint.shoulders,
        },
      // Mobility work cares for these joints.
      'stretch' => {
          BodyJoint.hips,
          BodyJoint.spine,
          BodyJoint.shoulders,
          BodyJoint.knees,
        },
      'run' => {BodyJoint.knees, BodyJoint.ankles, BodyJoint.shins},
      // Generic strength fallback.
      'gym' => {
          BodyJoint.shoulders,
          BodyJoint.elbows,
          BodyJoint.wrists,
          BodyJoint.spine,
        },
      'calisthenics' => {
          BodyJoint.shoulders,
          BodyJoint.elbows,
          BodyJoint.wrists,
        },
      _ => const <BodyJoint>{},
    };
  }
}
