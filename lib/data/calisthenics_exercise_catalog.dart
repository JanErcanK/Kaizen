// Calisthenics exercise catalog.

class CalisthenicsCatalogExercise {
  const CalisthenicsCatalogExercise({
    required this.name,
    required this.description,
    required this.mainGroup,
    required this.tags,
  });

  final String name;
  final String description;
  final String mainGroup;
  final List<String> tags;
}

const List<CalisthenicsCatalogExercise> calisthenicsCatalogExercises = [
  // Rücken
  CalisthenicsCatalogExercise(
    name: 'Klimmzüge (Pull-Ups)',
    description:
        'Brust Richtung Stange, Schulterblätter zuerst nach unten/hinten ziehen. Kein Schwingen.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'Unterarme', 'Nacken'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Chin-Ups (Untergriff)',
    description: 'Untergriff betont Bizeps. Körper stabil, kontrollierte Wiederholungen.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'Unterarme'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Australische Klimmzüge (Inverted Rows)',
    description:
        'Unter der Stange ziehen. Füße weiter vor = schwerer. Sehr gut für Rückendichte.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'hintere Schulter', 'Bizeps'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Muscle-Up (Strict / Assist)',
    description:
        'Explosiver Zug + Übergang über die Stange. Erst Pull-Ups + Dips stark machen.',
    mainGroup: 'Rücken',
    tags: [
      'oberer Rücken',
      'Bizeps',
      'Brust',
      'Trizeps',
      'Schultern',
      'Skill:Muscle Up',
    ],
  ),
  CalisthenicsCatalogExercise(
    name: 'Scap Pull-Ups',
    description:
        'Nur Schulterblätter bewegen: aus dem Hang Schulterblätter runterziehen, Arme gestreckt.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Nacken', 'hintere Schulter'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Dead Hang',
    description:
        'An der Stange hängen so lange wie möglich. Griffkraft + Schulterdekompression.',
    mainGroup: 'Unterarme',
    tags: ['Unterarme', 'oberer Rücken'],
  ),

  CalisthenicsCatalogExercise(
    name: 'Burpees',
    description:
        'Aus dem Stand in den Stütz springen, einen Liegestütz machen, die Füße vorholen und nach oben springen.',
    mainGroup: 'Brust',
    tags: ['Waden', 'Quadrizeps', 'Trizeps', 'Bauch', 'vordere Schulter'],
  ),

  // Brust / Trizeps
  CalisthenicsCatalogExercise(
    name: 'Dips (Barren)',
    description:
        'Leicht nach vorne für Brust-Fokus. Volle Tiefe nur schmerzfrei und kontrolliert.',
    mainGroup: 'Brust',
    tags: ['untere Brust', 'Trizeps', 'vordere Schulter', 'Skill:Muscle Up'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Liegestütze (Push-Ups)',
    description: 'Körper in Linie, Core fest. Brust bis kurz vor den Boden, sauber drücken.',
    mainGroup: 'Brust',
    tags: ['mittlere Brust', 'Trizeps', 'vordere Schulter', 'Bauch'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Liegestütze mit Drehung',
    description:
        'Liegestütz, oben in den Seitstütz drehen und den Arm zur Decke strecken (T-Push-Up).',
    mainGroup: 'Brust',
    tags: ['mittlere Brust', 'Trizeps', 'vordere Schulter', 'schräge Bauchmuskeln'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Decline Push-Ups',
    description: 'Füße erhöht. Mehr Last auf obere Brust und vordere Schulter.',
    mainGroup: 'Brust',
    tags: ['obere Brust', 'vordere Schulter', 'Trizeps'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Diamond Push-Ups',
    description: 'Hände eng. Sehr trizepslastig, Ellbogen nah am Körper.',
    mainGroup: 'Trizeps',
    tags: ['Trizeps', 'kleiner Trizepskopf', 'Brust'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Bench Dips',
    description: 'Auf Bank/Barre abstützen. Vorsicht Schulter – kontrolliert und schmerzfrei.',
    mainGroup: 'Trizeps',
    tags: ['Trizeps', 'großer Trizepskopf', 'kleiner Trizepskopf'],
  ),

  // Schultern
  CalisthenicsCatalogExercise(
    name: 'Pike Push-Ups',
    description: 'Hüfte hoch, Kopf Richtung Boden. Sehr guter Schulterdrück-Ersatz.',
    mainGroup: 'Schultern',
    tags: ['vordere Schulter', 'mittlere Schulter', 'Trizeps', 'Skill:Handstand'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Wall Angels',
    description:
        'Rücken, Kopf und Arme an der Wand. Ellbogen 90°, Arme kontrolliert nach oben und unten schieben.',
    mainGroup: 'Schultern',
    tags: ['hintere Schulter', 'oberer Rücken', 'Nacken'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Handstand Hold (Wand)',
    description: 'Stabil an der Wand halten. Fokus auf Core-Spannung und Schulter-Stack.',
    mainGroup: 'Schultern',
    tags: ['Schultern', 'Bauch', 'unterer Rücken', 'Skill:Handstand'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Handstand Push-Ups (Wand / Negativ)',
    description: 'Nur so tief wie kontrolliert. Alternative: Negative langsam ablassen.',
    mainGroup: 'Schultern',
    tags: [
      'vordere Schulter',
      'mittlere Schulter',
      'Trizeps',
      'Bauch',
      'Skill:Handstand',
    ],
  ),
  CalisthenicsCatalogExercise(
    name: 'Handstand Push-Ups (frei)',
    description:
        'Ohne Wand: freier Handstand-Liegestütz. Nur mit stabilem freiem Handstand.',
    mainGroup: 'Schultern',
    tags: [
      'vordere Schulter',
      'Trizeps',
      'Bauch',
      'Skill:Handstand',
    ],
  ),

  // Skills (park-appropriate progressions)
  CalisthenicsCatalogExercise(
    name: 'Planche Lean',
    description:
        'Auf dem Boden: Schultern weit nach vorne schieben, Arme gestreckt, Scapula proträhiert.',
    mainGroup: 'Schultern',
    tags: ['vordere Schulter', 'Bauch', 'Unterarme', 'Skill:Planche'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Tuck Front Lever Hold',
    description:
        'An der Stange: Knie zur Brust (Tuck), Schulterblätter depress/retract. Kurz halten.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bauch', 'Bizeps', 'Unterarme', 'Skill:Front Lever'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Front Lever Raises (Tuck)',
    description:
        'Aus dem Hang in eine Tuck-Front-Lever Position hochziehen. Kontrolle vor Range.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bauch', 'Bizeps', 'Unterarme', 'Skill:Front Lever'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Skin the Cat',
    description:
        'An der Stange: kontrolliert durchdrehen, Schultern warm! Stark für Lever-Skills.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Schultern', 'Bauch', 'Unterarme', 'Skill:Back Lever'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Tuck Back Lever Hold',
    description:
        'Aus Skin-the-Cat in Tuck-Back-Lever halten. Nur schmerzfrei, Schulterposition stabil.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Schultern', 'Bauch', 'Unterarme', 'Skill:Back Lever'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Straddle Front Lever Hold',
    description:
        'Beine gespreizt, horizontal. Zwischen Advanced Tuck und Full Front Lever.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bauch', 'Bizeps', 'Skill:Front Lever'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Full Front Lever Hold',
    description:
        'Gestreckter Körper horizontal unter der Stange. Elite-Rücken- und Core-Skill.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bauch', 'Bizeps', 'Unterarme', 'Skill:Front Lever'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Straddle Back Lever Hold',
    description:
        'Bauchlage unter der Stange, Beine gespreizt horizontal. Schultern vorbereiten.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Schultern', 'Skill:Back Lever'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Full Back Lever Hold',
    description:
        'Gestreckter Körper horizontal unter der Stange (Bauchlage). Fortgeschritten.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Schultern', 'Bauch', 'Skill:Back Lever'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Straddle Planche Hold',
    description:
        'Beine gespreizt vom Boden, Schultern weit vorne. Stufe nach Advanced Tuck.',
    mainGroup: 'Schultern',
    tags: ['vordere Schulter', 'Bauch', 'Unterarme', 'Skill:Planche'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Full Planche Hold',
    description:
        'Gestreckter Körper parallel zum Boden. Einer der härtesten Calisthenics-Skills.',
    mainGroup: 'Schultern',
    tags: ['vordere Schulter', 'Bauch', 'Unterarme', 'Skill:Planche'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Human Flag Hold',
    description:
        'Seitlich an Stange/Pfosten, Körper horizontal. Seitliche Core- und Schulterkraft.',
    mainGroup: 'Schultern',
    tags: ['Schultern', 'schräge Bauchmuskeln', 'oberer Rücken'],
  ),

  // Bauch / Core
  CalisthenicsCatalogExercise(
    name: 'Hanging Knee Raises',
    description: 'Im Hang Knie anheben. Unterer Bauch + Hüftbeuger. Ohne Schwung.',
    mainGroup: 'Bauch',
    tags: ['untere Bauchmuskeln', 'Bauch'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Hanging Leg Raises',
    description: 'Gestreckte Beine heben. Sehr intensiv für unteren Bauch. Langsam ablassen.',
    mainGroup: 'Bauch',
    tags: ['untere Bauchmuskeln', 'Bauch'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Hanging Side Knee Raises',
    description:
        'Im Hang Knie seitlich zur Brust. Schräge Bauchmuskeln und Hüftbeuger.',
    mainGroup: 'Bauch',
    tags: ['schräge Bauchmuskeln', 'untere Bauchmuskeln'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Hanging Side Leg Raises',
    description:
        'Im Hang gestrecktes Bein seitlich heben. Sehr anspruchsvoll für die Obliques.',
    mainGroup: 'Bauch',
    tags: ['schräge Bauchmuskeln', 'Hüftbeuger'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Toes-to-Bar',
    description: 'Fortgeschritten: Füße zur Stange. Core maximal, sauber ohne Kipping.',
    mainGroup: 'Bauch',
    tags: ['untere Bauchmuskeln', 'obere Bauchmuskeln', 'Unterarme'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Plank',
    description: 'Unterarme am Boden, Körper in Linie, Bauch fest. Ruhig atmen.',
    mainGroup: 'Bauch',
    tags: ['Bauch', 'obere Bauchmuskeln', 'untere Bauchmuskeln'],
  ),
  CalisthenicsCatalogExercise(
    name: 'L-Sit (Barren)',
    description: 'Auf dem Barren halten, Beine gestreckt. Sehr starker Core + Hüftbeuger.',
    mainGroup: 'Bauch',
    tags: ['untere Bauchmuskeln', 'Unterarme', 'Schultern'],
  ),
  CalisthenicsCatalogExercise(
    name: 'L-Sit-zu-Brücke (dynamisch)',
    description:
        'Aus dem L-Sit Hüfte nach oben in die Reverse Plank und kontrolliert wieder runter. Rauf und runter.',
    mainGroup: 'Bauch',
    tags: ['Bauch', 'Hintern', 'hinterer Oberschenkel', 'vordere Schulter'],
  ),
  CalisthenicsCatalogExercise(
    name: 'V-Sit Hold',
    description:
        'Sitzend Beine und Oberkörper im V halten. Hüftbeuger und unterer Bauch.',
    mainGroup: 'Bauch',
    tags: ['untere Bauchmuskeln', 'Hüftbeuger', 'obere Bauchmuskeln'],
  ),

  // Beine
  CalisthenicsCatalogExercise(
    name: 'Bodyweight Squats',
    description: 'Saubere Tiefe, Knie stabil. Ideal als Basis für Sprünge und Pistols.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'Knie'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Ausfallschritte (Walking Lunges)',
    description: 'Großer Schritt, Oberkörper aufrecht. Stabilität + Po/Beine.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'hinterer Oberschenkel', 'Knie'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Pistol Squat (Assist)',
    description: 'Einbeinige Kniebeuge mit Support (Pfosten/Barre). Kontrolliert, Knie ausrichten.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'Knie', 'Fuß'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Nordic Curl (Partner/Bar Fix)',
    description: 'Oberschenkelrückseite brutal effektiv. Nur so weit ablassen wie kontrolliert.',
    mainGroup: 'Beine',
    tags: ['hinterer Oberschenkel', 'Hintern', 'Knie'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Wadenheben (einbeinig)',
    description: 'Volle Streckung und maximal ablassen. Langsam für saubere Spannung.',
    mainGroup: 'Beine',
    tags: ['Waden', 'Fuß'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Tibialis Raises',
    description: 'Ferse am Boden, Zehen hochziehen. Stärkt Schienbein und unterstützt das Knie.',
    mainGroup: 'Beine',
    tags: ['Schienbein', 'Knie', 'Fuß'],
  ),

  // ── Rücken (zusätzliche Klimmzug-Varianten) ─────────────────────────────────
  CalisthenicsCatalogExercise(
    name: 'Klimmzüge mit weitem Griff (Wide Pull-Ups)',
    description:
        'Hände deutlich breiter als schulterbreit. Mehr Lats, weniger Bizepshilfe.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'breiter Rücken', 'hintere Schulter'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Klimmzüge mit engem Griff (Hammergriff)',
    description:
        'Hände eng, parallele Stange wenn möglich. Sehr armlastig (Brachialis, Bizeps).',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'Brachialis', 'Unterarme'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Commando Pull-Ups',
    description:
        'Über/Untergriff im Wechsel, Kopf links/rechts der Stange. Stark für Schulterstabilität.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'Bauch', 'Schultern'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Archer Pull-Ups',
    description:
        'Ein Arm zieht, anderer bleibt gestreckt. Zentrale Stufe zum One-Arm Pull-Up.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'Bauch'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Typewriter Pull-Ups',
    description:
        'Oben angekommen seitlich von einer Seite zur anderen wandern. Sehr intensiv.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'Bauch', 'Schultern'],
  ),
  CalisthenicsCatalogExercise(
    name: 'L-Sit Pull-Ups',
    description:
        'Klimmzüge mit gestreckten, waagerechten Beinen. Brutal für Core + Lats.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'untere Bauchmuskeln', 'Hüftbeuger'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Chest-to-Bar Pull-Ups',
    description:
        'Brustbein berührt die Stange. Mehr Rückenkraft + Scapula-Retraktion.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'hintere Schulter'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Negative Pull-Ups',
    description:
        'Hochspringen/klettern, dann 3–5 s langsam ablassen. Klassischer Aufbau zum Pull-Up.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'Unterarme'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Assistierte Klimmzüge (Band/Fuß)',
    description:
        'Mit Band oder Fuß auf niedriger Stange unterstützen. Saubere Technik zuerst.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Active Hang',
    description:
        'Aktiv hängend: Schulterblätter nach unten, Brust raus. Basis für jeden Pull.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Schultern', 'Unterarme'],
  ),
  CalisthenicsCatalogExercise(
    name: 'One-Arm Pull-Up Negativ',
    description:
        'Beidarmig hoch, einarmig 3–5 s ablassen. Härteste sinnvolle Stufe vor dem OAP.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'Unterarme', 'Bauch'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Klimmzüge mit engem Griff (Close Grip)',
    description:
        'Hände schulterbreit oder enger, Obergriff. Mehr Unterarm- und Bizepsanteil.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'Unterarme'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Klimmzüge in den Nacken',
    description:
        'Stange hinter dem Kopf berühren. Nur schmerzfrei – hohe Schulterbelastung.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'hintere Schulter', 'Nacken'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Klimmzüge mit Klatschen (Clapping)',
    description:
        'Explosiv hoch, kurz loslassen und in der Luft klatschen. Fortgeschritten.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'Unterarme'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Einarmiger Klimmzug',
    description:
        'Streng einarmig ziehen. Jahre Vorbereitung: Archer, Negativ, Griffkraft.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'Unterarme', 'Bauch'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Assistierte Einarm-Klimmzüge',
    description:
        'Ein Arm zieht, andere Hand am Unterarm oder Band. Kontrollierte Progression.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'Unterarme'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Isometrisches Halten oben (Klimmzug)',
    description:
        'Kinn über die Stange halten, 10–30 s. Maximale Spannung im oberen Rücken.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'Unterarme'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Klimmzüge am Handtuch',
    description:
        'Handtuch über die Stange, je Hand ein Ende. Extrem griffintensiv.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'Unterarme'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Wide Inverted Row',
    description:
        'Australische Klimmzüge mit weitem Griff. Stärkerer Lats-Akzent.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'breiter Rücken', 'hintere Schulter'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Archer Inverted Row',
    description:
        'Australische Klimmzüge mit Schwerpunkt auf einem Arm. Aufbau zum One-Arm Row.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'hintere Schulter'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Bar Bicep Curls (an niedriger Stange)',
    description:
        'Unter niedriger Stange in Untergriff stehen, Körper als Hebel hochziehen.',
    mainGroup: 'Bizeps',
    tags: ['Bizeps', 'Unterarme'],
  ),

  // ── Brust (zusätzliche Liegestütz-Varianten) ────────────────────────────────
  CalisthenicsCatalogExercise(
    name: 'Wide Push-Ups',
    description:
        'Hände deutlich breiter als die Schultern. Mehr Brust-Stretch, weniger Trizeps.',
    mainGroup: 'Brust',
    tags: ['mittlere Brust', 'vordere Schulter'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Close Push-Ups',
    description:
        'Hände schulterbreit oder enger, Ellbogen am Körper. Trizeps + Brustinnenseite.',
    mainGroup: 'Brust',
    tags: ['mittlere Brust', 'Trizeps'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Archer Push-Ups',
    description:
        'Ein Arm gestreckt, anderer drückt. Wichtige Stufe zum One-Arm Push-Up.',
    mainGroup: 'Brust',
    tags: ['mittlere Brust', 'Trizeps', 'Bauch'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Typewriter Push-Ups',
    description:
        'Unten von einer Seite zur anderen wandern. Starker Stretch + Stabilität.',
    mainGroup: 'Brust',
    tags: ['Brust', 'Trizeps', 'Schultern', 'Bauch'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Pseudo Planche Push-Ups',
    description:
        'Hände auf Hüfthöhe, Schultern weit über die Hände schieben. Planche-spezifisch.',
    mainGroup: 'Brust',
    tags: [
      'untere Brust',
      'vordere Schulter',
      'Trizeps',
      'Bauch',
      'Skill:Planche',
    ],
  ),
  CalisthenicsCatalogExercise(
    name: 'Hindu Push-Ups',
    description:
        'Bogen-Bewegung: aus Downward Dog durchschweben in Cobra. Dynamisch + Mobility.',
    mainGroup: 'Brust',
    tags: ['Brust', 'Schultern', 'Trizeps', 'unterer Rücken'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Plyometrische Push-Ups (Clap)',
    description:
        'Explosiv abdrücken, Hände vom Boden – mit oder ohne Klatschen. Schnellkraft.',
    mainGroup: 'Brust',
    tags: ['mittlere Brust', 'Trizeps', 'vordere Schulter'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Finger-Liegestütze',
    description:
        'Auf Fingerspitzen. Nur mit starker Hand-/Unterarmbasis – langsam steigern.',
    mainGroup: 'Brust',
    tags: ['Brust', 'Trizeps', 'Unterarme', 'Finger'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Superman Push-Ups',
    description:
        'Beim Hochdrücken Hände und Füße kurz vom Boden. Explosiv und core-lastig.',
    mainGroup: 'Brust',
    tags: ['Brust', 'Trizeps', 'unterer Rücken', 'Bauch'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Staggered Push-Ups',
    description:
        'Eine Hand weiter vorne, eine weiter hinten. Pro Satz oder Wdh. wechseln.',
    mainGroup: 'Brust',
    tags: ['mittlere Brust', 'Trizeps', 'Bauch'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Deficit Push-Ups',
    description:
        'Hände auf Parallettes für mehr ROM. Tiefer unten, stärker Brust und Trizeps.',
    mainGroup: 'Brust',
    tags: ['mittlere Brust', 'untere Brust', 'Trizeps'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Klatschen hinter dem Rücken (Push-Up)',
    description:
        'Explosiv hoch, Klatschen hinter dem Rücken. Sehr fortgeschritten.',
    mainGroup: 'Brust',
    tags: ['Brust', 'Trizeps', 'Schultern'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Spider-Man Push-Ups',
    description:
        'Beim Ablassen wechselnd Knie zum Ellbogen ziehen. Core + schräge Bauchmuskeln.',
    mainGroup: 'Brust',
    tags: ['Brust', 'Trizeps', 'schräge Bauchmuskeln'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Incline Push-Ups (Hände erhöht)',
    description:
        'Hände auf Bank/Stange. Leichtere Variante – idealer Einstieg.',
    mainGroup: 'Brust',
    tags: ['untere Brust', 'mittlere Brust', 'vordere Schulter', 'Trizeps'],
  ),
  CalisthenicsCatalogExercise(
    name: 'One-Arm Push-Up (Elevated)',
    description:
        'Einarmig auf erhöhter Stange/Bank. Erste Stufe zum vollen One-Arm Push-Up.',
    mainGroup: 'Brust',
    tags: ['Brust', 'Trizeps', 'vordere Schulter', 'schräge Bauchmuskeln'],
  ),
  CalisthenicsCatalogExercise(
    name: 'One-Arm Push-Up (Boden)',
    description:
        'Einarmig am Boden, Beine breit für Stabilität. Sehr fortgeschritten.',
    mainGroup: 'Brust',
    tags: ['Brust', 'Trizeps', 'vordere Schulter', 'schräge Bauchmuskeln'],
  ),

  // ── Trizeps / Dip-Varianten ────────────────────────────────────────────────
  CalisthenicsCatalogExercise(
    name: 'Korean Dips',
    description:
        'Auf hoher Stange/Pfosten, Körper hinter den Händen. Maximaler Brust-Stretch.',
    mainGroup: 'Trizeps',
    tags: ['untere Brust', 'Trizeps', 'vordere Schulter'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Russian Dips',
    description:
        'Aus Dip-Tiefe Unterarme auf Barren ablegen, dann zurückdrücken. Sehr trizepsintensiv.',
    mainGroup: 'Trizeps',
    tags: ['Trizeps', 'untere Brust', 'vordere Schulter'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Straight Bar Dips',
    description:
        'An einer Stange (statt Barren). Körper über die Stange drücken. Brustlastig.',
    mainGroup: 'Trizeps',
    tags: ['untere Brust', 'Trizeps', 'vordere Schulter', 'Skill:Muscle Up'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Pseudo Planche Dips (Barren)',
    description:
        'Barren-Dips, dabei Schultern weit nach vorne über die Hände. Sehr schulterlastig.',
    mainGroup: 'Schultern',
    tags: [
      'vordere Schulter',
      'Trizeps',
      'untere Brust',
      'Skill:Planche',
    ],
  ),
  CalisthenicsCatalogExercise(
    name: 'Bulgarian Dips (tief)',
    description:
        'Barren-Dips so tief wie sauber. Großer ROM – nur schmerzfrei machen.',
    mainGroup: 'Trizeps',
    tags: ['Trizeps', 'untere Brust', 'vordere Schulter'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Bench Triceps Extension (Stange)',
    description:
        'Hände auf niedriger Stange, Körper schräg, Stirn zur Stange senken (Skull-Crusher-Style).',
    mainGroup: 'Trizeps',
    tags: ['Trizeps', 'großer Trizepskopf', 'kleiner Trizepskopf'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Ring Dips',
    description:
        'An Gymnastikringen. Instabil – Schultern stabil, volle Tiefe nur kontrolliert.',
    mainGroup: 'Trizeps',
    tags: ['Trizeps', 'Brust', 'Schultern', 'Unterarme'],
  ),
  CalisthenicsCatalogExercise(
    name: 'L-Sit Dips',
    description:
        'Dips mit gestreckten Beinen waagerecht. Core und Trizeps maximal.',
    mainGroup: 'Trizeps',
    tags: ['Trizeps', 'untere Bauchmuskeln', 'Hüftbeuger'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Sprung-Dips (Jumping Dips)',
    description:
        'Mit leichtem Schwung nach oben, oben kurz halten. Aufbau zu strengen Dips.',
    mainGroup: 'Trizeps',
    tags: ['Trizeps', 'Brust', 'vordere Schulter'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Negative Dips',
    description:
        'Oben einsteigen, 3–5 s langsam absenken. Sehr gut zum Dip-Aufbau.',
    mainGroup: 'Trizeps',
    tags: ['Trizeps', 'Brust', 'Schultern'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Weighted Dips (Zusatzgewicht)',
    description:
        'Gewichtsgürtel oder Weste. Nur bei sauberer Technik und schmerzfreien Schultern.',
    mainGroup: 'Trizeps',
    tags: ['Trizeps', 'Brust', 'vordere Schulter'],
  ),

  // ── Schultern / Handstand-Vorstufen ────────────────────────────────────────
  CalisthenicsCatalogExercise(
    name: 'Box Pike Push-Ups',
    description:
        'Pike Push-Ups mit Füßen erhöht (Bank/Pfosten). Fast vertikaler Druck.',
    mainGroup: 'Schultern',
    tags: [
      'vordere Schulter',
      'mittlere Schulter',
      'Trizeps',
      'Skill:Handstand',
    ],
  ),
  CalisthenicsCatalogExercise(
    name: 'Pike Push-Up Negativ',
    description:
        'Pike Push-Up, in 3–5 s ablassen. Mehr Zeit unter Spannung für die Schultern.',
    mainGroup: 'Schultern',
    tags: [
      'vordere Schulter',
      'mittlere Schulter',
      'Trizeps',
      'Skill:Handstand',
    ],
  ),
  CalisthenicsCatalogExercise(
    name: 'Crow Pose (Frog Stand)',
    description:
        'Knie auf Trizeps, Balance auf den Händen. Basis für Handstand und Planche.',
    mainGroup: 'Schultern',
    tags: [
      'Schultern',
      'Bauch',
      'Unterarme',
      'Skill:Handstand',
      'Skill:Planche',
    ],
  ),
  CalisthenicsCatalogExercise(
    name: 'Wall Walks',
    description:
        'In Liegestütz starten, Füße die Wand hochlaufen, Hände nach hinten. Mobility + Kraft.',
    mainGroup: 'Schultern',
    tags: ['Schultern', 'Bauch', 'unterer Rücken', 'Skill:Handstand'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Wall Handstand (Bauch zur Wand)',
    description:
        'Handstand mit Bauch zur Wand. Korrigiert die Linie – Hüfte und Schultern stapeln.',
    mainGroup: 'Schultern',
    tags: ['Schultern', 'Bauch', 'unterer Rücken', 'Skill:Handstand'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Negative Handstand Push-Up (Wand)',
    description:
        'Aus dem Wall-Handstand 3–5 s ablassen, dann wieder hochlaufen. Brutal effektiv.',
    mainGroup: 'Schultern',
    tags: [
      'vordere Schulter',
      'mittlere Schulter',
      'Trizeps',
      'Bauch',
      'Skill:Handstand',
    ],
  ),
  CalisthenicsCatalogExercise(
    name: 'Tuck Planche Hold',
    description:
        'Aus Planche-Lean Knie an Brust ziehen, Füße vom Boden. Schultern nach vorne.',
    mainGroup: 'Schultern',
    tags: ['vordere Schulter', 'Bauch', 'Unterarme', 'Skill:Planche'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Advanced Tuck Planche',
    description:
        'Tuck Planche, aber Rücken flach (kein Banana-Back). Nächste Stufe zum Straddle.',
    mainGroup: 'Schultern',
    tags: ['vordere Schulter', 'Bauch', 'Unterarme', 'Skill:Planche'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Side Lever / Human Flag Vorstufen',
    description:
        'Vertikale Stange seitlich greifen, Tuck-Variante anheben. Schultern + Core seitlich.',
    mainGroup: 'Schultern',
    tags: [
      'Schultern',
      'breiter Rücken',
      'schräge Bauchmuskeln',
      'Bauch',
    ],
  ),
  CalisthenicsCatalogExercise(
    name: 'Schulter-Dislokationen (Stab/Tuch)',
    description:
        'Mit Stab oder Handtuch über Kopf von vorne nach hinten kreisen. Schultermobilität.',
    mainGroup: 'Schultern',
    tags: ['Schultern', 'Brust'],
  ),

  // ── Bauch / Core ───────────────────────────────────────────────────────────
  CalisthenicsCatalogExercise(
    name: 'Hollow Body Hold',
    description:
        'Rückenlage, unterer Rücken am Boden, Arme/Beine angehoben. Foundation für alle Skills.',
    mainGroup: 'Bauch',
    tags: ['obere Bauchmuskeln', 'untere Bauchmuskeln', 'Hüftbeuger'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Hollow Body Rock',
    description:
        'Hollow Hold mit kleiner Schaukelbewegung. Spannung dynamisch trainieren.',
    mainGroup: 'Bauch',
    tags: ['obere Bauchmuskeln', 'untere Bauchmuskeln', 'Hüftbeuger'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Superman Hold (Arch)',
    description:
        'Bauchlage, Arme + Beine anheben. Gegenstück zum Hollow Body – Rückenkette.',
    mainGroup: 'Bauch',
    tags: ['unterer Rücken', 'Hintern', 'hinterer Oberschenkel'],
  ),
  CalisthenicsCatalogExercise(
    name: 'V-Ups',
    description:
        'Aus Rückenlage Beine und Oberkörper gleichzeitig zum V zusammenführen.',
    mainGroup: 'Bauch',
    tags: ['obere Bauchmuskeln', 'untere Bauchmuskeln', 'Hüftbeuger'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Sit-Ups',
    description:
        'Klassisch: Hände am Kopf, hoch zur Hocke. Saubere Atmung, kein Reißen.',
    mainGroup: 'Bauch',
    tags: ['obere Bauchmuskeln', 'Hüftbeuger'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Crunches',
    description:
        'Rückenlage, Schultern vom Boden heben. Oberer Bauch, Lendenwirbel am Boden.',
    mainGroup: 'Bauch',
    tags: ['obere Bauchmuskeln'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Bicycle Crunches',
    description:
        'Wechselseitig Ellbogen zum gegenüberliegenden Knie. Schräge + obere Bauchmuskeln.',
    mainGroup: 'Bauch',
    tags: ['schräge Bauchmuskeln', 'obere Bauchmuskeln'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Russian Twists',
    description:
        'Sitzend, Beine angehoben, Oberkörper links/rechts drehen. Kontrolle vor Speed.',
    mainGroup: 'Bauch',
    tags: ['schräge Bauchmuskeln', 'Bauch'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Mountain Climbers',
    description:
        'In Liegestütz wechselseitig Knie zur Brust ziehen. Cardio + Core.',
    mainGroup: 'Bauch',
    tags: ['Bauch', 'Hüftbeuger', 'Schultern'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Side Plank',
    description:
        'Seitlich auf Unterarm, Hüfte hoch halten. Stabilität schräge Bauchmuskeln + Hüfte.',
    mainGroup: 'Bauch',
    tags: ['schräge Bauchmuskeln', 'Hüftabduktoren', 'Schultern'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Dynamic Side Plank',
    description:
        'Seitstütz, Hüfte langsam ab- und absenken. Mehr Reiz für Obliques und Hüfte.',
    mainGroup: 'Bauch',
    tags: ['schräge Bauchmuskeln', 'Hüftabduktoren'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Plank to Push-Up',
    description:
        'Aus Unterarm-Plank Arm für Arm in Liegestütz, dann zurück. Trizeps + Core.',
    mainGroup: 'Bauch',
    tags: ['Bauch', 'Trizeps', 'vordere Schulter'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Bird Dog',
    description:
        'Vierfüßlerstand: diagonal Arm + Bein strecken. Stabilisiert den unteren Rücken.',
    mainGroup: 'Bauch',
    tags: ['Bauch', 'unterer Rücken', 'Hintern'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Dead Bug',
    description:
        'Rückenlage, Arme/Beine in 90°. Diagonale Streckung – Lendenwirbel bleibt am Boden.',
    mainGroup: 'Bauch',
    tags: ['Bauch', 'Hüftbeuger', 'unterer Rücken'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Flutter Kicks',
    description:
        'Rückenlage, kleine schnelle Beinscheren. Brennt im unteren Bauch.',
    mainGroup: 'Bauch',
    tags: ['untere Bauchmuskeln', 'Hüftbeuger'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Hanging Windshield Wipers',
    description:
        'Im Hang Beine gestreckt von Seite zu Seite schwenken. Sehr fortgeschritten.',
    mainGroup: 'Bauch',
    tags: ['schräge Bauchmuskeln', 'untere Bauchmuskeln', 'Unterarme'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Dragon Flag Negativ',
    description:
        'Auf Bank: Schultern fixieren, Körper gestreckt langsam ablassen. Aufbau zum Dragon Flag.',
    mainGroup: 'Bauch',
    tags: [
      'obere Bauchmuskeln',
      'untere Bauchmuskeln',
      'Hüftbeuger',
      'unterer Rücken',
    ],
  ),
  CalisthenicsCatalogExercise(
    name: 'Dragon Flag',
    description:
        'Hände greifen Bank/Pfosten, Körper komplett gestreckt anheben und kontrollieren.',
    mainGroup: 'Bauch',
    tags: [
      'Bauch',
      'obere Bauchmuskeln',
      'untere Bauchmuskeln',
      'unterer Rücken',
    ],
  ),
  CalisthenicsCatalogExercise(
    name: 'Reverse Crunch',
    description:
        'Rückenlage, Knie zur Brust + Hüfte vom Boden. Sehr gezielt für unteren Bauch.',
    mainGroup: 'Bauch',
    tags: ['untere Bauchmuskeln'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Beinheben (liegend)',
    description:
        'Rückenlage, Beine gestreckt oder leicht gebeugt vom Boden heben und langsam senken. Unterer Bauch.',
    mainGroup: 'Bauch',
    tags: ['untere Bauchmuskeln', 'Hüftbeuger'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Ab Wheel Rollout',
    description:
        'Vom Knien oder Stehen mit Bauchroller ausrollen. Sehr intensiv für den gesamten Core.',
    mainGroup: 'Bauch',
    tags: ['obere Bauchmuskeln', 'untere Bauchmuskeln', 'unterer Rücken'],
  ),

  // ── Beine ──────────────────────────────────────────────────────────────────
  CalisthenicsCatalogExercise(
    name: 'Wall Sit',
    description:
        'Rücken an Wand, Oberschenkel parallel. Isometrische Quad-Brennübung.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Knie', 'Hintern'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Deep Squat Hold',
    description:
        'Tiefe Kniebeuge halten, Fersen möglichst am Boden, Brust aufrecht. Hüfte und Sprunggelenke öffnen.',
    mainGroup: 'Beine',
    tags: ['Hüfte', 'oberer Oberschenkel', 'Knie'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Hampelmann',
    description:
        'Beine und Arme gleichzeitig öffnen und schließen. Gleichmäßig springen, Core fest.',
    mainGroup: 'Beine',
    tags: ['Waden', 'Schultern', 'Bauch'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Jump Squats',
    description:
        'Tiefe Kniebeuge, explosiv hochspringen. Sauber landen, Knie ausrichten.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'Waden', 'Knie'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Bulgarian Split Squat',
    description:
        'Hinteres Bein auf Bank/Pfosten, vorderes Bein arbeitet einbeinig. Sehr stark.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'Knie'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Cossack Squats',
    description:
        'Breiter Stand, abwechselnd seitlich tief gehen. Mobility + Kraft.',
    mainGroup: 'Beine',
    tags: ['Adduktoren', 'oberer Oberschenkel', 'Hintern', 'Hüfte'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Shrimp Squat (Assist)',
    description:
        'Einbeinige Kniebeuge mit fixiertem hinteren Bein. Sehr fortgeschritten.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'Knie', 'Bauch'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Step-Ups (Bank/Pfosten)',
    description:
        'Auf eine Erhöhung steigen, einbeinig. Po + Stabilität.',
    mainGroup: 'Beine',
    tags: ['Hintern', 'oberer Oberschenkel', 'Knie'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Glute Bridge',
    description:
        'Rückenlage, Füße am Boden, Hüfte hoch drücken. Aktiviert die Gesäßmuskulatur.',
    mainGroup: 'Beine',
    tags: ['Hintern', 'hinterer Oberschenkel', 'unterer Rücken'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Glute Bridge einbeinig',
    description:
        'Glute Bridge mit einem gestreckten Bein. Sehr effektiv und einseitig.',
    mainGroup: 'Beine',
    tags: ['Hintern', 'hinterer Oberschenkel', 'Bauch'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Hip Thrust (Schultern auf Bank)',
    description:
        'Schultern auf Bank, Füße am Boden. Hüfte explosiv hochdrücken. Po-Klassiker.',
    mainGroup: 'Beine',
    tags: ['Hintern', 'hinterer Oberschenkel'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Reverse Lunges',
    description:
        'Schritt nach hinten in den Ausfall. Knieschonender als der klassische Lunge.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'Knie'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Sprung-Ausfallschritte (Jump Lunge)',
    description:
        'Ausfallschritt mit Wechsel in der Luft. Plyometrie für Beine und Balance.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'Waden', 'Knie'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Lateral Lunges (Seitlicher Ausfallschritt)',
    description:
        'Seitlich tief in eine Seite. Adduktoren + Hüftöffnung + Gesäß.',
    mainGroup: 'Beine',
    tags: ['Adduktoren', 'oberer Oberschenkel', 'Hintern', 'Hüfte'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Side-Lying Leg Raises',
    description:
        'Seitlich liegen, oberes Bein gestreckt heben. Hüftabduktoren / mittlerer Glute.',
    mainGroup: 'Beine',
    tags: ['Hüftabduktoren', 'Hintern'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Donkey Kicks',
    description:
        'Vierfüßlerstand, ein Bein nach hinten oben drücken. Isolierte Gesäßarbeit.',
    mainGroup: 'Beine',
    tags: ['Hintern', 'hinterer Oberschenkel'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Broad Jumps',
    description:
        'Aus tiefer Hocke maximal nach vorne springen. Schnellkraft der ganzen Beinkette.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'Waden'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Sprint-Bursts',
    description:
        '6–10 s maximal sprinten, lange Pause. Schnellkraft + Conditioning.',
    mainGroup: 'Beine',
    tags: [
      'oberer Oberschenkel',
      'hinterer Oberschenkel',
      'Hintern',
      'Waden',
    ],
  ),
  CalisthenicsCatalogExercise(
    name: 'High Knees',
    description:
        'Auf der Stelle laufen, Knie hoch zur Brust. Cardio-Warm-up + Hüftbeuger.',
    mainGroup: 'Beine',
    tags: ['Hüftbeuger', 'Waden', 'oberer Oberschenkel'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Sissy Squat',
    description:
        'Auf den Fußballen, Oberkörper nach hinten kippen, Knie nach vorne. Quads pur.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Knie'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Box Jumps',
    description:
        'Aus halber Hocke explosiv auf eine Erhöhung springen. Sauber landen.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'Waden', 'Knie'],
  ),

  // ── Unterarme / Griff ──────────────────────────────────────────────────────
  CalisthenicsCatalogExercise(
    name: 'Towel Hangs',
    description:
        'An Handtuch über der Stange hängen. Sehr starker Reiz für die Griffkraft.',
    mainGroup: 'Unterarme',
    tags: ['Unterarme', 'oberer Rücken'],
  ),
  CalisthenicsCatalogExercise(
    name: 'One-Arm Hang (Assist)',
    description:
        'Mit einer Hand hängen, andere unterstützt am Handgelenk. Aufbau zum One-Arm Pull-Up.',
    mainGroup: 'Unterarme',
    tags: ['Unterarme', 'oberer Rücken'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Fingertip Hangs',
    description:
        'An den Fingerspitzen hängen, Daumen unten. Vorsicht – nur trainiert beginnen.',
    mainGroup: 'Unterarme',
    tags: ['Unterarme', 'Hände', 'Finger'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Knuckle Push-Ups',
    description:
        'Liegestütz auf den Knöcheln. Handgelenks-schonend und Unterarm-stärkend.',
    mainGroup: 'Unterarme',
    tags: ['Unterarme', 'Brust', 'Trizeps'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Wrist Warm-Up (CARs)',
    description:
        'Hände am Boden, alle Richtungen kreisen. Pflicht vor Handstand und Planche.',
    mainGroup: 'Unterarme',
    tags: ['Unterarme', 'Hände'],
  ),

  // ── Nacken ─────────────────────────────────────────────────────────────────
  CalisthenicsCatalogExercise(
    name: 'Neck Curls (Nacken-Crunch)',
    description:
        'Rückenlage, Kopf gegen leichten Widerstand heben. Stärkt vorderen Nacken.',
    mainGroup: 'Nacken',
    tags: ['Nacken'],
  ),
  CalisthenicsCatalogExercise(
    name: 'Neck Extensions',
    description:
        'Bauchlage, Kopf langsam heben. Stärkt hinteren Nacken. Vorsicht mit Range.',
    mainGroup: 'Nacken',
    tags: ['Nacken', 'oberer Rücken'],
  ),
];

