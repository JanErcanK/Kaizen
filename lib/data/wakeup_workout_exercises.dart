import '../screens/workout_player_screen.dart';

/// Fixed full-body wake-up routine.
/// 7 s rest between every exercise (set via WorkoutPlayerScreen restSeconds).
/// Bilateral exercises are split into (Links) / (Rechts) entries so the
/// player counts down each side separately.
const List<WorkoutExercise> wakeupWorkoutExercises = [
  // 1 — Hampelmann
  WorkoutExercise(
    name: 'Hampelmann',
    benefit: 'Arme und Beine koordiniert bewegen. Gleichmäßig atmen und die Bewegung kontrolliert ausführen.',
    workSeconds: 30,
  ),
  // 2 — Deep Squat Hold
  WorkoutExercise(
    name: 'Deep Squat Hold',
    benefit: 'Tief in die Hocke gehen und Fersen auf dem Boden halten. Hüfte öffnen und aufrecht bleiben.',
    workSeconds: 60,
  ),
  // 3 — World's Greatest Stretch (Links)
  WorkoutExercise(
    name: "World's Greatest Stretch (Links)",
    benefit: 'Großer Ausfallschritt nach vorne, Ellenbogen zum Boden führen, dann Arm in die Höhe drehen. Hüfte und Brustwirbelsäule mobilisieren.',
    workSeconds: 20,
  ),
  // 3 — World's Greatest Stretch (Rechts)
  WorkoutExercise(
    name: "World's Greatest Stretch (Rechts)",
    benefit: 'Seite wechseln. Gleiche Bewegung: Ausfallschritt, Ellenbogen runter, Rotation nach oben.',
    workSeconds: 20,
  ),
  // 4 — Wall Sit
  WorkoutExercise(
    name: 'Wall Sit',
    benefit: 'Rücken flach an die Wand, Knie 90°, Oberschenkel parallel zum Boden. Spannung halten und ruhig atmen.',
    workSeconds: 60,
  ),
  // 5 — Liegestütze
  WorkoutExercise(
    name: 'Liegestütze',
    benefit: 'Körper gerade wie ein Brett. Brust zum Boden, Ellenbogen nah am Körper oder leicht ausgestellt. Kontrolliert drücken.',
    workSeconds: 30,
  ),
  // 6 — Tibialis Raises
  WorkoutExercise(
    name: 'Tibialis Raises',
    benefit: 'Rücken an die Wand, Füße schulterbreit. Zehenspitzen so weit wie möglich nach oben ziehen. Stärkt den Schienbeinmuskel.',
    workSeconds: 30,
  ),
  // 7 — Poliquin Step-Ups (Links)
  WorkoutExercise(
    name: 'Poliquin Step-Ups (Links)',
    benefit: 'Linkes Bein auf eine kleine Erhöhung, langsam auf der Ferse absenken ohne Ferse den Boden zu berühren. Knie stabil halten.',
    workSeconds: 20,
  ),
  // 7 — Poliquin Step-Ups (Rechts)
  WorkoutExercise(
    name: 'Poliquin Step-Ups (Rechts)',
    benefit: 'Rechtes Bein auf die Erhöhung. Gleiche Bewegung, Knie über der Fußmitte halten.',
    workSeconds: 20,
  ),
  // 8 — Waden Raises im Sitzen (Links)
  WorkoutExercise(
    name: 'Waden Raises im Sitzen (Links)',
    benefit: 'Im Sitzen das linke Bein aufstellen und die Ferse langsam heben und senken. Soleus-Muskel gezielt trainieren.',
    workSeconds: 20,
  ),
  // 8 — Waden Raises im Sitzen (Rechts)
  WorkoutExercise(
    name: 'Waden Raises im Sitzen (Rechts)',
    benefit: 'Seite wechseln. Rechtes Bein aufstellen und Ferse rhythmisch heben.',
    workSeconds: 20,
  ),
  // 9 — Seitliche Squats
  WorkoutExercise(
    name: 'Seitliche Squats',
    benefit: 'Breite Grätsche, abwechselnd zu einer Seite absinken. Knie über die Fußspitze, Rücken gerade. Innenschenkel dehnen.',
    workSeconds: 60,
  ),
  // 10 — Stuhl Step-Ups
  WorkoutExercise(
    name: 'Stuhl Step-Ups',
    benefit: 'Abwechselnd auf einen Stuhl oder eine Erhöhung steigen. Standfuß aktiv drücken, Oberkörper aufrecht halten.',
    workSeconds: 30,
  ),
  // 11 — Seitliche Unterarmstütze (Links)
  WorkoutExercise(
    name: 'Seitliche Unterarmstütze (Links)',
    benefit: 'Linke Seite: Unterarm auf dem Boden, Körper in einer Linie. Hüfte nicht absacken. Seitrumpf aktivieren.',
    workSeconds: 30,
  ),
  // 11 — Seitliche Unterarmstütze (Rechts)
  WorkoutExercise(
    name: 'Seitliche Unterarmstütze (Rechts)',
    benefit: 'Rechte Seite: Unterarm auf dem Boden, Hüfte hoch. Körper gerade halten und Kern anspannen.',
    workSeconds: 30,
  ),
  // 12 — Cobra zu Brücke
  WorkoutExercise(
    name: 'Cobra zu Brücke',
    benefit: 'Aus der Bauchlage in die Kobra (Schultern heben), dann in den herabschauenden Hund oder Brücke wechseln. Wirbelsäule mobilisieren.',
    workSeconds: 60,
  ),
  // 13 — Knie Strecker
  WorkoutExercise(
    name: 'Knie Strecker',
    benefit: 'Im Sitzen oder Stehen das Knie langsam strecken und halten. Quadrizeps und Kniestabilität stärken.',
    workSeconds: 30,
  ),
  // 14 — Bauchrolle
  WorkoutExercise(
    name: 'Bauchrolle',
    benefit: 'Ab-Roller oder Unterarmen auf dem Boden: langsam nach vorne rollen, Kern stark anspannen, kontrolliert zurückziehen.',
    workSeconds: 30,
  ),
  // 15 — Wall Angel
  WorkoutExercise(
    name: 'Wall Angel',
    benefit: 'Rücken und Arme flach an der Wand, Arme langsam nach oben und unten gleiten. Schulterblätter zusammenziehen. Haltung verbessern.',
    workSeconds: 30,
  ),
  // 16 — Handstand-Liegestütze
  WorkoutExercise(
    name: 'Handstand-Liegestütze',
    benefit: 'Gegen die Wand oder frei: Körper über den Händen halten und Ellenbogen beugen. Schultern und Trizeps maximal fordern.',
    workSeconds: 30,
  ),
  // 17 — Pigeon Stretch (Links)
  WorkoutExercise(
    name: 'Pigeon Stretch (Links)',
    benefit: 'Linkes Bein nach vorne legen (wie Taube), Hüfte Richtung Boden sinken lassen. Piriformis und Hüftbeuger tief dehnen.',
    workSeconds: 60,
  ),
  // 17 — Pigeon Stretch (Rechts)
  WorkoutExercise(
    name: 'Pigeon Stretch (Rechts)',
    benefit: 'Seite wechseln. Rechtes Bein nach vorne, Hüfte absenken. Ruhig atmen und in die Dehnung entspannen.',
    workSeconds: 60,
  ),
  // 18 — Couch Stretch (Links)
  WorkoutExercise(
    name: 'Couch Stretch (Links)',
    benefit: 'Linkes Knie an die Wand oder Stuhl, Oberschenkel senkrecht. Hüftbeuger und Quadrizeps intensiv dehnen.',
    workSeconds: 60,
  ),
  // 18 — Couch Stretch (Rechts)
  WorkoutExercise(
    name: 'Couch Stretch (Rechts)',
    benefit: 'Rechte Seite: Knie an die Wand, Hüfte nach vorne schieben. Tiefe Dehnung des vorderen Oberschenkels.',
    workSeconds: 60,
  ),
  // 19 — Toe Touch
  WorkoutExercise(
    name: 'Toe Touch',
    benefit: 'Beine gestreckt, langsam nach unten beugen und Zehen berühren. Ischiasmuskulatur und hintere Oberschenkelkette dehnen.',
    workSeconds: 60,
  ),
  // 20 — Wirbelsäule Drehen (Links)
  WorkoutExercise(
    name: 'Wirbelsäule Drehen (Links)',
    benefit: 'Im Sitzen oder Liegen: Rumpf nach links drehen, Schulter zur gegenüberliegenden Seite. Wirbelsäulenmobilität verbessern.',
    workSeconds: 20,
  ),
  // 20 — Wirbelsäule Drehen (Rechts)
  WorkoutExercise(
    name: 'Wirbelsäule Drehen (Rechts)',
    benefit: 'Seite wechseln. Rumpf nach rechts drehen, Schultern tief, gleichmäßig atmen.',
    workSeconds: 20,
  ),
];
