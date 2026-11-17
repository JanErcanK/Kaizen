import '../models/body_map_view_mode.dart';

/// General adult health education, paraphrased from the sources below.
/// Order is for reading, not a ranking or an individual treatment plan.
class AnatomyTip {
  const AnatomyTip(
    this.id,
    this.titleDe,
    this.titleEn,
    this.descriptionDe,
    this.descriptionEn,
    this.sourceIds,
  );

  final String id;
  final String titleDe;
  final String titleEn;
  final String descriptionDe;
  final String descriptionEn;
  final List<String> sourceIds;

  String title(bool german) => german ? titleDe : titleEn;
  String description(bool german) => german ? descriptionDe : descriptionEn;
}

class AnatomyTipSource {
  const AnatomyTipSource({
    required this.id,
    required this.title,
    required this.url,
    required this.modes,
  });

  final String id;
  final String title;
  final String url;
  final List<BodyMapViewMode> modes;
}

class AnatomyTips {
  AnatomyTips._();

  /// Date the linked sources were checked; this is not a clinical review.
  static const reviewedOn = '2026-10-22';

  static List<AnatomyTip> forMode(BodyMapViewMode mode) => switch (mode) {
    BodyMapViewMode.skeleton => _skeleton,
    BodyMapViewMode.connective => _connective,
    BodyMapViewMode.organs => _organs,
    _ => _muscles,
  };

