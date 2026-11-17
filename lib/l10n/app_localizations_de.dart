// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Kaizen';

  @override
  String get common_ok => 'OK';

  @override
  String get common_cancel => 'Abbrechen';

  @override
  String get common_save => 'Speichern';

  @override
  String get common_continue => 'Weiter';

  @override
  String get common_delete => 'Löschen';

  @override
  String get common_reset => 'Reset';

  @override
  String get common_create => 'Erstellen';

  @override
  String get common_add => 'Hinzufügen';

  @override
  String get common_rename => 'Umbenennen';

  @override
  String get common_close => 'Schließen';

  @override
  String get common_skip => 'Überspringen';

  @override
  String get common_done => 'Fertig';

  @override
  String get common_filter => 'Filter';

  @override
  String get common_info => 'Info';

  @override
  String get common_search => 'Suchen…';

  @override
  String get common_name => 'Name';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_profile => 'Profil';

  @override
  String get onboarding_welcomeTitle => 'Willkommen bei Kaizen';

  @override
  String get onboarding_profileNameLabel => 'Profilname';

  @override
  String get onboarding_profileNameHint => 'Gib deinen Namen ein';

  @override
  String get onboarding_stepProfileTitle => 'Lernen wir uns kennen';

  @override
  String get onboarding_stepProfileSubtitle =>
      'Deine Daten helfen uns, deine Tagesziele zu berechnen.';

  @override
  String get onboarding_stepGoalTitle => 'Was ist dein Ziel?';

  @override
  String get onboarding_stepGoalSubtitle =>
      'Wir passen Kalorien und Makros entsprechend an.';

  @override
  String get onboarding_stepMacrosTitle => 'Deine Tagesziele';

  @override
  String get onboarding_stepMacrosSubtitle =>
      'Individuell für dich berechnet — jederzeit im Profil änderbar.';

  @override
  String get onboarding_stepScheduleTitle => 'Dein Wochenplan';

  @override
  String get onboarding_stepScheduleSubtitle =>
      'Wähle Trainingstage und optional Uhrzeiten. Leer lassen ist auch okay.';

  @override
  String get onboarding_stepScheduleLaterHint =>
      'Du kannst deinen Wochenplan jederzeit unter Profil → Profil bearbeiten anpassen.';

  @override
  String get onboarding_skipSchedule => 'Vorerst überspringen';

  @override
  String get onboarding_stepNotificationsTitle => 'Dranbleiben';

  @override
  String get onboarding_stepNotificationsSubtitle =>
      'Erinnerungen 15 Minuten vor jedem geplanten Training.';

  @override
  String get onboarding_stepMorningTitle => 'Dein Morgen-Workout';

  @override
  String get onboarding_stepMorningSubtitle =>
      'Stelle deine persönliche Morgenroutine zusammen — ideal einmal täglich am Morgen.';

  @override
  String get onboarding_enableNotifications =>
      'Trainings-Erinnerungen aktivieren';

  @override
  String get onboarding_skipNotifications => 'Später';

  @override
  String get onboarding_next => 'Weiter';

  @override
  String get onboarding_finish => 'Los geht\'s';

  @override
  String get onboarding_back => 'Zurück';

  @override
  String get onboarding_morningSelected => 'Ausgewählte Übungen';

  @override
  String get onboarding_morningPickFrom => 'Aus Katalog hinzufügen';

  @override
  String get onboarding_morningTabStretch => 'Dehnen / Yoga';

  @override
  String get onboarding_morningTabCalisthenics => 'Calisthenics';

  @override
  String get onboarding_morningTabGym => 'Fitnessstudio';

  @override
  String get onboarding_morningMinOne =>
      'Mindestens eine Übung im Morgen-Workout behalten.';

  @override
  String get schedule_editorHint =>
      'Tag antippen = Training. Auf die Uhr tippen für die Zeit — optional.';

  @override
  String get schedule_editorTitle => 'Wochenplan';

  @override
  String get schedule_tapToEdit => 'Tippen zum Bearbeiten';

  @override
  String get schedule_emptySummary => 'Noch nichts geplant';

  @override
  String get schedule_activityGym => 'Fitnessstudio';

  @override
  String get schedule_activityCalisthenics => 'Körpergewicht';

  @override
  String get schedule_activityShortGym => 'Gym';

  @override
  String get schedule_activityShortCalisthenics => 'KG';

  @override
  String get schedule_activityShortRunning => 'Lauf';

  @override
  String get schedule_activityShortStretch => 'Dehn';

  @override
  String get profile_trainingReminders => 'Trainings-Erinnerungen';

  @override
  String get profile_trainingRemindersSubtitle =>
      'Benachrichtigung 15 Minuten vor geplanten Workouts';

  @override
  String get profile_fastingHud => 'Intervallfasten';

  @override
  String get profile_fastingHudSubtitle =>
      'Essensfenster-Timer auf dem Home Screen anzeigen';

  @override
  String get profile_waterTracking => 'Wasser tracken';

  @override
  String get profile_waterTrackingSubtitle =>
      'Wasser-Fortschrittsbalken auf dem Home Screen anzeigen';

  @override
  String get profile_waterGoal => 'Tägliches Wasserziel';

  @override
  String profile_waterGoalHint(Object liters) {
    return 'Empfehlung aus deinem Profil: $liters L';
  }

  @override
  String get fasting_setupTitle => 'Essensfenster';

  @override
  String get fasting_setupSubtitle =>
      'Ziehe den grünen Bereich, um dein Essensfenster festzulegen — morgens links bis abends rechts.';

  @override
  String get fasting_save => 'Speichern';

  @override
  String get fasting_reminders => 'Erinnerungen';

  @override
  String get fasting_remindersSubtitle =>
      '15 Min. bevor du essen darfst, 30 Min. bevor das Fenster schließt';

  @override
  String get fasting_windowLabel => 'Essensfenster';

  @override
  String get fasting_configureTap => 'Tippen zum Einrichten';

  @override
  String get fasting_untilEating => 'Essen in';

  @override
  String get fasting_untilEatingEnd => 'Essen endet in';

  @override
  String get fasting_notificationOpenTitle => 'Essensfenster bald offen';

  @override
  String fasting_notificationOpenBody(Object time) {
    return 'Du kannst ab $time essen';
  }

  @override
  String get fasting_notificationCloseTitle => 'Essensfenster endet bald';

  @override
  String fasting_notificationCloseBody(Object time) {
    return 'Essensfenster schließt um $time';
  }

  @override
  String get fasting_notificationChannelName => 'Fasten-Erinnerungen';

  @override
  String get fasting_notificationChannelDesc =>
      'Erinnerungen vor Öffnen und Schließen des Essensfensters';

  @override
  String get schedule_activityNineMin => '9min';

  @override
  String get schedule_activityMorning => 'Morgen';

  @override
  String get schedule_activityRunning => 'Laufen';

  @override
  String get schedule_activityStretch => 'Dehnen';

  @override
  String get schedule_editInProfile => 'Wochenplan';

  @override
  String get notification_trainingReminderTitle => 'Training bald';

  @override
  String notification_trainingReminderBody(String activity, String time) {
    return '$activity in 15 Min · $time';
  }

  @override
  String get notification_trainingChannelName => 'Trainings-Erinnerungen';

  @override
  String get notification_trainingChannelDesc =>
      'Erinnerungen vor geplanten Workouts';

  @override
  String get installHint_title => 'Willkommen bei Kaizen';

  @override
  String get installHint_body =>
      'Mit der kurzen App-Einweisung lernst du die wichtigsten Bereiche kennen. Du kannst sie überspringen und jederzeit erneut starten unter Profil → Einstellungen → App-Einweisung.';

  @override
  String get installHint_startTour => 'Einweisung starten';

  @override
  String get installHint_gotIt => 'Verstanden';

  @override
  String get start_featured => 'FEATURED';

  @override
  String get start_categories => 'KATEGORIEN';

  @override
  String get start_days => 'TAGE';

  @override
  String get start_open => 'Öffnen';

  @override
  String get start_heroPickGallery => 'Aus Galerie wählen';

  @override
  String get start_heroTakePhoto => 'Foto aufnehmen';

  @override
  String get start_heroResetDefault => 'Auf Standard zurücksetzen';

  @override
  String get start_cameraGalleryError =>
      'Kamera/Galerie konnte nicht geöffnet werden.';

  @override
  String start_cameraGalleryErrorWithDetail(Object detail) {
    return 'Kamera/Galerie Fehler: $detail';
  }

  @override
  String get start_imageSaveFailed => 'Konnte Bild nicht speichern.';

  @override
  String get home_bodyViewRecovery => 'Erholung';

  @override
  String get home_bodyViewAfterburn => 'Nachbrennen';

  @override
  String get home_bodyViewTrained => 'Trainiert';

  @override
  String get home_bodyViewOrgans => 'Organe';

  @override
  String get home_bodyViewSkeleton => 'Gelenke und Sehnen';

  @override
  String get home_bodyStillToTrain => 'Diese Woche noch zu trainieren';

  @override
  String get home_statusRecoveryReady => 'Alle Gruppen bereit';

  @override
  String home_statusRecoveryRecovering(int count) {
    return '$count Gruppen in Erholung';
  }

  @override
  String get home_statusAfterburnNone => 'Kein aktives Nachbrennen';

  @override
  String home_statusAfterburnActive(String kcal) {
    return '+$kcal kcal Nachbrennen';
  }

  @override
  String get home_statusTrainedComplete => 'Ganzkörper abgedeckt';

  @override
  String home_statusTrainedWeek(int trained, int total) {
    return '$trained/$total Gruppen diese Woche';
  }

  @override
  String home_statusTrainedPending(int trained, int total, Object muscles) {
    return '$trained/$total Gruppen · offen: $muscles';
  }

  @override
  String get home_statusOrgansGood => 'Ernährung im grünen Bereich';

  @override
  String home_statusOrgansAttention(int count) {
    return '$count Organe brauchen Aufmerksamkeit';
  }

  @override
  String get home_statusJointsNone => 'Noch kein Gelenk-Fokus';

  @override
  String home_statusJointsStrengthened(int count) {
    return '$count Gelenke diese Woche';
  }

  @override
  String get home_organRecommended => 'Empfohlen';

  @override
  String get home_organGoodFoods => 'Gut — letzte 30 Tage';

  @override
  String get home_organBadFoods => 'Belastend — letzte 30 Tage';

  @override
  String get home_organStatusGood => 'Gut versorgt';

  @override
  String get home_organStatusMixed => 'Gemischt';

  @override
  String get home_organStatusCareful => 'Achtung';

  @override
  String get home_organStatusNoData => 'Noch keine Daten';

  @override
  String get home_organStatusGoodActive => 'Grün aufleuchtend (24 Std.)';

  @override
  String get home_organGoodFoods24h => 'Helfende Lebensmittel — letzte 24 Std.';

  @override
  String get home_organsHint => 'Tippe ein Organ für Details.';

  @override
  String get home_bodyTabIntroRecoveryTitle => 'Recovery';

  @override
  String get home_bodyTabIntroRecoveryBody =>
      'Gelb zeigt trainierte Muskeln. Ein Muskel wird rot, wenn du ihn innerhalb von 24 Stunden in zwei mittleren Workouts direkt trainierst oder er bei drei mittleren Workouts mitarbeitet. Auch sechs direkte Gym-Sätze reichen aus. Rot hält ab dem auslösenden Workout 24 Stunden an. Die gelbe Markierung endet 48 Stunden nach dem letzten Training.';

  @override
  String get home_bodyTabIntroAfterburnTitle => 'Nachbrennen';

  @override
  String get home_bodyTabIntroAfterburnBody =>
      'Umrahmte Muskelgruppen verbrennen nach dem Training noch extra Kalorien (EPOC). Je intensiver das Training, desto länger hält das Nachbrennen an. Trainiere regelmäßig, um den Effekt zu nutzen.';

  @override
  String get home_bodyTabIntroTrainedTitle => 'Trainiert';

  @override
  String get home_bodyTabIntroTrainedBody =>
      'Blau markierte Muskelgruppen hast du diese Woche bereits trainiert. Unmarkierte Gruppen stehen noch aus — so behältst du einen ausgewogenen Wochenplan im Blick.';

  @override
  String get home_bodyTabIntroOrgansTitle => 'Organe';

  @override
  String get home_bodyTabIntroOrgansBody =>
      'Hier siehst du den Zustand deiner Organe anhand deiner Ernährung. Grün leuchtet ein Organ nur 24 Stunden, nachdem du ein helfendes Lebensmittel aufgenommen hast. Ernähre dich gesund und vielfältig — dann leuchten deine Organe grün auf. Tippe ein Organ für Details und Empfehlungen.';

  @override
  String get home_bodyTabIntroSkeletonTitle => 'Skelett';

  @override
  String get home_bodyTabIntroSkeletonBody =>
      'Grüne Gelenke hast du diese Woche durch passende Übungen gestärkt. Unmarkierte Gelenke brauchen noch Aufmerksamkeit — achte auf Mobilität und gezieltes Training.';

  @override
  String get home_skeletonHint => 'Grüne Gelenke wurden diese Woche gestärkt.';

  @override
  String get home_jointTrainedThisWeek => 'Diese Woche gestärkt';

  @override
  String get home_jointNotTrainedThisWeek => 'Diese Woche nicht trainiert';

  @override
  String get home_muscleExercises => 'Gute Übungen';

  @override
  String get home_muscleChest => 'Brust';

  @override
  String get home_muscleBack => 'Rücken';

  @override
  String get home_muscleShoulders => 'Schultern';

  @override
  String get home_muscleBiceps => 'Bizeps';

  @override
  String get home_muscleTriceps => 'Trizeps';

  @override
  String get home_muscleAbs => 'Bauch';

  @override
  String get home_muscleLegs => 'Beine';

  @override
  String get home_muscleForearms => 'Unterarme';

  @override
  String get home_muscleNeck => 'Nacken';

  @override
  String get home_bodyRecoveryHint =>
      'Innerhalb von 24 Stunden führen zwei mittlere Workouts mit direkter Belastung, drei mit Beteiligung oder sechs direkte Gym-Sätze zu Rot. Nach 24 Stunden wechselt Rot zu Gelb.';

  @override
  String get home_bodyAfterburnHint =>
      'Ein blaues Leuchten um den Muskel zeigt, dass sein geschätztes Nachbrennfenster noch läuft.';

  @override
  String get home_bodyAfterburnTitle => 'Nachbrennen bisher';

  @override
  String home_bodyAfterburnKcalValue(String kcal) {
    return '+$kcal kcal';
  }

  @override
  String get home_bodyLegendRecoveryRed => 'Hohe Belastung <24h';

  @override
  String get home_bodyLegendRecoveryYellow => 'Trainiert <48h';

  @override
  String get home_bodyLegendAfterburn => 'Blaues Leuchten bei Nachbrennen';

  @override
  String get home_bodyStreakLabel => 'STREAK';

  @override
  String get home_startIntro => 'Einleitung starten';

  @override
  String get home_hudTodaysAnalytics => 'Tagesanalyse';

  @override
  String get home_hudCubeDaily => 'Tages';

  @override
  String get home_hudCubeAnalytics => 'Analyse';

  @override
  String home_hudSteps(int count) {
    return 'Schritte: $count';
  }

  @override
  String home_hudBurned(int kcal) {
    return 'Verbrannt: $kcal kcal';
  }

  @override
  String home_hudDistanceRan(Object distance) {
    return 'Laufstrecke: $distance';
  }

  @override
  String home_hudWorkouts(int count) {
    return 'Workouts: $count';
  }

  @override
  String home_hudCaloriesIn(int kcal) {
    return 'Kalorien aufgenommen: $kcal kcal';
  }

  @override
  String home_hudProtein(int grams) {
    return 'Protein: ${grams}g';
  }

  @override
  String home_hudCarbs(int grams) {
    return 'Kohlenhydrate: ${grams}g';
  }

  @override
  String home_hudFats(int grams) {
    return 'Fette: ${grams}g';
  }

  @override
  String get home_hudRecoveryNoData => 'Recovery: no data';

  @override
  String home_hudRecovery(Object sleep, Object quality) {
    return 'Recovery: $sleep, $quality';
  }

  @override
  String get home_hudSleepNone => 'keine Schlafdaten';

  @override
  String home_hudSleepDuration(int hours, int minutes) {
    return '${hours}h ${minutes}m Schlaf';
  }

  @override
  String home_hudSleepDurationHours(int hours) {
    return '${hours}h Schlaf';
  }

  @override
  String home_hudSleepDurationMinutes(int minutes) {
    return '${minutes}m Schlaf';
  }

  @override
  String get home_hudSleepQualityBad => 'schlechte Qualität';

  @override
  String get home_hudSleepQualityGood => 'gute Qualität';

  @override
  String get home_hudSleepQualityPerfect => 'perfekte Qualität';

  @override
  String get home_hudSummaryDoingWell => 'Gut dabei diese Woche.';

  @override
  String get home_hudSummaryNoneToday => 'Beweg dich heute noch.';

  @override
  String get home_hudSummaryOneToday => 'Super! Mach weiter so.';

  @override
  String get home_hudSummaryTwoPlusToday => 'Du bist unglaublich!';

  @override
  String get home_hudSummaryEatHealthy => 'Gesund essen.';

  @override
  String get home_hudSummaryMoveToday => 'Beweg deinen Körper heute.';

  @override
  String get home_hudSummaryStretchToday =>
      'Du hast heute eine gute Dehn-Einheit gemacht, weiter so.';

  @override
  String get home_hudSummaryShortWorkoutToday =>
      'Super gemacht! Du hast ein kurzes Workout absolviert.';

  @override
  String get home_hudSummaryRunToday => 'Weiter so. Das war ein Super Lauf!';

  @override
  String get home_hudSummaryHardTrainingToday => 'Du bist unglaublich!';

  @override
  String home_hudTabRecoveryRest(String muscles) {
    return 'Ruhe heute deine $muscles aus.';
  }

  @override
  String get home_hudTabRecoveryAllReady =>
      'Alle Gruppen bereit zum Trainieren.';

  @override
  String home_hudTabAfterburnEpoc(int hours) {
    return 'Berechnet via EPOC. Nachbrennen kann je nach Intensität bis zu ${hours}h anhalten.';
  }

  @override
  String home_hudTabAfterburnActive(int kcal, String remaining) {
    return '+$kcal kcal verbrannt · noch $remaining';
  }

  @override
  String get home_hudTabAfterburnNone => 'Aktuell kein Nachbrennen.';

  @override
  String get home_hudTabAfterburnUnknownRemaining => 'noch aktiv';

  @override
  String home_hudTabTrainedOpen(String muscles) {
    return 'Noch zu trainieren: $muscles';
  }

  @override
  String get home_hudTabTrainedComplete =>
      'Alle Muskelgruppen diese Woche trainiert.';

  @override
  String home_hudTabOrgansNeed(String organs) {
    return 'Brauchen bessere Nährstoffe: $organs';
  }

  @override
  String get home_hudTabOrgansAllGood => 'Alle Organe gut versorgt.';

  @override
  String get home_hudTabOrgansEatToday => 'Iss heute gesund.';

  @override
  String home_hudTabJointsNeed(String joints) {
    return 'Diese Woche noch stärken: $joints';
  }

  @override
  String get home_hudTabJointsAllDone => 'Alle Gelenke diese Woche abgedeckt.';

  @override
  String home_hudTabDurationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String home_hudTabDurationHours(int hours) {
    return '${hours}h';
  }

  @override
  String home_hudTabDurationMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String get home_hudMuscleChest => 'Brust';

  @override
  String get home_hudMuscleBack => 'Rücken';

  @override
  String get home_hudMuscleShoulders => 'Schultern';

  @override
  String get home_hudMuscleBiceps => 'Bizeps';

  @override
  String get home_hudMuscleTriceps => 'Trizeps';

  @override
  String get home_hudMuscleAbs => 'Bauch';

  @override
  String get home_hudMuscleLegs => 'Beine';

  @override
  String get home_hudMuscleForearms => 'Unterarme';

  @override
  String get home_hudMuscleNeck => 'Nacken';

  @override
  String get home_hudOrganBrain => 'Gehirn';

  @override
  String get home_hudOrganHeart => 'Herz';

  @override
  String get home_hudOrganLungs => 'Lunge';

  @override
  String get home_hudOrganLiver => 'Leber';

  @override
  String get home_hudOrganStomach => 'Magen';

  @override
  String get home_hudOrganIntestines => 'Darm';

  @override
  String get home_hudOrganKidneys => 'Nieren';

  @override
  String get home_hudJointNeck => 'Nacken';

  @override
  String get home_hudJointShoulders => 'Schultern';

  @override
  String get home_hudJointElbows => 'Ellbogen';

  @override
  String get home_hudJointWrists => 'Handgelenke';

  @override
  String get home_hudJointSpine => 'Wirbelsäule';

  @override
  String get home_hudJointHips => 'Hüfte';

  @override
  String get home_hudJointKnees => 'Knie';

  @override
  String get home_hudJointShins => 'Schienbein';

  @override
  String get home_hudJointAnkles => 'Sprunggelenk';

  @override
  String get home_bodyFront => 'Vorne';

  @override
  String get home_bodyBack => 'Hinten';

  @override
  String get category_9min_title => '9min';

  @override
  String get category_9min_description =>
      'Ein kurzes Workout, das deinen ganzen Körper in kurzer Zeit aktiviert. Ideal als Aufwärmung oder Morgen-Workout.';

  @override
  String get category_hercules_title => 'Optimiert für Läufer';

  @override
  String get category_hercules_description =>
      'Stelle deine eigene Routine für Läufer zusammen. Standard enthält 9min, Dehnen und Extra-Übungen für Bein-Sehnen und Gelenke.';

  @override
  String get category_onlyStretch_title => 'Dehnen';

  @override
  String get category_onlyStretch_description =>
      'Eine kurze Dehnroutine für Menschen, die viel sitzen.';

  @override
  String get category_wakeup_title => 'Ganzkörper Wake-Up';

  @override
  String get category_wakeup_description =>
      'Festes Ganzkörper-Aktivierungsprogramm mit 20 Übungen. Mobilisierung, Kraft und Dehnung in ca. 20 Minuten.';

  @override
  String get category_gym_title => 'Fitnessstudio';

  @override
  String get category_gym_description =>
      'Erstelle eigene Workouts und trage sie täglich in dein Training ein.';

  @override
  String get category_calisthenics_title => 'Körpergewicht';

  @override
  String get category_calisthenics_description =>
      'Erstelle eigene Workouts und trage sie täglich in dein Training ein.';

  @override
  String get category_running_title => 'Lauf';

  @override
  String get category_running_description =>
      'Routen planen oder direkt starten — Distanz, Höhenmeter und Pace live tracken.';

  @override
  String get category_workout_title => 'Workout';

  @override
  String get category_workout_description =>
      'Gym, Calisthenics, Dehnen und Morgen-Workout — suchen, filtern und starten.';

  @override
  String get category_food_title => 'Lebensmittel und Gerichte';

  @override
  String get category_food_description =>
      'Erstelle eigene Gerichte und füge sie zu deiner Tagesbilanz hinzu, trage Lebensmittel direkt ein oder scanne sie einfach.';

  @override
  String get category_friends_title => 'Freunde';

  @override
  String get category_friends_description =>
      'Tritt in Challenges an und verfolge Freunde live auf der Laufkarte.';

  @override
  String get tour_stepMannequinTitle => 'Dein Körper im Überblick';

  @override
  String get tour_stepMannequinDescription =>
      'Das Körpermodell aktualisiert sich anhand deiner eingetragenen Workouts, Lebensmittel und Gerichte. Die Markierungen zeigen dir eine Einschätzung deiner Belastung, Ernährung und Erholung – so siehst du, welche Muskeln beansprucht wurden und wann sie voraussichtlich wieder erholt sind.';

  @override
  String get tour_stepWorkoutTitle => 'Workout';

  @override
  String get tour_stepWorkoutDescription =>
      'Hier liegen alle Workouts: 9 Min, Morning Workout, Dehnen, Fitnessstudio und Körpergewicht. Tippe rein, um zu suchen, eigene Workouts zu erstellen oder direkt zu starten.';

  @override
  String get tour_stepFriendsTitle => 'Freunde';

  @override
  String get tour_stepFriendsDescription =>
      'Tritt Challenges an und verfolge Freunde live auf der Laufkarte.';

  @override
  String get tour_step9minTitle => '9 Min Workout';

  @override
  String get tour_step9minDescription =>
      'Ein kurzes Workout, das deinen ganzen Körper in kurzer Zeit aktiviert. Ideal als Aufwärmung oder Morgen-Workout.';

  @override
  String get tour_stepHerculesTitle => 'Morning Workout';

  @override
  String get tour_stepHerculesDescription =>
      'Dein Workout-Bereich: Stelle deine persönliche Morgenroutine zusammen. Standard enthält 9min und Dehnübungen sowie Extra-Übungen für Bein-Sehnen und Gelenke.';

  @override
  String get tour_stepOnlyStretchTitle => 'Dehnen';

  @override
  String get tour_stepOnlyStretchDescription =>
      'Eine kurze Dehnroutine für Menschen, die viel sitzen.';

  @override
  String get tour_stepGymTitle => 'Fitnessstudio';

  @override
  String get tour_stepGymDescription =>
      'Erstelle eigene Workouts und trage sie täglich in dein Training ein.';

  @override
  String get tour_stepCalisthenicsTitle => 'Körpergewicht';

  @override
  String get tour_stepCalisthenicsDescription =>
      'Erstelle eigene Workouts und trage sie täglich in dein Training ein.';

  @override
  String get tour_stepRunningTitle => 'Laufen';

  @override
  String get tour_stepRunningDescription =>
      'Erstelle eigene Laufstrecken und tracke deine Läufe live.';

  @override
  String get tour_stepFoodTitle => 'Lebensmittel';

  @override
  String get tour_stepFoodDescription =>
      'Suche Lebensmittel und füge sie direkt zu deiner Tagesbilanz hinzu – oder erstelle eine Mahlzeit und speichere sie.';

  @override
  String get tour_stepShoppingTitle => 'Dein Einkaufszettel';

  @override
  String get tour_stepShoppingDescription =>
      'Über den kleinen Zettel öffnest du deine Einkaufsliste. Sammle Lebensmittel mit Mengenangaben, hake Einkäufe ab und speichere Listen für später.';

  @override
  String get tour_stepMetabolicTitle => 'Tages-Nährwerte';

  @override
  String get tour_stepMetabolicDescription =>
      'Dein persönliches Kalorien- und Makroziel basierend auf Profil und Aktivität. Sieh hier, wie viel du heute schon gegessen hast.';

  @override
  String get tour_stepCalendarTitle => 'Workout-Kalender';

  @override
  String get tour_stepCalendarDescription =>
      'Alle absolvierten Workouts im Monatsüberblick. Tippe einen Tag für Details oder die 30-Tage-Zusammenfassung unten rechts.';

  @override
  String get tour_stepGalleryTitle => 'Fortschritts-Galerie';

  @override
  String get tour_stepGalleryDescription =>
      'Speichere Fortschrittsfotos und vergleiche deine Entwicklung über Wochen und Monate hinweg.';

  @override
  String get tour_stepWeightTitle => 'Gewichtstracking';

  @override
  String get tour_stepWeightDescription =>
      'Hier siehst du dein aktuelles Gewicht. Mit dem Plus-Button trägst du dein heutiges Gewicht ein.';

  @override
  String get tour_stepHealthTitle => 'Deine Gesundheit';

  @override
  String get tour_stepHealthDescription =>
      'Diese Karte vereint deine Trainings-, Ernährungs- und Gesundheitsverläufe. Wähle oben einen Wert und 7 oder 28 Tage; tippe im Graphen auf einen Tag für Details. Über das Info-Symbol kannst du Apple Health oder Health Connect verbinden und deine Freigaben verwalten.';

  @override
  String get tour_stepLevelingTitle => 'Level & Abzeichen';

  @override
  String get tour_stepLevelingDescription =>
      'Ganz oben findest du dein Profil, dein Level und deine Körperdaten. Mit abgeschlossenen Workouts und Trainingsserien sammelst du Levels. Tippe auf den Pokal, um deine Abzeichen und Erfolge anzusehen.';

  @override
  String tour_progress(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get profile_settingsTooltip => 'Einstellungen';

  @override
  String get profile_metabolicTarget => 'METABOLIC TARGET';

  @override
  String get profile_analytics => 'ANALYTICS';

  @override
  String get profile_steps => 'SCHRITTE';

  @override
  String get profile_sleep => 'SCHLAF';

  @override
  String get profile_sleepLastNight => 'Letzte Nacht';

  @override
  String get profile_editProfile => 'Profil bearbeiten';

  @override
  String get profile_settings => 'Einstellungen';

  @override
  String get profile_settingsSectionFeatures => 'Funktionen';

  @override
  String get profile_settingsSectionSystem => 'App & System';

  @override
  String get profile_pinLevelIcon => 'Rang-Icon zum Startbildschirm hinzufügen';

  @override
  String get profile_pinLevelIconHint =>
      'Öffnet Kaizen und zeigt deinen aktuellen Rang.';

  @override
  String get profile_pinLevelIconUnavailable =>
      'Halte eine freie Stelle auf dem Startbildschirm gedrückt und wähle unter Widgets „Kaizen-Rang“.';

  @override
  String get profile_appTour => 'App-Einweisung';

  @override
  String get profile_appTourSubtitle =>
      'Interaktive Tour durch alle Bereiche der App';

  @override
  String get profile_syncSteps => 'Schritte synchronisieren';

  @override
  String get profile_syncStepsSubtitle =>
      'Apple Health / Health Connect verbinden';

  @override
  String get profile_syncSleep => 'Schlaf synchronisieren';

  @override
  String get profile_syncSleepSubtitle =>
      'Schlaf der letzten Nacht aus Apple Health / Health Connect importieren';

  @override
  String get profile_workoutVoice => 'Workoutstimme';

  @override
  String get profile_workoutVoiceSubtitle =>
      'Sprachansagen während des Trainings';

  @override
  String get profile_workoutVoiceGenderTitle => 'Stimmtyp';

  @override
  String get profile_workoutVoiceGenderSubtitle =>
      'Weibliche oder männliche Stimme für Workouts und Laufen';

  @override
  String get profile_workoutVoiceFemale => 'Weiblich';

  @override
  String get profile_workoutVoiceMale => 'Männlich';

  @override
  String get profile_workoutVoiceSystem => 'Systemstandard';

  @override
  String get profile_workoutVoicePreview => 'Stimme testen';

  @override
  String get profile_lightMode => 'Hellmodus';

  @override
  String get profile_lightModeSubtitle =>
      'Eingeschaltet: helle Oberflächen. Aus: bisheriges dunkles Design.';

  @override
  String get settings_languageTitle => 'Deutsche Sprache';

  @override
  String get settings_languageSubtitle => 'Ein: Deutsch. Aus: Englisch.';

  @override
  String get profile_gallery => 'Deine Galerie';

  @override
  String get profile_updateWeight => 'Gewicht aktualisieren';

  @override
  String get profile_weightKgLabel => 'Gewicht (kg)';

  @override
  String get profile_weightHint => 'z. B. 72.5';

  @override
  String get profile_updated => 'Profil aktualisiert.';

  @override
  String get profile_dailyCalorieGoal => 'Kalorien heute';

  @override
  String get profile_kcalGoal => 'KCAL ZIEL';

  @override
  String get profile_today => 'HEUTE';

  @override
  String profile_todayWithPercent(int percent) {
    return 'HEUTE · $percent%';
  }

  @override
  String get profile_protein => 'PROTEIN';

  @override
  String get profile_carbs => 'CARBOHYDRATES';

  @override
  String get profile_fats => 'FATS';

  @override
  String get profile_macroProteinShort => 'Eiweiß';

  @override
  String get profile_macroFatShort => 'Fett';

  @override
  String profile_macroSummary(Object protein, Object carbs, Object fats) {
    return 'E $protein g · KH $carbs g · F $fats g';
  }

  @override
  String get profile_kcalBurned => 'kcal verbrannt';

  @override
  String profile_workoutsKcal(Object kcal) {
    return 'Workouts: $kcal kcal';
  }

  @override
  String profile_stepsKcal(Object count, Object kcal) {
    return 'Schritte: $count · $kcal kcal';
  }

  @override
  String profile_stepsKcalNoData(Object kcal) {
    return 'Schritte: $kcal kcal (keine Schrittdaten)';
  }

  @override
  String profile_dishEntry(Object time) {
    return 'Gericht  •  $time';
  }

  @override
  String get profile_editTitle => 'Profil bearbeiten';

  @override
  String get profile_nameLabel => 'Name';

  @override
  String get profile_ageLabel => 'Alter';

  @override
  String get profile_heightLabel => 'Größe (cm)';

  @override
  String get profile_weightLabel => 'Gewicht (kg)';

  @override
  String get profile_bodyFatLabel => 'Fettanteil (%)';

  @override
  String get profile_muscleMassLabel => 'Muskelmasse (kg)';

  @override
  String get profile_boneWeightLabel => 'Knochengewicht (kg)';

  @override
  String get profile_genderLabel => 'Geschlecht';

  @override
  String get profile_activityLabel => 'Aktivität';

  @override
  String get profile_goalLabel => 'Ziel';

  @override
  String profile_biometricSummary(
    Object height,
    Object weight,
    Object age,
    Object gender,
  ) {
    return '$height · $weight · $age J · $gender';
  }

  @override
  String profile_foodEntryGrams(Object grams, Object time) {
    return '$grams g · $time';
  }

  @override
  String get gender_male => 'Male';

  @override
  String get gender_female => 'Female';

  @override
  String get activity_sedentary => 'Sitzend';

  @override
  String get activity_light => 'Leicht';

  @override
  String get activity_moderate => 'Moderat';

  @override
  String get activity_high => 'Hoch';

  @override
  String get activity_athlete => 'Athlet';

  @override
  String get goal_lose => 'Cut';

  @override
  String get goal_maintain => 'Maintain';

  @override
  String get goal_gain => 'Bulk';

  @override
  String get validation_nameRequired => 'Bitte einen Profilnamen eingeben.';

  @override
  String get validation_ageRequired => 'Bitte ein Alter eingeben.';

  @override
  String get validation_heightRequired => 'Bitte eine Größe eingeben.';

  @override
  String get validation_weightRequired => 'Bitte ein Gewicht eingeben.';

  @override
  String get validation_ageInvalid => 'Bitte ein gültiges Alter eingeben.';

  @override
  String get validation_heightInvalid =>
      'Bitte eine gültige Größe in cm eingeben.';

  @override
  String get validation_weightInvalid =>
      'Bitte ein gültiges Gewicht in kg eingeben.';

  @override
  String get validation_bodyFatInvalid =>
      'Bitte einen realistischen Fettanteil eingeben.';

  @override
  String get validation_muscleMassInvalid =>
      'Bitte eine gültige Muskelmasse eingeben.';

  @override
  String get validation_boneWeightInvalid =>
      'Bitte ein gültiges Knochengewicht eingeben.';

  @override
  String get avatar_mobileOnly =>
      'Avatar-Upload ist aktuell nur auf dem Handy aktiv.';

  @override
  String get avatar_takePhoto => 'Foto aufnehmen';

  @override
  String get avatar_pickGallery => 'Aus Galerie wählen';

  @override
  String get avatar_remove => 'Avatar entfernen';

  @override
  String get avatar_saveFailed => 'Konnte Avatar nicht speichern.';

  @override
  String get month_january => 'Januar';

  @override
  String get month_february => 'Februar';

  @override
  String get month_march => 'März';

  @override
  String get month_april => 'April';

  @override
  String get month_may => 'Mai';

  @override
  String get month_june => 'Juni';

  @override
  String get month_july => 'Juli';

  @override
  String get month_august => 'August';

  @override
  String get month_september => 'September';

  @override
  String get month_october => 'Oktober';

  @override
  String get month_november => 'November';

  @override
  String get month_december => 'Dezember';

  @override
  String get weekday_mon => 'Mo';

  @override
  String get weekday_tue => 'Di';

  @override
  String get weekday_wed => 'Mi';

  @override
  String get weekday_thu => 'Do';

  @override
  String get weekday_fri => 'Fr';

  @override
  String get weekday_sat => 'Sa';

  @override
  String get weekday_sun => 'So';

  @override
  String get calendar_nutritionAvg => 'ERNÄHRUNG (Ø pro Tag)';

  @override
  String get calendar_workouts => 'WORKOUTS';

  @override
  String get calendar_noWorkoutsPeriod => 'Keine Workouts in diesem Zeitraum.';

  @override
  String get calendar_noWorkoutsDay => 'Keine Workouts an diesem Tag.';

  @override
  String get calendar_consumption => 'VERBRAUCH';

  @override
  String get calendar_nutrition => 'ERNÄHRUNG';

  @override
  String get calendar_noMealsDay => 'Keine Mahlzeiten an diesem Tag.';

  @override
  String get calendar_feelingEmpty => 'Feeling: --';

  @override
  String get calendar_feelingSaved => 'Feeling gespeichert';

  @override
  String get calendar_hint =>
      'Punkte = Workout-Typ. Tippe einen Tag für Details.';

  @override
  String get calendar_workoutType9min => '9 Min';

  @override
  String get calendar_workoutTypeHercules => 'Morning Workout';

  @override
  String get calendar_workoutTypeStretch => 'Stretch / Yoga';

  @override
  String get calendar_workoutTypeGym => 'Gym';

  @override
  String get calendar_workoutTypeCalisthenics => 'Calisthenics';

  @override
  String get calendar_workoutTypeRun => 'Lauf';

  @override
  String get calendar_workoutTypeLegacy => 'Training';

  @override
  String calendar_calorieBreakdown(Object label, Object kcal) {
    return '$label · $kcal kcal';
  }

  @override
  String get calendar_30DaySummary => '30-Tage Zusammenfassung';

  @override
  String calendar_streakDays(int count) {
    return '$count Tage Streak';
  }

  @override
  String calendar_workoutsInLastDays(int count, int days) {
    return '$count Workouts in den letzten $days Tagen';
  }

  @override
  String calendar_kcalBurnedSuffix(int kcal) {
    return ' · $kcal kcal verbrannt';
  }

  @override
  String get steps_unavailableDevice =>
      'Schritte sind auf diesem Gerät nicht verfügbar.';

  @override
  String get steps_connectHint =>
      'Tippe auf Verbinden, um Apple Health oder Health Connect freizugeben.';

  @override
  String get steps_loadFailed => 'Schritte konnten nicht geladen werden.';

  @override
  String steps_loadedToday(int count) {
    return 'Heute: $count Schritte geladen';
  }

  @override
  String steps_todaySnack(int count) {
    return 'Heute: $count Schritte';
  }

  @override
  String get steps_appleHealth => 'Apple Health';

  @override
  String get steps_healthConnect => 'Health Connect';

  @override
  String get steps_notAvailable => 'Nicht verfügbar';

  @override
  String get steps_notSynced => 'Noch nicht synchronisiert';

  @override
  String steps_updatedAt(Object time) {
    return 'Aktualisiert um $time';
  }

  @override
  String get steps_connect => 'Verbinden';

  @override
  String get steps_refresh => 'Aktualisieren';

  @override
  String get steps_label => 'Schritte';

  @override
  String get steps_mobileOnly => 'Nur auf iPhone und Android verfügbar';

  @override
  String get steps_wearablesHint =>
      'Fitbit, Garmin und Samsung Health können über Health Connect verbunden werden.';

  @override
  String get sleep_unavailableDevice =>
      'Schlaftracking ist auf diesem Gerät nicht verfügbar.';

  @override
  String get sleep_connectHint =>
      'Tippe auf Verbinden, um Apple Health oder Health Connect für Schlaf freizugeben.';

  @override
  String get sleep_loadFailed => 'Schlafdaten konnten nicht geladen werden.';

  @override
  String sleep_loadedLastNight(Object duration) {
    return 'Letzte Nacht: $duration geladen';
  }

  @override
  String sleep_durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String sleep_durationHours(int hours) {
    return '${hours}h';
  }

  @override
  String sleep_durationMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String get sleep_mobileOnly => 'Nur auf iPhone und Android verfügbar';

  @override
  String get home_statusSleepNone => 'Keine Schlafdaten synchronisiert';

  @override
  String home_statusSleepLastNight(int hours, int minutes) {
    return '${hours}h ${minutes}m Schlaf letzte Nacht';
  }

  @override
  String home_statusSleepHours(int hours) {
    return '${hours}h Schlaf letzte Nacht';
  }

  @override
  String home_statusSleepMinutes(int minutes) {
    return '${minutes}m Schlaf letzte Nacht';
  }

  @override
  String get health_stepsUnsupported =>
      'Schritte sind nur auf iPhone und Android verfügbar.';

  @override
  String get health_stepsPermissionConnect =>
      'Verbinde Apple Health oder Health Connect, um Schritte zu laden.';

  @override
  String get health_stepsPermissionDenied =>
      'Berechtigung abgelehnt. In den System-Einstellungen kannst du Apple Health bzw. Health Connect erneut freigeben.';

  @override
  String get health_connectNotInstalled =>
      'Health Connect ist nicht installiert. Bitte aus dem Play Store installieren und Fitbit/Garmin/Samsung dort verbinden.';

  @override
  String get analytics_weight => 'Gewicht';

  @override
  String get analytics_steps => 'Schritte';

  @override
  String get analytics_calories => 'Kalorien';

  @override
  String get analytics_burn => 'Verbrauch';

  @override
  String get analytics_water => 'Wasser';

  @override
  String get analytics_afterburn => 'Nachbrennen';

  @override
  String get analytics_protein => 'Protein';

  @override
  String get analytics_fat => 'Fett';

  @override
  String get analytics_carbs => 'Carbs';

  @override
  String get analytics_workouts => 'Workouts';

  @override
  String get analytics_emptyWeight =>
      'Gewicht eintragen, um den Verlauf zu sehen.';

  @override
  String get analytics_emptySteps =>
      'Schritte synchronisieren, um die Aktivität zu sehen.';

  @override
  String get analytics_emptyCalories =>
      'Noch keine Kalorien in den letzten 30 Tagen.';

  @override
  String get analytics_emptyBurn =>
      'Noch kein Verbrauch in den letzten 30 Tagen.';

  @override
  String get analytics_emptyWater =>
      'Noch kein Wasser in den letzten 30 Tagen.';

  @override
  String get analytics_emptyAfterburn =>
      'Noch kein Nachbrennen in den letzten 30 Tagen.';

  @override
  String get analytics_emptyProtein =>
      'Noch kein Protein in den letzten 30 Tagen.';

  @override
  String get analytics_emptyFat => 'Noch kein Fett in den letzten 30 Tagen.';

  @override
  String get analytics_emptyCarbs =>
      'Noch keine Carbs in den letzten 30 Tagen.';

  @override
  String get analytics_emptyWorkouts =>
      'Noch keine Workouts in den letzten 30 Tagen.';

  @override
  String get analytics_unitKg => 'kg';

  @override
  String get analytics_unitKcal => 'kcal';

  @override
  String get analytics_unitMl => 'ml';

  @override
  String get analytics_unitG => 'g';

  @override
  String get analytics_addWeightHint =>
      'Gewicht eintragen, um den Verlauf zu sehen.';

  @override
  String get achievements_levelingSystem => 'Leveling System';

  @override
  String get achievements_noXp =>
      'Hier sammelst du keine XP, sondern direkt Level.';

  @override
  String get achievements_levelPerWorkout => 'Level pro Workout';

  @override
  String get achievements_onlyStretch => 'Only Stretch';

  @override
  String get achievements_nineMin => '9 Min Workout';

  @override
  String get achievements_hercules => 'Morning Workout';

  @override
  String get achievements_gymWorkout => 'Gym Workout';

  @override
  String get achievements_caliWorkout => 'Calisthenics Workout';

  @override
  String achievements_levelPlus(int count) {
    return '+$count Level';
  }

  @override
  String get achievements_streakBonus =>
      'Streak-Bonus (einmalig beim Erreichen)';

  @override
  String get achievements_streak10 => '10 Tage';

  @override
  String get achievements_streak30 => '30 Tage';

  @override
  String get achievements_streak100 => '100 Tage';

  @override
  String get achievements_streak365 => '365 Tage';

  @override
  String get achievements_streak1000 => '1000 Tage';

  @override
  String get achievements_gymCaliHint =>
      'Hinweis: Gym/Calisthenics zählen, wenn du im Workout-Detail oben auf das Häkchen „Workout abgeschlossen“ tippst.';

  @override
  String get achievements_milestones => 'Milestones';

  @override
  String get achievements_streaks => 'Streaks';

  @override
  String achievements_earnedCount(int earned, int total) {
    return '$earned / $total Earned';
  }

  @override
  String get achievements_coreLevel => 'CORE LEVEL';

  @override
  String achievements_level(int level) {
    return 'Level $level';
  }

  @override
  String achievements_rank(Object rank) {
    return 'Rank: $rank';
  }

  @override
  String get achievements_toNextMilestone => 'to next milestone';

  @override
  String achievements_nextMilestone(int level) {
    return 'Next milestone: Level $level';
  }

  @override
  String get achievements_specializations => 'Specializations';

  @override
  String get achievements_gym => 'Gym';

  @override
  String get achievements_calisthenics => 'Calisthenics';

  @override
  String get rank_rookie => 'Rookie';

  @override
  String get rank_student => 'Student';

  @override
  String get rank_trainee => 'Trainee';

  @override
  String get rank_performer => 'Performer';

  @override
  String get rank_profi => 'Profi';

  @override
  String get rank_athlet => 'Athlet';

  @override
  String get rank_krieger => 'Krieger';

  @override
  String get rank_elite => 'Elite';

  @override
  String get rank_champion => 'Champion';

  @override
  String get rank_goat => 'GOAT';

  @override
  String get rank_halbgott => 'Halbgott';

  @override
  String get badge_level0_title => 'Rookie';

  @override
  String get badge_level0_subtitle => 'Level 0';

  @override
  String get badge_level20_title => 'Student';

  @override
  String get badge_level20_subtitle => 'Level 20';

  @override
  String get badge_level50_title => 'Trainee';

  @override
  String get badge_level50_subtitle => 'Level 50';

  @override
  String get badge_level100_title => 'Performer';

  @override
  String get badge_level100_subtitle => 'Level 100';

  @override
  String get badge_level300_title => 'Profi';

  @override
  String get badge_level300_subtitle => 'Level 300';

  @override
  String get badge_level500_title => 'Athlet';

  @override
  String get badge_level500_subtitle => 'Level 500';

  @override
  String get badge_level1000_title => 'Krieger';

  @override
  String get badge_level1000_subtitle => 'Level 1000';

  @override
  String get badge_level2500_title => 'Elite';

  @override
  String get badge_level2500_subtitle => 'Level 2500';

  @override
  String get badge_level5000_title => 'Champion';

  @override
  String get badge_level5000_subtitle => 'Level 5000';

  @override
  String get badge_level7500_title => 'GOAT';

  @override
  String get badge_level7500_subtitle => 'Level 7500';

  @override
  String get badge_level10000_title => 'Halbgott';

  @override
  String get badge_level10000_subtitle => 'Level 10000';

  @override
  String get badge_streak30_title => 'Disziplin';

  @override
  String get badge_streak30_subtitle => '30 Tage Streak';

  @override
  String get badge_streak100_title => 'Eiserne Disziplin';

  @override
  String get badge_streak100_subtitle => '100 Tage Streak';

  @override
  String get badge_streak365_title => 'Krieger Mentalität';

  @override
  String get badge_streak365_subtitle => '365 Tage Streak';

  @override
  String get badge_streak500_title => 'Titan';

  @override
  String get badge_streak500_subtitle => '500 Tage Streak';

  @override
  String get badge_streak1000_title => 'Halbgott Mentalität';

  @override
  String get badge_streak1000_subtitle => '1000 Tage Streak';

  @override
  String get badge_gym50_title => 'Gym Junior';

  @override
  String get badge_gym50_subtitle => '50 Gym Workouts';

  @override
  String get badge_gym100_title => 'Gym Profi';

  @override
  String get badge_gym100_subtitle => '100 Gym Workouts';

  @override
  String get badge_gym500_title => 'Bodybuilding Junior';

  @override
  String get badge_gym500_subtitle => '500 Gym Workouts';

  @override
  String get badge_gym1000_title => 'Bodybuilder';

  @override
  String get badge_gym1000_subtitle => '1000 Gym Workouts';

  @override
  String get badge_cali50_title => 'Calisthenics Junior';

  @override
  String get badge_cali50_subtitle => '50 Calisthenics Workouts';

  @override
  String get badge_cali100_title => 'Calisthenics Profi';

  @override
  String get badge_cali100_subtitle => '100 Calisthenics Workouts';

  @override
  String get badge_cali500_title => 'Bodyweight Junior';

  @override
  String get badge_cali500_subtitle => '500 Calisthenics Workouts';

  @override
  String get badge_cali1000_title => 'Bodyweight Master';

  @override
  String get badge_cali1000_subtitle => '1000 Calisthenics Workouts';

  @override
  String get gallery_mobileOnly =>
      'Galerie ist aktuell nur auf dem Handy aktiv.';

  @override
  String get gallery_saveFailed => 'Konnte Foto nicht speichern.';

  @override
  String get gallery_title => 'Galerie';

  @override
  String get gallery_empty =>
      'Noch keine Fotos.\nTippe auf + um ein Foto zu machen.';

  @override
  String get food_tabFoods => 'Lebensmittel';

  @override
  String get food_tabDishes => 'Gerichte';

  @override
  String get food_tabSupplements => 'Supplements';

  @override
  String get food_supplementsSearchHint => 'Supplements suchen…';

  @override
  String get food_supplementsEmpty =>
      'Heute noch keine Supplements eingetragen.';

  @override
  String get food_supplementsToday => 'Heute';

  @override
  String food_supplementMg(Object mg) {
    return '$mg mg';
  }

  @override
  String get food_supplementAddTitle => 'Supplement hinzufügen';

  @override
  String get food_supplementAmountLabel => 'Menge (mg)';

  @override
  String get food_supplementSlotMorning => 'Morgens';

  @override
  String get food_supplementSlotMidday => 'Mittags';

  @override
  String get food_supplementSlotEvening => 'Abends';

  @override
  String get food_supplementSlotLabel => 'Tageszeit';

  @override
  String get food_supplementDragHint =>
      'Karte lange drücken und nach Morgens, Mittags oder Abends ziehen.';

  @override
  String get food_supplementDropHere => 'Hier ablegen';

  @override
  String get food_searchHint => 'Nach Lebensmittel oder Tag suchen';

  @override
  String get food_newDish => 'Neues Gericht';

  @override
  String get food_dishPhotoAction => 'Gerichtsfoto wählen';

  @override
  String get food_dishesSearchHint => 'Gerichte suchen…';

  @override
  String get food_dishNoIngredients => 'Gericht hat noch keine Zutaten.';

  @override
  String food_dishAddedToday(Object name) {
    return '\"$name\" zum heutigen Tag hinzugefügt.';
  }

  @override
  String get food_deleteDishTitle => 'Gericht löschen?';

  @override
  String food_deleteDishBody(Object name) {
    return '\"$name\" wird unwiderruflich gelöscht.';
  }

  @override
  String get food_enterGramsMacros => 'Bitte Gramm und Makros eingeben.';

  @override
  String get food_macroProtein => 'Protein';

  @override
  String get food_macroCarbs => 'KH';

  @override
  String get food_macroFat => 'Fett';

  @override
  String get food_macroKcal => 'kcal';

  @override
  String get food_dishNameHint => 'z. B. Frühstücks-Bowl';

  @override
  String get food_newDishTitle => 'Neues Gericht';

  @override
  String get food_macrosHeading => 'Makros';

  @override
  String get food_noFoodsFound => 'Keine Lebensmittel gefunden';

  @override
  String food_foodCount(int count) {
    return '$count Lebensmittel';
  }

  @override
  String get food_macroAll => 'Alle';

  @override
  String get food_focusNeverEat => 'Nie essen';

  @override
  String get food_focusHealthyBrain => 'Gehirngesund';

  @override
  String get food_macroCarbsLong => 'Kohlenhydrate';

  @override
  String food_kcalPer100g(Object kcal) {
    return '$kcal kcal / 100 g';
  }

  @override
  String get food_renameDishTitle => 'Gericht umbenennen';

  @override
  String get food_dishNotFound => 'Gericht nicht gefunden';

  @override
  String get food_dishFallback => 'Gericht';

  @override
  String food_addedToDish(Object name, Object grams) {
    return '$name ($grams g) hinzugefügt.';
  }

  @override
  String food_addedToTodayFull(Object name, Object grams) {
    return '$name ($grams g) zum heutigen Tag hinzugefügt.';
  }

  @override
  String get food_eatToday => 'Heute essen';

  @override
  String get food_addToDishBtn => 'Zum Gericht';

  @override
  String get food_per100g => 'Pro 100 g';

  @override
  String get food_amount => 'Menge';

  @override
  String food_forGrams(Object grams) {
    return 'Für $grams g';
  }

  @override
  String get food_macrosNotStored => 'Makros nicht hinterlegt';

  @override
  String get food_macrosManualHint =>
      'Gib die Makros pro 100 g manuell ein, um dieses Lebensmittel zu einem Gericht hinzuzufügen.';

  @override
  String get food_ingredientFood => 'Lebensmittel';

  @override
  String get food_emptyDishesTitle => 'Noch keine Gerichte';

  @override
  String get food_emptyDishesBody =>
      'Erstelle dein erstes Gericht, um Mahlzeiten zu kombinieren.';

  @override
  String get food_pickIngredientTitle => 'Lebensmittel auswählen';

  @override
  String get food_manualEntry => 'manuell';

  @override
  String get food_whichDish => 'Zu welchem Gericht?';

  @override
  String get food_newDishEllipsis => 'Neues Gericht…';

  @override
  String get food_removeFromDish => 'Aus Gericht entfernen';

  @override
  String get food_barcodeScanTitle => 'Barcode scannen';

  @override
  String get food_barcodeScanHint => 'Barcode in den Rahmen halten';

  @override
  String get food_barcodeDesktopHint =>
      'Barcode-Scanner ist auf dem Handy verfügbar. Gib den Barcode hier manuell ein.';

  @override
  String get food_barcodeManualLabel => 'Barcode eingeben';

  @override
  String get food_barcodeManualHint => 'z. B. 4008400407321';

  @override
  String get food_barcodeLookupBtn => 'Produkt suchen';

  @override
  String get food_barcodeLookingUp => 'Produkt wird gesucht…';

  @override
  String get food_barcodeNotFound =>
      'Produkt nicht in Open Food Facts gefunden.';

  @override
  String get food_scannedProduct => 'Gescanntes Produkt';

  @override
  String food_barcodeValue(Object code) {
    return 'Barcode: $code';
  }

  @override
  String get muscleExercise_emptyGym =>
      'Keine Gym-Übungen für diesen Muskel hinterlegt.';

  @override
  String get muscleExercise_emptyCalisthenics =>
      'Keine Calisthenics-Übungen für diesen Muskel hinterlegt.';

  @override
  String get strength_setsLabel => 'Sätze';

  @override
  String get strength_repsLabel => 'Wiederholungen';

  @override
  String get strength_sectionMyWorkouts => 'Meine Workouts';

  @override
  String get strength_sectionPresetWorkouts => 'Vorgefertigte Workouts';

  @override
  String get strength_renameWorkoutTitle => 'Namen ändern';

  @override
  String get strength_deleteWorkoutTitle => 'Workout löschen?';

  @override
  String get strength_deleteWorkoutBody =>
      'Dieses Workout wird dauerhaft gelöscht.';

  @override
  String get strength_deleteWorkoutMenu => 'Workout löschen';

  @override
  String strength_exerciseCount(Object count) {
    return '$count Übungen';
  }

  @override
  String get strength_addToWorkoutTooltip => 'Zum Workout hinzufügen';

  @override
  String get strength_workoutFallback => 'Workout';

  @override
  String get cali_skillsHeading => 'SKILLS';

  @override
  String get gym_tabExercises => 'Übungen';

  @override
  String get gym_tabWorkouts => 'Workouts';

  @override
  String get gym_addToLastWorkout => 'Zum letzten Workout hinzufügen';

  @override
  String get gym_noWorkoutYet => 'Noch kein Workout erstellt.';

  @override
  String get gym_addWorkout => 'Workout hinzufügen';

  @override
  String get gym_addToWorkoutTitle => 'Zu Workout hinzufügen';

  @override
  String get gym_noWorkoutsCreated => 'Du hast noch keine Workouts erstellt.';

  @override
  String get gym_newWorkout => 'Neues Workout';

  @override
  String get gym_createNewWorkout => 'Neues Workout erstellen';

  @override
  String get gym_exerciseAdded => 'Übung hinzugefügt.';

  @override
  String get gym_workoutNotFound => 'Workout nicht gefunden.';

  @override
  String get gym_defaultWorkoutName => 'My Workout';

  @override
  String get cali_tabExercises => 'Übungen';

  @override
  String get cali_tabWorkouts => 'Workouts';

  @override
  String get cali_skillProgramsIntro =>
      'Hier kommen später mehrere Workouts/Programme hin, die dich Schritt für Schritt zu dieser Königsübung bringen.';

  @override
  String get cali_programBeginner => 'Beginner Program';

  @override
  String get cali_programBeginnerSub => 'Basics + Technik + Mobilität';

  @override
  String get cali_programIntermediate => 'Intermediate Program';

  @override
  String get cali_programIntermediateSub => 'Progressions + Kraftaufbau';

  @override
  String get cali_programAdvanced => 'Advanced Program';

  @override
  String get cali_programAdvancedSub => 'Skills + Volumen + Intensität';

  @override
  String get cali_programPlaceholder =>
      'Wichtig: Diese Seite ist schon verlinkt, damit die Struktur steht. Als nächstes füllen wir sie mit echten Workouts und speichern sie wie beim Gym/Cali Workout Builder.';

  @override
  String get categoryDetail_startWorkout => 'Workout starten';

  @override
  String categoryDetail_exerciseCountDuration(int count, Object duration) {
    return '$count Übungen · Gesamtzeit: $duration';
  }

  @override
  String get categoryDetail_secondsDefaultHint =>
      'Standard: 30s. Tippe auf die Sekunden, um sie zu ändern.';

  @override
  String categoryDetail_durationMinSec(int minutes, Object seconds) {
    return '$minutes Min $seconds Sek';
  }

  @override
  String get categoryDetail_heading9min => '9 Min Workout';

  @override
  String get categoryDetail_info9min =>
      'Hier kannst du die Zeiten selber anpassen, indem du auf die grünen 30s klickst.';

  @override
  String get categoryDetail_infoStretch =>
      'Hier kannst du die Zeiten selber anpassen, indem du auf die grünen 30s klickst.';

  @override
  String get categoryDetail_infoMorning =>
      'Hier kannst du die Zeiten selber anpassen, indem du auf die grünen 30s klickst. Außerdem kannst du Übungen nach Belieben hinzufügen oder entfernen.';

  @override
  String get categoryDetail_headingHercules => 'Optimiert für Läufer';

  @override
  String get morningWorkout_addExercise => 'Übung hinzufügen';

  @override
  String get morningWorkout_removeExercise => 'Übung entfernen';

  @override
  String get morningWorkout_pickExercise => 'Übung zum Workout hinzufügen';

  @override
  String get morningWorkout_sourceMorning => 'Morning';

  @override
  String get morningWorkout_sourceYoga => 'Yoga';

  @override
  String get morningWorkout_sourceGym => 'Gym';

  @override
  String get morningWorkout_sourceCalisthenics => 'Calisthenics';

  @override
  String get morningWorkout_cannotRemoveLast =>
      'Mindestens eine Übung muss im Workout bleiben.';

  @override
  String get morningWorkout_allExercisesAdded =>
      'Alle Übungen sind bereits im Workout.';

  @override
  String get categoryDetail_headingStretch => 'Only Stretch';

  @override
  String get strength_exercisesZero => '0 Übungen';

  @override
  String strength_exercisesSummary(Object kcal, int count, Object duration) {
    return '$kcal kcal · $count Übungen · $duration';
  }

  @override
  String get strength_workoutComplete => 'Workout abgeschlossen';

  @override
  String strength_workoutCompleteSnack(Object kcal) {
    return 'Workout abgeschlossen. +5 Level · $kcal kcal';
  }

  @override
  String get strength_estimatedBurn => 'Geschätzter Verbrauch';

  @override
  String get strength_exerciseFallback => 'Übung';

  @override
  String strength_exerciseKcalDuration(Object kcal, Object duration) {
    return '~$kcal kcal · $duration';
  }

  @override
  String get preset_push => 'Push Workout';

  @override
  String get preset_pull => 'Pull Workout';

  @override
  String get preset_abs => 'Ab Workout';

  @override
  String get preset_chestTriShoulder => 'Chest · Trizeps · Schulter';

  @override
  String get preset_backBiceps => 'Back · Bizeps';

  @override
  String get preset_legsAbs => 'Legs · Abs';

  @override
  String get preset_caliBack => 'Back Workout';

  @override
  String get preset_caliChest => 'Chest Workout';

  @override
  String get preset_caliAbs => 'Abs Calisthenics';

  @override
  String get preset_caliLegs => 'Leg Workout';

  @override
  String get preset_caliShoulders => 'Shoulder Workout';

  @override
  String get preset_caliHumanFlag => 'Human Flag Workout';

  @override
  String get preset_caliHandstand => 'Handstand Workout';

  @override
  String get preset_caliPlanche => 'Planche Workout';

  @override
  String get mood_title => 'Wie fühlst du dich?';

  @override
  String get mood_veryBad => 'Sehr\nschlecht';

  @override
  String get mood_bad => 'Schlecht';

  @override
  String get mood_neutral => 'Neutral';

  @override
  String get mood_good => 'Gut';

  @override
  String get mood_veryGood => 'Sehr\ngut';

  @override
  String get workout_phaseGetReady => 'GET READY';

  @override
  String get workout_phaseWork => 'WORK';

  @override
  String get workout_phaseRest => 'REST';

  @override
  String get workout_phaseComplete => 'WORKOUT COMPLETE';

  @override
  String workout_setProgress(int current, int total) {
    return 'Satz $current von $total';
  }

  @override
  String workout_finishedMessage(int count) {
    return 'Super! Du hast alle $count Übungen geschafft.';
  }

  @override
  String get workout_tapCheckHint =>
      'Tippe auf den Haken, um deinen Fortschritt zu sehen.';

  @override
  String get tts_getReady => 'Get ready';

  @override
  String get tts_halfway => 'Halbzeit';

  @override
  String get tts_start => 'Los!';

  @override
  String get tts_workoutComplete => 'Workout beendet, SUPER!';

  @override
  String tts_pauseNext(Object name) {
    return 'Pause. Nächste Übung: $name';
  }

  @override
  String get running_tabNewRoute => 'Neue Route';

  @override
  String get running_tabSaved => 'Gespeichert';

  @override
  String get running_tabHistory => 'Verlauf';

  @override
  String get running_historyEmpty => 'Noch keine Läufe';

  @override
  String get running_historyEmptyHint =>
      'Beende einen Lauf — er erscheint dann hier.';

  @override
  String running_historyMonthKm(Object km) {
    return '$km km diesen Monat';
  }

  @override
  String running_historyMonthAvgPace(Object pace) {
    return 'Ø Tempo $pace';
  }

  @override
  String get running_historyUntitledRun => 'Lauf';

  @override
  String get running_needStartEnd =>
      'Setze mindestens einen Start- und einen Zielpunkt.';

  @override
  String running_unexpectedError(Object detail) {
    return 'Unerwarteter Fehler: $detail';
  }

  @override
  String running_routeSaved(Object name) {
    return 'Route \"$name\" gespeichert.';
  }

  @override
  String get running_saveRouteTitle => 'Route speichern';

  @override
  String get running_routeNameLabel => 'Name';

  @override
  String running_defaultRouteName(Object date) {
    return 'Lauf $date';
  }

  @override
  String get running_myLocation => 'Mein Standort';

  @override
  String get running_reset => 'Zurücksetzen';

  @override
  String get running_removeLastPoint => 'Letzten Punkt entfernen';

  @override
  String get running_mapHint =>
      'Tippe auf die Karte für deine Route oder starte sofort.';

  @override
  String get running_calculateRoute => 'Route berechnen';

  @override
  String get running_save => 'Speichern';

  @override
  String get running_points => 'PUNKTE';

  @override
  String get running_distance => 'DISTANZ';

  @override
  String get running_elevation => 'HÖHE';

  @override
  String get running_pinStart => 'S';

  @override
  String get running_pinEnd => 'Z';

  @override
  String get running_noRoutes => 'Noch keine Routen';

  @override
  String get running_noRoutesHint =>
      'Wechsle zum Tab \"Neue Route\" und plane deinen ersten Lauf.';

  @override
  String get running_deleteRouteTitle => 'Route löschen?';

  @override
  String running_deleteRouteBody(Object name) {
    return '\"$name\" wird unwiderruflich entfernt.';
  }

  @override
  String get running_renameTitle => 'Umbenennen';

  @override
  String get running_deleteConfirmBody =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get run_gpsOff => 'Standortdienste sind ausgeschaltet.';

  @override
  String get run_gpsDenied => 'Standortfreigabe verweigert.';

  @override
  String run_gpsError(Object detail) {
    return 'GPS-Fehler: $detail';
  }

  @override
  String run_gpsStartFailed(Object detail) {
    return 'GPS konnte nicht gestartet werden: $detail';
  }

  @override
  String run_ttsIn100m(Object instruction) {
    return 'In 100 Metern: $instruction';
  }

  @override
  String run_ttsIn300m(Object instruction) {
    return 'In 300 Metern: $instruction';
  }

  @override
  String get run_ttsGoalReached => 'Ziel erreicht. Gut gemacht!';

  @override
  String get run_goalReached => 'Ziel erreicht';

  @override
  String get run_ttsStarted => 'Lauf gestartet. Viel Erfolg!';

  @override
  String get run_ttsPause => 'Pause.';

  @override
  String get run_ttsResume => 'Weiter geht\'s.';

  @override
  String get run_endTitle => 'Lauf beenden?';

  @override
  String get run_endBody => 'Distanz, Zeit und der Lauf werden gespeichert.';

  @override
  String get run_keepRunning => 'Weiterlaufen';

  @override
  String get run_end => 'Beenden';

  @override
  String get run_finishedTitle => 'Lauf beendet';

  @override
  String get run_distance => 'Distanz';

  @override
  String get run_time => 'Zeit';

  @override
  String get run_calories => 'Kalorien';

  @override
  String get run_level => 'Level';

  @override
  String run_levelNextMeters(Object meters) {
    return 'Noch $meters m bis zum nächsten Level.';
  }

  @override
  String run_levelEvery5km(Object meters) {
    return 'Ab 5 km gibt es +1 Level – noch $meters m.';
  }

  @override
  String get run_autoFollowOn => 'Auto-Verfolgen aktiv';

  @override
  String get run_autoFollowOff => 'Auto-Verfolgen aus';

  @override
  String get run_voiceOn => 'Stimme an';

  @override
  String get run_voiceOff => 'Stimme aus';

  @override
  String get run_waitingGps => 'Warte auf GPS-Signal…';

  @override
  String get run_distNow => 'Jetzt';

  @override
  String run_distInMeters(Object meters) {
    return 'in $meters m';
  }

  @override
  String run_distInKm(Object km) {
    return 'in $km km';
  }

  @override
  String get run_labelTime => 'ZEIT';

  @override
  String get run_labelKm => 'KM';

  @override
  String get run_labelPace => 'TEMPO';

  @override
  String get run_start => 'LAUF STARTEN';

  @override
  String get run_waitGps => 'WARTE AUF GPS…';

  @override
  String get run_resume => 'WEITER';

  @override
  String get run_pause => 'PAUSE';

  @override
  String get run_endButton => 'BEENDEN';

  @override
  String get social_connectTitle => 'Freunde verbinden';

  @override
  String get social_connectSubtitle => 'Workouts, Routen und Rezepte teilen';

  @override
  String get social_inboxTitle => 'Postfach';

  @override
  String get social_yourIdTitle => 'Deine Kaizen-ID';

  @override
  String get social_copyCode => 'ID kopieren';

  @override
  String get social_shareInvite => 'Einladung teilen';

  @override
  String get social_addFriendTitle => 'Freund per ID hinzufügen';

  @override
  String get social_addFriendHint => 'KZN-ABC123';

  @override
  String get social_addFriendAction => 'Verbinden';

  @override
  String social_friendsListTitle(int count) {
    return 'Freunde ($count)';
  }

  @override
  String get social_noFriendsYet => 'Noch keine Freunde verbunden.';

  @override
  String get social_notifyRunStart => 'Benachrichtigen bei Laufstart';

  @override
  String get social_removeFriendTitle => 'Freund entfernen?';

  @override
  String social_removeFriendBody(String name) {
    return '$name aus der Freundesliste entfernen?';
  }

  @override
  String get social_codeCopied => 'ID kopiert';

  @override
  String get social_friendAdded => 'Freund verbunden';

  @override
  String get social_errorInvalidCode => 'Bitte eine gültige ID eingeben.';

  @override
  String get social_errorSelfFriend =>
      'Du kannst dich nicht selbst hinzufügen.';

  @override
  String get social_errorFriendNotFound =>
      'Kein Nutzer mit dieser ID gefunden.';

  @override
  String get social_errorAlreadyFriends => 'Ihr seid bereits verbunden.';

  @override
  String get social_errorCloudDisabled =>
      'Cloud-Sync ist noch nicht eingerichtet. Firebase konfigurieren, um Freunde zu verbinden.';

  @override
  String get social_errorGeneric =>
      'Verbindung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get social_cloudSetupHint =>
      'Freunde-Sync benötigt Firebase. Trage projectId und apiKey in lib/services/social/social_cloud_config.dart ein, aktiviere Anonymous Auth + Firestore und baue neu.';

  @override
  String social_inviteShareText(String link, String code) {
    return 'Verbinde dich mit mir in Kaizen: $link\nMeine ID: $code';
  }

  @override
  String get social_shareAction => 'Mit Freund teilen';

  @override
  String get social_shareWithFriendsTitle => 'Teilen mit';

  @override
  String get social_noFriendsToShare =>
      'Füge zuerst Freunde unter Profil → Freunde verbinden hinzu.';

  @override
  String get social_shareSent => 'Erfolgreich geteilt';

  @override
  String get social_inboxEmpty => 'Noch keine Nachrichten.';

  @override
  String social_inboxRoute(String name) {
    return '$name hat eine Laufroute mit dir geteilt.';
  }

  @override
  String social_inboxGymWorkout(String name) {
    return '$name hat ein Gym-Workout mit dir geteilt.';
  }

  @override
  String social_inboxCalisthenicsWorkout(String name) {
    return '$name hat ein Calisthenics-Workout mit dir geteilt.';
  }

  @override
  String social_inboxFoodDish(String name) {
    return '$name hat ein Gericht mit dir geteilt.';
  }

  @override
  String social_inboxThumbsUp(String name) {
    return '$name hat dir einen Daumen hoch geschickt 👍';
  }

  @override
  String get social_sendThumbsUp => 'Daumen hoch senden';

  @override
  String get social_thumbsUpSent => 'Daumen hoch gesendet';

  @override
  String get social_acceptRoute => 'Zu gespeicherten Routen';

  @override
  String get social_acceptWorkout => 'Zu meinen Workouts';

  @override
  String get social_acceptDish => 'Zu meinen Rezepten';

  @override
  String get social_reject => 'Ablehnen';

  @override
  String get social_inboxAccepted => 'Hinzugefügt';

  @override
  String get social_inboxRejected => 'Abgelehnt';

  @override
  String get social_inboxAdded => 'Zu deiner Bibliothek hinzugefügt';

  @override
  String get friends_hubTitle => 'Freunde';

  @override
  String get friends_monthlyChallengeTab => 'Monats-Challenge';

  @override
  String get friends_runningMapTab => 'Laufkarte';

  @override
  String get friends_challengeTitle => '1.000-Liegestütze-Challenge';

  @override
  String get friends_goal => 'Ziel';

  @override
  String get friends_pushUps => 'Liegestütze';

  @override
  String get friends_tapToEdit => 'Tippen, um deinen Stand zu bearbeiten';

  @override
  String get friends_editCountTitle => 'Liegestütze aktualisieren';

  @override
  String get friends_editCountHint => 'Aktueller Gesamtstand dieses Monats';

  @override
  String get friends_save => 'Speichern';

  @override
  String get friends_leaderboard => 'Rangliste';

  @override
  String get friends_you => 'Du';

  @override
  String get friends_noFriendsHint =>
      'Verbinde Freunde, um hier gegen sie anzutreten.';

  @override
  String get friends_goalReached => 'Ziel erreicht — weiter geht’s!';

  @override
  String get running_tabShared => 'Shared';

  @override
  String get sharedRuns_tabHint =>
      'Sieh live, welche Freunde gerade laufen. Tippe auf ein Profilicon für Pace und Routendetails.';

  @override
  String get sharedRuns_empty => 'Aktuell läuft kein Freund.';

  @override
  String get sharedRuns_homeTitle => 'Freunde laufen live';

  @override
  String sharedRuns_liveCount(int count) {
    return '$count live';
  }

  @override
  String get sharedRuns_distance => 'Distanz';

  @override
  String get sharedRuns_currentPace => 'Aktuelle Pace';

  @override
  String get sharedRuns_avgPace => 'Durchschnittspace';

  @override
  String get onTheGo_exercises => 'Übungen';

  @override
  String get onTheGo_search => 'Übung suchen…';

  @override
  String get onTheGo_select => 'Muskeln antippen';

  @override
  String get onTheGo_show => 'Übungen anzeigen';

  @override
  String get onTheGo_noMatches => 'Keine passende Übung gefunden.';

  @override
  String get onTheGo_empty =>
      'Dein Workout ist leer. Füge rechts Übungen hinzu.';

  @override
  String get onTheGo_generate => 'Workout generieren';

  @override
  String get onTheGo_moreExercises => 'Weitere Übungen';

  @override
  String get onTheGo_complement => 'Ergänzung für dieselbe Körperregion';

  @override
  String get onTheGo_saveFailed =>
      'Das Workout konnte nicht gespeichert werden. Bitte erneut versuchen.';

  @override
  String get workoutHub_searchHint => 'Workouts suchen…';

  @override
  String get workoutHub_filter => 'Filter';

  @override
  String get workoutHub_filterTitle => 'Filter';

  @override
  String get workoutHub_filterApply => 'Übernehmen';

  @override
  String get workoutHub_filterKind => 'Art';

  @override
  String get workoutHub_filterMuscles => 'Muskelgruppen';

  @override
  String get workoutHub_kindGym => 'Gym';

  @override
  String get workoutHub_kindCalisthenics => 'Calisthenics';

  @override
  String get workoutHub_kindStretch => 'Dehnen';

  @override
  String get workoutHub_quickAccess => 'Schnellstart';

  @override
  String get workoutHub_myWorkouts => 'Meine Workouts';

  @override
  String get workoutHub_presets => 'Vorgefertigte Workouts';

  @override
  String get workoutHub_favorites => 'Favoriten';

  @override
  String get workoutHub_empty => 'Keine Workouts gefunden.';

  @override
  String get workoutHub_startAsYouGo => 'Leeres Workout starten';

  @override
  String get workoutHub_startWorkout => 'Workout starten';

  @override
  String get workoutHub_favorite => 'Favorit';

  @override
  String get workoutHub_unfavorite => 'Favorit entfernen';

  @override
  String get running_startFree => 'Sofort starten';

  @override
  String get running_freeRunName => 'Freier Lauf';

  @override
  String get running_savedFreeRun => 'Lauf gespeichert';

  @override
  String get strength_setsMaxHint => 'Max. 100 Sätze';

  @override
  String get strength_editSetReps => 'Wiederholungen ändern';
}
