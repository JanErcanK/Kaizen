import '../data/calisthenics_exercise_catalog.dart';
import '../data/gym_exercise_catalog.dart';
import '../l10n/app_localizations.dart';
import '../utils/strength_exercise_config.dart';

class PresetWorkoutTemplate {
  const PresetWorkoutTemplate({
    required this.id,
    required this.exerciseNames,
    required this.kind,
  });

  final String id;
  final List<String> exerciseNames;
  /// `gym` | `calisthenics`
  final String kind;

  String localizedName(AppLocalizations l10n) =>
      presetWorkoutLocalizedName(id, l10n);
}

String presetWorkoutLocalizedName(String id, AppLocalizations l10n) {
  switch (id) {
    case 'gym_push':
      return l10n.preset_push;
    case 'gym_pull':
      return l10n.preset_pull;
    case 'gym_abs':
      return l10n.preset_abs;
    case 'gym_chest_tri_shoulder':
      return l10n.preset_chestTriShoulder;
    case 'gym_back_biceps':
      return l10n.preset_backBiceps;
    case 'gym_legs_abs':
      return l10n.preset_legsAbs;
    case 'cali_back':
      return l10n.preset_caliBack;
    case 'cali_chest':
      return l10n.preset_caliChest;
    case 'cali_abs':
      return l10n.preset_caliAbs;
    case 'cali_legs':
      return l10n.preset_caliLegs;
    case 'cali_shoulders':
      return l10n.preset_caliShoulders;
    case 'cali_human_flag':
      return l10n.preset_caliHumanFlag;
    case 'cali_handstand':
      return l10n.preset_caliHandstand;
    case 'cali_planche':
      return l10n.preset_caliPlanche;
    default:
      return id;
  }
}

const List<PresetWorkoutTemplate> gymPresetWorkouts = [
  PresetWorkoutTemplate(
    id: 'gym_push',
    exerciseNames: [
      'Bankdrücken (Langhantel)',
      'Schrägbankdrücken (positiv)',
      'Schulterdrücken (Kurzhantel, sitzend)',
      'Seitheben (Kurzhantel)',
      'Trizepsdrücken (Kabel, Seil)',
      'Dips (enge Griffvariante)',
    ],
    kind: 'gym',
  ),
  PresetWorkoutTemplate(
    id: 'gym_pull',
    exerciseNames: [
      'Klimmzüge (weiter Griff)',
      'Latzug (weiter Griff)',
      'Langhantel-Rudern',
      'Kurzhantel-Rudern (einarmig)',
      'Kreuzheben (konventionell)',
      'Bizepscurls (Langhantel)',
    ],
    kind: 'gym',
  ),
  PresetWorkoutTemplate(
    id: 'gym_abs',
    exerciseNames: [
      'Kabelzug Crunches',
      'Leg Raises (hängend)',
      'Russian Twists (mit Gewicht)',
      'Ab Wheel Rollout',
      'Plank',
      'Pallof Press',
    ],
    kind: 'gym',
  ),
  PresetWorkoutTemplate(
    id: 'gym_chest_tri_shoulder',
    exerciseNames: [
      'Bankdrücken (Langhantel)',
      'Schrägbankdrücken (positiv)',
      'Pec Deck / Butterfly',
      'Schulterdrücken (Kurzhantel, sitzend)',
      'Seitheben (Kurzhantel)',
      'Trizepsdrücken (Kabel, Stange)',
      'Skull Crushers (EZ-Stange)',
    ],
    kind: 'gym',
  ),
  PresetWorkoutTemplate(
    id: 'gym_back_biceps',
    exerciseNames: [
      'Kreuzheben (konventionell)',
      'Langhantel-Rudern',
      'Latzug (enger Untergriff)',
      'T-Bar Rudern',
      'Face Pulls',
      'Bizepscurls (EZ-Stange)',
      'Hammer Curls',
    ],
    kind: 'gym',
  ),
  PresetWorkoutTemplate(
    id: 'gym_legs_abs',
    exerciseNames: [
      'Kniebeugen (Langhantel, High Bar)',
      'Beinpresse',
      'Romanian Deadlift',
      'Bein Curl (liegend)',
      'Wadenheben stehend (Maschine)',
      'Kabelzug Crunches',
      'Leg Raises (hängend)',
    ],
    kind: 'gym',
  ),
];