  static const sources = <AnatomyTipSource>[
    AnatomyTipSource(
      id: 'acsm_resistance_2026',
      title: 'ACSM — Resistance Training Prescription (2026 Position Stand)',
      url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC12965823/',
      modes: [BodyMapViewMode.skeleton, BodyMapViewMode.connective],
    ),
    AnatomyTipSource(
      id: 'rnoh_tendon_loading',
      title: 'NHS / RNOH — Achilles Tendinopathy: Strengthening Exercises',
      url:
          'https://www.rnoh.nhs.uk/patients-and-visitors/patient-information-guides/achilles-tendinopathy',
      modes: [BodyMapViewMode.skeleton, BodyMapViewMode.connective],
    ),
    AnatomyTipSource(
      id: 'who_activity',
      title:
          'WHO — Guidelines on Physical Activity and Sedentary Behaviour: Recommendations',
      url: 'https://www.ncbi.nlm.nih.gov/books/NBK566046/',
      modes: [BodyMapViewMode.recovery, BodyMapViewMode.organs],
    ),
    AnatomyTipSource(
      id: 'nhs_strength',
      title: 'NHS — How to improve your strength and flexibility',
      url:
          'https://www.nhs.uk/live-well/exercise/how-to-improve-strength-flexibility/',
      modes: [BodyMapViewMode.recovery, BodyMapViewMode.connective],
    ),
    AnatomyTipSource(
      id: 'aaos_safe_exercise',
      title: 'AAOS OrthoInfo — Safe Exercise',
      url: 'https://www.orthoinfo.org/staying-healthy/safe-exercise/',
      modes: [BodyMapViewMode.recovery, BodyMapViewMode.skeleton],
    ),
    AnatomyTipSource(
      id: 'nhs_eatwell',
      title: 'NHS — The Eatwell Guide',
      url:
          'https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/the-eatwell-guide/',
      modes: [BodyMapViewMode.recovery],
    ),
    AnatomyTipSource(
      id: 'nhs_hydration',
      title: 'NHS — Water, drinks and hydration',
      url:
          'https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/water-drinks-nutrition/',
      modes: [BodyMapViewMode.recovery, BodyMapViewMode.organs],
    ),
    AnatomyTipSource(
      id: 'nhlbi_sleep',
      title:
          'NHLBI / NIH — Heart-Healthy Living: Get Enough Good-Quality Sleep',
      url: 'https://www.nhlbi.nih.gov/health/heart-healthy-living/sleep',
      modes: [BodyMapViewMode.recovery, BodyMapViewMode.organs],
    ),
    AnatomyTipSource(
      id: 'niams_bone_exercise',
      title: 'NIAMS / NIH — Exercise for Your Bone Health',
      url: 'https://www.niams.nih.gov/health-topics/exercise-your-bone-health',
      modes: [BodyMapViewMode.skeleton],
    ),
    AnatomyTipSource(
      id: 'nhs_osteoporosis',
      title: 'NHS — Osteoporosis: Prevention',
      url: 'https://www.nhs.uk/conditions/osteoporosis/prevention/',
      modes: [BodyMapViewMode.skeleton],
    ),
    AnatomyTipSource(
      id: 'nia_osteoarthritis',
      title: 'NIA / NIH — Osteoarthritis',
      url: 'https://www.nia.nih.gov/health/osteoarthritis/osteoarthritis',
      modes: [BodyMapViewMode.skeleton],
    ),
    AnatomyTipSource(
      id: 'nhs_osteoarthritis',
      title: 'NHS — Osteoarthritis',
      url: 'https://www.nhs.uk/conditions/osteoarthritis/',
      modes: [BodyMapViewMode.skeleton],
    ),
    AnatomyTipSource(
      id: 'nhs_tendonitis',
      title: 'NHS — Tendonitis',
      url: 'https://www.nhs.uk/conditions/tendonitis/',
      modes: [BodyMapViewMode.connective],
    ),
    AnatomyTipSource(
      id: 'nhs_rsi',
      title: 'NHS — Repetitive strain injury (RSI)',
      url: 'https://www.nhs.uk/conditions/repetitive-strain-injury-rsi/',
      modes: [BodyMapViewMode.connective],
    ),
    AnatomyTipSource(
      id: 'aaos_ankle',
      title: 'AAOS OrthoInfo — Sprained Ankle',
      url: 'https://www.orthoinfo.org/diseases--conditions/sprained-ankle',
      modes: [BodyMapViewMode.connective],
    ),
    AnatomyTipSource(
      id: 'nhs_smoking',
      title: 'NHS — Benefits of quitting smoking',
      url:
          'https://www.nhs.uk/better-health/quit-smoking/why-quit-smoking/benefits-of-quitting-smoking/',
      modes: [BodyMapViewMode.organs],
    ),
    AnatomyTipSource(
      id: 'who_alcohol',
      title: 'WHO — Alcohol',
      url: 'https://www.who.int/news-room/fact-sheets/detail/alcohol',
      modes: [BodyMapViewMode.organs],
    ),
    AnatomyTipSource(
      id: 'who_diet',
      title: 'WHO — Healthy diet',
      url: 'https://www.who.int/news-room/fact-sheets/detail/healthy-diet',
      modes: [BodyMapViewMode.organs],
    ),
    AnatomyTipSource(
      id: 'niddk_fibre',
      title: 'NIDDK / NIH — Eating, Diet, & Nutrition for Constipation',
      url:
          'https://www.niddk.nih.gov/health-information/digestive-diseases/constipation/eating-diet-nutrition',
      modes: [BodyMapViewMode.organs],
    ),
    AnatomyTipSource(
      id: 'niddk_kidney_prevention',
      title: 'NIDDK / NIH — Preventing Chronic Kidney Disease',
      url:
          'https://www.niddk.nih.gov/health-information/kidney-disease/chronic-kidney-disease-ckd/prevention',
      modes: [BodyMapViewMode.organs],
    ),
    AnatomyTipSource(
      id: 'niddk_medicines',
      title:
          'NIDDK / NIH — Keeping Kidneys Safe: Smart Choices about Medicines',
      url:
          'https://www.niddk.nih.gov/health-information/kidney-disease/keeping-kidneys-safe',
      modes: [BodyMapViewMode.organs],
    ),
  ];

