// Gym exercise catalog.

class GymCatalogExercise {
  const GymCatalogExercise({
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

const List<GymCatalogExercise> gymCatalogExercises = [
  // ── Brust ──────────────────────────────────────────────────────────────────
  GymCatalogExercise(
    name: 'Bankdrücken (Langhantel)',
    description:
        'Klassische Grundübung. Schulterbreiter Griff, Ellbogen 45° zum Körper, kontrolliert absenken.',
    mainGroup: 'Brust',
    tags: ['mittlere Brust', 'vordere Schulter', 'Trizeps'],
  ),
  GymCatalogExercise(
    name: 'Bankdrücken (Kurzhantel)',
    description:
        'Größere Bewegungsamplitude als Langhantel. Ideal für symmetrische Kraftentwicklung.',
    mainGroup: 'Brust',
    tags: ['mittlere Brust', 'vordere Schulter', 'Trizeps'],
  ),
  GymCatalogExercise(
    name: 'Schrägbankdrücken (positiv)',
    description:
        'Bank auf 30–45° einstellen. Betont den oberen Brustbereich und die Klavikularportion.',
    mainGroup: 'Brust',
    tags: ['obere Brust', 'vordere Schulter', 'Trizeps'],
  ),
  GymCatalogExercise(
    name: 'Schrägbankdrücken (negativ)',
    description:
        'Bank abwärts geneigt. Isoliert den unteren Brustbereich stark.',
    mainGroup: 'Brust',
    tags: ['untere Brust', 'Trizeps'],
  ),
  GymCatalogExercise(
    name: 'Kurzhantel-Flys (flach)',
    description:
        'Arme leicht gebeugt halten, weite Bewegungsbahn. Dehnt die Brust maximal.',
    mainGroup: 'Brust',
    tags: ['mittlere Brust', 'vordere Schulter'],
  ),
  GymCatalogExercise(
    name: 'Kurzhantel-Flys (Schrägbank)',
    description: 'Wie Flys flach, aber mit positiver Neigung für obere Brust.',
    mainGroup: 'Brust',
    tags: ['obere Brust', 'vordere Schulter'],
  ),
  GymCatalogExercise(
    name: 'Kabelcrossover (oben nach unten)',
    description:
        'Kabel auf höchste Position, Hände treffen sich unterhalb der Hüfte. Betont untere Brust.',
    mainGroup: 'Brust',
    tags: ['untere Brust', 'mittlere Brust'],
  ),
  GymCatalogExercise(
    name: 'Kabelcrossover (unten nach oben)',
    description:
        'Kabel auf niedrigste Position, Hände treffen sich auf Brusthöhe. Betont obere Brust.',
    mainGroup: 'Brust',
    tags: ['obere Brust', 'mittlere Brust'],
  ),
  GymCatalogExercise(
    name: 'Dips (Brust-Variante)',
    description:
        'Körper leicht nach vorne neigen, Ellbogen weit auseinander. Belastet stark die untere Brust.',
    mainGroup: 'Brust',
    tags: ['untere Brust', 'Trizeps', 'vordere Schulter'],
  ),
  GymCatalogExercise(
    name: 'Liegestütze',
    description:
        'Bodyweight-Klassiker. Körper in einer Linie, Brust bis kurz vor den Boden, sauberer Core.',
    mainGroup: 'Brust',
    tags: ['mittlere Brust', 'untere Brust', 'vordere Schulter', 'Trizeps', 'Bauch'],
  ),
  GymCatalogExercise(
    name: 'Pec Deck / Butterfly',
    description:
        'Isolationsübung an der Maschine. Arme gestreckt halten und langsam zusammenführen.',
    mainGroup: 'Brust',
    tags: ['mittlere Brust', 'obere Brust'],
  ),
  GymCatalogExercise(
    name: 'Langhantel Pullover',
    description:
        'Liegt quer auf der Bank. Trainiert gleichzeitig Brust und Lats, guter Stretch.',
    mainGroup: 'Brust',
    tags: ['obere Brust', 'oberer Rücken'],
  ),
  GymCatalogExercise(
    name: 'Schrägbankdrücken (Kurzhantel)',
    description:
        'Bank 30–45° positiv, Kurzhanteln. Größere ROM und symmetrische obere Brust.',
    mainGroup: 'Brust',
    tags: ['obere Brust', 'vordere Schulter', 'Trizeps'],
  ),
  GymCatalogExercise(
    name: 'Brustpresse (Maschine)',
    description:
        'Sitzend an der Chest-Press-Maschine. Geführte Bewegung, gut für Einsteiger.',
    mainGroup: 'Brust',
    tags: ['mittlere Brust', 'vordere Schulter', 'Trizeps'],
  ),

  // ── Schultern ──────────────────────────────────────────────────────────────
  GymCatalogExercise(
    name: 'Schulterdrücken (Langhantel, stehend)',
    description:
        'Stehende Ausführung aktiviert mehr Core-Stabilität. Rücken nicht überstrecken.',
    mainGroup: 'Schultern',
    tags: ['vordere Schulter', 'mittlere Schulter', 'Trizeps'],
  ),
  GymCatalogExercise(
    name: 'Schulterdrücken (Kurzhantel, sitzend)',
    description:
        'Sitzend ausgeführt für höhere Isolation der Schultern ohne Schwung.',
    mainGroup: 'Schultern',
    tags: ['vordere Schulter', 'mittlere Schulter', 'Trizeps'],
  ),
  GymCatalogExercise(
    name: 'Seitheben (Kurzhantel)',
    description:
        'Arme seitlich bis auf Schulterhöhe heben. Langsames Absenken für mehr Spannung.',
    mainGroup: 'Schultern',
    tags: ['mittlere Schulter'],
  ),
  GymCatalogExercise(
    name: 'Seitheben (Kabel)',
    description:
        'Kabelzug von unten. Kontinuierliche Spannung über den gesamten Bewegungsweg.',
    mainGroup: 'Schultern',
    tags: ['mittlere Schulter'],
  ),
  GymCatalogExercise(
    name: 'Frontheben',
    description:
        'Langhantel oder Kurzhantel nach vorne heben bis auf Schulterhöhe.',
    mainGroup: 'Schultern',
    tags: ['vordere Schulter'],
  ),
  GymCatalogExercise(
    name: 'Reverse Fly (hintere Schulter)',
    description:
        'Oberkörper nach vorne gebeugt, Arme seitlich ausbreiten. Trainiert oft vernachlässigte hintere Schulter.',
    mainGroup: 'Schultern',
    tags: ['hintere Schulter', 'oberer Rücken'],
  ),
  GymCatalogExercise(
    name: 'Arnold Press',
    description:
        'Kurzhantel-Press mit Rotation. Trifft alle drei Schulterköpfe durch den Dreh.',
    mainGroup: 'Schultern',
    tags: ['vordere Schulter', 'mittlere Schulter', 'Trizeps'],
  ),
  GymCatalogExercise(
    name: 'Face Pulls',
    description:
        'Kabel auf Kopfhöhe, Seil zu Ohren ziehen. Wichtig für Schultergesundheit und hintere Schulter.',
    mainGroup: 'Schultern',
    tags: ['hintere Schulter', 'oberer Rücken', 'Nacken'],
  ),
  GymCatalogExercise(
    name: 'Upright Row',
    description:
        'Langhantel nah am Körper bis Kinnhöhe ziehen. Belastet mittlere Schulter und Fallen.',
    mainGroup: 'Schultern',
    tags: ['mittlere Schulter', 'Nacken'],
  ),
  GymCatalogExercise(
    name: 'Schulterdrücken (Smith-Maschine)',
    description:
        'Geführtes Schulterdrücken in der Multipresse. Stabile Bahn für schwere Sätze.',
    mainGroup: 'Schultern',
    tags: ['vordere Schulter', 'mittlere Schulter', 'Trizeps'],
  ),
  GymCatalogExercise(
    name: 'Seitheben (Maschine)',
    description:
        'Laterale Raise-Maschine. Isoliert den mittleren Deltamuskel mit konstanter Spannung.',
    mainGroup: 'Schultern',
    tags: ['mittlere Schulter'],
  ),
  GymCatalogExercise(
    name: 'Frontheben (Langhantel)',
    description:
        'Langhantel nach vorne bis Schulterhöhe. Fokus vordere Schulter.',
    mainGroup: 'Schultern',
    tags: ['vordere Schulter'],
  ),
  GymCatalogExercise(
    name: 'Reverse Pec Deck',
    description:
        'Hintere Schulter-Maschine (Butterfly rückwärts). Schultergesundheit und Haltung.',
    mainGroup: 'Schultern',
    tags: ['hintere Schulter', 'oberer Rücken'],
  ),

  // ── Rücken ─────────────────────────────────────────────────────────────────
  GymCatalogExercise(
    name: 'Klimmzüge (weiter Griff)',
    description:
        'Überkopfzug am eigenen Körpergewicht. Einer der effektivsten Latissimus-Aufbauer.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps', 'hintere Schulter'],
  ),
  GymCatalogExercise(
    name: 'Latzug (weiter Griff)',
    description:
        'Maschinenunterstützte Variante der Klimmzüge. Ideal für Einsteiger.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'Bizeps'],
  ),
  GymCatalogExercise(
    name: 'Latzug (enger Untergriff)',
    description:
        'Enger Griff aktiviert mehr Bizeps und mittleren Rücken.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'unterer Rücken', 'Bizeps'],
  ),
  GymCatalogExercise(
    name: 'Langhantel-Rudern',
    description:
        'Oberkörper 45° nach vorne, Stange zum Bauchnabel ziehen. Fundamentale Rückenübung.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'unterer Rücken', 'hintere Schulter', 'Bizeps'],
  ),
  GymCatalogExercise(
    name: 'Kurzhantel-Rudern (einarmig)',
    description:
        'Auf Bank abstützen. Volle Bewegungsamplitude ermöglicht maximale Kontraktion.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'hintere Schulter', 'Bizeps'],
  ),
  GymCatalogExercise(
    name: 'Sitzrudern (Kabel, enger Griff)',
    description:
        'Rücken aufrecht, Ellbogen nah am Körper rückwärts führen.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'unterer Rücken', 'Bizeps'],
  ),
  GymCatalogExercise(
    name: 'T-Bar Rudern',
    description:
        'Hohe Gewichtslast möglich. Sehr guter Masseaufbauer für den mittleren Rücken.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'unterer Rücken'],
  ),
  GymCatalogExercise(
    name: 'Kreuzheben (konventionell)',
    description:
        'König der Rückenübungen. Rücken gerade halten, aus den Beinen drücken.',
    mainGroup: 'Rücken',
    tags: ['unterer Rücken', 'oberer Rücken', 'oberer Oberschenkel', 'Hintern'],
  ),
  GymCatalogExercise(
    name: 'Kreuzheben (Sumo)',
    description:
        'Breitere Beinstellung verlagert mehr Last auf Hüfte und Adduktoren.',
    mainGroup: 'Rücken',
    tags: ['unterer Rücken', 'oberer Oberschenkel', 'Adduktoren', 'Hintern'],
  ),
  GymCatalogExercise(
    name: 'Hyperextensions',
    description:
        'Am Rückenstrecker-Gerät. Langsam und kontrolliert ausführen, nicht überstrecken.',
    mainGroup: 'Rücken',
    tags: ['unterer Rücken', 'Hintern', 'hinterer Oberschenkel'],
  ),
  GymCatalogExercise(
    name: 'Latzug in den Nacken',
    description:
        'Stange hinter den Kopf ziehen. Nur schmerzfrei – hohe Schulterbelastung.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'hintere Schulter', 'Nacken'],
  ),
  GymCatalogExercise(
    name: 'Straight-Arm Pulldown (Kabel)',
    description:
        'Arme gestreckt, Lat-Pulldown-Bewegung. Isoliert den Latissimus ohne Bizeps.',
    mainGroup: 'Rücken',
    tags: ['oberer Rücken', 'breiter Rücken'],
  ),
  GymCatalogExercise(
    name: 'Rack Pulls',
    description:
        'Kreuzheben ab Kniehöhe im Rack. Starke Rücken- und Trapez-Reizung mit weniger Bein.',
    mainGroup: 'Rücken',
    tags: ['unterer Rücken', 'oberer Rücken', 'Nacken', 'Hintern'],
  ),

  // ── Trizeps ────────────────────────────────────────────────────────────────
  GymCatalogExercise(
    name: 'Trizepsdrücken (Kabel, Stange)',
    description:
        'Ellbogen fest am Körper, nur Unterarme bewegen. Klassischer Trizeps-Isolator.',
    mainGroup: 'Trizeps',
    tags: ['großer Trizepskopf', 'kleiner Trizepskopf'],
  ),
  GymCatalogExercise(
    name: 'Trizepsdrücken (Kabel, Seil)',
    description:
        'Seil am unteren Ende auseinanderziehen für mehr Außenrotation und Kontraktion.',
    mainGroup: 'Trizeps',
    tags: ['großer Trizepskopf', 'kleiner Trizepskopf'],
  ),
  GymCatalogExercise(
    name: 'Skull Crushers (EZ-Stange)',
    description:
        'Liegend, Stange zur Stirn führen. Betont den langen Trizepskopf stark.',
    mainGroup: 'Trizeps',
    tags: ['großer Trizepskopf'],
  ),
  GymCatalogExercise(
    name: 'Overhead Trizepsdrücken (Kurzhantel)',
    description:
        'Arme über Kopf gestreckt, Kurzhantel hinter Kopf absenken. Maximaler Stretch des langen Kopfes.',
    mainGroup: 'Trizeps',
    tags: ['großer Trizepskopf'],
  ),
  GymCatalogExercise(
    name: 'Trizeps Kickback',
    description:
        'Oberkörper vor, Ellbogen am Körper, Unterarm nach hinten strecken.',
    mainGroup: 'Trizeps',
    tags: ['kleiner Trizepskopf'],
  ),
  GymCatalogExercise(
    name: 'Trizepsdrücken über Kopf (Kabel, Seil)',
    description:
        'Seil hinter dem Kopf nach unten strecken. Langer Trizeps-Dehnungsweg.',
    mainGroup: 'Trizeps',
    tags: ['Trizeps', 'langer Trizepskopf'],
  ),
  GymCatalogExercise(
    name: 'Dips (enge Griffvariante)',
    description:
        'Körper aufrecht halten, Ellbogen nah am Körper. Maximale Trizepsaktivierung.',
    mainGroup: 'Trizeps',
    tags: ['großer Trizepskopf', 'kleiner Trizepskopf', 'vordere Schulter'],
  ),
  GymCatalogExercise(
    name: 'JM Press',
    description:
        'Hybrid aus Bankdrücken und Skull Crusher. Sehr hohe Gewichtslast auf den Trizeps.',
    mainGroup: 'Trizeps',
    tags: ['großer Trizepskopf', 'kleiner Trizepskopf'],
  ),
  GymCatalogExercise(
    name: 'Enges Bankdrücken (Close Grip Bench Press)',
    description:
        'Enger Griff (etwa schulterbreit), Ellbogen nah am Körper. Trizeps-Fokus mit hoher Last.',
    mainGroup: 'Trizeps',
    tags: ['großer Trizepskopf', 'kleiner Trizepskopf', 'mittlere Brust', 'vordere Schulter'],
  ),

  // ── Bizeps ─────────────────────────────────────────────────────────────────
  GymCatalogExercise(
    name: 'Bizepscurls (Langhantel)',
    description:
        'Schulterbreiter Untergriff, Ellbogen fest am Körper. Grundübung für Bizepsaufbau.',
    mainGroup: 'Bizeps',
    tags: ['Bizeps', 'Unterarme'],
  ),
  GymCatalogExercise(
    name: 'Bizepscurls (EZ-Stange)',
    description:
        'Schont die Handgelenke durch die angewinkelte Griffhaltung.',
    mainGroup: 'Bizeps',
    tags: ['Bizeps', 'Unterarme'],
  ),
  GymCatalogExercise(
    name: 'Bizepscurls (Kurzhantel, alternierend)',
    description:
        'Abwechselnd curlen erlaubt Supination im Handgelenk für maximale Bizepskontraktion.',
    mainGroup: 'Bizeps',
    tags: ['Bizeps'],
  ),
  GymCatalogExercise(
    name: 'Konzentrationscurls',
    description:
        'Sitzend, Ellbogen am Oberschenkel. Stärkste Isolation des Bizeps ohne Schwung.',
    mainGroup: 'Bizeps',
    tags: ['Bizeps'],
  ),
  GymCatalogExercise(
    name: 'Hammer Curls',
    description:
        'Neutraler Griff (Daumen oben). Trainiert gleichzeitig Bizeps und Brachioradialis.',
    mainGroup: 'Bizeps',
    tags: ['Bizeps', 'Unterarme'],
  ),
  GymCatalogExercise(
    name: 'Spider Curls',
    description:
        'Auf schrägem Bankrand aufstützen, Arme hängen lassen. Langer Dehnweg für maximalen Pump.',
    mainGroup: 'Bizeps',
    tags: ['Bizeps'],
  ),
  GymCatalogExercise(
    name: 'Kabelcurls',
    description:
        'Konstante Spannung auch in der Ausgangsposition. Ideal als Ergänzung zu Kurzhanteln.',
    mainGroup: 'Bizeps',
    tags: ['Bizeps'],
  ),
  GymCatalogExercise(
    name: 'Preacher Curls (Scottbank)',
    description:
        'Ellbogen auf geneigter Auflage – verhindert Schwung komplett.',
    mainGroup: 'Bizeps',
    tags: ['Bizeps'],
  ),
  GymCatalogExercise(
    name: 'Bizepscurls (Schrägbank)',
    description:
        'Bank leicht zurück, Arme hängen frei – maximaler Dehnungsweg am Bizeps.',
    mainGroup: 'Bizeps',
    tags: ['Bizeps', 'langer Bizepskopf'],
  ),
  GymCatalogExercise(
    name: '21s Curls (SZ-Stange)',
    description:
        '7 halbe Wdh. unten + 7 oben + 7 voll. Intensitäts-Methode für den Bizeps.',
    mainGroup: 'Bizeps',
    tags: ['Bizeps', 'kurzer Bizepskopf', 'langer Bizepskopf'],
  ),

  // ── Bauch ──────────────────────────────────────────────────────────────────
  GymCatalogExercise(
    name: 'Kabelzug Crunches',
    description:
        'Kabel von oben, im Kniestand nach unten beugen. Gewichteter Bauchaufbau.',
    mainGroup: 'Bauch',
    tags: ['obere Bauchmuskeln', 'untere Bauchmuskeln'],
  ),
  GymCatalogExercise(
    name: 'Leg Raises (hängend)',
    description:
        'Am Klimmzugstangengriff hängen, Beine gestreckt heben. Starke Belastung des unteren Bauchs.',
    mainGroup: 'Bauch',
    tags: ['untere Bauchmuskeln'],
  ),
  GymCatalogExercise(
    name: 'Decline Crunches',
    description:
        'Auf negativer Schrägbank ausgeführte Crunches. Intensiver als flache Crunches.',
    mainGroup: 'Bauch',
    tags: ['obere Bauchmuskeln'],
  ),
  GymCatalogExercise(
    name: 'Russian Twists (mit Gewicht)',
    description:
        'Oberkörper zurücklehnen, Gewicht von Seite zu Seite drehen. Trainiert die Obliques stark.',
    mainGroup: 'Bauch',
    tags: ['Bauch', 'obere Bauchmuskeln'],
  ),
  GymCatalogExercise(
    name: 'Ab Wheel Rollout',
    description:
        'Rollout nach vorne mit geradem Rücken. Sehr effektiver Core-Stabilisator.',
    mainGroup: 'Bauch',
    tags: ['obere Bauchmuskeln', 'untere Bauchmuskeln', 'unterer Rücken'],
  ),
  GymCatalogExercise(
    name: 'Dragon Flag',
    description:
        'Fortgeschrittene Übung: Körper gestreckt auf Bank, langsam absenken und halten.',
    mainGroup: 'Bauch',
    tags: ['obere Bauchmuskeln', 'untere Bauchmuskeln'],
  ),
  GymCatalogExercise(
    name: 'Pallof Press',
    description:
        'Kabelzug seitlich, Widerstand gegen Rotation halten. Trainiert Anti-Rotations-Stabilität.',
    mainGroup: 'Bauch',
    tags: ['Bauch', 'untere Bauchmuskeln'],
  ),
  GymCatalogExercise(
    name: 'Plank',
    description:
        'Unterarme am Boden, Körper in Linie, Bauch fest. Nicht im unteren Rücken durchhängen.',
    mainGroup: 'Bauch',
    tags: ['Bauch', 'obere Bauchmuskeln', 'untere Bauchmuskeln'],
  ),

  // ── Beine ──────────────────────────────────────────────────────────────────
  GymCatalogExercise(
    name: 'Kniebeugen (Langhantel, High Bar)',
    description:
        'Stange hoch auf den Trapezmuskeln. Betont mehr Quadrizeps und aufrechten Oberkörper.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'unterer Rücken'],
  ),
  GymCatalogExercise(
    name: 'Frontkniebeuge (Langhantel)',
    description:
        'Stange vor den Schultern. Aufrechter Torso, starker Quad- und Core-Fokus.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'unterer Rücken', 'Bauch'],
  ),
  GymCatalogExercise(
    name: 'Goblet Squat',
    description:
        'Kurzhantel vor der Brust halten, tief in die Kniebeuge. Technikfreundlich.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'Bauch'],
  ),
  GymCatalogExercise(
    name: 'Kniebeugen (Langhantel, Low Bar)',
    description:
        'Stange tiefer auf dem Rücken. Mehr Hüftbeugung, betont Gesäß und hintere Oberschenkelkette.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'hinterer Oberschenkel'],
  ),
  GymCatalogExercise(
    name: 'Beinpresse',
    description:
        'Fußposition verändert Belastungsverteilung. Höher = mehr Gesäß/Hamstring, tiefer = mehr Quads.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'hinterer Oberschenkel'],
  ),
  GymCatalogExercise(
    name: 'Bulgarische Ausfallschritte',
    description:
        'Hinterer Fuß auf Bank. Intensive einseitige Beinübung für Kraft und Balance.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'hinterer Oberschenkel'],
  ),
  GymCatalogExercise(
    name: 'Ausfallschritte (Langhantel, gehend)',
    description:
        'Langhantel auf dem Rücken, Schritt für Schritt nach vorne. Beine und Balance.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern', 'unterer Rücken'],
  ),
  GymCatalogExercise(
    name: 'Beinstrecker (Maschine)',
    description:
        'Isolierte Quadrizeps-Übung. Knie gesund halten – nur volle Streckung ohne Überextension.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel'],
  ),
  GymCatalogExercise(
    name: 'Bein Curl (liegend)',
    description:
        'Isoliert die Oberschenkelrückseite. Hüfte fest auf der Bank halten.',
    mainGroup: 'Beine',
    tags: ['hinterer Oberschenkel'],
  ),
  GymCatalogExercise(
    name: 'Bein Curl (sitzend)',
    description:
        'Am sitzenden Beinbeuger. Hüfte fixiert, Hamstrings isoliert.',
    mainGroup: 'Beine',
    tags: ['hinterer Oberschenkel'],
  ),
  GymCatalogExercise(
    name: 'Romanian Deadlift',
    description:
        'Beine leicht gebeugt, Stange nah am Körper führen. Maximaler Stretch der Hamstrings.',
    mainGroup: 'Beine',
    tags: ['hinterer Oberschenkel', 'Hintern', 'unterer Rücken'],
  ),
  GymCatalogExercise(
    name: 'Hip Thrust (Langhantel)',
    description:
        'Schulterblätter auf Bank, Langhantel auf Hüfte. Beste Übung für Gesäßaufbau.',
    mainGroup: 'Beine',
    tags: ['Hintern', 'hinterer Oberschenkel'],
  ),
  GymCatalogExercise(
    name: 'Glute Kickback (Kabel/Maschine)',
    description:
        'Bein nach hinten am Kabel oder an der Kickback-Maschine. Glute-Isolation.',
    mainGroup: 'Beine',
    tags: ['Hintern', 'hinterer Oberschenkel'],
  ),
  GymCatalogExercise(
    name: 'Adduktorenmaschine',
    description:
        'Beine aus weiter Position zusammendrücken. Kräftigt die Innenseite der Oberschenkel.',
    mainGroup: 'Beine',
    tags: ['Adduktoren'],
  ),
  GymCatalogExercise(
    name: 'Abduktorenmaschine',
    description:
        'Beine gegen Widerstand auseinanderbewegen. Kräftigt die Außenseite der Oberschenkel.',
    mainGroup: 'Beine',
    tags: ['Abduktoren'],
  ),
  GymCatalogExercise(
    name: 'Wadenheben stehend (Maschine)',
    description:
        'Volles Strecken und maximales Absenken der Ferse für optimale Wadenentwicklung.',
    mainGroup: 'Beine',
    tags: ['Waden'],
  ),
  GymCatalogExercise(
    name: 'Wadenheben sitzend',
    description:
        'Sitzende Variante isoliert den Soleus-Muskel (tiefer Wadenmuskel) effektiver.',
    mainGroup: 'Beine',
    tags: ['Waden', 'Schienbein'],
  ),
  GymCatalogExercise(
    name: 'Tibialis Raises',
    description:
        'Ferse auf erhöhter Fläche, Zehen hochziehen. Stärkt Schienbeinmuskel und schützt das Knie.',
    mainGroup: 'Beine',
    tags: ['Schienbein', 'Knie', 'Fuß'],
  ),
  GymCatalogExercise(
    name: 'Poliquin Step-Up',
    description:
        'Ferse auf Stufe, langsam auf Zehenspitze gehen. Stärkt Knie-Sehnen und VMO.',
    mainGroup: 'Beine',
    tags: ['Knie', 'oberer Oberschenkel', 'Schienbein'],
  ),
  GymCatalogExercise(
    name: 'Hack Squat (Maschine)',
    description:
        'Geführte Kniebeuge mit hohem Fußstand. Intensiver Quadrizeps-Fokus.',
    mainGroup: 'Beine',
    tags: ['oberer Oberschenkel', 'Hintern'],
  ),
  GymCatalogExercise(
    name: 'Wadenheben an der Beinpresse',
    description:
        'Ferse auf dem Fußbrett der Leg Press, Waden maximal strecken und absenken.',
    mainGroup: 'Beine',
    tags: ['Waden'],
  ),