const List<PresetWorkoutTemplate> calisthenicsPresetWorkouts = [
  PresetWorkoutTemplate(
    id: 'cali_back',
    exerciseNames: [
      'Klimmzüge (Pull-Ups)',
      'Chin-Ups (Untergriff)',
      'Australische Klimmzüge (Inverted Rows)',
      'Scap Pull-Ups',
      'Archer Pull-Ups',
      'Dead Hang',
    ],
    kind: 'calisthenics',
  ),
  PresetWorkoutTemplate(
    id: 'cali_chest',
    exerciseNames: [
      'Liegestütze (Push-Ups)',
      'Decline Push-Ups',
      'Wide Push-Ups',
      'Dips (Barren)',
      'Diamond Push-Ups',
      'Archer Push-Ups',
    ],
    kind: 'calisthenics',
  ),
  PresetWorkoutTemplate(
    id: 'cali_abs',
    exerciseNames: [
      'Hanging Leg Raises',
      'Hanging Knee Raises',
      'Toes-to-Bar',
      'Hollow Body Hold',
      'Plank',
      'L-Sit (Barren)',
    ],
    kind: 'calisthenics',
  ),
  PresetWorkoutTemplate(
    id: 'cali_legs',
    exerciseNames: [
      'Bodyweight Squats',
      'Ausfallschritte (Walking Lunges)',
      'Pistol Squat (Assist)',
      'Wadenheben (einbeinig)',
      'Tibialis Raises',
      'Nordic Curl (Partner/Bar Fix)',
    ],
    kind: 'calisthenics',
  ),
  PresetWorkoutTemplate(
    id: 'cali_shoulders',
    exerciseNames: [
      'Pike Push-Ups',
      'Box Pike Push-Ups',
      'Pike Push-Up Negativ',
      'Handstand Hold (Wand)',
      'Wall Handstand (Bauch zur Wand)',
      'Negative Handstand Push-Up (Wand)',
    ],
    kind: 'calisthenics',
  ),
  PresetWorkoutTemplate(
    id: 'cali_human_flag',
    exerciseNames: [
      'Side Lever / Human Flag Vorstufen',
      'Active Hang',
      'Scap Pull-Ups',
      'Hollow Body Hold',
      'Side Plank',
      'Plank',
    ],
    kind: 'calisthenics',
  ),
  PresetWorkoutTemplate(
    id: 'cali_handstand',
    exerciseNames: [
      'Wall Walks',
      'Crow Pose (Frog Stand)',
      'Handstand Hold (Wand)',
      'Wall Handstand (Bauch zur Wand)',
      'Pike Push-Ups',
      'Negative Handstand Push-Up (Wand)',
    ],
    kind: 'calisthenics',
  ),
  PresetWorkoutTemplate(
    id: 'cali_planche',
    exerciseNames: [
      'Planche Lean',
      'Pseudo Planche Push-Ups',
      'Tuck Planche Hold',
      'Advanced Tuck Planche',
      'Pseudo Planche Dips (Barren)',
      'Plank',
    ],
    kind: 'calisthenics',
  ),
];

PresetWorkoutTemplate? findPresetWorkoutById(String id) {
  for (final p in gymPresetWorkouts) {
    if (p.id == id) return p;
  }
  for (final p in calisthenicsPresetWorkouts) {
    if (p.id == id) return p;
  }
  return null;
}

List<Map<String, dynamic>> resolvePresetWorkoutExercises(
  PresetWorkoutTemplate preset,
) {
  if (preset.kind == 'gym') {
    final catalog = {for (final e in gymCatalogExercises) e.name: e};
    return [
      for (final name in preset.exerciseNames)
        if (catalog.containsKey(name))
          StrengthExerciseConfig.applyDefaults({
            'name': catalog[name]!.name,
            'description': catalog[name]!.description,
            'mainGroup': catalog[name]!.mainGroup,
            'tags': catalog[name]!.tags,
          }),
    ];
  }

  final catalog = {for (final e in calisthenicsCatalogExercises) e.name: e};
  return [
    for (final name in preset.exerciseNames)
      if (catalog.containsKey(name))
        StrengthExerciseConfig.applyDefaults({
          'name': catalog[name]!.name,
          'description': catalog[name]!.description,
          'mainGroup': catalog[name]!.mainGroup,
          'tags': catalog[name]!.tags,
        }),
  ];
}