  static const _muscles = <AnatomyTip>[
    AnatomyTip(
      'muscles_strength',
      'Krafttraining fest einplanen',
      'Make time for strength',
      'Trainiere als Erwachsener an mindestens zwei Tagen pro Woche deine Kraft. Auch Übungen mit dem eigenen Körpergewicht zählen.',
      'Aim for strength activity on at least two days a week as an adult. Bodyweight exercises count too.',
      ['who_activity'],
    ),
    AnatomyTip(
      'muscles_whole_body',
      'Den ganzen Körper einbeziehen',
      'Include your whole body',
      'Berücksichtige Beine, Hüfte, Rücken, Bauch, Brust, Schultern und Arme. Wechsle Übungen so ab, dass keine große Muskelgruppe dauerhaft fehlt.',
      'Include legs, hips, back, abdomen, chest, shoulders and arms. Vary your exercises so no major muscle group is consistently left out.',
      ['nhs_strength'],
    ),
    AnatomyTip(
      'muscles_progress',
      'Schrittweise steigern',
      'Build up gradually',
      'Beginne mit gut beherrschbaren Übungen und steigere die Belastung über mehrere Wochen. Nach einer Pause hilft ein leichterer Wiedereinstieg.',
      'Start with exercises you can manage comfortably and build the workload over several weeks. Ease back in after a break.',
      ['nhs_strength'],
    ),
    AnatomyTip(
      'muscles_warmup',
      'In Bewegung kommen',
      'Ease into movement',
      'Wärme dich vor dem Training mit lockerer Bewegung auf. Übe die anschließenden Bewegungen zunächst sanft und mit wenig Belastung.',
      'Warm up with easy movement before training. Rehearse the movements you will use gently and with a light load.',
      ['aaos_safe_exercise'],
    ),
    AnatomyTip(
      'muscles_control',
      'Kontrolliert bewegen',
      'Move with control',
      'Führe Wiederholungen ruhig durch deinen gut verträglichen Bewegungsumfang aus. Atme regelmäßig weiter, statt die Luft anzuhalten.',
      'Perform repetitions with control through a range of motion you tolerate well. Keep breathing regularly rather than holding your breath.',
      ['aaos_safe_exercise'],
    ),
    AnatomyTip(
      'muscles_rest',
      'Erholung einplanen',
      'Plan recovery time',
      'Baue freie oder leichtere Tage ein. Bei deutlicher Erschöpfung, starken Muskelschmerzen oder neuen Schmerzen ist eine harte Einheit keine gute Wahl.',
      'Include rest or easier days. Marked fatigue, substantial muscle soreness or new pain are reasons to skip a hard session.',
      ['aaos_safe_exercise'],
    ),
    AnatomyTip(
      'muscles_protein',
      'Eiweiß abwechslungsreich essen',
      'Vary your protein foods',
      'Baue Eiweißquellen wie Bohnen, Linsen, Tofu, Eier, Fisch oder Milchprodukte in deine Ernährung ein. Abwechslung liefert weitere wichtige Nährstoffe.',
      'Include protein foods such as beans, lentils, tofu, eggs, fish or dairy. Variety also provides other useful nutrients.',
      ['nhs_eatwell'],
    ),
    AnatomyTip(
      'muscles_energy',
      'Energie für Aktivität bereitstellen',
      'Fuel your activity',
      'Kartoffeln, Haferflocken, Vollkornbrot oder Reis liefern Energie. Kombiniere sie mit Gemüse und Eiweißquellen zu ausgewogenen Mahlzeiten.',
      'Potatoes, oats, wholegrain bread and rice provide energy. Combine them with vegetables and protein foods in balanced meals.',
      ['nhs_eatwell'],
    ),
    AnatomyTip(
      'muscles_fluids',
      'Trinken mitdenken',
      'Remember to drink',
      'Trinke regelmäßig über den Tag. Bei langem Training, Hitze oder starkem Schwitzen steigt der Flüssigkeitsbedarf; Wasser ist eine gute Wahl.',
      'Drink regularly throughout the day. Long workouts, heat and heavy sweating increase fluid needs; water is a good choice.',
      ['nhs_hydration'],
    ),
    AnatomyTip(
      'muscles_sleep',
      'Schlaf Raum geben',
      'Make room for sleep',
      'Plane als Erwachsener meist sieben bis neun Stunden Schlaf ein. Eine regelmäßige Schlafenszeit unterstützt eine verlässliche Erholungsroutine.',
      'Most adults should allow seven to nine hours for sleep. A regular bedtime helps establish a consistent recovery routine.',
      ['nhlbi_sleep'],
    ),
  ];