  // ── Nacken ─────────────────────────────────────────────────────────────────
  GymCatalogExercise(
    name: 'Neck Curls (liegend)',
    description:
        'Auf Bank liegend, Kopf langsam zur Brust ziehen. Stärkt die vordere Nackenmuskulatur.',
    mainGroup: 'Nacken',
    tags: ['Nacken'],
  ),
  GymCatalogExercise(
    name: 'Neck Extensions (liegend)',
    description:
        'Bauchlage, Kopf nach hinten strecken. Stärkt die hintere Nackenmuskulatur.',
    mainGroup: 'Nacken',
    tags: ['Nacken'],
  ),
  GymCatalogExercise(
    name: 'Neck Harness (Stirnband)',
    description:
        'Gewicht an Stirnband befestigt, Kopf heben und senken. Ermöglicht höhere Gewichte.',
    mainGroup: 'Nacken',
    tags: ['Nacken'],
  ),
  GymCatalogExercise(
    name: 'Shrugs (Langhantel)',
    description:
        'Schultern gerade nach oben ziehen, nicht rotieren. Trainiert die Trapezmuskeln.',
    mainGroup: 'Nacken',
    tags: ['Nacken', 'oberer Rücken'],
  ),
  GymCatalogExercise(
    name: 'Shrugs (Kurzhantel)',
    description:
        'Wie Langhantel-Shrugs aber mit freierem Bewegungsweg seitlich am Körper.',
    mainGroup: 'Nacken',
    tags: ['Nacken', 'oberer Rücken'],
  ),

