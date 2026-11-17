// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kaizen';

  @override
  String get common_ok => 'OK';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_continue => 'Continue';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_reset => 'Reset';

  @override
  String get common_create => 'Create';

  @override
  String get common_add => 'Add';

  @override
  String get common_rename => 'Rename';

  @override
  String get common_close => 'Close';

  @override
  String get common_skip => 'Skip';

  @override
  String get common_done => 'Done';

  @override
  String get common_filter => 'Filter';

  @override
  String get common_info => 'Info';

  @override
  String get common_search => 'Search…';

  @override
  String get common_name => 'Name';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_profile => 'Profile';

  @override
  String get onboarding_welcomeTitle => 'Welcome to Kaizen';

  @override
  String get onboarding_profileNameLabel => 'Profile name';

  @override
  String get onboarding_profileNameHint => 'Enter your name';

  @override
  String get onboarding_stepProfileTitle => 'Let\'s get to know you';

  @override
  String get onboarding_stepProfileSubtitle =>
      'Your data helps us calculate your daily targets.';

  @override
  String get onboarding_stepGoalTitle => 'What\'s your goal?';

  @override
  String get onboarding_stepGoalSubtitle =>
      'We\'ll adjust your calories and macros accordingly.';

  @override
  String get onboarding_stepMacrosTitle => 'Your daily targets';

  @override
  String get onboarding_stepMacrosSubtitle =>
      'Calculated just for you — you can change this anytime in Profile.';

  @override
  String get onboarding_stepScheduleTitle => 'Your weekly plan';

  @override
  String get onboarding_stepScheduleSubtitle =>
      'Pick training days and optional times. Leave empty if you\'re not sure yet.';

  @override
  String get onboarding_stepScheduleLaterHint =>
      'You can adjust your weekly plan anytime in Profile → Edit profile.';

  @override
  String get onboarding_skipSchedule => 'Skip for now';

  @override
  String get onboarding_stepNotificationsTitle => 'Stay on track';

  @override
  String get onboarding_stepNotificationsSubtitle =>
      'Allow reminders 15 minutes before each scheduled session.';

  @override
  String get onboarding_stepMorningTitle => 'Your morning workout';

  @override
  String get onboarding_stepMorningSubtitle =>
      'Build your personal morning routine — ideally once daily, best in the morning.';

  @override
  String get onboarding_enableNotifications => 'Enable training reminders';

  @override
  String get onboarding_skipNotifications => 'Not now';

  @override
  String get onboarding_next => 'Continue';

  @override
  String get onboarding_finish => 'Get started';

  @override
  String get onboarding_back => 'Back';

  @override
  String get onboarding_morningSelected => 'Selected exercises';

  @override
  String get onboarding_morningPickFrom => 'Add from catalog';

  @override
  String get onboarding_morningTabStretch => 'Stretch / Yoga';

  @override
  String get onboarding_morningTabCalisthenics => 'Calisthenics';

  @override
  String get onboarding_morningTabGym => 'Gym';

  @override
  String get onboarding_morningMinOne =>
      'Keep at least one exercise in your morning workout.';

  @override
  String get schedule_editorHint =>
      'Tap a day to train. Tap the time to set when — optional.';

  @override
  String get schedule_editorTitle => 'Weekly training plan';

  @override
  String get schedule_tapToEdit => 'Tap to edit';

  @override
  String get schedule_emptySummary => 'Nothing planned yet';

  @override
  String get schedule_activityGym => 'Gym';

  @override
  String get schedule_activityCalisthenics => 'Bodyweight';

  @override
  String get schedule_activityShortGym => 'Gym';

  @override
  String get schedule_activityShortCalisthenics => 'BW';

  @override
  String get schedule_activityShortRunning => 'Run';

  @override
  String get schedule_activityShortStretch => 'Str';

  @override
  String get profile_trainingReminders => 'Training reminders';

  @override
  String get profile_trainingRemindersSubtitle =>
      'Notifications 15 minutes before scheduled workouts';

  @override
  String get profile_fastingHud => 'Intermittent fasting';

  @override
  String get profile_fastingHudSubtitle =>
      'Show eating window timer on the home screen';

  @override
  String get profile_waterTracking => 'Water tracking';

  @override
  String get profile_waterTrackingSubtitle =>
      'Show a water progress bar on the home screen';

  @override
  String get profile_waterGoal => 'Daily water goal';

  @override
  String profile_waterGoalHint(Object liters) {
    return 'Recommended from your profile: $liters L';
  }

  @override
  String get fasting_setupTitle => 'Eating window';

  @override
  String get fasting_setupSubtitle =>
      'Drag the green zone to choose when you can eat — from morning (left) to evening (right).';

  @override
  String get fasting_save => 'Save';

  @override
  String get fasting_reminders => 'Reminders';

  @override
  String get fasting_remindersSubtitle =>
      '15 min before eating opens, 30 min before it closes';

  @override
  String get fasting_windowLabel => 'Eating window';

  @override
  String get fasting_configureTap => 'Tap to set eating window';

  @override
  String get fasting_untilEating => 'Eat in';

  @override
  String get fasting_untilEatingEnd => 'Eating ends in';

  @override
  String get fasting_notificationOpenTitle => 'Eating window soon';

  @override
  String fasting_notificationOpenBody(Object time) {
    return 'You can eat at $time';
  }

  @override
  String get fasting_notificationCloseTitle => 'Eating window ending';

  @override
  String fasting_notificationCloseBody(Object time) {
    return 'Eating window closes at $time';
  }

  @override
  String get fasting_notificationChannelName => 'Fasting reminders';

  @override
  String get fasting_notificationChannelDesc =>
      'Reminders before your eating window opens and closes';

  @override
  String get schedule_activityNineMin => '9min';

  @override
  String get schedule_activityMorning => 'Morning';

  @override
  String get schedule_activityRunning => 'Running';

  @override
  String get schedule_activityStretch => 'Stretch';

  @override
  String get schedule_editInProfile => 'Weekly plan';

  @override
  String get notification_trainingReminderTitle => 'Training soon';

  @override
  String notification_trainingReminderBody(String activity, String time) {
    return '$activity in 15 min · $time';
  }

  @override
  String get notification_trainingChannelName => 'Training reminders';

  @override
  String get notification_trainingChannelDesc =>
      'Reminders before scheduled workouts';

  @override
  String get installHint_title => 'Welcome to Kaizen';

  @override
  String get installHint_body =>
      'Take a quick tour of the app to learn the main areas. You can skip it for now and restart anytime from Profile → Settings → App tour.';

  @override
  String get installHint_startTour => 'Start tour';

  @override
  String get installHint_gotIt => 'Got it';

  @override
  String get start_featured => 'FEATURED';

  @override
  String get start_categories => 'CATEGORIES';

  @override
  String get start_days => 'DAYS';

  @override
  String get start_open => 'Open';

  @override
  String get start_heroPickGallery => 'Choose from gallery';

  @override
  String get start_heroTakePhoto => 'Take photo';

  @override
  String get start_heroResetDefault => 'Reset to default';

  @override
  String get start_cameraGalleryError => 'Could not open camera/gallery.';

  @override
  String start_cameraGalleryErrorWithDetail(Object detail) {
    return 'Camera/gallery error: $detail';
  }

  @override
  String get start_imageSaveFailed => 'Could not save image.';

  @override
  String get home_bodyViewRecovery => 'Recovery';

  @override
  String get home_bodyViewAfterburn => 'Afterburn';

  @override
  String get home_bodyViewTrained => 'Trained';

  @override
  String get home_bodyViewOrgans => 'Organs';

  @override
  String get home_bodyViewSkeleton => 'Joints and tendons';

  @override
  String get home_bodyStillToTrain => 'Still to train this week';

  @override
  String get home_statusRecoveryReady => 'All groups ready';

  @override
  String home_statusRecoveryRecovering(int count) {
    return '$count groups recovering';
  }

  @override
  String get home_statusAfterburnNone => 'No active afterburn';

  @override
  String home_statusAfterburnActive(String kcal) {
    return '+$kcal kcal afterburn';
  }

  @override
  String get home_statusTrainedComplete => 'Full body covered';

  @override
  String home_statusTrainedWeek(int trained, int total) {
    return '$trained/$total groups this week';
  }

  @override
  String home_statusTrainedPending(int trained, int total, Object muscles) {
    return '$trained/$total groups · open: $muscles';
  }

  @override
  String get home_statusOrgansGood => 'Nutrition on track';

  @override
  String home_statusOrgansAttention(int count) {
    return '$count organs need attention';
  }

  @override
  String get home_statusJointsNone => 'No joint focus yet';

  @override
  String home_statusJointsStrengthened(int count) {
    return '$count joints this week';
  }

  @override
  String get home_organRecommended => 'Recommended';

  @override
  String get home_organGoodFoods => 'Good — last 30 days';

  @override
  String get home_organBadFoods => 'Straining — last 30 days';

  @override
  String get home_organStatusGood => 'Well supported';

  @override
  String get home_organStatusMixed => 'Mixed';

  @override
  String get home_organStatusCareful => 'Needs attention';

  @override
  String get home_organStatusNoData => 'No data yet';

  @override
  String get home_organStatusGoodActive => 'Glowing green (24h)';

  @override
  String get home_organGoodFoods24h => 'Helpful foods — last 24 hours';

  @override
  String get home_organsHint => 'Tap an organ for details.';

  @override
  String get home_bodyTabIntroRecoveryTitle => 'Recovery';

  @override
  String get home_bodyTabIntroRecoveryBody =>
      'Yellow shows trained muscles. A muscle turns red when two moderate workouts target it directly or three moderate workouts involve it within 24 hours. Six direct gym sets also qualify. Red lasts for 24 hours after the qualifying workout. Yellow clears 48 hours after the last workout.';

  @override
  String get home_bodyTabIntroAfterburnTitle => 'Afterburn';

  @override
  String get home_bodyTabIntroAfterburnBody =>
      'Outlined muscle groups still burn extra calories after training (EPOC). The more intense the workout, the longer afterburn lasts. Train regularly to benefit from the effect.';

  @override
  String get home_bodyTabIntroTrainedTitle => 'Trained';

  @override
  String get home_bodyTabIntroTrainedBody =>
      'Blue muscle groups were trained this week. Unmarked groups are still open — keep a balanced weekly plan in view.';

  @override
  String get home_bodyTabIntroOrgansTitle => 'Organs';

  @override
  String get home_bodyTabIntroOrgansBody =>
      'See how your organs are doing based on your nutrition. An organ glows green for only 24 hours after you log a helpful food. Eat healthy and varied — then your organs light up green. Tap an organ for details and recommendations.';

  @override
  String get home_bodyTabIntroSkeletonTitle => 'Skeleton';

  @override
  String get home_bodyTabIntroSkeletonBody =>
      'Green joints were strengthened this week with suitable exercises. Unmarked joints still need attention — focus on mobility and targeted training.';

  @override
  String get home_skeletonHint => 'Green joints were strengthened this week.';

  @override
  String get home_jointTrainedThisWeek => 'Strengthened this week';

  @override
  String get home_jointNotTrainedThisWeek => 'Not trained this week';

  @override
  String get home_muscleExercises => 'Good exercises';

  @override
  String get home_muscleChest => 'Chest';

  @override
  String get home_muscleBack => 'Back';

  @override
  String get home_muscleShoulders => 'Shoulders';

  @override
  String get home_muscleBiceps => 'Biceps';

  @override
  String get home_muscleTriceps => 'Triceps';

  @override
  String get home_muscleAbs => 'Abs';

  @override
  String get home_muscleLegs => 'Legs';

  @override
  String get home_muscleForearms => 'Forearms';

  @override
  String get home_muscleNeck => 'Neck';

  @override
  String get home_bodyRecoveryHint =>
      'Within 24 hours, two moderate workouts targeting a muscle, three involving it, or six direct gym sets turn it red. Red turns yellow after 24 hours.';

  @override
  String get home_bodyAfterburnHint =>
      'A blue glow around a muscle shows that its estimated afterburn window is still active.';

  @override
  String get home_bodyAfterburnTitle => 'Afterburn so far';

  @override
  String home_bodyAfterburnKcalValue(String kcal) {
    return '+$kcal kcal';
  }

  @override
  String get home_bodyLegendRecoveryRed => 'High load <24h';

  @override
  String get home_bodyLegendRecoveryYellow => 'Trained <48h';

  @override
  String get home_bodyLegendAfterburn => 'Blue glow during afterburn';

  @override
  String get home_bodyStreakLabel => 'STREAK';

  @override
  String get home_startIntro => 'Start introduction';

  @override
  String get home_hudTodaysAnalytics => 'Today\'s analytics';

  @override
  String get home_hudCubeDaily => 'Daily';

  @override
  String get home_hudCubeAnalytics => 'Analytics';

  @override
  String home_hudSteps(int count) {
    return 'Steps: $count';
  }

  @override
  String home_hudBurned(int kcal) {
    return 'Burned: $kcal kcal';
  }

  @override
  String home_hudDistanceRan(Object distance) {
    return 'Distance ran: $distance';
  }

  @override
  String home_hudWorkouts(int count) {
    return 'Workouts: $count';
  }

  @override
  String home_hudCaloriesIn(int kcal) {
    return 'Calories in: $kcal kcal';
  }

  @override
  String home_hudProtein(int grams) {
    return 'Protein: ${grams}g';
  }

  @override
  String home_hudCarbs(int grams) {
    return 'Carbs: ${grams}g';
  }

  @override
  String home_hudFats(int grams) {
    return 'Fats: ${grams}g';
  }

  @override
  String get home_hudRecoveryNoData => 'Recovery: no data';

  @override
  String home_hudRecovery(Object sleep, Object quality) {
    return 'Recovery: $sleep, $quality';
  }

  @override
  String get home_hudSleepNone => 'no sleep data';

  @override
  String home_hudSleepDuration(int hours, int minutes) {
    return '${hours}h ${minutes}m of sleep';
  }

  @override
  String home_hudSleepDurationHours(int hours) {
    return '${hours}h of sleep';
  }

  @override
  String home_hudSleepDurationMinutes(int minutes) {
    return '${minutes}m of sleep';
  }

  @override
  String get home_hudSleepQualityBad => 'bad quality';

  @override
  String get home_hudSleepQualityGood => 'good quality';

  @override
  String get home_hudSleepQualityPerfect => 'perfect quality';

  @override
  String get home_hudSummaryDoingWell => 'Doing well this week.';

  @override
  String get home_hudSummaryNoneToday => 'Get moving today.';

  @override
  String get home_hudSummaryOneToday => 'Great! Keep it up.';

  @override
  String get home_hudSummaryTwoPlusToday => 'You\'re incredible!';

  @override
  String get home_hudSummaryEatHealthy => 'Eating healthy.';

  @override
  String get home_hudSummaryMoveToday => 'Move your body today.';

  @override
  String get home_hudSummaryStretchToday =>
      'You have done a good stretching session today, keep going.';

  @override
  String get home_hudSummaryShortWorkoutToday =>
      'Great work! You\'ve done a short workout.';

  @override
  String get home_hudSummaryRunToday => 'Keep it up. That was a great run!';

  @override
  String get home_hudSummaryHardTrainingToday => 'You\'re incredible!';

  @override
  String home_hudTabRecoveryRest(String muscles) {
    return 'Rest your $muscles today.';
  }

  @override
  String get home_hudTabRecoveryAllReady => 'All groups ready to train.';

  @override
  String home_hudTabAfterburnEpoc(int hours) {
    return 'Calculated via EPOC. Afterburn can last up to ${hours}h depending on workout intensity.';
  }

  @override
  String home_hudTabAfterburnActive(int kcal, String remaining) {
    return '+$kcal kcal burned · $remaining left';
  }

  @override
  String get home_hudTabAfterburnNone => 'No active afterburn right now.';

  @override
  String get home_hudTabAfterburnUnknownRemaining => 'still active';

  @override
  String home_hudTabTrainedOpen(String muscles) {
    return 'Still to train: $muscles';
  }

  @override
  String get home_hudTabTrainedComplete =>
      'All muscle groups trained this week.';

  @override
  String home_hudTabOrgansNeed(String organs) {
    return 'Needs better nutrition: $organs';
  }

  @override
  String get home_hudTabOrgansAllGood => 'All organs well supported.';

  @override
  String get home_hudTabOrgansEatToday => 'Eat healthy today.';

  @override
  String home_hudTabJointsNeed(String joints) {
    return 'Strengthen this week: $joints';
  }

  @override
  String get home_hudTabJointsAllDone => 'All joints covered this week.';

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
  String get home_hudMuscleChest => 'Chest';

  @override
  String get home_hudMuscleBack => 'Back';

  @override
  String get home_hudMuscleShoulders => 'Shoulders';

  @override
  String get home_hudMuscleBiceps => 'Biceps';

  @override
  String get home_hudMuscleTriceps => 'Triceps';

  @override
  String get home_hudMuscleAbs => 'Abs';

  @override
  String get home_hudMuscleLegs => 'Legs';

  @override
  String get home_hudMuscleForearms => 'Forearms';

  @override
  String get home_hudMuscleNeck => 'Neck';

  @override
  String get home_hudOrganBrain => 'Brain';

  @override
  String get home_hudOrganHeart => 'Heart';

  @override
  String get home_hudOrganLungs => 'Lungs';

  @override
  String get home_hudOrganLiver => 'Liver';

  @override
  String get home_hudOrganStomach => 'Stomach';

  @override
  String get home_hudOrganIntestines => 'Intestines';

  @override
  String get home_hudOrganKidneys => 'Kidneys';

  @override
  String get home_hudJointNeck => 'Neck';

  @override
  String get home_hudJointShoulders => 'Shoulders';

  @override
  String get home_hudJointElbows => 'Elbows';

  @override
  String get home_hudJointWrists => 'Wrists';

  @override
  String get home_hudJointSpine => 'Spine';

  @override
  String get home_hudJointHips => 'Hips';

  @override
  String get home_hudJointKnees => 'Knees';

  @override
  String get home_hudJointShins => 'Shins';

  @override
  String get home_hudJointAnkles => 'Ankles';

  @override
  String get home_bodyFront => 'Front';

  @override
  String get home_bodyBack => 'Back';

  @override
  String get category_9min_title => '9min';

  @override
  String get category_9min_description =>
      'A short workout that activates your whole body in little time. Great as a warmup or morning workout.';

  @override
  String get category_hercules_title => 'Optimized for runners';

  @override
  String get category_hercules_description =>
      'Build your own routine optimized for runners. The default includes the 9min workout, stretching, and extra exercises to strengthen leg tendons and joints.';

  @override
  String get category_onlyStretch_title => 'Stretch';

  @override
  String get category_onlyStretch_description =>
      'A short stretching routine optimized for people who sit too long.';

  @override
  String get category_wakeup_title => 'Full-Body Wake-Up';

  @override
  String get category_wakeup_description =>
      'A fixed full-body activation program with 20 exercises. Mobility, strength and stretching in ~20 minutes.';

  @override
  String get category_gym_title => 'Gym';

  @override
  String get category_gym_description =>
      'Create your own workouts and add them to your daily training log.';

  @override
  String get category_calisthenics_title => 'Bodyweight';

  @override
  String get category_calisthenics_description =>
      'Create your own workouts and add them to your daily training log.';

  @override
  String get category_running_title => 'Run';

  @override
  String get category_running_description =>
      'Create routes or start a free run and live-track distance, elevation and pace.';

  @override
  String get category_workout_title => 'Workout';

  @override
  String get category_workout_description =>
      'Gym, calisthenics, stretch and morning workouts — search, filter and start.';

  @override
  String get category_food_title => 'Food and meals';

  @override
  String get category_food_description =>
      'Create your own meals and add them to your daily intake, add food directly, or just scan it.';

  @override
  String get category_friends_title => 'Friends';

  @override
  String get category_friends_description =>
      'Compete in challenges and follow friends live on the running map.';

  @override
  String get tour_stepMannequinTitle => 'Your body at a glance';

  @override
  String get tour_stepMannequinDescription =>
      'The body model updates based on your logged workouts, foods and meals. Its highlights give you an estimate of training load, nutrition and recovery, helping you see which muscles were used and when they are expected to recover.';

  @override
  String get tour_stepWorkoutTitle => 'Workout';

  @override
  String get tour_stepWorkoutDescription =>
      'All your workouts live here: 9 min, morning workout, stretch, gym and bodyweight. Tap in to search, create your own, or start right away.';

  @override
  String get tour_stepFriendsTitle => 'Friends';

  @override
  String get tour_stepFriendsDescription =>
      'Join challenges and follow friends live on the running map.';

  @override
  String get tour_step9minTitle => '9 Min Workout';

  @override
  String get tour_step9minDescription =>
      'This is a short workout which activates your whole body in short time. Use as a good warmup or morning workout.';

  @override
  String get tour_stepHerculesTitle => 'Morning Workout';

  @override
  String get tour_stepHerculesDescription =>
      'This is your workout section — build your own custom morning routine. The default includes the 9min workout and stretching exercises, plus extra exercises to strengthen your leg tendons and joints.';

  @override
  String get tour_stepOnlyStretchTitle => 'Stretch';

  @override
  String get tour_stepOnlyStretchDescription =>
      'This is a short stretching routine optimized for people that sit too long.';

  @override
  String get tour_stepGymTitle => 'Gym';

  @override
  String get tour_stepGymDescription =>
      'Here you can create your own workouts and add them daily to your record.';

  @override
  String get tour_stepCalisthenicsTitle => 'Bodyweight';

  @override
  String get tour_stepCalisthenicsDescription =>
      'Here you can create your own workouts and add them daily to your record.';

  @override
  String get tour_stepRunningTitle => 'Running';

  @override
  String get tour_stepRunningDescription =>
      'Here you can create your own running routes and then live track your runs.';

  @override
  String get tour_stepFoodTitle => 'Food';

  @override
  String get tour_stepFoodDescription =>
      'Search food and add it directly to your daily intake or create a meal and save it.';

  @override
  String get tour_stepShoppingTitle => 'Your shopping list';

  @override
  String get tour_stepShoppingDescription =>
      'Tap the small note to open your shopping list. Collect food and quantities, check off purchases and save lists for later.';

  @override
  String get tour_stepMetabolicTitle => 'Daily nutrition';

  @override
  String get tour_stepMetabolicDescription =>
      'Your personal calorie and macro target based on profile and activity. See how much you\'ve eaten today.';

  @override
  String get tour_stepCalendarTitle => 'Workout calendar';

  @override
  String get tour_stepCalendarDescription =>
      'All completed workouts in the monthly overview. Tap a day for details or the 30-day summary bottom right.';

  @override
  String get tour_stepGalleryTitle => 'Progress gallery';

  @override
  String get tour_stepGalleryDescription =>
      'Save progress photos and compare your development over weeks and months.';

  @override
  String get tour_stepWeightTitle => 'Weight tracking';

  @override
  String get tour_stepWeightDescription =>
      'See your current weight here. Use the plus button to log today\'s weight.';

  @override
  String get tour_stepHealthTitle => 'Your health';

  @override
  String get tour_stepHealthDescription =>
      'This card brings together your training, nutrition and health trends. Choose a metric and 7 or 28 days, then tap a day in the chart for details. Use the info icon to connect Apple Health or Health Connect and manage what you share.';

  @override
  String get tour_stepLevelingTitle => 'Level & badges';

  @override
  String get tour_stepLevelingDescription =>
      'At the top you will find your profile, level and body measurements. Completed workouts and training streaks earn you levels. Tap the trophy to see your badges and achievements.';

  @override
  String tour_progress(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get profile_settingsTooltip => 'Settings';

  @override
  String get profile_metabolicTarget => 'METABOLIC TARGET';

  @override
  String get profile_analytics => 'ANALYTICS';

  @override
  String get profile_steps => 'STEPS';

  @override
  String get profile_sleep => 'SLEEP';

  @override
  String get profile_sleepLastNight => 'Last night';

  @override
  String get profile_editProfile => 'Edit profile';

  @override
  String get profile_settings => 'Settings';

  @override
  String get profile_settingsSectionFeatures => 'Features';

  @override
  String get profile_settingsSectionSystem => 'App & System';

  @override
  String get profile_pinLevelIcon => 'Add rank icon to home screen';

  @override
  String get profile_pinLevelIconHint =>
      'Opens Kaizen and shows your current rank.';

  @override
  String get profile_pinLevelIconUnavailable =>
      'Touch and hold an empty space on your home screen, then select “Kaizen Rank” under Widgets.';

  @override
  String get profile_appTour => 'App tour';

  @override
  String get profile_appTourSubtitle =>
      'Interactive tour through all areas of the app';

  @override
  String get profile_syncSteps => 'Sync steps';

  @override
  String get profile_syncStepsSubtitle =>
      'Connect Apple Health / Health Connect';

  @override
  String get profile_syncSleep => 'Sync sleep';

  @override
  String get profile_syncSleepSubtitle =>
      'Import last night\'s sleep from Apple Health / Health Connect';

  @override
  String get profile_workoutVoice => 'Workout voice';

  @override
  String get profile_workoutVoiceSubtitle => 'Voice prompts during training';

  @override
  String get profile_workoutVoiceGenderTitle => 'Voice type';

  @override
  String get profile_workoutVoiceGenderSubtitle =>
      'Female or male voice for workouts and running';

  @override
  String get profile_workoutVoiceFemale => 'Female';

  @override
  String get profile_workoutVoiceMale => 'Male';

  @override
  String get profile_workoutVoiceSystem => 'System default';

  @override
  String get profile_workoutVoicePreview => 'Preview voice';

  @override
  String get profile_lightMode => 'Light mode';

  @override
  String get profile_lightModeSubtitle =>
      'On: light surfaces. Off: previous dark design.';

  @override
  String get settings_languageTitle => 'German language';

  @override
  String get settings_languageSubtitle => 'On: German. Off: English.';

  @override
  String get profile_gallery => 'Your Gallery';

  @override
  String get profile_updateWeight => 'Update weight';

  @override
  String get profile_weightKgLabel => 'Weight (kg)';

  @override
  String get profile_weightHint => 'e.g. 72.5';

  @override
  String get profile_updated => 'Profile updated.';

  @override
  String get profile_dailyCalorieGoal => 'Today\'s calories';

  @override
  String get profile_kcalGoal => 'KCAL GOAL';

  @override
  String get profile_today => 'TODAY';

  @override
  String profile_todayWithPercent(int percent) {
    return 'TODAY · $percent%';
  }

  @override
  String get profile_protein => 'PROTEIN';

  @override
  String get profile_carbs => 'CARBOHYDRATES';

  @override
  String get profile_fats => 'FATS';

  @override
  String get profile_macroProteinShort => 'Protein';

  @override
  String get profile_macroFatShort => 'Fat';

  @override
  String profile_macroSummary(Object protein, Object carbs, Object fats) {
    return 'P $protein g · C $carbs g · F $fats g';
  }

  @override
  String get profile_kcalBurned => 'kcal burned';

  @override
  String profile_workoutsKcal(Object kcal) {
    return 'Workouts: $kcal kcal';
  }

  @override
  String profile_stepsKcal(Object count, Object kcal) {
    return 'Steps: $count · $kcal kcal';
  }

  @override
  String profile_stepsKcalNoData(Object kcal) {
    return 'Steps: $kcal kcal (no step data)';
  }

  @override
  String profile_dishEntry(Object time) {
    return 'Dish  •  $time';
  }

  @override
  String get profile_editTitle => 'Edit profile';

  @override
  String get profile_nameLabel => 'Name';

  @override
  String get profile_ageLabel => 'Age';

  @override
  String get profile_heightLabel => 'Height (cm)';

  @override
  String get profile_weightLabel => 'Weight (kg)';

  @override
  String get profile_bodyFatLabel => 'Body fat (%)';

  @override
  String get profile_muscleMassLabel => 'Muscle mass (kg)';

  @override
  String get profile_boneWeightLabel => 'Bone weight (kg)';

  @override
  String get profile_genderLabel => 'Gender';

  @override
  String get profile_activityLabel => 'Activity';

  @override
  String get profile_goalLabel => 'Goal';

  @override
  String profile_biometricSummary(
    Object height,
    Object weight,
    Object age,
    Object gender,
  ) {
    return '$height · $weight · $age y · $gender';
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
  String get activity_sedentary => 'Sedentary';

  @override
  String get activity_light => 'Light';

  @override
  String get activity_moderate => 'Moderate';

  @override
  String get activity_high => 'High';

  @override
  String get activity_athlete => 'Athlete';

  @override
  String get goal_lose => 'Cut';

  @override
  String get goal_maintain => 'Maintain';

  @override
  String get goal_gain => 'Bulk';

  @override
  String get validation_nameRequired => 'Please enter a profile name.';

  @override
  String get validation_ageRequired => 'Please enter your age.';

  @override
  String get validation_heightRequired => 'Please enter your height.';

  @override
  String get validation_weightRequired => 'Please enter your weight.';

  @override
  String get validation_ageInvalid => 'Please enter a valid age.';

  @override
  String get validation_heightInvalid => 'Please enter a valid height in cm.';

  @override
  String get validation_weightInvalid => 'Please enter a valid weight in kg.';

  @override
  String get validation_bodyFatInvalid =>
      'Please enter a realistic body fat percentage.';

  @override
  String get validation_muscleMassInvalid =>
      'Please enter a valid muscle mass.';

  @override
  String get validation_boneWeightInvalid =>
      'Please enter a valid bone weight.';

  @override
  String get avatar_mobileOnly =>
      'Avatar upload is currently only available on mobile.';

  @override
  String get avatar_takePhoto => 'Take photo';

  @override
  String get avatar_pickGallery => 'Choose from gallery';

  @override
  String get avatar_remove => 'Remove avatar';

  @override
  String get avatar_saveFailed => 'Could not save avatar.';

  @override
  String get month_january => 'January';

  @override
  String get month_february => 'February';

  @override
  String get month_march => 'March';

  @override
  String get month_april => 'April';

  @override
  String get month_may => 'May';

  @override
  String get month_june => 'June';

  @override
  String get month_july => 'July';

  @override
  String get month_august => 'August';

  @override
  String get month_september => 'September';

  @override
  String get month_october => 'October';

  @override
  String get month_november => 'November';

  @override
  String get month_december => 'December';

  @override
  String get weekday_mon => 'Mon';

  @override
  String get weekday_tue => 'Tue';

  @override
  String get weekday_wed => 'Wed';

  @override
  String get weekday_thu => 'Thu';

  @override
  String get weekday_fri => 'Fri';

  @override
  String get weekday_sat => 'Sat';

  @override
  String get weekday_sun => 'Sun';

  @override
  String get calendar_nutritionAvg => 'NUTRITION (avg per day)';

  @override
  String get calendar_workouts => 'WORKOUTS';

  @override
  String get calendar_noWorkoutsPeriod => 'No workouts in this period.';

  @override
  String get calendar_noWorkoutsDay => 'No workouts on this day.';

  @override
  String get calendar_consumption => 'BURN';

  @override
  String get calendar_nutrition => 'NUTRITION';

  @override
  String get calendar_noMealsDay => 'No meals on this day.';

  @override
  String get calendar_feelingEmpty => 'Feeling: --';

  @override
  String get calendar_feelingSaved => 'Feeling saved';

  @override
  String get calendar_hint => 'Dots = workout type. Tap a day for details.';

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
  String get calendar_workoutTypeRun => 'Run';

  @override
  String get calendar_workoutTypeLegacy => 'Training';

  @override
  String calendar_calorieBreakdown(Object label, Object kcal) {
    return '$label · $kcal kcal';
  }

  @override
  String get calendar_30DaySummary => '30-day summary';

  @override
  String calendar_streakDays(int count) {
    return '$count-day streak';
  }

  @override
  String calendar_workoutsInLastDays(int count, int days) {
    return '$count workouts in the last $days days';
  }

  @override
  String calendar_kcalBurnedSuffix(int kcal) {
    return ' · $kcal kcal burned';
  }

  @override
  String get steps_unavailableDevice =>
      'Steps are not available on this device.';

  @override
  String get steps_connectHint =>
      'Tap Connect to grant Apple Health or Health Connect access.';

  @override
  String get steps_loadFailed => 'Could not load steps.';

  @override
  String steps_loadedToday(int count) {
    return 'Today: $count steps loaded';
  }

  @override
  String steps_todaySnack(int count) {
    return 'Today: $count steps';
  }

  @override
  String get steps_appleHealth => 'Apple Health';

  @override
  String get steps_healthConnect => 'Health Connect';

  @override
  String get steps_notAvailable => 'Not available';

  @override
  String get steps_notSynced => 'Not synced yet';

  @override
  String steps_updatedAt(Object time) {
    return 'Updated at $time';
  }

  @override
  String get steps_connect => 'Connect';

  @override
  String get steps_refresh => 'Refresh';

  @override
  String get steps_label => 'Steps';

  @override
  String get steps_mobileOnly => 'Only available on iPhone and Android';

  @override
  String get steps_wearablesHint =>
      'Fitbit, Garmin and Samsung Health can sync via Health Connect.';

  @override
  String get sleep_unavailableDevice =>
      'Sleep tracking is not available on this device.';

  @override
  String get sleep_connectHint =>
      'Tap Connect to grant Apple Health or Health Connect access for sleep.';

  @override
  String get sleep_loadFailed => 'Could not load sleep data.';

  @override
  String sleep_loadedLastNight(Object duration) {
    return 'Last night: $duration loaded';
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
  String get sleep_mobileOnly => 'Only available on iPhone and Android';

  @override
  String get home_statusSleepNone => 'No sleep data synced';

  @override
  String home_statusSleepLastNight(int hours, int minutes) {
    return '${hours}h ${minutes}m sleep last night';
  }

  @override
  String home_statusSleepHours(int hours) {
    return '${hours}h sleep last night';
  }

  @override
  String home_statusSleepMinutes(int minutes) {
    return '${minutes}m sleep last night';
  }

  @override
  String get health_stepsUnsupported =>
      'Steps are only available on iPhone and Android.';

  @override
  String get health_stepsPermissionConnect =>
      'Connect Apple Health or Health Connect to load steps.';

  @override
  String get health_stepsPermissionDenied =>
      'Permission denied. You can re-enable Apple Health or Health Connect in system settings.';

  @override
  String get health_connectNotInstalled =>
      'Health Connect is not installed. Install it from the Play Store and connect Fitbit/Garmin/Samsung there.';

  @override
  String get analytics_weight => 'Weight';

  @override
  String get analytics_steps => 'Steps';

  @override
  String get analytics_calories => 'Calories';

  @override
  String get analytics_burn => 'Burn';

  @override
  String get analytics_water => 'Water';

  @override
  String get analytics_afterburn => 'Afterburn';

  @override
  String get analytics_protein => 'Protein';

  @override
  String get analytics_fat => 'Fat';

  @override
  String get analytics_carbs => 'Carbs';

  @override
  String get analytics_workouts => 'Workouts';

  @override
  String get analytics_emptyWeight => 'Log weight to see your progress.';

  @override
  String get analytics_emptySteps => 'Sync steps to see your daily activity.';

  @override
  String get analytics_emptyCalories => 'No calories in the last 30 days yet.';

  @override
  String get analytics_emptyBurn => 'No burn data in the last 30 days yet.';

  @override
  String get analytics_emptyWater => 'No water data in the last 30 days yet.';

  @override
  String get analytics_emptyAfterburn =>
      'No afterburn in the last 30 days yet.';

  @override
  String get analytics_emptyProtein => 'No protein in the last 30 days yet.';

  @override
  String get analytics_emptyFat => 'No fat in the last 30 days yet.';

  @override
  String get analytics_emptyCarbs => 'No carbs in the last 30 days yet.';

  @override
  String get analytics_emptyWorkouts => 'No workouts in the last 30 days yet.';

  @override
  String get analytics_unitKg => 'kg';

  @override
  String get analytics_unitKcal => 'kcal';

  @override
  String get analytics_unitMl => 'ml';

  @override
  String get analytics_unitG => 'g';

  @override
  String get analytics_addWeightHint => 'Add weight entries to see progress.';

  @override
  String get achievements_levelingSystem => 'Leveling System';

  @override
  String get achievements_noXp =>
      'You don\'t collect XP here — you earn levels directly.';

  @override
  String get achievements_levelPerWorkout => 'Levels per workout';

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
  String get achievements_streakBonus => 'Streak bonus (one-time when reached)';

  @override
  String get achievements_streak10 => '10 days';

  @override
  String get achievements_streak30 => '30 days';

  @override
  String get achievements_streak100 => '100 days';

  @override
  String get achievements_streak365 => '365 days';

  @override
  String get achievements_streak1000 => '1000 days';

  @override
  String get achievements_gymCaliHint =>
      'Note: Gym/Calisthenics count when you tap the checkmark „Workout complete“ at the top of the workout detail.';

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
  String get rank_profi => 'Pro';

  @override
  String get rank_athlet => 'Athlete';

  @override
  String get rank_krieger => 'Warrior';

  @override
  String get rank_elite => 'Elite';

  @override
  String get rank_champion => 'Champion';

  @override
  String get rank_goat => 'GOAT';

  @override
  String get rank_halbgott => 'Demigod';

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
  String get badge_level300_title => 'Pro';

  @override
  String get badge_level300_subtitle => 'Level 300';

  @override
  String get badge_level500_title => 'Athlete';

  @override
  String get badge_level500_subtitle => 'Level 500';

  @override
  String get badge_level1000_title => 'Warrior';

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
  String get badge_level10000_title => 'Demigod';

  @override
  String get badge_level10000_subtitle => 'Level 10000';

  @override
  String get badge_streak30_title => 'Discipline';

  @override
  String get badge_streak30_subtitle => '30 day streak';

  @override
  String get badge_streak100_title => 'Iron discipline';

  @override
  String get badge_streak100_subtitle => '100 day streak';

  @override
  String get badge_streak365_title => 'Warrior mindset';

  @override
  String get badge_streak365_subtitle => '365 day streak';

  @override
  String get badge_streak500_title => 'Titan';

  @override
  String get badge_streak500_subtitle => '500 day streak';

  @override
  String get badge_streak1000_title => 'Demigod mindset';

  @override
  String get badge_streak1000_subtitle => '1000 day streak';

  @override
  String get badge_gym50_title => 'Gym Junior';

  @override
  String get badge_gym50_subtitle => '50 gym workouts';

  @override
  String get badge_gym100_title => 'Gym Pro';

  @override
  String get badge_gym100_subtitle => '100 gym workouts';

  @override
  String get badge_gym500_title => 'Bodybuilding Junior';

  @override
  String get badge_gym500_subtitle => '500 gym workouts';

  @override
  String get badge_gym1000_title => 'Bodybuilder';

  @override
  String get badge_gym1000_subtitle => '1000 gym workouts';

  @override
  String get badge_cali50_title => 'Calisthenics Junior';

  @override
  String get badge_cali50_subtitle => '50 calisthenics workouts';

  @override
  String get badge_cali100_title => 'Calisthenics Pro';

  @override
  String get badge_cali100_subtitle => '100 calisthenics workouts';

  @override
  String get badge_cali500_title => 'Bodyweight Junior';

  @override
  String get badge_cali500_subtitle => '500 calisthenics workouts';

  @override
  String get badge_cali1000_title => 'Bodyweight Master';

  @override
  String get badge_cali1000_subtitle => '1000 calisthenics workouts';

  @override
  String get gallery_mobileOnly =>
      'Gallery is currently only available on mobile.';

  @override
  String get gallery_saveFailed => 'Could not save photo.';

  @override
  String get gallery_title => 'Gallery';

  @override
  String get gallery_empty => 'No photos yet.\nTap + to take a photo.';

  @override
  String get food_tabFoods => 'Foods';

  @override
  String get food_tabDishes => 'Dishes';

  @override
  String get food_tabSupplements => 'Supplements';

  @override
  String get food_supplementsSearchHint => 'Search supplements…';

  @override
  String get food_supplementsEmpty => 'No supplements logged today.';

  @override
  String get food_supplementsToday => 'Today';

  @override
  String food_supplementMg(Object mg) {
    return '$mg mg';
  }

  @override
  String get food_supplementAddTitle => 'Add supplement';

  @override
  String get food_supplementAmountLabel => 'Amount (mg)';

  @override
  String get food_supplementSlotMorning => 'Morning';

  @override
  String get food_supplementSlotMidday => 'Midday';

  @override
  String get food_supplementSlotEvening => 'Evening';

  @override
  String get food_supplementSlotLabel => 'Time of day';

  @override
  String get food_supplementDragHint =>
      'Long-press a card and drag it to Morning, Midday or Evening.';

  @override
  String get food_supplementDropHere => 'Drop here';

  @override
  String get food_searchHint => 'Search food or tag';

  @override
  String get food_newDish => 'New Dish';

  @override
  String get food_dishPhotoAction => 'Choose dish photo';

  @override
  String get food_dishesSearchHint => 'Search dishes…';

  @override
  String get food_dishNoIngredients => 'Dish has no ingredients yet.';

  @override
  String food_dishAddedToday(Object name) {
    return '\"$name\" added to today.';
  }

  @override
  String get food_deleteDishTitle => 'Delete dish?';

  @override
  String food_deleteDishBody(Object name) {
    return '\"$name\" will be permanently deleted.';
  }

  @override
  String get food_enterGramsMacros => 'Please enter grams and macros.';

  @override
  String get food_macroProtein => 'Protein';

  @override
  String get food_macroCarbs => 'Carbs';

  @override
  String get food_macroFat => 'Fat';

  @override
  String get food_macroKcal => 'kcal';

  @override
  String get food_dishNameHint => 'e.g. Breakfast bowl';

  @override
  String get food_newDishTitle => 'New Dish';

  @override
  String get food_macrosHeading => 'Macros';

  @override
  String get food_noFoodsFound => 'No foods found';

  @override
  String food_foodCount(int count) {
    return '$count foods';
  }

  @override
  String get food_macroAll => 'All';

  @override
  String get food_focusNeverEat => 'Never eat';

  @override
  String get food_focusHealthyBrain => 'Healthy brain';

  @override
  String get food_macroCarbsLong => 'Carbs';

  @override
  String food_kcalPer100g(Object kcal) {
    return '$kcal kcal / 100 g';
  }

  @override
  String get food_renameDishTitle => 'Rename dish';

  @override
  String get food_dishNotFound => 'Dish not found';

  @override
  String get food_dishFallback => 'Dish';

  @override
  String food_addedToDish(Object name, Object grams) {
    return '$name ($grams g) added.';
  }

  @override
  String food_addedToTodayFull(Object name, Object grams) {
    return '$name ($grams g) added to today.';
  }

  @override
  String get food_eatToday => 'Eat today';

  @override
  String get food_addToDishBtn => 'Add to dish';

  @override
  String get food_per100g => 'Per 100 g';

  @override
  String get food_amount => 'Amount';

  @override
  String food_forGrams(Object grams) {
    return 'For $grams g';
  }

  @override
  String get food_macrosNotStored => 'Macros not on file';

  @override
  String get food_macrosManualHint =>
      'Enter macros per 100 g manually to add this food to a dish.';

  @override
  String get food_ingredientFood => 'Food';

  @override
  String get food_emptyDishesTitle => 'No dishes yet';

  @override
  String get food_emptyDishesBody =>
      'Create your first dish to log combined meals.';

  @override
  String get food_pickIngredientTitle => 'Pick food';

  @override
  String get food_manualEntry => 'manual';

  @override
  String get food_whichDish => 'Which dish?';

  @override
  String get food_newDishEllipsis => 'New dish…';

  @override
  String get food_removeFromDish => 'Remove from dish';

  @override
  String get food_barcodeScanTitle => 'Scan barcode';

  @override
  String get food_barcodeScanHint => 'Hold the barcode inside the frame';

  @override
  String get food_barcodeDesktopHint =>
      'Barcode scanning works on mobile. Enter the barcode manually here.';

  @override
  String get food_barcodeManualLabel => 'Enter barcode';

  @override
  String get food_barcodeManualHint => 'e.g. 4008400407321';

  @override
  String get food_barcodeLookupBtn => 'Look up product';

  @override
  String get food_barcodeLookingUp => 'Looking up product…';

  @override
  String get food_barcodeNotFound => 'Product not found in Open Food Facts.';

  @override
  String get food_scannedProduct => 'Scanned product';

  @override
  String food_barcodeValue(Object code) {
    return 'Barcode: $code';
  }

  @override
  String get muscleExercise_emptyGym =>
      'No gym exercises listed for this muscle.';

  @override
  String get muscleExercise_emptyCalisthenics =>
      'No calisthenics exercises listed for this muscle.';

  @override
  String get strength_setsLabel => 'Sets';

  @override
  String get strength_repsLabel => 'Reps';

  @override
  String get strength_sectionMyWorkouts => 'My workouts';

  @override
  String get strength_sectionPresetWorkouts => 'Preset workouts';

  @override
  String get strength_renameWorkoutTitle => 'Rename';

  @override
  String get strength_deleteWorkoutTitle => 'Delete workout?';

  @override
  String get strength_deleteWorkoutBody =>
      'This workout will be permanently deleted.';

  @override
  String get strength_deleteWorkoutMenu => 'Delete workout';

  @override
  String strength_exerciseCount(Object count) {
    return '$count exercises';
  }

  @override
  String get strength_addToWorkoutTooltip => 'Add to workout';

  @override
  String get strength_workoutFallback => 'Workout';

  @override
  String get cali_skillsHeading => 'SKILLS';

  @override
  String get gym_tabExercises => 'Exercises';

  @override
  String get gym_tabWorkouts => 'Workouts';

  @override
  String get gym_addToLastWorkout => 'Add to last workout';

  @override
  String get gym_noWorkoutYet => 'No workout created yet.';

  @override
  String get gym_addWorkout => 'Add to workout';

  @override
  String get gym_addToWorkoutTitle => 'Add to workout';

  @override
  String get gym_noWorkoutsCreated => 'You haven\'t created any workouts yet.';

  @override
  String get gym_newWorkout => 'New workout';

  @override
  String get gym_createNewWorkout => 'Create new workout';

  @override
  String get gym_exerciseAdded => 'Exercise added.';

  @override
  String get gym_workoutNotFound => 'Workout not found.';

  @override
  String get gym_defaultWorkoutName => 'My Workout';

  @override
  String get cali_tabExercises => 'Exercises';

  @override
  String get cali_tabWorkouts => 'Workouts';

  @override
  String get cali_skillProgramsIntro =>
      'More workouts and programs for this skill will be added here step by step.';

  @override
  String get cali_programBeginner => 'Beginner Program';

  @override
  String get cali_programBeginnerSub => 'Basics + technique + mobility';

  @override
  String get cali_programIntermediate => 'Intermediate Program';

  @override
  String get cali_programIntermediateSub => 'Progressions + strength building';

  @override
  String get cali_programAdvanced => 'Advanced Program';

  @override
  String get cali_programAdvancedSub => 'Skills + volume + intensity';

  @override
  String get cali_programPlaceholder =>
      'This page is linked so the structure is ready. Next we\'ll fill it with real workouts like the Gym/Cali workout builder.';

  @override
  String get categoryDetail_startWorkout => 'Start workout';

  @override
  String categoryDetail_exerciseCountDuration(int count, Object duration) {
    return '$count exercises · Total time: $duration';
  }

  @override
  String get categoryDetail_secondsDefaultHint =>
      'Default: 30s. Tap the seconds to change them.';

  @override
  String categoryDetail_durationMinSec(int minutes, Object seconds) {
    return '$minutes min $seconds sec';
  }

  @override
  String get categoryDetail_heading9min => '9 Min Workout';

  @override
  String get categoryDetail_info9min =>
      'Here you can adjust the times yourself by tapping the green 30s labels.';

  @override
  String get categoryDetail_infoStretch =>
      'Here you can adjust the times yourself by tapping the green 30s labels.';

  @override
  String get categoryDetail_infoMorning =>
      'Here you can adjust the times yourself by tapping the green 30s labels. You can also add or remove exercises as you like.';

  @override
  String get categoryDetail_headingHercules => 'Optimized for runners';

  @override
  String get morningWorkout_addExercise => 'Add exercise';

  @override
  String get morningWorkout_removeExercise => 'Remove exercise';

  @override
  String get morningWorkout_pickExercise => 'Add exercise to workout';

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
      'At least one exercise must remain.';

  @override
  String get morningWorkout_allExercisesAdded =>
      'All exercises are already in your workout.';

  @override
  String get categoryDetail_headingStretch => 'Only Stretch';

  @override
  String get strength_exercisesZero => '0 exercises';

  @override
  String strength_exercisesSummary(Object kcal, int count, Object duration) {
    return '$kcal kcal · $count exercises · $duration';
  }

  @override
  String get strength_workoutComplete => 'Workout complete';

  @override
  String strength_workoutCompleteSnack(Object kcal) {
    return 'Workout complete. +5 Level · $kcal kcal';
  }

  @override
  String get strength_estimatedBurn => 'Estimated burn';

  @override
  String get strength_exerciseFallback => 'Exercise';

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
  String get preset_chestTriShoulder => 'Chest · Triceps · Shoulder';

  @override
  String get preset_backBiceps => 'Back · Biceps';

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
  String get mood_title => 'How do you feel?';

  @override
  String get mood_veryBad => 'Very\nbad';

  @override
  String get mood_bad => 'Bad';

  @override
  String get mood_neutral => 'Neutral';

  @override
  String get mood_good => 'Good';

  @override
  String get mood_veryGood => 'Very\ngood';

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
    return 'Set $current of $total';
  }

  @override
  String workout_finishedMessage(int count) {
    return 'Great job! You completed all $count exercises.';
  }

  @override
  String get workout_tapCheckHint => 'Tap the checkmark to see your progress.';

  @override
  String get tts_getReady => 'Get ready';

  @override
  String get tts_halfway => 'Halfway';

  @override
  String get tts_start => 'Go!';

  @override
  String get tts_workoutComplete => 'Workout finished, GREAT!';

  @override
  String tts_pauseNext(Object name) {
    return 'Pause. Next exercise: $name';
  }

  @override
  String get running_tabNewRoute => 'New route';

  @override
  String get running_tabSaved => 'Saved';

  @override
  String get running_tabHistory => 'History';

  @override
  String get running_historyEmpty => 'No runs yet';

  @override
  String get running_historyEmptyHint =>
      'Finish a tracked run and it will appear here.';

  @override
  String running_historyMonthKm(Object km) {
    return '$km km this month';
  }

  @override
  String running_historyMonthAvgPace(Object pace) {
    return 'Avg pace $pace';
  }

  @override
  String get running_historyUntitledRun => 'Run';

  @override
  String get running_needStartEnd => 'Set at least a start and end point.';

  @override
  String running_unexpectedError(Object detail) {
    return 'Unexpected error: $detail';
  }

  @override
  String running_routeSaved(Object name) {
    return 'Route \"$name\" saved.';
  }

  @override
  String get running_saveRouteTitle => 'Save route';

  @override
  String get running_routeNameLabel => 'Name';

  @override
  String running_defaultRouteName(Object date) {
    return 'Run $date';
  }

  @override
  String get running_myLocation => 'My location';

  @override
  String get running_reset => 'Reset';

  @override
  String get running_removeLastPoint => 'Remove last point';

  @override
  String get running_mapHint =>
      'Tap the map for your route or start right away.';

  @override
  String get running_calculateRoute => 'Calculate route';

  @override
  String get running_save => 'Save';

  @override
  String get running_points => 'POINTS';

  @override
  String get running_distance => 'DISTANCE';

  @override
  String get running_elevation => 'ELEVATION';

  @override
  String get running_pinStart => 'S';

  @override
  String get running_pinEnd => 'E';

  @override
  String get running_noRoutes => 'No routes yet';

  @override
  String get running_noRoutesHint =>
      'Switch to the \"New route\" tab and plan your first run.';

  @override
  String get running_deleteRouteTitle => 'Delete route?';

  @override
  String running_deleteRouteBody(Object name) {
    return '\"$name\" will be permanently removed.';
  }

  @override
  String get running_renameTitle => 'Rename';

  @override
  String get running_deleteConfirmBody => 'This action cannot be undone.';

  @override
  String get run_gpsOff => 'Location services are disabled.';

  @override
  String get run_gpsDenied => 'Location permission denied.';

  @override
  String run_gpsError(Object detail) {
    return 'GPS error: $detail';
  }

  @override
  String run_gpsStartFailed(Object detail) {
    return 'Could not start GPS: $detail';
  }

  @override
  String run_ttsIn100m(Object instruction) {
    return 'In 100 meters: $instruction';
  }

  @override
  String run_ttsIn300m(Object instruction) {
    return 'In 300 meters: $instruction';
  }

  @override
  String get run_ttsGoalReached => 'Destination reached. Well done!';

  @override
  String get run_goalReached => 'Destination reached';

  @override
  String get run_ttsStarted => 'Run started. Good luck!';

  @override
  String get run_ttsPause => 'Pause.';

  @override
  String get run_ttsResume => 'Let\'s go.';

  @override
  String get run_endTitle => 'End run?';

  @override
  String get run_endBody => 'Distance, time and the run will be saved.';

  @override
  String get run_keepRunning => 'Keep running';

  @override
  String get run_end => 'End';

  @override
  String get run_finishedTitle => 'Run finished';

  @override
  String get run_distance => 'Distance';

  @override
  String get run_time => 'Time';

  @override
  String get run_calories => 'Calories';

  @override
  String get run_level => 'Level';

  @override
  String run_levelNextMeters(Object meters) {
    return '$meters m until next level.';
  }

  @override
  String run_levelEvery5km(Object meters) {
    return '+1 level every 5 km — $meters m to go.';
  }

  @override
  String get run_autoFollowOn => 'Auto-follow on';

  @override
  String get run_autoFollowOff => 'Auto-follow off';

  @override
  String get run_voiceOn => 'Voice on';

  @override
  String get run_voiceOff => 'Voice off';

  @override
  String get run_waitingGps => 'Waiting for GPS signal…';

  @override
  String get run_distNow => 'Now';

  @override
  String run_distInMeters(Object meters) {
    return 'in $meters m';
  }

  @override
  String run_distInKm(Object km) {
    return 'in $km km';
  }

  @override
  String get run_labelTime => 'TIME';

  @override
  String get run_labelKm => 'KM';

  @override
  String get run_labelPace => 'PACE';

  @override
  String get run_start => 'START RUN';

  @override
  String get run_waitGps => 'WAITING FOR GPS…';

  @override
  String get run_resume => 'RESUME';

  @override
  String get run_pause => 'PAUSE';

  @override
  String get run_endButton => 'END';

  @override
  String get social_connectTitle => 'Connect friends';

  @override
  String get social_connectSubtitle => 'Share workouts, routes and recipes';

  @override
  String get social_inboxTitle => 'Inbox';

  @override
  String get social_yourIdTitle => 'Your Kaizen ID';

  @override
  String get social_copyCode => 'Copy ID';

  @override
  String get social_shareInvite => 'Share invite';

  @override
  String get social_addFriendTitle => 'Add friend by ID';

  @override
  String get social_addFriendHint => 'KZN-ABC123';

  @override
  String get social_addFriendAction => 'Connect';

  @override
  String social_friendsListTitle(int count) {
    return 'Friends ($count)';
  }

  @override
  String get social_noFriendsYet => 'No friends connected yet.';

  @override
  String get social_notifyRunStart => 'Notify when starting a run';

  @override
  String get social_removeFriendTitle => 'Remove friend?';

  @override
  String social_removeFriendBody(String name) {
    return 'Remove $name from your friends list?';
  }

  @override
  String get social_codeCopied => 'ID copied';

  @override
  String get social_friendAdded => 'Friend connected';

  @override
  String get social_errorInvalidCode => 'Please enter a valid ID.';

  @override
  String get social_errorSelfFriend => 'You cannot add yourself.';

  @override
  String get social_errorFriendNotFound => 'No user found with this ID.';

  @override
  String get social_errorAlreadyFriends => 'You are already connected.';

  @override
  String get social_errorCloudDisabled =>
      'Cloud sync is not set up yet. Configure Firebase to connect with friends.';

  @override
  String get social_errorGeneric => 'Could not connect. Please try again.';

  @override
  String get social_cloudSetupHint =>
      'Friend sync requires Firebase. Add your projectId and apiKey in lib/services/social/social_cloud_config.dart, enable Anonymous Auth + Firestore, then rebuild.';

  @override
  String social_inviteShareText(String link, String code) {
    return 'Connect with me on Kaizen: $link\nMy ID: $code';
  }

  @override
  String get social_shareAction => 'Share with friend';

  @override
  String get social_shareWithFriendsTitle => 'Share with';

  @override
  String get social_noFriendsToShare =>
      'Add friends in Profile → Connect friends first.';

  @override
  String get social_shareSent => 'Shared successfully';

  @override
  String get social_inboxEmpty => 'No messages yet.';

  @override
  String social_inboxRoute(String name) {
    return '$name shared a running route with you.';
  }

  @override
  String social_inboxGymWorkout(String name) {
    return '$name shared a gym workout with you.';
  }

  @override
  String social_inboxCalisthenicsWorkout(String name) {
    return '$name shared a calisthenics workout with you.';
  }

  @override
  String social_inboxFoodDish(String name) {
    return '$name shared a dish with you.';
  }

  @override
  String social_inboxThumbsUp(String name) {
    return '$name sent you a thumbs up 👍';
  }

  @override
  String get social_sendThumbsUp => 'Send thumbs up';

  @override
  String get social_thumbsUpSent => 'Thumbs up sent';

  @override
  String get social_acceptRoute => 'Add to saved routes';

  @override
  String get social_acceptWorkout => 'Add to my workouts';

  @override
  String get social_acceptDish => 'Add to my recipes';

  @override
  String get social_reject => 'Decline';

  @override
  String get social_inboxAccepted => 'Added';

  @override
  String get social_inboxRejected => 'Declined';

  @override
  String get social_inboxAdded => 'Added to your library';

  @override
  String get friends_hubTitle => 'Friends';

  @override
  String get friends_monthlyChallengeTab => 'Monthly Challenge';

  @override
  String get friends_runningMapTab => 'Running Map';

  @override
  String get friends_challengeTitle => '1,000 Push-Up Challenge';

  @override
  String get friends_goal => 'Goal';

  @override
  String get friends_pushUps => 'push-ups';

  @override
  String get friends_tapToEdit => 'Tap to edit your count';

  @override
  String get friends_editCountTitle => 'Update push-up count';

  @override
  String get friends_editCountHint => 'Current total this month';

  @override
  String get friends_save => 'Save';

  @override
  String get friends_leaderboard => 'Leaderboard';

  @override
  String get friends_you => 'You';

  @override
  String get friends_noFriendsHint =>
      'Connect friends to compete with them here.';

  @override
  String get friends_goalReached => 'Goal reached — keep going!';

  @override
  String get running_tabShared => 'Shared';

  @override
  String get sharedRuns_tabHint =>
      'See friends who are running live. Tap a profile icon for pace and route details.';

  @override
  String get sharedRuns_empty => 'No friends are running right now.';

  @override
  String get sharedRuns_homeTitle => 'Friends running live';

  @override
  String sharedRuns_liveCount(int count) {
    return '$count live';
  }

  @override
  String get sharedRuns_distance => 'Distance';

  @override
  String get sharedRuns_currentPace => 'Current pace';

  @override
  String get sharedRuns_avgPace => 'Average pace';

  @override
  String get onTheGo_exercises => 'Exercises';

  @override
  String get onTheGo_search => 'Search exercises…';

  @override
  String get onTheGo_select => 'Tap muscles to select';

  @override
  String get onTheGo_show => 'Show exercises';

  @override
  String get onTheGo_noMatches => 'No matching exercises found.';

  @override
  String get onTheGo_empty =>
      'Your workout is empty. Add exercises from the list on the right.';

  @override
  String get onTheGo_generate => 'Generate workout';

  @override
  String get onTheGo_moreExercises => 'More exercises';

  @override
  String get onTheGo_complement => 'Complement for the same body area';

  @override
  String get onTheGo_saveFailed =>
      'Could not save the workout. Please try again.';

  @override
  String get workoutHub_searchHint => 'Search workouts…';

  @override
  String get workoutHub_filter => 'Filter';

  @override
  String get workoutHub_filterTitle => 'Filters';

  @override
  String get workoutHub_filterApply => 'Apply';

  @override
  String get workoutHub_filterKind => 'Type';

  @override
  String get workoutHub_filterMuscles => 'Muscle groups';

  @override
  String get workoutHub_kindGym => 'Gym';

  @override
  String get workoutHub_kindCalisthenics => 'Calisthenics';

  @override
  String get workoutHub_kindStretch => 'Stretch';

  @override
  String get workoutHub_quickAccess => 'Quick start';

  @override
  String get workoutHub_myWorkouts => 'My workouts';

  @override
  String get workoutHub_presets => 'Preset workouts';

  @override
  String get workoutHub_favorites => 'Favorites';

  @override
  String get workoutHub_empty => 'No workouts match your search.';

  @override
  String get workoutHub_startAsYouGo => 'Start empty workout';

  @override
  String get workoutHub_startWorkout => 'Start workout';

  @override
  String get workoutHub_favorite => 'Favorite';

  @override
  String get workoutHub_unfavorite => 'Unpin favorite';

  @override
  String get running_startFree => 'Start right away';

  @override
  String get running_freeRunName => 'Free run';

  @override
  String get running_savedFreeRun => 'Run saved';

  @override
  String get strength_setsMaxHint => 'Up to 100 sets';

  @override
  String get strength_editSetReps => 'Edit reps';
}