  static const _skeleton = <AnatomyTip>[
    AnatomyTip(
      'skeleton_weight_bearing',
      'Das eigene Gewicht tragen',
      'Use weight-bearing movement',
      'Gehen, Treppensteigen oder Tanzen belasten die Knochen sinnvoll. Wähle eine passende Form; bei Osteoporose sollte das Training individuell abgestimmt sein.',
      'Walking, stairs and dancing provide weight-bearing activity. Choose a suitable option; with osteoporosis, have exercise tailored to your needs.',
      ['niams_bone_exercise'],
    ),
    AnatomyTip(
      'skeleton_resistance',
      'Aufwärmen, dann gezielt schwerer trainieren',
      'Warm up, then build heavier strength',
      'Wärme dich mit lockerer Bewegung und leichten Übungssätzen gut auf. Mit sicherer Technik und Trainingserfahrung können höhere Gewichte mit weniger sauberen Wiederholungen deine Kraft fördern. Steigere schrittweise; bei Osteoporose oder Gelenkbeschwerden sollte die Belastung individuell abgestimmt sein.',
      'Warm up with easy movement and light practice sets. With sound technique and training experience, heavier weights for fewer controlled repetitions can develop strength. Build up gradually; have loading tailored to you if you have osteoporosis or joint symptoms.',
      ['niams_bone_exercise', 'aaos_safe_exercise', 'acsm_resistance_2026'],
    ),
    AnatomyTip(
      'skeleton_balance',
      'Das Gleichgewicht üben',
      'Practise balance',
      'Baue sichere Balanceübungen ein, etwa Gewichtsverlagerungen nahe einer stabilen Stütze. Besonders im höheren Alter hilft Gleichgewichtstraining, Stürzen vorzubeugen.',
      'Include safe balance practice, such as weight shifts beside a sturdy support. Balance training helps prevent falls, especially in older adults.',
      ['niams_bone_exercise'],
    ),
    AnatomyTip(
      'skeleton_calcium',
      'Kalzium über Lebensmittel',
      'Include calcium-rich foods',
      'Wähle regelmäßig kalziumreiche Lebensmittel wie Joghurt, Käse oder kalziumreichen Tofu. Kalzium wird für gesunde Knochen benötigt.',
      'Regularly choose calcium-rich foods such as yoghurt, cheese or calcium-rich tofu. Calcium is needed for healthy bones.',
      ['nhs_osteoporosis'],
    ),
    AnatomyTip(
      'skeleton_vitamin_d',
      'Vitamin D berücksichtigen',
      'Consider vitamin D',
      'Vitamin D unterstützt die Kalziumaufnahme. Fisch und angereicherte Lebensmittel liefern etwas davon; kläre bei Unsicherheit deinen Bedarf fachlich ab.',
      'Vitamin D supports calcium absorption. Fish and fortified foods provide some; seek professional advice if you are unsure about your needs.',
      ['nhs_osteoporosis'],
    ),
    AnatomyTip(
      'skeleton_joint_friendly',
      'Gelenkfreundlich aktiv bleiben',
      'Choose joint-friendly activity',
      'Bei Arthrose können Radfahren oder Schwimmen passende Bewegungsformen sein. Lass Intensität und Übungen an deine Beschwerden anpassen.',
      'With osteoarthritis, cycling or swimming can be suitable activities. Have exercise choices and intensity adapted to your symptoms.',
      ['nia_osteoarthritis'],
    ),
    AnatomyTip(
      'skeleton_weight',
      'Gelenkbelastung im Blick behalten',
      'Consider joint loading',
      'Falls du Übergewicht hast, kann eine schrittweise Gewichtsabnahme die Belastung von Knie und Hüfte verringern. Suche einen langfristig passenden Weg.',
      'If you are overweight, gradual weight loss can reduce the load on knees and hips. Choose an approach you can sustain.',
      ['nhs_osteoarthritis'],
    ),
    AnatomyTip(
      'skeleton_eccentric',
      'Exzentrisch langsam absenken',
      'Lower slowly in the eccentric phase',
      'Lass das Gewicht beim Absenken bewusst langsam und kontrolliert nach unten gehen, ohne Schwung oder Fallenlassen. Diese nachgebende Phase heißt exzentrisch. Isometrisch bedeutet dagegen, eine Position unter Spannung ohne Bewegung zu halten. Wähle ein Gewicht, das du durchgehend kontrollieren kannst.',
      'Lower the weight deliberately slowly and under control, without swinging or dropping it. This lengthening phase is called eccentric. Isometric means holding a position under tension without moving. Choose a weight you can control throughout.',
      ['rnoh_tendon_loading', 'aaos_safe_exercise'],
    ),
    AnatomyTip(
      'skeleton_smoking',
      'Rauchfrei werden',
      'Work towards being smoke-free',
      'Rauchen erhöht das Osteoporoserisiko. Wenn du rauchst, nutze Unterstützung beim Aufhören – auch deine Knochengesundheit profitiert davon.',
      'Smoking increases osteoporosis risk. If you smoke, seek help to quit; stopping also supports your bone health.',
      ['nhs_osteoporosis'],
    ),
    AnatomyTip(
      'skeleton_alcohol',
      'Alkohol reduzieren',
      'Reduce alcohol',
      'Begrenze Alkohol und vermeide Rauschtrinken. Weniger Alkohol gehört auch zur Vorbeugung von Osteoporose.',
      'Limit alcohol and avoid binge drinking. Drinking less is also part of osteoporosis prevention.',
      ['nhs_osteoporosis'],
    ),
  ];