  // ── Unterarme ──────────────────────────────────────────────────────────────
  GymCatalogExercise(
    name: 'Handgelenk Curls (Langhantel)',
    description:
        'Unterarme auf Bank, Handflächen nach oben. Trainiert die Beuger der Unterarme.',
    mainGroup: 'Unterarme',
    tags: ['Unterarme'],
  ),
  GymCatalogExercise(
    name: 'Reverse Curls',
    description:
        'Obergriff beim Bizepscurl. Trainiert Brachioradialis und Unterarmbeuger.',
    mainGroup: 'Unterarme',
    tags: ['Unterarme', 'Bizeps'],
  ),
  GymCatalogExercise(
    name: 'Farmer\'s Walk',
    description:
        'Schwere Kurzhanteln tragen und gehen. Einer der besten Griff- und Unterarmaufbauer.',
    mainGroup: 'Unterarme',
    tags: ['Unterarme', 'Nacken', 'oberer Rücken'],
  ),
  GymCatalogExercise(
    name: 'Plate Pinch',
    description:
        'Scheibe mit Fingern und Daumen halten. Stärkt Griffkraft und Fingermuskulatur.',
    mainGroup: 'Unterarme',
    tags: ['Unterarme'],
  ),
  GymCatalogExercise(
    name: 'Dead Hang',
    description:
        'An der Stange hängen so lange wie möglich. Trainiert Griffausdauer und dekomprimiert die Wirbelsäule.',
    mainGroup: 'Unterarme',
    tags: ['Unterarme', 'oberer Rücken'],
  ),
];