  static const _connective = <AnatomyTip>[
    AnatomyTip(
      'connective_progress',
      'Gut aufwärmen, Gewicht schrittweise steigern',
      'Warm up and increase weight gradually',
      'Wärme dich vor schwereren Sätzen gut auf und übe die Bewegung zunächst mit leichter Last. Für den Kraftaufbau können höhere Gewichte und weniger saubere Wiederholungen sinnvoll sein, sobald du die Technik sicher beherrschst. Bei Sehnenbeschwerden müssen Gewicht, Tempo und Wiederholungen zum Rehaplan passen.',
      'Warm up thoroughly before heavier sets and practise with a light load first. Heavier weights and fewer controlled repetitions can support strength once your technique is reliable. With tendon symptoms, load, tempo and repetitions need to fit your rehabilitation plan.',
      [
        'nhs_strength',
        'nhs_tendonitis',
        'acsm_resistance_2026',
        'rnoh_tendon_loading',
      ],
    ),
    AnatomyTip(
      'connective_warmup',
      'Vorher locker aufwärmen',
      'Warm up first',
      'Starte mit lockerer Bewegung, bevor du intensiv trainierst. Dehne nachher sanft, ohne schmerzhaft zu ziehen.',
      'Start with easy movement before intense exercise. Stretch gently afterwards without pulling into pain.',
      ['nhs_tendonitis'],
    ),
    AnatomyTip(
      'connective_breaks',
      'Wiederholungen unterbrechen',
      'Break up repetitive tasks',
      'Lege bei wiederholten Griffen, Würfen oder ähnlichen Bewegungen regelmäßig Pausen ein. Das gilt auch für Arbeit und Hobbys.',
      'Take regular breaks from repeated gripping, throwing or similar movements. This applies at work and during hobbies too.',
      ['nhs_tendonitis'],
    ),
    AnatomyTip(
      'connective_eccentric',
      'Langsam absenken oder statisch halten',
      'Lower slowly or hold still',
      'Betone bei passenden Kraftübungen die exzentrische Phase: Senke das Gewicht bewusst langsam und kontrolliert ab. Isometrische Übungen halten die Spannung ohne Bewegung. Beide Formen können Teil eines angepassten Sehnentrainings sein; bei Beschwerden lass die passende Variante und Dosierung physiotherapeutisch abstimmen.',
      'Emphasise the eccentric phase in suitable strength exercises: lower the weight deliberately slowly and under control. Isometric exercises hold tension without movement. Both can be part of tailored tendon training; with symptoms, have a physiotherapist guide the exercise choice and dosage.',
      ['rnoh_tendon_loading'],
    ),
    AnatomyTip(
      'connective_fatigue',
      'Müdigkeit ernst nehmen',
      'Respect fatigue',
      'Überlaste bereits müde Muskeln nicht weiter. Passe die Einheit an, statt zusätzliche harte Wiederholungen zu erzwingen.',
      'Avoid overworking muscles that are already tired. Adjust the session rather than forcing extra hard repetitions.',
      ['nhs_tendonitis'],
    ),
    AnatomyTip(
      'connective_workspace',
      'Arbeit passend einrichten',
      'Adapt repetitive work',
      'Achte bei wiederholten Tätigkeiten auf eine angenehme Haltung. Bei Beschwerden können angepasste Arbeitsabläufe oder Hilfsmittel die Belastung verringern.',
      'Use a comfortable posture for repetitive tasks. If symptoms develop, changes to work methods or equipment can reduce strain.',
      ['nhs_rsi'],
    ),
    AnatomyTip(
      'connective_strength',
      'Gelenkführende Muskeln kräftigen',
      'Strengthen supporting muscles',
      'Gezielte Kraftübungen können die Sprunggelenkstabilität unterstützen. Nach einer Verletzung richtet sich der Aufbau nach dem vereinbarten Rehaplan.',
      'Targeted strength exercises can support ankle stability. After an injury, follow your agreed rehabilitation plan when rebuilding strength.',
      ['aaos_ankle'],
    ),
    AnatomyTip(
      'connective_balance',
      'Bewegungskontrolle trainieren',
      'Practise movement control',
      'Ergänze dein Training durch sichere Balanceübungen. Nach Umknickverletzungen hilft angeleitetes Gleichgewichtstraining, die Kontrolle über das Sprunggelenk wieder aufzubauen.',
      'Add safe balance exercises. After an ankle sprain, guided balance training helps rebuild control of the ankle.',
      ['aaos_ankle'],
    ),
    AnatomyTip(
      'connective_footwear',
      'Passende Schuhe wählen',
      'Choose suitable footwear',
      'Trage Schuhe, die zur Aktivität passen und Halt geben. Achte auf unebenem Boden besonders auf deine Schritte.',
      'Wear footwear that supports your activity. Pay particular attention to your footing on uneven ground.',
      ['aaos_ankle'],
    ),
    AnatomyTip(
      'connective_symptoms',
      'Anhaltende Beschwerden abklären',
      'Check persistent symptoms',
      'Lass wiederkehrende oder zunehmende Schmerzen, Schwellung oder Bewegungseinschränkungen fachlich beurteilen. Ein angepasster Plan ist hilfreicher als dauerhaftes Durchhalten.',
      'Get recurring or worsening pain, swelling or restricted movement assessed. A tailored plan is more useful than repeatedly pushing through.',
      ['nhs_rsi'],
    ),
  ];

  static const _organs = <AnatomyTip>[
    AnatomyTip(
      'organs_smoking',
      'Herz und Lunge rauchfrei halten',
      'Be smoke-free for heart and lungs',
      'Wenn du rauchst, suche Unterstützung beim Aufhören. Der Rauchstopp senkt langfristig Risiken für Herz- und Lungenerkrankungen.',
      'If you smoke, get support to quit. Stopping lowers long-term risks of heart and lung disease.',
      ['nhs_smoking'],
    ),
    AnatomyTip(
      'organs_alcohol',
      'Weniger Alkohol wählen',
      'Choose less alcohol',
      'Greife öfter zu alkoholfreien Getränken. Alkohol kann unter anderem Leber und Herz schädigen; auch geringe Mengen sind nicht risikofrei.',
      'Choose alcohol-free drinks more often. Alcohol can harm the liver and heart, among other organs; even small amounts are not risk-free.',
      ['who_alcohol'],
    ),
    AnatomyTip(
      'organs_activity',
      'Regelmäßig in Bewegung bleiben',
      'Move regularly',
      'Strebe als Erwachsener 150–300 Minuten mäßig intensive Bewegung pro Woche an, etwa zügiges Gehen. Auch kleinere Mengen bringen gesundheitlichen Nutzen.',
      'Aim for 150–300 minutes of moderate activity a week as an adult, such as brisk walking. Smaller amounts also benefit health.',
      ['who_activity'],
    ),
    AnatomyTip(
      'organs_variety',
      'Pflanzliche Vielfalt auf den Teller',
      'Eat a variety of plant foods',
      'Iss abwechslungsreich Gemüse, Obst, Vollkorn, Hülsenfrüchte und Nüsse. Diese Lebensmittel passen zu einer Ernährung, die Herz und Stoffwechsel unterstützt.',
      'Vary vegetables, fruit, whole grains, pulses and nuts. These foods fit an eating pattern that supports heart and metabolic health.',
      ['who_diet'],
    ),
    AnatomyTip(
      'organs_salt',
      'Salz bewusster auswählen',
      'Be mindful of salt',
      'Vergleiche Salzangaben auf Verpackungen und würze öfter mit Kräutern. Weniger Salz hilft, erhöhtem Blutdruck vorzubeugen.',
      'Compare salt content on food labels and use herbs for flavour more often. Less salt helps prevent high blood pressure.',
      ['who_diet'],
    ),
    AnatomyTip(
      'organs_fibre',
      'Ballaststoffe langsam steigern',
      'Increase fibre gradually',
      'Vollkorn, Bohnen, Gemüse und Obst unterstützen die Verdauung. Steigere Ballaststoffe schrittweise und trinke ausreichend, damit sich dein Darm daran gewöhnt.',
      'Whole grains, beans, vegetables and fruit support bowel regularity. Increase fibre gradually and drink enough to help your gut adjust.',
      ['niddk_fibre'],
    ),
    AnatomyTip(
      'organs_water',
      'Wasser zur Gewohnheit machen',
      'Make water a regular choice',
      'Trinke regelmäßig und ersetze zuckerreiche Getränke häufiger durch Wasser. Orientiere die Menge an Alltag, Wärme und Aktivität.',
      'Drink regularly and replace sugary drinks with water more often. Adapt the amount to your day, the temperature and your activity.',
      ['nhs_hydration'],
    ),
    AnatomyTip(
      'organs_checks',
      'Blutdruck und Blutzucker beachten',
      'Keep track of blood pressure and glucose',
      'Nutze passende Vorsorgekontrollen. Bei Bluthochdruck oder Diabetes helfen vereinbarte Behandlungsziele, auch die Nieren zu schützen.',
      'Use appropriate preventive check-ups. If you have high blood pressure or diabetes, following agreed treatment targets also helps protect your kidneys.',
      ['niddk_kidney_prevention'],
    ),
    AnatomyTip(
      'organs_medicines',
      'Medikamente bewusst verwenden',
      'Use medicines thoughtfully',
      'Frage bei regelmäßig benötigten Schmerzmitteln nach Risiken und Wechselwirkungen. Besonders bei Nierenproblemen sollten frei verkäufliche Mittel fachlich abgestimmt werden.',
      'Ask about risks and interactions if you regularly need painkillers. Seek advice on over-the-counter medicines, particularly if you have kidney problems.',
      ['niddk_medicines'],
    ),
    AnatomyTip(
      'organs_sleep',
      'Einen ruhigen Schlafrhythmus pflegen',
      'Keep a steady sleep routine',
      'Halte möglichst feste Schlaf- und Aufstehzeiten ein. Ausreichender Schlaf unterstützt Gehirn und Herz; ein ruhiges, dunkles Schlafzimmer kann dabei helfen.',
      'Keep bedtime and wake-up times consistent where possible. Enough sleep supports the brain and heart; a quiet, dark bedroom can help.',
      ['nhlbi_sleep'],
    ),
  ];
}
