import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Kaizen'**
  String get appTitle;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get common_continue;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get common_reset;

  /// No description provided for @common_create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get common_create;

  /// No description provided for @common_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_add;

  /// No description provided for @common_rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get common_rename;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get common_skip;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @common_filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get common_filter;

  /// No description provided for @common_info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get common_info;

  /// No description provided for @common_search.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get common_search;

  /// No description provided for @common_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get common_name;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// No description provided for @onboarding_welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Kaizen'**
  String get onboarding_welcomeTitle;

  /// No description provided for @onboarding_profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get onboarding_profileNameLabel;

  /// No description provided for @onboarding_profileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get onboarding_profileNameHint;

  /// No description provided for @onboarding_stepProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get to know you'**
  String get onboarding_stepProfileTitle;

  /// No description provided for @onboarding_stepProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your data helps us calculate your daily targets.'**
  String get onboarding_stepProfileSubtitle;

  /// No description provided for @onboarding_stepGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your goal?'**
  String get onboarding_stepGoalTitle;

  /// No description provided for @onboarding_stepGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll adjust your calories and macros accordingly.'**
  String get onboarding_stepGoalSubtitle;

  /// No description provided for @onboarding_stepMacrosTitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily targets'**
  String get onboarding_stepMacrosTitle;

  /// No description provided for @onboarding_stepMacrosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calculated just for you — you can change this anytime in Profile.'**
  String get onboarding_stepMacrosSubtitle;

  /// No description provided for @onboarding_stepScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Your weekly plan'**
  String get onboarding_stepScheduleTitle;

  /// No description provided for @onboarding_stepScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick training days and optional times. Leave empty if you\'re not sure yet.'**
  String get onboarding_stepScheduleSubtitle;

  /// No description provided for @onboarding_stepScheduleLaterHint.
  ///
  /// In en, this message translates to:
  /// **'You can adjust your weekly plan anytime in Profile → Edit profile.'**
  String get onboarding_stepScheduleLaterHint;

  /// No description provided for @onboarding_skipSchedule.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onboarding_skipSchedule;

  /// No description provided for @onboarding_stepNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on track'**
  String get onboarding_stepNotificationsTitle;

  /// No description provided for @onboarding_stepNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow reminders 15 minutes before each scheduled session.'**
  String get onboarding_stepNotificationsSubtitle;

  /// No description provided for @onboarding_stepMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Your morning workout'**
  String get onboarding_stepMorningTitle;

  /// No description provided for @onboarding_stepMorningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build your personal morning routine — ideally once daily, best in the morning.'**
  String get onboarding_stepMorningSubtitle;

  /// No description provided for @onboarding_enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable training reminders'**
  String get onboarding_enableNotifications;

  /// No description provided for @onboarding_skipNotifications.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboarding_skipNotifications;

  /// No description provided for @onboarding_next.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboarding_next;

  /// No description provided for @onboarding_finish.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboarding_finish;

  /// No description provided for @onboarding_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboarding_back;

  /// No description provided for @onboarding_morningSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected exercises'**
  String get onboarding_morningSelected;

  /// No description provided for @onboarding_morningPickFrom.
  ///
  /// In en, this message translates to:
  /// **'Add from catalog'**
  String get onboarding_morningPickFrom;

  /// No description provided for @onboarding_morningTabStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch / Yoga'**
  String get onboarding_morningTabStretch;

  /// No description provided for @onboarding_morningTabCalisthenics.
  ///
  /// In en, this message translates to:
  /// **'Calisthenics'**
  String get onboarding_morningTabCalisthenics;

  /// No description provided for @onboarding_morningTabGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get onboarding_morningTabGym;

  /// No description provided for @onboarding_morningMinOne.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one exercise in your morning workout.'**
  String get onboarding_morningMinOne;

  /// No description provided for @schedule_editorHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to train. Tap the time to set when — optional.'**
  String get schedule_editorHint;

  /// No description provided for @schedule_editorTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly training plan'**
  String get schedule_editorTitle;

  /// No description provided for @schedule_tapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit'**
  String get schedule_tapToEdit;

  /// No description provided for @schedule_emptySummary.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet'**
  String get schedule_emptySummary;

  /// No description provided for @schedule_activityGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get schedule_activityGym;

  /// No description provided for @schedule_activityCalisthenics.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get schedule_activityCalisthenics;

  /// No description provided for @schedule_activityShortGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get schedule_activityShortGym;

  /// No description provided for @schedule_activityShortCalisthenics.
  ///
  /// In en, this message translates to:
  /// **'BW'**
  String get schedule_activityShortCalisthenics;

  /// No description provided for @schedule_activityShortRunning.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get schedule_activityShortRunning;

  /// No description provided for @schedule_activityShortStretch.
  ///
  /// In en, this message translates to:
  /// **'Str'**
  String get schedule_activityShortStretch;

  /// No description provided for @profile_trainingReminders.
  ///
  /// In en, this message translates to:
  /// **'Training reminders'**
  String get profile_trainingReminders;

  /// No description provided for @profile_trainingRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications 15 minutes before scheduled workouts'**
  String get profile_trainingRemindersSubtitle;

  /// No description provided for @profile_fastingHud.
  ///
  /// In en, this message translates to:
  /// **'Intermittent fasting'**
  String get profile_fastingHud;

  /// No description provided for @profile_fastingHudSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show eating window timer on the home screen'**
  String get profile_fastingHudSubtitle;

  /// No description provided for @profile_waterTracking.
  ///
  /// In en, this message translates to:
  /// **'Water tracking'**
  String get profile_waterTracking;

  /// No description provided for @profile_waterTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show a water progress bar on the home screen'**
  String get profile_waterTrackingSubtitle;

  /// No description provided for @profile_waterGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily water goal'**
  String get profile_waterGoal;

  /// No description provided for @profile_waterGoalHint.
  ///
  /// In en, this message translates to:
  /// **'Recommended from your profile: {liters} L'**
  String profile_waterGoalHint(Object liters);

  /// No description provided for @fasting_setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Eating window'**
  String get fasting_setupTitle;

  /// No description provided for @fasting_setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drag the green zone to choose when you can eat — from morning (left) to evening (right).'**
  String get fasting_setupSubtitle;

  /// No description provided for @fasting_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get fasting_save;

  /// No description provided for @fasting_reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get fasting_reminders;

  /// No description provided for @fasting_remindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'15 min before eating opens, 30 min before it closes'**
  String get fasting_remindersSubtitle;

  /// No description provided for @fasting_windowLabel.
  ///
  /// In en, this message translates to:
  /// **'Eating window'**
  String get fasting_windowLabel;

  /// No description provided for @fasting_configureTap.
  ///
  /// In en, this message translates to:
  /// **'Tap to set eating window'**
  String get fasting_configureTap;

  /// No description provided for @fasting_untilEating.
  ///
  /// In en, this message translates to:
  /// **'Eat in'**
  String get fasting_untilEating;

  /// No description provided for @fasting_untilEatingEnd.
  ///
  /// In en, this message translates to:
  /// **'Eating ends in'**
  String get fasting_untilEatingEnd;

  /// No description provided for @fasting_notificationOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Eating window soon'**
  String get fasting_notificationOpenTitle;

  /// No description provided for @fasting_notificationOpenBody.
  ///
  /// In en, this message translates to:
  /// **'You can eat at {time}'**
  String fasting_notificationOpenBody(Object time);

  /// No description provided for @fasting_notificationCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Eating window ending'**
  String get fasting_notificationCloseTitle;

  /// No description provided for @fasting_notificationCloseBody.
  ///
  /// In en, this message translates to:
  /// **'Eating window closes at {time}'**
  String fasting_notificationCloseBody(Object time);

  /// No description provided for @fasting_notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Fasting reminders'**
  String get fasting_notificationChannelName;

  /// No description provided for @fasting_notificationChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders before your eating window opens and closes'**
  String get fasting_notificationChannelDesc;

  /// No description provided for @schedule_activityNineMin.
  ///
  /// In en, this message translates to:
  /// **'9min'**
  String get schedule_activityNineMin;

  /// No description provided for @schedule_activityMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get schedule_activityMorning;

  /// No description provided for @schedule_activityRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get schedule_activityRunning;

  /// No description provided for @schedule_activityStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get schedule_activityStretch;

  /// No description provided for @schedule_editInProfile.
  ///
  /// In en, this message translates to:
  /// **'Weekly plan'**
  String get schedule_editInProfile;

  /// No description provided for @notification_trainingReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Training soon'**
  String get notification_trainingReminderTitle;

  /// No description provided for @notification_trainingReminderBody.
  ///
  /// In en, this message translates to:
  /// **'{activity} in 15 min · {time}'**
  String notification_trainingReminderBody(String activity, String time);

  /// No description provided for @notification_trainingChannelName.
  ///
  /// In en, this message translates to:
  /// **'Training reminders'**
  String get notification_trainingChannelName;

  /// No description provided for @notification_trainingChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders before scheduled workouts'**
  String get notification_trainingChannelDesc;

  /// No description provided for @installHint_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Kaizen'**
  String get installHint_title;

  /// No description provided for @installHint_body.
  ///
  /// In en, this message translates to:
  /// **'Take a quick tour of the app to learn the main areas. You can skip it for now and restart anytime from Profile → Settings → App tour.'**
  String get installHint_body;

  /// No description provided for @installHint_startTour.
  ///
  /// In en, this message translates to:
  /// **'Start tour'**
  String get installHint_startTour;

  /// No description provided for @installHint_gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get installHint_gotIt;

  /// No description provided for @start_featured.
  ///
  /// In en, this message translates to:
  /// **'FEATURED'**
  String get start_featured;

  /// No description provided for @start_categories.
  ///
  /// In en, this message translates to:
  /// **'CATEGORIES'**
  String get start_categories;

  /// No description provided for @start_days.
  ///
  /// In en, this message translates to:
  /// **'DAYS'**
  String get start_days;

  /// No description provided for @start_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get start_open;

  /// No description provided for @start_heroPickGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get start_heroPickGallery;

  /// No description provided for @start_heroTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get start_heroTakePhoto;

  /// No description provided for @start_heroResetDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get start_heroResetDefault;

  /// No description provided for @start_cameraGalleryError.
  ///
  /// In en, this message translates to:
  /// **'Could not open camera/gallery.'**
  String get start_cameraGalleryError;

  /// Localized string for start_cameraGalleryErrorWithDetail
  ///
  /// In en, this message translates to:
  /// **'Camera/gallery error: {detail}'**
  String start_cameraGalleryErrorWithDetail(Object detail);

  /// No description provided for @start_imageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save image.'**
  String get start_imageSaveFailed;

  /// No description provided for @home_bodyViewRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get home_bodyViewRecovery;

  /// No description provided for @home_bodyViewAfterburn.
  ///
  /// In en, this message translates to:
  /// **'Afterburn'**
  String get home_bodyViewAfterburn;

  /// No description provided for @home_bodyViewTrained.
  ///
  /// In en, this message translates to:
  /// **'Trained'**
  String get home_bodyViewTrained;

  /// No description provided for @home_bodyViewOrgans.
  ///
  /// In en, this message translates to:
  /// **'Organs'**
  String get home_bodyViewOrgans;

  /// No description provided for @home_bodyViewSkeleton.
  ///
  /// In en, this message translates to:
  /// **'Joints and tendons'**
  String get home_bodyViewSkeleton;

  /// No description provided for @home_bodyStillToTrain.
  ///
  /// In en, this message translates to:
  /// **'Still to train this week'**
  String get home_bodyStillToTrain;

  /// No description provided for @home_statusRecoveryReady.
  ///
  /// In en, this message translates to:
  /// **'All groups ready'**
  String get home_statusRecoveryReady;

  /// No description provided for @home_statusRecoveryRecovering.
  ///
  /// In en, this message translates to:
  /// **'{count} groups recovering'**
  String home_statusRecoveryRecovering(int count);

  /// No description provided for @home_statusAfterburnNone.
  ///
  /// In en, this message translates to:
  /// **'No active afterburn'**
  String get home_statusAfterburnNone;

  /// No description provided for @home_statusAfterburnActive.
  ///
  /// In en, this message translates to:
  /// **'+{kcal} kcal afterburn'**
  String home_statusAfterburnActive(String kcal);

  /// No description provided for @home_statusTrainedComplete.
  ///
  /// In en, this message translates to:
  /// **'Full body covered'**
  String get home_statusTrainedComplete;

  /// No description provided for @home_statusTrainedWeek.
  ///
  /// In en, this message translates to:
  /// **'{trained}/{total} groups this week'**
  String home_statusTrainedWeek(int trained, int total);

  /// No description provided for @home_statusTrainedPending.
  ///
  /// In en, this message translates to:
  /// **'{trained}/{total} groups · open: {muscles}'**
  String home_statusTrainedPending(int trained, int total, Object muscles);

  /// No description provided for @home_statusOrgansGood.
  ///
  /// In en, this message translates to:
  /// **'Nutrition on track'**
  String get home_statusOrgansGood;

  /// No description provided for @home_statusOrgansAttention.
  ///
  /// In en, this message translates to:
  /// **'{count} organs need attention'**
  String home_statusOrgansAttention(int count);

  /// No description provided for @home_statusJointsNone.
  ///
  /// In en, this message translates to:
  /// **'No joint focus yet'**
  String get home_statusJointsNone;

  /// No description provided for @home_statusJointsStrengthened.
  ///
  /// In en, this message translates to:
  /// **'{count} joints this week'**
  String home_statusJointsStrengthened(int count);

  /// No description provided for @home_organRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get home_organRecommended;

  /// No description provided for @home_organGoodFoods.
  ///
  /// In en, this message translates to:
  /// **'Good — last 30 days'**
  String get home_organGoodFoods;

  /// No description provided for @home_organBadFoods.
  ///
  /// In en, this message translates to:
  /// **'Straining — last 30 days'**
  String get home_organBadFoods;

  /// No description provided for @home_organStatusGood.
  ///
  /// In en, this message translates to:
  /// **'Well supported'**
  String get home_organStatusGood;

  /// No description provided for @home_organStatusMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get home_organStatusMixed;

  /// No description provided for @home_organStatusCareful.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get home_organStatusCareful;

  /// No description provided for @home_organStatusNoData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get home_organStatusNoData;

  /// No description provided for @home_organStatusGoodActive.
  ///
  /// In en, this message translates to:
  /// **'Glowing green (24h)'**
  String get home_organStatusGoodActive;

  /// No description provided for @home_organGoodFoods24h.
  ///
  /// In en, this message translates to:
  /// **'Helpful foods — last 24 hours'**
  String get home_organGoodFoods24h;

  /// No description provided for @home_organsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an organ for details.'**
  String get home_organsHint;

  /// No description provided for @home_bodyTabIntroRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get home_bodyTabIntroRecoveryTitle;

  /// No description provided for @home_bodyTabIntroRecoveryBody.
  ///
  /// In en, this message translates to:
  /// **'Yellow shows trained muscles. A muscle turns red when two moderate workouts target it directly or three moderate workouts involve it within 24 hours. Six direct gym sets also qualify. Red lasts for 24 hours after the qualifying workout. Yellow clears 48 hours after the last workout.'**
  String get home_bodyTabIntroRecoveryBody;

  /// No description provided for @home_bodyTabIntroAfterburnTitle.
  ///
  /// In en, this message translates to:
  /// **'Afterburn'**
  String get home_bodyTabIntroAfterburnTitle;

  /// No description provided for @home_bodyTabIntroAfterburnBody.
  ///
  /// In en, this message translates to:
  /// **'Outlined muscle groups still burn extra calories after training (EPOC). The more intense the workout, the longer afterburn lasts. Train regularly to benefit from the effect.'**
  String get home_bodyTabIntroAfterburnBody;

  /// No description provided for @home_bodyTabIntroTrainedTitle.
  ///
  /// In en, this message translates to:
  /// **'Trained'**
  String get home_bodyTabIntroTrainedTitle;

  /// No description provided for @home_bodyTabIntroTrainedBody.
  ///
  /// In en, this message translates to:
  /// **'Blue muscle groups were trained this week. Unmarked groups are still open — keep a balanced weekly plan in view.'**
  String get home_bodyTabIntroTrainedBody;

  /// No description provided for @home_bodyTabIntroOrgansTitle.
  ///
  /// In en, this message translates to:
  /// **'Organs'**
  String get home_bodyTabIntroOrgansTitle;

  /// No description provided for @home_bodyTabIntroOrgansBody.
  ///
  /// In en, this message translates to:
  /// **'See how your organs are doing based on your nutrition. An organ glows green for only 24 hours after you log a helpful food. Eat healthy and varied — then your organs light up green. Tap an organ for details and recommendations.'**
  String get home_bodyTabIntroOrgansBody;

  /// No description provided for @home_bodyTabIntroSkeletonTitle.
  ///
  /// In en, this message translates to:
  /// **'Skeleton'**
  String get home_bodyTabIntroSkeletonTitle;

  /// No description provided for @home_bodyTabIntroSkeletonBody.
  ///
  /// In en, this message translates to:
  /// **'Green joints were strengthened this week with suitable exercises. Unmarked joints still need attention — focus on mobility and targeted training.'**
  String get home_bodyTabIntroSkeletonBody;

  /// No description provided for @home_skeletonHint.
  ///
  /// In en, this message translates to:
  /// **'Green joints were strengthened this week.'**
  String get home_skeletonHint;

  /// No description provided for @home_jointTrainedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Strengthened this week'**
  String get home_jointTrainedThisWeek;

  /// No description provided for @home_jointNotTrainedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Not trained this week'**
  String get home_jointNotTrainedThisWeek;

  /// No description provided for @home_muscleExercises.
  ///
  /// In en, this message translates to:
  /// **'Good exercises'**
  String get home_muscleExercises;

  /// No description provided for @home_muscleChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get home_muscleChest;

  /// No description provided for @home_muscleBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get home_muscleBack;

  /// No description provided for @home_muscleShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get home_muscleShoulders;

  /// No description provided for @home_muscleBiceps.
  ///
  /// In en, this message translates to:
  /// **'Biceps'**
  String get home_muscleBiceps;

  /// No description provided for @home_muscleTriceps.
  ///
  /// In en, this message translates to:
  /// **'Triceps'**
  String get home_muscleTriceps;

  /// No description provided for @home_muscleAbs.
  ///
  /// In en, this message translates to:
  /// **'Abs'**
  String get home_muscleAbs;

  /// No description provided for @home_muscleLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get home_muscleLegs;

  /// No description provided for @home_muscleForearms.
  ///
  /// In en, this message translates to:
  /// **'Forearms'**
  String get home_muscleForearms;

  /// No description provided for @home_muscleNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get home_muscleNeck;

  /// No description provided for @home_bodyRecoveryHint.
  ///
  /// In en, this message translates to:
  /// **'Within 24 hours, two moderate workouts targeting a muscle, three involving it, or six direct gym sets turn it red. Red turns yellow after 24 hours.'**
  String get home_bodyRecoveryHint;

  /// No description provided for @home_bodyAfterburnHint.
  ///
  /// In en, this message translates to:
  /// **'A blue glow around a muscle shows that its estimated afterburn window is still active.'**
  String get home_bodyAfterburnHint;

  /// No description provided for @home_bodyAfterburnTitle.
  ///
  /// In en, this message translates to:
  /// **'Afterburn so far'**
  String get home_bodyAfterburnTitle;

  /// No description provided for @home_bodyAfterburnKcalValue.
  ///
  /// In en, this message translates to:
  /// **'+{kcal} kcal'**
  String home_bodyAfterburnKcalValue(String kcal);

  /// No description provided for @home_bodyLegendRecoveryRed.
  ///
  /// In en, this message translates to:
  /// **'High load <24h'**
  String get home_bodyLegendRecoveryRed;

  /// No description provided for @home_bodyLegendRecoveryYellow.
  ///
  /// In en, this message translates to:
  /// **'Trained <48h'**
  String get home_bodyLegendRecoveryYellow;

  /// No description provided for @home_bodyLegendAfterburn.
  ///
  /// In en, this message translates to:
  /// **'Blue glow during afterburn'**
  String get home_bodyLegendAfterburn;

  /// No description provided for @home_bodyStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'STREAK'**
  String get home_bodyStreakLabel;

  /// No description provided for @home_startIntro.
  ///
  /// In en, this message translates to:
  /// **'Start introduction'**
  String get home_startIntro;

  /// No description provided for @home_hudTodaysAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Today\'s analytics'**
  String get home_hudTodaysAnalytics;

  /// No description provided for @home_hudCubeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get home_hudCubeDaily;

  /// No description provided for @home_hudCubeAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get home_hudCubeAnalytics;

  /// No description provided for @home_hudSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps: {count}'**
  String home_hudSteps(int count);

  /// No description provided for @home_hudBurned.
  ///
  /// In en, this message translates to:
  /// **'Burned: {kcal} kcal'**
  String home_hudBurned(int kcal);

  /// No description provided for @home_hudDistanceRan.
  ///
  /// In en, this message translates to:
  /// **'Distance ran: {distance}'**
  String home_hudDistanceRan(Object distance);

  /// No description provided for @home_hudWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts: {count}'**
  String home_hudWorkouts(int count);

  /// No description provided for @home_hudCaloriesIn.
  ///
  /// In en, this message translates to:
  /// **'Calories in: {kcal} kcal'**
  String home_hudCaloriesIn(int kcal);

  /// No description provided for @home_hudProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein: {grams}g'**
  String home_hudProtein(int grams);

  /// No description provided for @home_hudCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs: {grams}g'**
  String home_hudCarbs(int grams);

  /// No description provided for @home_hudFats.
  ///
  /// In en, this message translates to:
  /// **'Fats: {grams}g'**
  String home_hudFats(int grams);

  /// No description provided for @home_hudRecoveryNoData.
  ///
  /// In en, this message translates to:
  /// **'Recovery: no data'**
  String get home_hudRecoveryNoData;

  /// No description provided for @home_hudRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery: {sleep}, {quality}'**
  String home_hudRecovery(Object sleep, Object quality);

  /// No description provided for @home_hudSleepNone.
  ///
  /// In en, this message translates to:
  /// **'no sleep data'**
  String get home_hudSleepNone;

  /// No description provided for @home_hudSleepDuration.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m of sleep'**
  String home_hudSleepDuration(int hours, int minutes);

  /// No description provided for @home_hudSleepDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h of sleep'**
  String home_hudSleepDurationHours(int hours);

  /// No description provided for @home_hudSleepDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m of sleep'**
  String home_hudSleepDurationMinutes(int minutes);

  /// No description provided for @home_hudSleepQualityBad.
  ///
  /// In en, this message translates to:
  /// **'bad quality'**
  String get home_hudSleepQualityBad;

  /// No description provided for @home_hudSleepQualityGood.
  ///
  /// In en, this message translates to:
  /// **'good quality'**
  String get home_hudSleepQualityGood;

  /// No description provided for @home_hudSleepQualityPerfect.
  ///
  /// In en, this message translates to:
  /// **'perfect quality'**
  String get home_hudSleepQualityPerfect;

  /// No description provided for @home_hudSummaryDoingWell.
  ///
  /// In en, this message translates to:
  /// **'Doing well this week.'**
  String get home_hudSummaryDoingWell;

  /// No description provided for @home_hudSummaryNoneToday.
  ///
  /// In en, this message translates to:
  /// **'Get moving today.'**
  String get home_hudSummaryNoneToday;

  /// No description provided for @home_hudSummaryOneToday.
  ///
  /// In en, this message translates to:
  /// **'Great! Keep it up.'**
  String get home_hudSummaryOneToday;

  /// No description provided for @home_hudSummaryTwoPlusToday.
  ///
  /// In en, this message translates to:
  /// **'You\'re incredible!'**
  String get home_hudSummaryTwoPlusToday;

  /// No description provided for @home_hudSummaryEatHealthy.
  ///
  /// In en, this message translates to:
  /// **'Eating healthy.'**
  String get home_hudSummaryEatHealthy;

  /// No description provided for @home_hudSummaryMoveToday.
  ///
  /// In en, this message translates to:
  /// **'Move your body today.'**
  String get home_hudSummaryMoveToday;

  /// No description provided for @home_hudSummaryStretchToday.
  ///
  /// In en, this message translates to:
  /// **'You have done a good stretching session today, keep going.'**
  String get home_hudSummaryStretchToday;

  /// No description provided for @home_hudSummaryShortWorkoutToday.
  ///
  /// In en, this message translates to:
  /// **'Great work! You\'ve done a short workout.'**
  String get home_hudSummaryShortWorkoutToday;

  /// No description provided for @home_hudSummaryRunToday.
  ///
  /// In en, this message translates to:
  /// **'Keep it up. That was a great run!'**
  String get home_hudSummaryRunToday;

  /// No description provided for @home_hudSummaryHardTrainingToday.
  ///
  /// In en, this message translates to:
  /// **'You\'re incredible!'**
  String get home_hudSummaryHardTrainingToday;

  /// No description provided for @home_hudTabRecoveryRest.
  ///
  /// In en, this message translates to:
  /// **'Rest your {muscles} today.'**
  String home_hudTabRecoveryRest(String muscles);

  /// No description provided for @home_hudTabRecoveryAllReady.
  ///
  /// In en, this message translates to:
  /// **'All groups ready to train.'**
  String get home_hudTabRecoveryAllReady;

  /// No description provided for @home_hudTabAfterburnEpoc.
  ///
  /// In en, this message translates to:
  /// **'Calculated via EPOC. Afterburn can last up to {hours}h depending on workout intensity.'**
  String home_hudTabAfterburnEpoc(int hours);

  /// No description provided for @home_hudTabAfterburnActive.
  ///
  /// In en, this message translates to:
  /// **'+{kcal} kcal burned · {remaining} left'**
  String home_hudTabAfterburnActive(int kcal, String remaining);

  /// No description provided for @home_hudTabAfterburnNone.
  ///
  /// In en, this message translates to:
  /// **'No active afterburn right now.'**
  String get home_hudTabAfterburnNone;

  /// No description provided for @home_hudTabAfterburnUnknownRemaining.
  ///
  /// In en, this message translates to:
  /// **'still active'**
  String get home_hudTabAfterburnUnknownRemaining;

  /// No description provided for @home_hudTabTrainedOpen.
  ///
  /// In en, this message translates to:
  /// **'Still to train: {muscles}'**
  String home_hudTabTrainedOpen(String muscles);

  /// No description provided for @home_hudTabTrainedComplete.
  ///
  /// In en, this message translates to:
  /// **'All muscle groups trained this week.'**
  String get home_hudTabTrainedComplete;

  /// No description provided for @home_hudTabOrgansNeed.
  ///
  /// In en, this message translates to:
  /// **'Needs better nutrition: {organs}'**
  String home_hudTabOrgansNeed(String organs);

  /// No description provided for @home_hudTabOrgansAllGood.
  ///
  /// In en, this message translates to:
  /// **'All organs well supported.'**
  String get home_hudTabOrgansAllGood;

  /// No description provided for @home_hudTabOrgansEatToday.
  ///
  /// In en, this message translates to:
  /// **'Eat healthy today.'**
  String get home_hudTabOrgansEatToday;

  /// No description provided for @home_hudTabJointsNeed.
  ///
  /// In en, this message translates to:
  /// **'Strengthen this week: {joints}'**
  String home_hudTabJointsNeed(String joints);

  /// No description provided for @home_hudTabJointsAllDone.
  ///
  /// In en, this message translates to:
  /// **'All joints covered this week.'**
  String get home_hudTabJointsAllDone;

  /// No description provided for @home_hudTabDurationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String home_hudTabDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @home_hudTabDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String home_hudTabDurationHours(int hours);

  /// No description provided for @home_hudTabDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String home_hudTabDurationMinutes(int minutes);

  /// No description provided for @home_hudMuscleChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get home_hudMuscleChest;

  /// No description provided for @home_hudMuscleBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get home_hudMuscleBack;

  /// No description provided for @home_hudMuscleShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get home_hudMuscleShoulders;

  /// No description provided for @home_hudMuscleBiceps.
  ///
  /// In en, this message translates to:
  /// **'Biceps'**
  String get home_hudMuscleBiceps;

  /// No description provided for @home_hudMuscleTriceps.
  ///
  /// In en, this message translates to:
  /// **'Triceps'**
  String get home_hudMuscleTriceps;

  /// No description provided for @home_hudMuscleAbs.
  ///
  /// In en, this message translates to:
  /// **'Abs'**
  String get home_hudMuscleAbs;

  /// No description provided for @home_hudMuscleLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get home_hudMuscleLegs;

  /// No description provided for @home_hudMuscleForearms.
  ///
  /// In en, this message translates to:
  /// **'Forearms'**
  String get home_hudMuscleForearms;

  /// No description provided for @home_hudMuscleNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get home_hudMuscleNeck;

  /// No description provided for @home_hudOrganBrain.
  ///
  /// In en, this message translates to:
  /// **'Brain'**
  String get home_hudOrganBrain;

  /// No description provided for @home_hudOrganHeart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get home_hudOrganHeart;

  /// No description provided for @home_hudOrganLungs.
  ///
  /// In en, this message translates to:
  /// **'Lungs'**
  String get home_hudOrganLungs;

  /// No description provided for @home_hudOrganLiver.
  ///
  /// In en, this message translates to:
  /// **'Liver'**
  String get home_hudOrganLiver;

  /// No description provided for @home_hudOrganStomach.
  ///
  /// In en, this message translates to:
  /// **'Stomach'**
  String get home_hudOrganStomach;

  /// No description provided for @home_hudOrganIntestines.
  ///
  /// In en, this message translates to:
  /// **'Intestines'**
  String get home_hudOrganIntestines;

  /// No description provided for @home_hudOrganKidneys.
  ///
  /// In en, this message translates to:
  /// **'Kidneys'**
  String get home_hudOrganKidneys;

  /// No description provided for @home_hudJointNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get home_hudJointNeck;

  /// No description provided for @home_hudJointShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get home_hudJointShoulders;

  /// No description provided for @home_hudJointElbows.
  ///
  /// In en, this message translates to:
  /// **'Elbows'**
  String get home_hudJointElbows;

  /// No description provided for @home_hudJointWrists.
  ///
  /// In en, this message translates to:
  /// **'Wrists'**
  String get home_hudJointWrists;

  /// No description provided for @home_hudJointSpine.
  ///
  /// In en, this message translates to:
  /// **'Spine'**
  String get home_hudJointSpine;

  /// No description provided for @home_hudJointHips.
  ///
  /// In en, this message translates to:
  /// **'Hips'**
  String get home_hudJointHips;

  /// No description provided for @home_hudJointKnees.
  ///
  /// In en, this message translates to:
  /// **'Knees'**
  String get home_hudJointKnees;

  /// No description provided for @home_hudJointShins.
  ///
  /// In en, this message translates to:
  /// **'Shins'**
  String get home_hudJointShins;

  /// No description provided for @home_hudJointAnkles.
  ///
  /// In en, this message translates to:
  /// **'Ankles'**
  String get home_hudJointAnkles;

  /// No description provided for @home_bodyFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get home_bodyFront;

  /// No description provided for @home_bodyBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get home_bodyBack;

  /// No description provided for @category_9min_title.
  ///
  /// In en, this message translates to:
  /// **'9min'**
  String get category_9min_title;

  /// No description provided for @category_9min_description.
  ///
  /// In en, this message translates to:
  /// **'A short workout that activates your whole body in little time. Great as a warmup or morning workout.'**
  String get category_9min_description;

  /// No description provided for @category_hercules_title.
  ///
  /// In en, this message translates to:
  /// **'Optimized for runners'**
  String get category_hercules_title;

  /// No description provided for @category_hercules_description.
  ///
  /// In en, this message translates to:
  /// **'Build your own routine optimized for runners. The default includes the 9min workout, stretching, and extra exercises to strengthen leg tendons and joints.'**
  String get category_hercules_description;

  /// No description provided for @category_onlyStretch_title.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get category_onlyStretch_title;

  /// No description provided for @category_onlyStretch_description.
  ///
  /// In en, this message translates to:
  /// **'A short stretching routine optimized for people who sit too long.'**
  String get category_onlyStretch_description;

  /// No description provided for @category_wakeup_title.
  ///
  /// In en, this message translates to:
  /// **'Full-Body Wake-Up'**
  String get category_wakeup_title;

  /// No description provided for @category_wakeup_description.
  ///
  /// In en, this message translates to:
  /// **'A fixed full-body activation program with 20 exercises. Mobility, strength and stretching in ~20 minutes.'**
  String get category_wakeup_description;

  /// No description provided for @category_gym_title.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get category_gym_title;

  /// No description provided for @category_gym_description.
  ///
  /// In en, this message translates to:
  /// **'Create your own workouts and add them to your daily training log.'**
  String get category_gym_description;

  /// No description provided for @category_calisthenics_title.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get category_calisthenics_title;

  /// No description provided for @category_calisthenics_description.
  ///
  /// In en, this message translates to:
  /// **'Create your own workouts and add them to your daily training log.'**
  String get category_calisthenics_description;

  /// No description provided for @category_running_title.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get category_running_title;

  /// No description provided for @category_running_description.
  ///
  /// In en, this message translates to:
  /// **'Create routes or start a free run and live-track distance, elevation and pace.'**
  String get category_running_description;

  /// No description provided for @category_workout_title.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get category_workout_title;

  /// No description provided for @category_workout_description.
  ///
  /// In en, this message translates to:
  /// **'Gym, calisthenics, stretch and morning workouts — search, filter and start.'**
  String get category_workout_description;

  /// No description provided for @category_food_title.
  ///
  /// In en, this message translates to:
  /// **'Food and meals'**
  String get category_food_title;

  /// No description provided for @category_food_description.
  ///
  /// In en, this message translates to:
  /// **'Create your own meals and add them to your daily intake, add food directly, or just scan it.'**
  String get category_food_description;

  /// No description provided for @category_friends_title.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get category_friends_title;

  /// No description provided for @category_friends_description.
  ///
  /// In en, this message translates to:
  /// **'Compete in challenges and follow friends live on the running map.'**
  String get category_friends_description;

  /// No description provided for @tour_stepMannequinTitle.
  ///
  /// In en, this message translates to:
  /// **'Your body at a glance'**
  String get tour_stepMannequinTitle;

  /// No description provided for @tour_stepMannequinDescription.
  ///
  /// In en, this message translates to:
  /// **'The body model updates based on your logged workouts, foods and meals. Its highlights give you an estimate of training load, nutrition and recovery, helping you see which muscles were used and when they are expected to recover.'**
  String get tour_stepMannequinDescription;

  /// No description provided for @tour_stepWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get tour_stepWorkoutTitle;

  /// No description provided for @tour_stepWorkoutDescription.
  ///
  /// In en, this message translates to:
  /// **'All your workouts live here: 9 min, morning workout, stretch, gym and bodyweight. Tap in to search, create your own, or start right away.'**
  String get tour_stepWorkoutDescription;

  /// No description provided for @tour_stepFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get tour_stepFriendsTitle;

  /// No description provided for @tour_stepFriendsDescription.
  ///
  /// In en, this message translates to:
  /// **'Join challenges and follow friends live on the running map.'**
  String get tour_stepFriendsDescription;

  /// No description provided for @tour_step9minTitle.
  ///
  /// In en, this message translates to:
  /// **'9 Min Workout'**
  String get tour_step9minTitle;

  /// No description provided for @tour_step9minDescription.
  ///
  /// In en, this message translates to:
  /// **'This is a short workout which activates your whole body in short time. Use as a good warmup or morning workout.'**
  String get tour_step9minDescription;

  /// No description provided for @tour_stepHerculesTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning Workout'**
  String get tour_stepHerculesTitle;

  /// No description provided for @tour_stepHerculesDescription.
  ///
  /// In en, this message translates to:
  /// **'This is your workout section — build your own custom morning routine. The default includes the 9min workout and stretching exercises, plus extra exercises to strengthen your leg tendons and joints.'**
  String get tour_stepHerculesDescription;

  /// No description provided for @tour_stepOnlyStretchTitle.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get tour_stepOnlyStretchTitle;

  /// No description provided for @tour_stepOnlyStretchDescription.
  ///
  /// In en, this message translates to:
  /// **'This is a short stretching routine optimized for people that sit too long.'**
  String get tour_stepOnlyStretchDescription;

  /// No description provided for @tour_stepGymTitle.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get tour_stepGymTitle;

  /// No description provided for @tour_stepGymDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can create your own workouts and add them daily to your record.'**
  String get tour_stepGymDescription;

  /// No description provided for @tour_stepCalisthenicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get tour_stepCalisthenicsTitle;

  /// No description provided for @tour_stepCalisthenicsDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can create your own workouts and add them daily to your record.'**
  String get tour_stepCalisthenicsDescription;

  /// No description provided for @tour_stepRunningTitle.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get tour_stepRunningTitle;

  /// No description provided for @tour_stepRunningDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can create your own running routes and then live track your runs.'**
  String get tour_stepRunningDescription;

  /// No description provided for @tour_stepFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get tour_stepFoodTitle;

  /// No description provided for @tour_stepFoodDescription.
  ///
  /// In en, this message translates to:
  /// **'Search food and add it directly to your daily intake or create a meal and save it.'**
  String get tour_stepFoodDescription;

  /// No description provided for @tour_stepShoppingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list'**
  String get tour_stepShoppingTitle;

  /// No description provided for @tour_stepShoppingDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap the small note to open your shopping list. Collect food and quantities, check off purchases and save lists for later.'**
  String get tour_stepShoppingDescription;

  /// No description provided for @tour_stepMetabolicTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily nutrition'**
  String get tour_stepMetabolicTitle;

  /// No description provided for @tour_stepMetabolicDescription.
  ///
  /// In en, this message translates to:
  /// **'Your personal calorie and macro target based on profile and activity. See how much you\'ve eaten today.'**
  String get tour_stepMetabolicDescription;

  /// No description provided for @tour_stepCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout calendar'**
  String get tour_stepCalendarTitle;

  /// No description provided for @tour_stepCalendarDescription.
  ///
  /// In en, this message translates to:
  /// **'All completed workouts in the monthly overview. Tap a day for details or the 30-day summary bottom right.'**
  String get tour_stepCalendarDescription;

  /// No description provided for @tour_stepGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress gallery'**
  String get tour_stepGalleryTitle;

  /// No description provided for @tour_stepGalleryDescription.
  ///
  /// In en, this message translates to:
  /// **'Save progress photos and compare your development over weeks and months.'**
  String get tour_stepGalleryDescription;

  /// No description provided for @tour_stepWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight tracking'**
  String get tour_stepWeightTitle;

  /// No description provided for @tour_stepWeightDescription.
  ///
  /// In en, this message translates to:
  /// **'See your current weight here. Use the plus button to log today\'s weight.'**
  String get tour_stepWeightDescription;

  /// No description provided for @tour_stepHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Your health'**
  String get tour_stepHealthTitle;

  /// No description provided for @tour_stepHealthDescription.
  ///
  /// In en, this message translates to:
  /// **'This card brings together your training, nutrition and health trends. Choose a metric and 7 or 28 days, then tap a day in the chart for details. Use the info icon to connect Apple Health or Health Connect and manage what you share.'**
  String get tour_stepHealthDescription;

  /// No description provided for @tour_stepLevelingTitle.
  ///
  /// In en, this message translates to:
  /// **'Level & badges'**
  String get tour_stepLevelingTitle;

  /// No description provided for @tour_stepLevelingDescription.
  ///
  /// In en, this message translates to:
  /// **'At the top you will find your profile, level and body measurements. Completed workouts and training streaks earn you levels. Tap the trophy to see your badges and achievements.'**
  String get tour_stepLevelingDescription;

  /// Localized string for tour_progress
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String tour_progress(Object current, Object total);

  /// No description provided for @profile_settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profile_settingsTooltip;

  /// No description provided for @profile_metabolicTarget.
  ///
  /// In en, this message translates to:
  /// **'METABOLIC TARGET'**
  String get profile_metabolicTarget;

  /// No description provided for @profile_analytics.
  ///
  /// In en, this message translates to:
  /// **'ANALYTICS'**
  String get profile_analytics;

  /// No description provided for @profile_steps.
  ///
  /// In en, this message translates to:
  /// **'STEPS'**
  String get profile_steps;

  /// No description provided for @profile_sleep.
  ///
  /// In en, this message translates to:
  /// **'SLEEP'**
  String get profile_sleep;

  /// No description provided for @profile_sleepLastNight.
  ///
  /// In en, this message translates to:
  /// **'Last night'**
  String get profile_sleepLastNight;

  /// No description provided for @profile_editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profile_editProfile;

  /// No description provided for @profile_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profile_settings;

  /// No description provided for @profile_settingsSectionFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get profile_settingsSectionFeatures;

  /// No description provided for @profile_settingsSectionSystem.
  ///
  /// In en, this message translates to:
  /// **'App & System'**
  String get profile_settingsSectionSystem;

  /// No description provided for @profile_pinLevelIcon.
  ///
  /// In en, this message translates to:
  /// **'Add rank icon to home screen'**
  String get profile_pinLevelIcon;

  /// No description provided for @profile_pinLevelIconHint.
  ///
  /// In en, this message translates to:
  /// **'Opens Kaizen and shows your current rank.'**
  String get profile_pinLevelIconHint;

  /// No description provided for @profile_pinLevelIconUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Touch and hold an empty space on your home screen, then select “Kaizen Rank” under Widgets.'**
  String get profile_pinLevelIconUnavailable;

  /// No description provided for @profile_appTour.
  ///
  /// In en, this message translates to:
  /// **'App tour'**
  String get profile_appTour;

  /// No description provided for @profile_appTourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Interactive tour through all areas of the app'**
  String get profile_appTourSubtitle;

  /// No description provided for @profile_syncSteps.
  ///
  /// In en, this message translates to:
  /// **'Sync steps'**
  String get profile_syncSteps;

  /// No description provided for @profile_syncStepsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Apple Health / Health Connect'**
  String get profile_syncStepsSubtitle;

  /// No description provided for @profile_syncSleep.
  ///
  /// In en, this message translates to:
  /// **'Sync sleep'**
  String get profile_syncSleep;

  /// No description provided for @profile_syncSleepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import last night\'s sleep from Apple Health / Health Connect'**
  String get profile_syncSleepSubtitle;

  /// No description provided for @profile_workoutVoice.
  ///
  /// In en, this message translates to:
  /// **'Workout voice'**
  String get profile_workoutVoice;

  /// No description provided for @profile_workoutVoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Voice prompts during training'**
  String get profile_workoutVoiceSubtitle;

  /// No description provided for @profile_workoutVoiceGenderTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice type'**
  String get profile_workoutVoiceGenderTitle;

  /// No description provided for @profile_workoutVoiceGenderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Female or male voice for workouts and running'**
  String get profile_workoutVoiceGenderSubtitle;

  /// No description provided for @profile_workoutVoiceFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get profile_workoutVoiceFemale;

  /// No description provided for @profile_workoutVoiceMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get profile_workoutVoiceMale;

  /// No description provided for @profile_workoutVoiceSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get profile_workoutVoiceSystem;

  /// No description provided for @profile_workoutVoicePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview voice'**
  String get profile_workoutVoicePreview;

  /// No description provided for @profile_lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get profile_lightMode;

  /// No description provided for @profile_lightModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On: light surfaces. Off: previous dark design.'**
  String get profile_lightModeSubtitle;

  /// No description provided for @settings_languageTitle.
  ///
  /// In en, this message translates to:
  /// **'German language'**
  String get settings_languageTitle;

  /// No description provided for @settings_languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On: German. Off: English.'**
  String get settings_languageSubtitle;

  /// No description provided for @profile_gallery.
  ///
  /// In en, this message translates to:
  /// **'Your Gallery'**
  String get profile_gallery;

  /// No description provided for @profile_updateWeight.
  ///
  /// In en, this message translates to:
  /// **'Update weight'**
  String get profile_updateWeight;

  /// No description provided for @profile_weightKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get profile_weightKgLabel;

  /// No description provided for @profile_weightHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 72.5'**
  String get profile_weightHint;

  /// No description provided for @profile_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profile_updated;

  /// No description provided for @profile_dailyCalorieGoal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s calories'**
  String get profile_dailyCalorieGoal;

  /// No description provided for @profile_kcalGoal.
  ///
  /// In en, this message translates to:
  /// **'KCAL GOAL'**
  String get profile_kcalGoal;

  /// No description provided for @profile_today.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get profile_today;

  /// Localized string for profile_todayWithPercent
  ///
  /// In en, this message translates to:
  /// **'TODAY · {percent}%'**
  String profile_todayWithPercent(int percent);

  /// No description provided for @profile_protein.
  ///
  /// In en, this message translates to:
  /// **'PROTEIN'**
  String get profile_protein;

  /// No description provided for @profile_carbs.
  ///
  /// In en, this message translates to:
  /// **'CARBOHYDRATES'**
  String get profile_carbs;

  /// No description provided for @profile_fats.
  ///
  /// In en, this message translates to:
  /// **'FATS'**
  String get profile_fats;

  /// No description provided for @profile_macroProteinShort.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get profile_macroProteinShort;

  /// No description provided for @profile_macroFatShort.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get profile_macroFatShort;

  /// Localized string for profile_macroSummary
  ///
  /// In en, this message translates to:
  /// **'P {protein} g · C {carbs} g · F {fats} g'**
  String profile_macroSummary(Object protein, Object carbs, Object fats);

  /// No description provided for @profile_kcalBurned.
  ///
  /// In en, this message translates to:
  /// **'kcal burned'**
  String get profile_kcalBurned;

  /// Localized string for profile_workoutsKcal
  ///
  /// In en, this message translates to:
  /// **'Workouts: {kcal} kcal'**
  String profile_workoutsKcal(Object kcal);

  /// Localized string for profile_stepsKcal
  ///
  /// In en, this message translates to:
  /// **'Steps: {count} · {kcal} kcal'**
  String profile_stepsKcal(Object count, Object kcal);

  /// Localized string for profile_stepsKcalNoData
  ///
  /// In en, this message translates to:
  /// **'Steps: {kcal} kcal (no step data)'**
  String profile_stepsKcalNoData(Object kcal);

  /// Localized string for profile_dishEntry
  ///
  /// In en, this message translates to:
  /// **'Dish  •  {time}'**
  String profile_dishEntry(Object time);

  /// No description provided for @profile_editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profile_editTitle;

  /// No description provided for @profile_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profile_nameLabel;

  /// No description provided for @profile_ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get profile_ageLabel;

  /// No description provided for @profile_heightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get profile_heightLabel;

  /// No description provided for @profile_weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get profile_weightLabel;

  /// No description provided for @profile_bodyFatLabel.
  ///
  /// In en, this message translates to:
  /// **'Body fat (%)'**
  String get profile_bodyFatLabel;

  /// No description provided for @profile_muscleMassLabel.
  ///
  /// In en, this message translates to:
  /// **'Muscle mass (kg)'**
  String get profile_muscleMassLabel;

  /// No description provided for @profile_boneWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Bone weight (kg)'**
  String get profile_boneWeightLabel;

  /// No description provided for @profile_genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profile_genderLabel;

  /// No description provided for @profile_activityLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get profile_activityLabel;

  /// No description provided for @profile_goalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get profile_goalLabel;

  /// Biometric summary line on profile
  ///
  /// In en, this message translates to:
  /// **'{height} · {weight} · {age} y · {gender}'**
  String profile_biometricSummary(
    Object height,
    Object weight,
    Object age,
    Object gender,
  );

  /// Food log entry with grams and time
  ///
  /// In en, this message translates to:
  /// **'{grams} g · {time}'**
  String profile_foodEntryGrams(Object grams, Object time);

  /// No description provided for @gender_male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get gender_male;

  /// No description provided for @gender_female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get gender_female;

  /// No description provided for @activity_sedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get activity_sedentary;

  /// No description provided for @activity_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get activity_light;

  /// No description provided for @activity_moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get activity_moderate;

  /// No description provided for @activity_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get activity_high;

  /// No description provided for @activity_athlete.
  ///
  /// In en, this message translates to:
  /// **'Athlete'**
  String get activity_athlete;

  /// No description provided for @goal_lose.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get goal_lose;

  /// No description provided for @goal_maintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get goal_maintain;

  /// No description provided for @goal_gain.
  ///
  /// In en, this message translates to:
  /// **'Bulk'**
  String get goal_gain;

  /// No description provided for @validation_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a profile name.'**
  String get validation_nameRequired;

  /// No description provided for @validation_ageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your age.'**
  String get validation_ageRequired;

  /// No description provided for @validation_heightRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your height.'**
  String get validation_heightRequired;

  /// No description provided for @validation_weightRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your weight.'**
  String get validation_weightRequired;

  /// No description provided for @validation_ageInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid age.'**
  String get validation_ageInvalid;

  /// No description provided for @validation_heightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid height in cm.'**
  String get validation_heightInvalid;

  /// No description provided for @validation_weightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight in kg.'**
  String get validation_weightInvalid;

  /// No description provided for @validation_bodyFatInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a realistic body fat percentage.'**
  String get validation_bodyFatInvalid;

  /// No description provided for @validation_muscleMassInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid muscle mass.'**
  String get validation_muscleMassInvalid;

  /// No description provided for @validation_boneWeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid bone weight.'**
  String get validation_boneWeightInvalid;

  /// No description provided for @avatar_mobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Avatar upload is currently only available on mobile.'**
  String get avatar_mobileOnly;

  /// No description provided for @avatar_takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get avatar_takePhoto;

  /// No description provided for @avatar_pickGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get avatar_pickGallery;

  /// No description provided for @avatar_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove avatar'**
  String get avatar_remove;

  /// No description provided for @avatar_saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save avatar.'**
  String get avatar_saveFailed;

  /// No description provided for @month_january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get month_january;

  /// No description provided for @month_february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get month_february;

  /// No description provided for @month_march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get month_march;

  /// No description provided for @month_april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get month_april;

  /// No description provided for @month_may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get month_may;

  /// No description provided for @month_june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get month_june;

  /// No description provided for @month_july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get month_july;

  /// No description provided for @month_august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get month_august;

  /// No description provided for @month_september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get month_september;

  /// No description provided for @month_october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get month_october;

  /// No description provided for @month_november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get month_november;

  /// No description provided for @month_december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get month_december;

  /// No description provided for @weekday_mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekday_mon;

  /// No description provided for @weekday_tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekday_tue;

  /// No description provided for @weekday_wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekday_wed;

  /// No description provided for @weekday_thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekday_thu;

  /// No description provided for @weekday_fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekday_fri;

  /// No description provided for @weekday_sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekday_sat;

  /// No description provided for @weekday_sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekday_sun;

  /// No description provided for @calendar_nutritionAvg.
  ///
  /// In en, this message translates to:
  /// **'NUTRITION (avg per day)'**
  String get calendar_nutritionAvg;

  /// No description provided for @calendar_workouts.
  ///
  /// In en, this message translates to:
  /// **'WORKOUTS'**
  String get calendar_workouts;

  /// No description provided for @calendar_noWorkoutsPeriod.
  ///
  /// In en, this message translates to:
  /// **'No workouts in this period.'**
  String get calendar_noWorkoutsPeriod;

  /// No description provided for @calendar_noWorkoutsDay.
  ///
  /// In en, this message translates to:
  /// **'No workouts on this day.'**
  String get calendar_noWorkoutsDay;

  /// No description provided for @calendar_consumption.
  ///
  /// In en, this message translates to:
  /// **'BURN'**
  String get calendar_consumption;

  /// No description provided for @calendar_nutrition.
  ///
  /// In en, this message translates to:
  /// **'NUTRITION'**
  String get calendar_nutrition;

  /// No description provided for @calendar_noMealsDay.
  ///
  /// In en, this message translates to:
  /// **'No meals on this day.'**
  String get calendar_noMealsDay;

  /// No description provided for @calendar_feelingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Feeling: --'**
  String get calendar_feelingEmpty;

  /// No description provided for @calendar_feelingSaved.
  ///
  /// In en, this message translates to:
  /// **'Feeling saved'**
  String get calendar_feelingSaved;

  /// No description provided for @calendar_hint.
  ///
  /// In en, this message translates to:
  /// **'Dots = workout type. Tap a day for details.'**
  String get calendar_hint;

  /// No description provided for @calendar_workoutType9min.
  ///
  /// In en, this message translates to:
  /// **'9 Min'**
  String get calendar_workoutType9min;

  /// No description provided for @calendar_workoutTypeHercules.
  ///
  /// In en, this message translates to:
  /// **'Morning Workout'**
  String get calendar_workoutTypeHercules;

  /// No description provided for @calendar_workoutTypeStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch / Yoga'**
  String get calendar_workoutTypeStretch;

  /// No description provided for @calendar_workoutTypeGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get calendar_workoutTypeGym;

  /// No description provided for @calendar_workoutTypeCalisthenics.
  ///
  /// In en, this message translates to:
  /// **'Calisthenics'**
  String get calendar_workoutTypeCalisthenics;

  /// No description provided for @calendar_workoutTypeRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get calendar_workoutTypeRun;

  /// No description provided for @calendar_workoutTypeLegacy.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get calendar_workoutTypeLegacy;

  /// Localized string for calendar_calorieBreakdown
  ///
  /// In en, this message translates to:
  /// **'{label} · {kcal} kcal'**
  String calendar_calorieBreakdown(Object label, Object kcal);

  /// No description provided for @calendar_30DaySummary.
  ///
  /// In en, this message translates to:
  /// **'30-day summary'**
  String get calendar_30DaySummary;

  /// Workout streak badge on calendar
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak'**
  String calendar_streakDays(int count);

  /// Workout count in 30-day summary
  ///
  /// In en, this message translates to:
  /// **'{count} workouts in the last {days} days'**
  String calendar_workoutsInLastDays(int count, int days);

  /// Optional kcal suffix for workout summary
  ///
  /// In en, this message translates to:
  /// **' · {kcal} kcal burned'**
  String calendar_kcalBurnedSuffix(int kcal);

  /// No description provided for @steps_unavailableDevice.
  ///
  /// In en, this message translates to:
  /// **'Steps are not available on this device.'**
  String get steps_unavailableDevice;

  /// No description provided for @steps_connectHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Connect to grant Apple Health or Health Connect access.'**
  String get steps_connectHint;

  /// No description provided for @steps_loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load steps.'**
  String get steps_loadFailed;

  /// Localized string for steps_loadedToday
  ///
  /// In en, this message translates to:
  /// **'Today: {count} steps loaded'**
  String steps_loadedToday(int count);

  /// Localized string for steps_todaySnack
  ///
  /// In en, this message translates to:
  /// **'Today: {count} steps'**
  String steps_todaySnack(int count);

  /// No description provided for @steps_appleHealth.
  ///
  /// In en, this message translates to:
  /// **'Apple Health'**
  String get steps_appleHealth;

  /// No description provided for @steps_healthConnect.
  ///
  /// In en, this message translates to:
  /// **'Health Connect'**
  String get steps_healthConnect;

  /// No description provided for @steps_notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get steps_notAvailable;

  /// No description provided for @steps_notSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get steps_notSynced;

  /// Localized string for steps_updatedAt
  ///
  /// In en, this message translates to:
  /// **'Updated at {time}'**
  String steps_updatedAt(Object time);

  /// No description provided for @steps_connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get steps_connect;

  /// No description provided for @steps_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get steps_refresh;

  /// No description provided for @steps_label.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps_label;

  /// No description provided for @steps_mobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Only available on iPhone and Android'**
  String get steps_mobileOnly;

  /// No description provided for @steps_wearablesHint.
  ///
  /// In en, this message translates to:
  /// **'Fitbit, Garmin and Samsung Health can sync via Health Connect.'**
  String get steps_wearablesHint;

  /// No description provided for @sleep_unavailableDevice.
  ///
  /// In en, this message translates to:
  /// **'Sleep tracking is not available on this device.'**
  String get sleep_unavailableDevice;

  /// No description provided for @sleep_connectHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Connect to grant Apple Health or Health Connect access for sleep.'**
  String get sleep_connectHint;

  /// No description provided for @sleep_loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load sleep data.'**
  String get sleep_loadFailed;

  /// Localized string for sleep_loadedLastNight
  ///
  /// In en, this message translates to:
  /// **'Last night: {duration} loaded'**
  String sleep_loadedLastNight(Object duration);

  /// No description provided for @sleep_durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String sleep_durationHoursMinutes(int hours, int minutes);

  /// No description provided for @sleep_durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String sleep_durationHours(int hours);

  /// No description provided for @sleep_durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String sleep_durationMinutes(int minutes);

  /// No description provided for @sleep_mobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Only available on iPhone and Android'**
  String get sleep_mobileOnly;

  /// No description provided for @home_statusSleepNone.
  ///
  /// In en, this message translates to:
  /// **'No sleep data synced'**
  String get home_statusSleepNone;

  /// No description provided for @home_statusSleepLastNight.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m sleep last night'**
  String home_statusSleepLastNight(int hours, int minutes);

  /// No description provided for @home_statusSleepHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h sleep last night'**
  String home_statusSleepHours(int hours);

  /// No description provided for @home_statusSleepMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m sleep last night'**
  String home_statusSleepMinutes(int minutes);

  /// No description provided for @health_stepsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Steps are only available on iPhone and Android.'**
  String get health_stepsUnsupported;

  /// No description provided for @health_stepsPermissionConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect Apple Health or Health Connect to load steps.'**
  String get health_stepsPermissionConnect;

  /// No description provided for @health_stepsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. You can re-enable Apple Health or Health Connect in system settings.'**
  String get health_stepsPermissionDenied;

  /// No description provided for @health_connectNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Health Connect is not installed. Install it from the Play Store and connect Fitbit/Garmin/Samsung there.'**
  String get health_connectNotInstalled;

  /// No description provided for @analytics_weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get analytics_weight;

  /// No description provided for @analytics_steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get analytics_steps;

  /// No description provided for @analytics_calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get analytics_calories;

  /// No description provided for @analytics_burn.
  ///
  /// In en, this message translates to:
  /// **'Burn'**
  String get analytics_burn;

  /// No description provided for @analytics_water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get analytics_water;

  /// No description provided for @analytics_afterburn.
  ///
  /// In en, this message translates to:
  /// **'Afterburn'**
  String get analytics_afterburn;

  /// No description provided for @analytics_protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get analytics_protein;

  /// No description provided for @analytics_fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get analytics_fat;

  /// No description provided for @analytics_carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get analytics_carbs;

  /// No description provided for @analytics_workouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get analytics_workouts;

  /// No description provided for @analytics_emptyWeight.
  ///
  /// In en, this message translates to:
  /// **'Log weight to see your progress.'**
  String get analytics_emptyWeight;

  /// No description provided for @analytics_emptySteps.
  ///
  /// In en, this message translates to:
  /// **'Sync steps to see your daily activity.'**
  String get analytics_emptySteps;

  /// No description provided for @analytics_emptyCalories.
  ///
  /// In en, this message translates to:
  /// **'No calories in the last 30 days yet.'**
  String get analytics_emptyCalories;

  /// No description provided for @analytics_emptyBurn.
  ///
  /// In en, this message translates to:
  /// **'No burn data in the last 30 days yet.'**
  String get analytics_emptyBurn;

  /// No description provided for @analytics_emptyWater.
  ///
  /// In en, this message translates to:
  /// **'No water data in the last 30 days yet.'**
  String get analytics_emptyWater;

  /// No description provided for @analytics_emptyAfterburn.
  ///
  /// In en, this message translates to:
  /// **'No afterburn in the last 30 days yet.'**
  String get analytics_emptyAfterburn;

  /// No description provided for @analytics_emptyProtein.
  ///
  /// In en, this message translates to:
  /// **'No protein in the last 30 days yet.'**
  String get analytics_emptyProtein;

  /// No description provided for @analytics_emptyFat.
  ///
  /// In en, this message translates to:
  /// **'No fat in the last 30 days yet.'**
  String get analytics_emptyFat;

  /// No description provided for @analytics_emptyCarbs.
  ///
  /// In en, this message translates to:
  /// **'No carbs in the last 30 days yet.'**
  String get analytics_emptyCarbs;

  /// No description provided for @analytics_emptyWorkouts.
  ///
  /// In en, this message translates to:
  /// **'No workouts in the last 30 days yet.'**
  String get analytics_emptyWorkouts;

  /// No description provided for @analytics_unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get analytics_unitKg;

  /// No description provided for @analytics_unitKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get analytics_unitKcal;

  /// No description provided for @analytics_unitMl.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get analytics_unitMl;

  /// No description provided for @analytics_unitG.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get analytics_unitG;

  /// No description provided for @analytics_addWeightHint.
  ///
  /// In en, this message translates to:
  /// **'Add weight entries to see progress.'**
  String get analytics_addWeightHint;

  /// No description provided for @achievements_levelingSystem.
  ///
  /// In en, this message translates to:
  /// **'Leveling System'**
  String get achievements_levelingSystem;

  /// No description provided for @achievements_noXp.
  ///
  /// In en, this message translates to:
  /// **'You don\'t collect XP here — you earn levels directly.'**
  String get achievements_noXp;

  /// No description provided for @achievements_levelPerWorkout.
  ///
  /// In en, this message translates to:
  /// **'Levels per workout'**
  String get achievements_levelPerWorkout;

  /// No description provided for @achievements_onlyStretch.
  ///
  /// In en, this message translates to:
  /// **'Only Stretch'**
  String get achievements_onlyStretch;

  /// No description provided for @achievements_nineMin.
  ///
  /// In en, this message translates to:
  /// **'9 Min Workout'**
  String get achievements_nineMin;

  /// No description provided for @achievements_hercules.
  ///
  /// In en, this message translates to:
  /// **'Morning Workout'**
  String get achievements_hercules;

  /// No description provided for @achievements_gymWorkout.
  ///
  /// In en, this message translates to:
  /// **'Gym Workout'**
  String get achievements_gymWorkout;

  /// No description provided for @achievements_caliWorkout.
  ///
  /// In en, this message translates to:
  /// **'Calisthenics Workout'**
  String get achievements_caliWorkout;

  /// Localized string for achievements_levelPlus
  ///
  /// In en, this message translates to:
  /// **'+{count} Level'**
  String achievements_levelPlus(int count);

  /// No description provided for @achievements_streakBonus.
  ///
  /// In en, this message translates to:
  /// **'Streak bonus (one-time when reached)'**
  String get achievements_streakBonus;

  /// No description provided for @achievements_streak10.
  ///
  /// In en, this message translates to:
  /// **'10 days'**
  String get achievements_streak10;

  /// No description provided for @achievements_streak30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get achievements_streak30;

  /// No description provided for @achievements_streak100.
  ///
  /// In en, this message translates to:
  /// **'100 days'**
  String get achievements_streak100;

  /// No description provided for @achievements_streak365.
  ///
  /// In en, this message translates to:
  /// **'365 days'**
  String get achievements_streak365;

  /// No description provided for @achievements_streak1000.
  ///
  /// In en, this message translates to:
  /// **'1000 days'**
  String get achievements_streak1000;

  /// No description provided for @achievements_gymCaliHint.
  ///
  /// In en, this message translates to:
  /// **'Note: Gym/Calisthenics count when you tap the checkmark „Workout complete“ at the top of the workout detail.'**
  String get achievements_gymCaliHint;

  /// No description provided for @achievements_milestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get achievements_milestones;

  /// No description provided for @achievements_streaks.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get achievements_streaks;

  /// Localized string for achievements_earnedCount
  ///
  /// In en, this message translates to:
  /// **'{earned} / {total} Earned'**
  String achievements_earnedCount(int earned, int total);

  /// No description provided for @achievements_coreLevel.
  ///
  /// In en, this message translates to:
  /// **'CORE LEVEL'**
  String get achievements_coreLevel;

  /// Localized string for achievements_level
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String achievements_level(int level);

  /// Localized string for achievements_rank
  ///
  /// In en, this message translates to:
  /// **'Rank: {rank}'**
  String achievements_rank(Object rank);

  /// No description provided for @achievements_toNextMilestone.
  ///
  /// In en, this message translates to:
  /// **'to next milestone'**
  String get achievements_toNextMilestone;

  /// Localized string for achievements_nextMilestone
  ///
  /// In en, this message translates to:
  /// **'Next milestone: Level {level}'**
  String achievements_nextMilestone(int level);

  /// No description provided for @achievements_specializations.
  ///
  /// In en, this message translates to:
  /// **'Specializations'**
  String get achievements_specializations;

  /// No description provided for @achievements_gym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get achievements_gym;

  /// No description provided for @achievements_calisthenics.
  ///
  /// In en, this message translates to:
  /// **'Calisthenics'**
  String get achievements_calisthenics;

  /// No description provided for @rank_rookie.
  ///
  /// In en, this message translates to:
  /// **'Rookie'**
  String get rank_rookie;

  /// No description provided for @rank_student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get rank_student;

  /// No description provided for @rank_trainee.
  ///
  /// In en, this message translates to:
  /// **'Trainee'**
  String get rank_trainee;

  /// No description provided for @rank_performer.
  ///
  /// In en, this message translates to:
  /// **'Performer'**
  String get rank_performer;

  /// No description provided for @rank_profi.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get rank_profi;

  /// No description provided for @rank_athlet.
  ///
  /// In en, this message translates to:
  /// **'Athlete'**
  String get rank_athlet;

  /// No description provided for @rank_krieger.
  ///
  /// In en, this message translates to:
  /// **'Warrior'**
  String get rank_krieger;

  /// No description provided for @rank_elite.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get rank_elite;

  /// No description provided for @rank_champion.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get rank_champion;

  /// No description provided for @rank_goat.
  ///
  /// In en, this message translates to:
  /// **'GOAT'**
  String get rank_goat;

  /// No description provided for @rank_halbgott.
  ///
  /// In en, this message translates to:
  /// **'Demigod'**
  String get rank_halbgott;

  /// No description provided for @badge_level0_title.
  ///
  /// In en, this message translates to:
  /// **'Rookie'**
  String get badge_level0_title;

  /// No description provided for @badge_level0_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Level 0'**
  String get badge_level0_subtitle;

  /// No description provided for @badge_level20_title.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get badge_level20_title;

  /// No description provided for @badge_level20_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Level 20'**
  String get badge_level20_subtitle;

  /// No description provided for @badge_level50_title.
  ///
  /// In en, this message translates to:
  /// **'Trainee'**
  String get badge_level50_title;

  /// No description provided for @badge_level50_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Level 50'**
  String get badge_level50_subtitle;

  /// No description provided for @badge_level100_title.
  ///
  /// In en, this message translates to:
  /// **'Performer'**
  String get badge_level100_title;

  /// No description provided for @badge_level100_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Level 100'**
  String get badge_level100_subtitle;

  /// No description provided for @badge_level300_title.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get badge_level300_title;

  /// No description provided for @badge_level300_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Level 300'**
  String get badge_level300_subtitle;

  /// No description provided for @badge_level500_title.
  ///
  /// In en, this message translates to:
  /// **'Athlete'**
  String get badge_level500_title;

  /// No description provided for @badge_level500_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Level 500'**
  String get badge_level500_subtitle;

  /// No description provided for @badge_level1000_title.
  ///
  /// In en, this message translates to:
  /// **'Warrior'**
  String get badge_level1000_title;

  /// No description provided for @badge_level1000_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Level 1000'**
  String get badge_level1000_subtitle;

  /// No description provided for @badge_level2500_title.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get badge_level2500_title;

  /// No description provided for @badge_level2500_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Level 2500'**
  String get badge_level2500_subtitle;

  /// No description provided for @badge_level5000_title.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get badge_level5000_title;

  /// No description provided for @badge_level5000_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Level 5000'**
  String get badge_level5000_subtitle;

  /// No description provided for @badge_level7500_title.
  ///
  /// In en, this message translates to:
  /// **'GOAT'**
  String get badge_level7500_title;

  /// No description provided for @badge_level7500_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Level 7500'**
  String get badge_level7500_subtitle;

  /// No description provided for @badge_level10000_title.
  ///
  /// In en, this message translates to:
  /// **'Demigod'**
  String get badge_level10000_title;

  /// No description provided for @badge_level10000_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Level 10000'**
  String get badge_level10000_subtitle;

  /// No description provided for @badge_streak30_title.
  ///
  /// In en, this message translates to:
  /// **'Discipline'**
  String get badge_streak30_title;

  /// No description provided for @badge_streak30_subtitle.
  ///
  /// In en, this message translates to:
  /// **'30 day streak'**
  String get badge_streak30_subtitle;

  /// No description provided for @badge_streak100_title.
  ///
  /// In en, this message translates to:
  /// **'Iron discipline'**
  String get badge_streak100_title;

  /// No description provided for @badge_streak100_subtitle.
  ///
  /// In en, this message translates to:
  /// **'100 day streak'**
  String get badge_streak100_subtitle;

  /// No description provided for @badge_streak365_title.
  ///
  /// In en, this message translates to:
  /// **'Warrior mindset'**
  String get badge_streak365_title;

  /// No description provided for @badge_streak365_subtitle.
  ///
  /// In en, this message translates to:
  /// **'365 day streak'**
  String get badge_streak365_subtitle;

  /// No description provided for @badge_streak500_title.
  ///
  /// In en, this message translates to:
  /// **'Titan'**
  String get badge_streak500_title;

  /// No description provided for @badge_streak500_subtitle.
  ///
  /// In en, this message translates to:
  /// **'500 day streak'**
  String get badge_streak500_subtitle;

  /// No description provided for @badge_streak1000_title.
  ///
  /// In en, this message translates to:
  /// **'Demigod mindset'**
  String get badge_streak1000_title;

  /// No description provided for @badge_streak1000_subtitle.
  ///
  /// In en, this message translates to:
  /// **'1000 day streak'**
  String get badge_streak1000_subtitle;

  /// No description provided for @badge_gym50_title.
  ///
  /// In en, this message translates to:
  /// **'Gym Junior'**
  String get badge_gym50_title;

  /// No description provided for @badge_gym50_subtitle.
  ///
  /// In en, this message translates to:
  /// **'50 gym workouts'**
  String get badge_gym50_subtitle;

  /// No description provided for @badge_gym100_title.
  ///
  /// In en, this message translates to:
  /// **'Gym Pro'**
  String get badge_gym100_title;

  /// No description provided for @badge_gym100_subtitle.
  ///
  /// In en, this message translates to:
  /// **'100 gym workouts'**
  String get badge_gym100_subtitle;

  /// No description provided for @badge_gym500_title.
  ///
  /// In en, this message translates to:
  /// **'Bodybuilding Junior'**
  String get badge_gym500_title;

  /// No description provided for @badge_gym500_subtitle.
  ///
  /// In en, this message translates to:
  /// **'500 gym workouts'**
  String get badge_gym500_subtitle;

  /// No description provided for @badge_gym1000_title.
  ///
  /// In en, this message translates to:
  /// **'Bodybuilder'**
  String get badge_gym1000_title;

  /// No description provided for @badge_gym1000_subtitle.
  ///
  /// In en, this message translates to:
  /// **'1000 gym workouts'**
  String get badge_gym1000_subtitle;

  /// No description provided for @badge_cali50_title.
  ///
  /// In en, this message translates to:
  /// **'Calisthenics Junior'**
  String get badge_cali50_title;

  /// No description provided for @badge_cali50_subtitle.
  ///
  /// In en, this message translates to:
  /// **'50 calisthenics workouts'**
  String get badge_cali50_subtitle;

  /// No description provided for @badge_cali100_title.
  ///
  /// In en, this message translates to:
  /// **'Calisthenics Pro'**
  String get badge_cali100_title;

  /// No description provided for @badge_cali100_subtitle.
  ///
  /// In en, this message translates to:
  /// **'100 calisthenics workouts'**
  String get badge_cali100_subtitle;

  /// No description provided for @badge_cali500_title.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight Junior'**
  String get badge_cali500_title;

  /// No description provided for @badge_cali500_subtitle.
  ///
  /// In en, this message translates to:
  /// **'500 calisthenics workouts'**
  String get badge_cali500_subtitle;

  /// No description provided for @badge_cali1000_title.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight Master'**
  String get badge_cali1000_title;

  /// No description provided for @badge_cali1000_subtitle.
  ///
  /// In en, this message translates to:
  /// **'1000 calisthenics workouts'**
  String get badge_cali1000_subtitle;

  /// No description provided for @gallery_mobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Gallery is currently only available on mobile.'**
  String get gallery_mobileOnly;

  /// No description provided for @gallery_saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save photo.'**
  String get gallery_saveFailed;

  /// No description provided for @gallery_title.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery_title;

  /// No description provided for @gallery_empty.
  ///
  /// In en, this message translates to:
  /// **'No photos yet.\nTap + to take a photo.'**
  String get gallery_empty;

  /// No description provided for @food_tabFoods.
  ///
  /// In en, this message translates to:
  /// **'Foods'**
  String get food_tabFoods;

  /// No description provided for @food_tabDishes.
  ///
  /// In en, this message translates to:
  /// **'Dishes'**
  String get food_tabDishes;

  /// No description provided for @food_tabSupplements.
  ///
  /// In en, this message translates to:
  /// **'Supplements'**
  String get food_tabSupplements;

  /// No description provided for @food_supplementsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search supplements…'**
  String get food_supplementsSearchHint;

  /// No description provided for @food_supplementsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No supplements logged today.'**
  String get food_supplementsEmpty;

  /// No description provided for @food_supplementsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get food_supplementsToday;

  /// No description provided for @food_supplementMg.
  ///
  /// In en, this message translates to:
  /// **'{mg} mg'**
  String food_supplementMg(Object mg);

  /// No description provided for @food_supplementAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add supplement'**
  String get food_supplementAddTitle;

  /// No description provided for @food_supplementAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (mg)'**
  String get food_supplementAmountLabel;

  /// No description provided for @food_supplementSlotMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get food_supplementSlotMorning;

  /// No description provided for @food_supplementSlotMidday.
  ///
  /// In en, this message translates to:
  /// **'Midday'**
  String get food_supplementSlotMidday;

  /// No description provided for @food_supplementSlotEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get food_supplementSlotEvening;

  /// No description provided for @food_supplementSlotLabel.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get food_supplementSlotLabel;

  /// No description provided for @food_supplementDragHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press a card and drag it to Morning, Midday or Evening.'**
  String get food_supplementDragHint;

  /// No description provided for @food_supplementDropHere.
  ///
  /// In en, this message translates to:
  /// **'Drop here'**
  String get food_supplementDropHere;

  /// No description provided for @food_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search food or tag'**
  String get food_searchHint;

  /// No description provided for @food_newDish.
  ///
  /// In en, this message translates to:
  /// **'New Dish'**
  String get food_newDish;

  /// No description provided for @food_dishPhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Choose dish photo'**
  String get food_dishPhotoAction;

  /// No description provided for @food_dishesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search dishes…'**
  String get food_dishesSearchHint;

  /// No description provided for @food_dishNoIngredients.
  ///
  /// In en, this message translates to:
  /// **'Dish has no ingredients yet.'**
  String get food_dishNoIngredients;

  /// Localized string for food_dishAddedToday
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" added to today.'**
  String food_dishAddedToday(Object name);

  /// No description provided for @food_deleteDishTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete dish?'**
  String get food_deleteDishTitle;

  /// Localized string for food_deleteDishBody
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be permanently deleted.'**
  String food_deleteDishBody(Object name);

  /// No description provided for @food_enterGramsMacros.
  ///
  /// In en, this message translates to:
  /// **'Please enter grams and macros.'**
  String get food_enterGramsMacros;

  /// No description provided for @food_macroProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get food_macroProtein;

  /// No description provided for @food_macroCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get food_macroCarbs;

  /// No description provided for @food_macroFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get food_macroFat;

  /// No description provided for @food_macroKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get food_macroKcal;

  /// No description provided for @food_dishNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Breakfast bowl'**
  String get food_dishNameHint;

  /// No description provided for @food_newDishTitle.
  ///
  /// In en, this message translates to:
  /// **'New Dish'**
  String get food_newDishTitle;

  /// No description provided for @food_macrosHeading.
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get food_macrosHeading;

  /// No description provided for @food_noFoodsFound.
  ///
  /// In en, this message translates to:
  /// **'No foods found'**
  String get food_noFoodsFound;

  /// No description provided for @food_foodCount.
  ///
  /// In en, this message translates to:
  /// **'{count} foods'**
  String food_foodCount(int count);

  /// No description provided for @food_macroAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get food_macroAll;

  /// No description provided for @food_focusNeverEat.
  ///
  /// In en, this message translates to:
  /// **'Never eat'**
  String get food_focusNeverEat;

  /// No description provided for @food_focusHealthyBrain.
  ///
  /// In en, this message translates to:
  /// **'Healthy brain'**
  String get food_focusHealthyBrain;

  /// No description provided for @food_macroCarbsLong.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get food_macroCarbsLong;

  /// No description provided for @food_kcalPer100g.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal / 100 g'**
  String food_kcalPer100g(Object kcal);

  /// No description provided for @food_renameDishTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename dish'**
  String get food_renameDishTitle;

  /// No description provided for @food_dishNotFound.
  ///
  /// In en, this message translates to:
  /// **'Dish not found'**
  String get food_dishNotFound;

  /// No description provided for @food_dishFallback.
  ///
  /// In en, this message translates to:
  /// **'Dish'**
  String get food_dishFallback;

  /// No description provided for @food_addedToDish.
  ///
  /// In en, this message translates to:
  /// **'{name} ({grams} g) added.'**
  String food_addedToDish(Object name, Object grams);

  /// No description provided for @food_addedToTodayFull.
  ///
  /// In en, this message translates to:
  /// **'{name} ({grams} g) added to today.'**
  String food_addedToTodayFull(Object name, Object grams);

  /// No description provided for @food_eatToday.
  ///
  /// In en, this message translates to:
  /// **'Eat today'**
  String get food_eatToday;

  /// No description provided for @food_addToDishBtn.
  ///
  /// In en, this message translates to:
  /// **'Add to dish'**
  String get food_addToDishBtn;

  /// No description provided for @food_per100g.
  ///
  /// In en, this message translates to:
  /// **'Per 100 g'**
  String get food_per100g;

  /// No description provided for @food_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get food_amount;

  /// No description provided for @food_forGrams.
  ///
  /// In en, this message translates to:
  /// **'For {grams} g'**
  String food_forGrams(Object grams);

  /// No description provided for @food_macrosNotStored.
  ///
  /// In en, this message translates to:
  /// **'Macros not on file'**
  String get food_macrosNotStored;

  /// No description provided for @food_macrosManualHint.
  ///
  /// In en, this message translates to:
  /// **'Enter macros per 100 g manually to add this food to a dish.'**
  String get food_macrosManualHint;

  /// No description provided for @food_ingredientFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food_ingredientFood;

  /// No description provided for @food_emptyDishesTitle.
  ///
  /// In en, this message translates to:
  /// **'No dishes yet'**
  String get food_emptyDishesTitle;

  /// No description provided for @food_emptyDishesBody.
  ///
  /// In en, this message translates to:
  /// **'Create your first dish to log combined meals.'**
  String get food_emptyDishesBody;

  /// No description provided for @food_pickIngredientTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick food'**
  String get food_pickIngredientTitle;

  /// No description provided for @food_manualEntry.
  ///
  /// In en, this message translates to:
  /// **'manual'**
  String get food_manualEntry;

  /// No description provided for @food_whichDish.
  ///
  /// In en, this message translates to:
  /// **'Which dish?'**
  String get food_whichDish;

  /// No description provided for @food_newDishEllipsis.
  ///
  /// In en, this message translates to:
  /// **'New dish…'**
  String get food_newDishEllipsis;

  /// No description provided for @food_removeFromDish.
  ///
  /// In en, this message translates to:
  /// **'Remove from dish'**
  String get food_removeFromDish;

  /// No description provided for @food_barcodeScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get food_barcodeScanTitle;

  /// No description provided for @food_barcodeScanHint.
  ///
  /// In en, this message translates to:
  /// **'Hold the barcode inside the frame'**
  String get food_barcodeScanHint;

  /// No description provided for @food_barcodeDesktopHint.
  ///
  /// In en, this message translates to:
  /// **'Barcode scanning works on mobile. Enter the barcode manually here.'**
  String get food_barcodeDesktopHint;

  /// No description provided for @food_barcodeManualLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter barcode'**
  String get food_barcodeManualLabel;

  /// No description provided for @food_barcodeManualHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 4008400407321'**
  String get food_barcodeManualHint;

  /// No description provided for @food_barcodeLookupBtn.
  ///
  /// In en, this message translates to:
  /// **'Look up product'**
  String get food_barcodeLookupBtn;

  /// No description provided for @food_barcodeLookingUp.
  ///
  /// In en, this message translates to:
  /// **'Looking up product…'**
  String get food_barcodeLookingUp;

  /// No description provided for @food_barcodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found in Open Food Facts.'**
  String get food_barcodeNotFound;

  /// No description provided for @food_scannedProduct.
  ///
  /// In en, this message translates to:
  /// **'Scanned product'**
  String get food_scannedProduct;

  /// No description provided for @food_barcodeValue.
  ///
  /// In en, this message translates to:
  /// **'Barcode: {code}'**
  String food_barcodeValue(Object code);

  /// No description provided for @muscleExercise_emptyGym.
  ///
  /// In en, this message translates to:
  /// **'No gym exercises listed for this muscle.'**
  String get muscleExercise_emptyGym;

  /// No description provided for @muscleExercise_emptyCalisthenics.
  ///
  /// In en, this message translates to:
  /// **'No calisthenics exercises listed for this muscle.'**
  String get muscleExercise_emptyCalisthenics;

  /// No description provided for @strength_setsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get strength_setsLabel;

  /// No description provided for @strength_repsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get strength_repsLabel;

  /// No description provided for @strength_sectionMyWorkouts.
  ///
  /// In en, this message translates to:
  /// **'My workouts'**
  String get strength_sectionMyWorkouts;

  /// No description provided for @strength_sectionPresetWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Preset workouts'**
  String get strength_sectionPresetWorkouts;

  /// No description provided for @strength_renameWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get strength_renameWorkoutTitle;

  /// No description provided for @strength_deleteWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete workout?'**
  String get strength_deleteWorkoutTitle;

  /// No description provided for @strength_deleteWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'This workout will be permanently deleted.'**
  String get strength_deleteWorkoutBody;

  /// No description provided for @strength_deleteWorkoutMenu.
  ///
  /// In en, this message translates to:
  /// **'Delete workout'**
  String get strength_deleteWorkoutMenu;

  /// No description provided for @strength_exerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises'**
  String strength_exerciseCount(Object count);

  /// No description provided for @strength_addToWorkoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to workout'**
  String get strength_addToWorkoutTooltip;

  /// No description provided for @strength_workoutFallback.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get strength_workoutFallback;

  /// No description provided for @cali_skillsHeading.
  ///
  /// In en, this message translates to:
  /// **'SKILLS'**
  String get cali_skillsHeading;

  /// No description provided for @gym_tabExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get gym_tabExercises;

  /// No description provided for @gym_tabWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get gym_tabWorkouts;

  /// No description provided for @gym_addToLastWorkout.
  ///
  /// In en, this message translates to:
  /// **'Add to last workout'**
  String get gym_addToLastWorkout;

  /// No description provided for @gym_noWorkoutYet.
  ///
  /// In en, this message translates to:
  /// **'No workout created yet.'**
  String get gym_noWorkoutYet;

  /// No description provided for @gym_addWorkout.
  ///
  /// In en, this message translates to:
  /// **'Add to workout'**
  String get gym_addWorkout;

  /// No description provided for @gym_addToWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to workout'**
  String get gym_addToWorkoutTitle;

  /// No description provided for @gym_noWorkoutsCreated.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any workouts yet.'**
  String get gym_noWorkoutsCreated;

  /// No description provided for @gym_newWorkout.
  ///
  /// In en, this message translates to:
  /// **'New workout'**
  String get gym_newWorkout;

  /// No description provided for @gym_createNewWorkout.
  ///
  /// In en, this message translates to:
  /// **'Create new workout'**
  String get gym_createNewWorkout;

  /// No description provided for @gym_exerciseAdded.
  ///
  /// In en, this message translates to:
  /// **'Exercise added.'**
  String get gym_exerciseAdded;

  /// No description provided for @gym_workoutNotFound.
  ///
  /// In en, this message translates to:
  /// **'Workout not found.'**
  String get gym_workoutNotFound;

  /// No description provided for @gym_defaultWorkoutName.
  ///
  /// In en, this message translates to:
  /// **'My Workout'**
  String get gym_defaultWorkoutName;

  /// No description provided for @cali_tabExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get cali_tabExercises;

  /// No description provided for @cali_tabWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get cali_tabWorkouts;

  /// No description provided for @cali_skillProgramsIntro.
  ///
  /// In en, this message translates to:
  /// **'More workouts and programs for this skill will be added here step by step.'**
  String get cali_skillProgramsIntro;

  /// No description provided for @cali_programBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner Program'**
  String get cali_programBeginner;

  /// No description provided for @cali_programBeginnerSub.
  ///
  /// In en, this message translates to:
  /// **'Basics + technique + mobility'**
  String get cali_programBeginnerSub;

  /// No description provided for @cali_programIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate Program'**
  String get cali_programIntermediate;

  /// No description provided for @cali_programIntermediateSub.
  ///
  /// In en, this message translates to:
  /// **'Progressions + strength building'**
  String get cali_programIntermediateSub;

  /// No description provided for @cali_programAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced Program'**
  String get cali_programAdvanced;

  /// No description provided for @cali_programAdvancedSub.
  ///
  /// In en, this message translates to:
  /// **'Skills + volume + intensity'**
  String get cali_programAdvancedSub;

  /// No description provided for @cali_programPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'This page is linked so the structure is ready. Next we\'ll fill it with real workouts like the Gym/Cali workout builder.'**
  String get cali_programPlaceholder;

  /// No description provided for @categoryDetail_startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get categoryDetail_startWorkout;

  /// Localized string for categoryDetail_exerciseCountDuration
  ///
  /// In en, this message translates to:
  /// **'{count} exercises · Total time: {duration}'**
  String categoryDetail_exerciseCountDuration(int count, Object duration);

  /// No description provided for @categoryDetail_secondsDefaultHint.
  ///
  /// In en, this message translates to:
  /// **'Default: 30s. Tap the seconds to change them.'**
  String get categoryDetail_secondsDefaultHint;

  /// Localized string for categoryDetail_durationMinSec
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} sec'**
  String categoryDetail_durationMinSec(int minutes, Object seconds);

  /// No description provided for @categoryDetail_heading9min.
  ///
  /// In en, this message translates to:
  /// **'9 Min Workout'**
  String get categoryDetail_heading9min;

  /// No description provided for @categoryDetail_info9min.
  ///
  /// In en, this message translates to:
  /// **'Here you can adjust the times yourself by tapping the green 30s labels.'**
  String get categoryDetail_info9min;

  /// No description provided for @categoryDetail_infoStretch.
  ///
  /// In en, this message translates to:
  /// **'Here you can adjust the times yourself by tapping the green 30s labels.'**
  String get categoryDetail_infoStretch;

  /// No description provided for @categoryDetail_infoMorning.
  ///
  /// In en, this message translates to:
  /// **'Here you can adjust the times yourself by tapping the green 30s labels. You can also add or remove exercises as you like.'**
  String get categoryDetail_infoMorning;

  /// No description provided for @categoryDetail_headingHercules.
  ///
  /// In en, this message translates to:
  /// **'Optimized for runners'**
  String get categoryDetail_headingHercules;

  /// No description provided for @morningWorkout_addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get morningWorkout_addExercise;

  /// No description provided for @morningWorkout_removeExercise.
  ///
  /// In en, this message translates to:
  /// **'Remove exercise'**
  String get morningWorkout_removeExercise;

  /// No description provided for @morningWorkout_pickExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise to workout'**
  String get morningWorkout_pickExercise;

  /// No description provided for @morningWorkout_sourceMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morningWorkout_sourceMorning;

  /// No description provided for @morningWorkout_sourceYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get morningWorkout_sourceYoga;

  /// No description provided for @morningWorkout_sourceGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get morningWorkout_sourceGym;

  /// No description provided for @morningWorkout_sourceCalisthenics.
  ///
  /// In en, this message translates to:
  /// **'Calisthenics'**
  String get morningWorkout_sourceCalisthenics;

  /// No description provided for @morningWorkout_cannotRemoveLast.
  ///
  /// In en, this message translates to:
  /// **'At least one exercise must remain.'**
  String get morningWorkout_cannotRemoveLast;

  /// No description provided for @morningWorkout_allExercisesAdded.
  ///
  /// In en, this message translates to:
  /// **'All exercises are already in your workout.'**
  String get morningWorkout_allExercisesAdded;

  /// No description provided for @categoryDetail_headingStretch.
  ///
  /// In en, this message translates to:
  /// **'Only Stretch'**
  String get categoryDetail_headingStretch;

  /// No description provided for @strength_exercisesZero.
  ///
  /// In en, this message translates to:
  /// **'0 exercises'**
  String get strength_exercisesZero;

  /// Localized string for strength_exercisesSummary
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal · {count} exercises · {duration}'**
  String strength_exercisesSummary(Object kcal, int count, Object duration);

  /// No description provided for @strength_workoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Workout complete'**
  String get strength_workoutComplete;

  /// Localized string for strength_workoutCompleteSnack
  ///
  /// In en, this message translates to:
  /// **'Workout complete. +5 Level · {kcal} kcal'**
  String strength_workoutCompleteSnack(Object kcal);

  /// No description provided for @strength_estimatedBurn.
  ///
  /// In en, this message translates to:
  /// **'Estimated burn'**
  String get strength_estimatedBurn;

  /// No description provided for @strength_exerciseFallback.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get strength_exerciseFallback;

  /// Localized string for strength_exerciseKcalDuration
  ///
  /// In en, this message translates to:
  /// **'~{kcal} kcal · {duration}'**
  String strength_exerciseKcalDuration(Object kcal, Object duration);

  /// No description provided for @preset_push.
  ///
  /// In en, this message translates to:
  /// **'Push Workout'**
  String get preset_push;

  /// No description provided for @preset_pull.
  ///
  /// In en, this message translates to:
  /// **'Pull Workout'**
  String get preset_pull;

  /// No description provided for @preset_abs.
  ///
  /// In en, this message translates to:
  /// **'Ab Workout'**
  String get preset_abs;

  /// No description provided for @preset_chestTriShoulder.
  ///
  /// In en, this message translates to:
  /// **'Chest · Triceps · Shoulder'**
  String get preset_chestTriShoulder;

  /// No description provided for @preset_backBiceps.
  ///
  /// In en, this message translates to:
  /// **'Back · Biceps'**
  String get preset_backBiceps;

  /// No description provided for @preset_legsAbs.
  ///
  /// In en, this message translates to:
  /// **'Legs · Abs'**
  String get preset_legsAbs;

  /// No description provided for @preset_caliBack.
  ///
  /// In en, this message translates to:
  /// **'Back Workout'**
  String get preset_caliBack;

  /// No description provided for @preset_caliChest.
  ///
  /// In en, this message translates to:
  /// **'Chest Workout'**
  String get preset_caliChest;

  /// No description provided for @preset_caliAbs.
  ///
  /// In en, this message translates to:
  /// **'Abs Calisthenics'**
  String get preset_caliAbs;

  /// No description provided for @preset_caliLegs.
  ///
  /// In en, this message translates to:
  /// **'Leg Workout'**
  String get preset_caliLegs;

  /// No description provided for @preset_caliShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulder Workout'**
  String get preset_caliShoulders;

  /// No description provided for @preset_caliHumanFlag.
  ///
  /// In en, this message translates to:
  /// **'Human Flag Workout'**
  String get preset_caliHumanFlag;

  /// No description provided for @preset_caliHandstand.
  ///
  /// In en, this message translates to:
  /// **'Handstand Workout'**
  String get preset_caliHandstand;

  /// No description provided for @preset_caliPlanche.
  ///
  /// In en, this message translates to:
  /// **'Planche Workout'**
  String get preset_caliPlanche;

  /// No description provided for @mood_title.
  ///
  /// In en, this message translates to:
  /// **'How do you feel?'**
  String get mood_title;

  /// No description provided for @mood_veryBad.
  ///
  /// In en, this message translates to:
  /// **'Very\nbad'**
  String get mood_veryBad;

  /// No description provided for @mood_bad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get mood_bad;

  /// No description provided for @mood_neutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get mood_neutral;

  /// No description provided for @mood_good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get mood_good;

  /// No description provided for @mood_veryGood.
  ///
  /// In en, this message translates to:
  /// **'Very\ngood'**
  String get mood_veryGood;

  /// No description provided for @workout_phaseGetReady.
  ///
  /// In en, this message translates to:
  /// **'GET READY'**
  String get workout_phaseGetReady;

  /// No description provided for @workout_phaseWork.
  ///
  /// In en, this message translates to:
  /// **'WORK'**
  String get workout_phaseWork;

  /// No description provided for @workout_phaseRest.
  ///
  /// In en, this message translates to:
  /// **'REST'**
  String get workout_phaseRest;

  /// No description provided for @workout_phaseComplete.
  ///
  /// In en, this message translates to:
  /// **'WORKOUT COMPLETE'**
  String get workout_phaseComplete;

  /// Localized string for workout_setProgress
  ///
  /// In en, this message translates to:
  /// **'Set {current} of {total}'**
  String workout_setProgress(int current, int total);

  /// Localized string for workout_finishedMessage
  ///
  /// In en, this message translates to:
  /// **'Great job! You completed all {count} exercises.'**
  String workout_finishedMessage(int count);

  /// No description provided for @workout_tapCheckHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the checkmark to see your progress.'**
  String get workout_tapCheckHint;

  /// No description provided for @tts_getReady.
  ///
  /// In en, this message translates to:
  /// **'Get ready'**
  String get tts_getReady;

  /// No description provided for @tts_halfway.
  ///
  /// In en, this message translates to:
  /// **'Halfway'**
  String get tts_halfway;

  /// No description provided for @tts_start.
  ///
  /// In en, this message translates to:
  /// **'Go!'**
  String get tts_start;

  /// No description provided for @tts_workoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Workout finished, GREAT!'**
  String get tts_workoutComplete;

  /// Localized string for tts_pauseNext
  ///
  /// In en, this message translates to:
  /// **'Pause. Next exercise: {name}'**
  String tts_pauseNext(Object name);

  /// No description provided for @running_tabNewRoute.
  ///
  /// In en, this message translates to:
  /// **'New route'**
  String get running_tabNewRoute;

  /// No description provided for @running_tabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get running_tabSaved;

  /// No description provided for @running_tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get running_tabHistory;

  /// No description provided for @running_historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No runs yet'**
  String get running_historyEmpty;

  /// No description provided for @running_historyEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Finish a tracked run and it will appear here.'**
  String get running_historyEmptyHint;

  /// No description provided for @running_historyMonthKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km this month'**
  String running_historyMonthKm(Object km);

  /// No description provided for @running_historyMonthAvgPace.
  ///
  /// In en, this message translates to:
  /// **'Avg pace {pace}'**
  String running_historyMonthAvgPace(Object pace);

  /// No description provided for @running_historyUntitledRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get running_historyUntitledRun;

  /// No description provided for @running_needStartEnd.
  ///
  /// In en, this message translates to:
  /// **'Set at least a start and end point.'**
  String get running_needStartEnd;

  /// Localized string for running_unexpectedError
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {detail}'**
  String running_unexpectedError(Object detail);

  /// Localized string for running_routeSaved
  ///
  /// In en, this message translates to:
  /// **'Route \"{name}\" saved.'**
  String running_routeSaved(Object name);

  /// No description provided for @running_saveRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Save route'**
  String get running_saveRouteTitle;

  /// No description provided for @running_routeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get running_routeNameLabel;

  /// Localized string for running_defaultRouteName
  ///
  /// In en, this message translates to:
  /// **'Run {date}'**
  String running_defaultRouteName(Object date);

  /// No description provided for @running_myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get running_myLocation;

  /// No description provided for @running_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get running_reset;

  /// No description provided for @running_removeLastPoint.
  ///
  /// In en, this message translates to:
  /// **'Remove last point'**
  String get running_removeLastPoint;

  /// No description provided for @running_mapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map for your route or start right away.'**
  String get running_mapHint;

  /// No description provided for @running_calculateRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculate route'**
  String get running_calculateRoute;

  /// No description provided for @running_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get running_save;

  /// No description provided for @running_points.
  ///
  /// In en, this message translates to:
  /// **'POINTS'**
  String get running_points;

  /// No description provided for @running_distance.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get running_distance;

  /// No description provided for @running_elevation.
  ///
  /// In en, this message translates to:
  /// **'ELEVATION'**
  String get running_elevation;

  /// No description provided for @running_pinStart.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get running_pinStart;

  /// No description provided for @running_pinEnd.
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get running_pinEnd;

  /// No description provided for @running_noRoutes.
  ///
  /// In en, this message translates to:
  /// **'No routes yet'**
  String get running_noRoutes;

  /// No description provided for @running_noRoutesHint.
  ///
  /// In en, this message translates to:
  /// **'Switch to the \"New route\" tab and plan your first run.'**
  String get running_noRoutesHint;

  /// No description provided for @running_deleteRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete route?'**
  String get running_deleteRouteTitle;

  /// Localized string for running_deleteRouteBody
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be permanently removed.'**
  String running_deleteRouteBody(Object name);

  /// No description provided for @running_renameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get running_renameTitle;

  /// No description provided for @running_deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get running_deleteConfirmBody;

  /// No description provided for @run_gpsOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get run_gpsOff;

  /// No description provided for @run_gpsDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get run_gpsDenied;

  /// Localized string for run_gpsError
  ///
  /// In en, this message translates to:
  /// **'GPS error: {detail}'**
  String run_gpsError(Object detail);

  /// Localized string for run_gpsStartFailed
  ///
  /// In en, this message translates to:
  /// **'Could not start GPS: {detail}'**
  String run_gpsStartFailed(Object detail);

  /// Localized string for run_ttsIn100m
  ///
  /// In en, this message translates to:
  /// **'In 100 meters: {instruction}'**
  String run_ttsIn100m(Object instruction);

  /// Localized string for run_ttsIn300m
  ///
  /// In en, this message translates to:
  /// **'In 300 meters: {instruction}'**
  String run_ttsIn300m(Object instruction);

  /// No description provided for @run_ttsGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Destination reached. Well done!'**
  String get run_ttsGoalReached;

  /// No description provided for @run_goalReached.
  ///
  /// In en, this message translates to:
  /// **'Destination reached'**
  String get run_goalReached;

  /// No description provided for @run_ttsStarted.
  ///
  /// In en, this message translates to:
  /// **'Run started. Good luck!'**
  String get run_ttsStarted;

  /// No description provided for @run_ttsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause.'**
  String get run_ttsPause;

  /// No description provided for @run_ttsResume.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go.'**
  String get run_ttsResume;

  /// No description provided for @run_endTitle.
  ///
  /// In en, this message translates to:
  /// **'End run?'**
  String get run_endTitle;

  /// No description provided for @run_endBody.
  ///
  /// In en, this message translates to:
  /// **'Distance, time and the run will be saved.'**
  String get run_endBody;

  /// No description provided for @run_keepRunning.
  ///
  /// In en, this message translates to:
  /// **'Keep running'**
  String get run_keepRunning;

  /// No description provided for @run_end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get run_end;

  /// No description provided for @run_finishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Run finished'**
  String get run_finishedTitle;

  /// No description provided for @run_distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get run_distance;

  /// No description provided for @run_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get run_time;

  /// No description provided for @run_calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get run_calories;

  /// No description provided for @run_level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get run_level;

  /// Localized string for run_levelNextMeters
  ///
  /// In en, this message translates to:
  /// **'{meters} m until next level.'**
  String run_levelNextMeters(Object meters);

  /// Localized string for run_levelEvery5km
  ///
  /// In en, this message translates to:
  /// **'+1 level every 5 km — {meters} m to go.'**
  String run_levelEvery5km(Object meters);

  /// No description provided for @run_autoFollowOn.
  ///
  /// In en, this message translates to:
  /// **'Auto-follow on'**
  String get run_autoFollowOn;

  /// No description provided for @run_autoFollowOff.
  ///
  /// In en, this message translates to:
  /// **'Auto-follow off'**
  String get run_autoFollowOff;

  /// No description provided for @run_voiceOn.
  ///
  /// In en, this message translates to:
  /// **'Voice on'**
  String get run_voiceOn;

  /// No description provided for @run_voiceOff.
  ///
  /// In en, this message translates to:
  /// **'Voice off'**
  String get run_voiceOff;

  /// No description provided for @run_waitingGps.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS signal…'**
  String get run_waitingGps;

  /// No description provided for @run_distNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get run_distNow;

  /// Localized string for run_distInMeters
  ///
  /// In en, this message translates to:
  /// **'in {meters} m'**
  String run_distInMeters(Object meters);

  /// Localized string for run_distInKm
  ///
  /// In en, this message translates to:
  /// **'in {km} km'**
  String run_distInKm(Object km);

  /// No description provided for @run_labelTime.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get run_labelTime;

  /// No description provided for @run_labelKm.
  ///
  /// In en, this message translates to:
  /// **'KM'**
  String get run_labelKm;

  /// No description provided for @run_labelPace.
  ///
  /// In en, this message translates to:
  /// **'PACE'**
  String get run_labelPace;

  /// No description provided for @run_start.
  ///
  /// In en, this message translates to:
  /// **'START RUN'**
  String get run_start;

  /// No description provided for @run_waitGps.
  ///
  /// In en, this message translates to:
  /// **'WAITING FOR GPS…'**
  String get run_waitGps;

  /// No description provided for @run_resume.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get run_resume;

  /// No description provided for @run_pause.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get run_pause;

  /// No description provided for @run_endButton.
  ///
  /// In en, this message translates to:
  /// **'END'**
  String get run_endButton;

  /// No description provided for @social_connectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect friends'**
  String get social_connectTitle;

  /// No description provided for @social_connectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share workouts, routes and recipes'**
  String get social_connectSubtitle;

  /// No description provided for @social_inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get social_inboxTitle;

  /// No description provided for @social_yourIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Kaizen ID'**
  String get social_yourIdTitle;

  /// No description provided for @social_copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get social_copyCode;

  /// No description provided for @social_shareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share invite'**
  String get social_shareInvite;

  /// No description provided for @social_addFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Add friend by ID'**
  String get social_addFriendTitle;

  /// No description provided for @social_addFriendHint.
  ///
  /// In en, this message translates to:
  /// **'KZN-ABC123'**
  String get social_addFriendHint;

  /// No description provided for @social_addFriendAction.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get social_addFriendAction;

  /// No description provided for @social_friendsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends ({count})'**
  String social_friendsListTitle(int count);

  /// No description provided for @social_noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends connected yet.'**
  String get social_noFriendsYet;

  /// No description provided for @social_notifyRunStart.
  ///
  /// In en, this message translates to:
  /// **'Notify when starting a run'**
  String get social_notifyRunStart;

  /// No description provided for @social_removeFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove friend?'**
  String get social_removeFriendTitle;

  /// No description provided for @social_removeFriendBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from your friends list?'**
  String social_removeFriendBody(String name);

  /// No description provided for @social_codeCopied.
  ///
  /// In en, this message translates to:
  /// **'ID copied'**
  String get social_codeCopied;

  /// No description provided for @social_friendAdded.
  ///
  /// In en, this message translates to:
  /// **'Friend connected'**
  String get social_friendAdded;

  /// No description provided for @social_errorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid ID.'**
  String get social_errorInvalidCode;

  /// No description provided for @social_errorSelfFriend.
  ///
  /// In en, this message translates to:
  /// **'You cannot add yourself.'**
  String get social_errorSelfFriend;

  /// No description provided for @social_errorFriendNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found with this ID.'**
  String get social_errorFriendNotFound;

  /// No description provided for @social_errorAlreadyFriends.
  ///
  /// In en, this message translates to:
  /// **'You are already connected.'**
  String get social_errorAlreadyFriends;

  /// No description provided for @social_errorCloudDisabled.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync is not set up yet. Configure Firebase to connect with friends.'**
  String get social_errorCloudDisabled;

  /// No description provided for @social_errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Please try again.'**
  String get social_errorGeneric;

  /// No description provided for @social_cloudSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Friend sync requires Firebase. Add your projectId and apiKey in lib/services/social/social_cloud_config.dart, enable Anonymous Auth + Firestore, then rebuild.'**
  String get social_cloudSetupHint;

  /// No description provided for @social_inviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Connect with me on Kaizen: {link}\nMy ID: {code}'**
  String social_inviteShareText(String link, String code);

  /// No description provided for @social_shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share with friend'**
  String get social_shareAction;

  /// No description provided for @social_shareWithFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Share with'**
  String get social_shareWithFriendsTitle;

  /// No description provided for @social_noFriendsToShare.
  ///
  /// In en, this message translates to:
  /// **'Add friends in Profile → Connect friends first.'**
  String get social_noFriendsToShare;

  /// No description provided for @social_shareSent.
  ///
  /// In en, this message translates to:
  /// **'Shared successfully'**
  String get social_shareSent;

  /// No description provided for @social_inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get social_inboxEmpty;

  /// No description provided for @social_inboxRoute.
  ///
  /// In en, this message translates to:
  /// **'{name} shared a running route with you.'**
  String social_inboxRoute(String name);

  /// No description provided for @social_inboxGymWorkout.
  ///
  /// In en, this message translates to:
  /// **'{name} shared a gym workout with you.'**
  String social_inboxGymWorkout(String name);

  /// No description provided for @social_inboxCalisthenicsWorkout.
  ///
  /// In en, this message translates to:
  /// **'{name} shared a calisthenics workout with you.'**
  String social_inboxCalisthenicsWorkout(String name);

  /// No description provided for @social_inboxFoodDish.
  ///
  /// In en, this message translates to:
  /// **'{name} shared a dish with you.'**
  String social_inboxFoodDish(String name);

  /// No description provided for @social_inboxThumbsUp.
  ///
  /// In en, this message translates to:
  /// **'{name} sent you a thumbs up 👍'**
  String social_inboxThumbsUp(String name);

  /// No description provided for @social_sendThumbsUp.
  ///
  /// In en, this message translates to:
  /// **'Send thumbs up'**
  String get social_sendThumbsUp;

  /// No description provided for @social_thumbsUpSent.
  ///
  /// In en, this message translates to:
  /// **'Thumbs up sent'**
  String get social_thumbsUpSent;

  /// No description provided for @social_acceptRoute.
  ///
  /// In en, this message translates to:
  /// **'Add to saved routes'**
  String get social_acceptRoute;

  /// No description provided for @social_acceptWorkout.
  ///
  /// In en, this message translates to:
  /// **'Add to my workouts'**
  String get social_acceptWorkout;

  /// No description provided for @social_acceptDish.
  ///
  /// In en, this message translates to:
  /// **'Add to my recipes'**
  String get social_acceptDish;

  /// No description provided for @social_reject.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get social_reject;

  /// No description provided for @social_inboxAccepted.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get social_inboxAccepted;

  /// No description provided for @social_inboxRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get social_inboxRejected;

  /// No description provided for @social_inboxAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to your library'**
  String get social_inboxAdded;

  /// No description provided for @friends_hubTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends_hubTitle;

  /// No description provided for @friends_monthlyChallengeTab.
  ///
  /// In en, this message translates to:
  /// **'Monthly Challenge'**
  String get friends_monthlyChallengeTab;

  /// No description provided for @friends_runningMapTab.
  ///
  /// In en, this message translates to:
  /// **'Running Map'**
  String get friends_runningMapTab;

  /// No description provided for @friends_challengeTitle.
  ///
  /// In en, this message translates to:
  /// **'1,000 Push-Up Challenge'**
  String get friends_challengeTitle;

  /// No description provided for @friends_goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get friends_goal;

  /// No description provided for @friends_pushUps.
  ///
  /// In en, this message translates to:
  /// **'push-ups'**
  String get friends_pushUps;

  /// No description provided for @friends_tapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit your count'**
  String get friends_tapToEdit;

  /// No description provided for @friends_editCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Update push-up count'**
  String get friends_editCountTitle;

  /// No description provided for @friends_editCountHint.
  ///
  /// In en, this message translates to:
  /// **'Current total this month'**
  String get friends_editCountHint;

  /// No description provided for @friends_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get friends_save;

  /// No description provided for @friends_leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get friends_leaderboard;

  /// No description provided for @friends_you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get friends_you;

  /// No description provided for @friends_noFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Connect friends to compete with them here.'**
  String get friends_noFriendsHint;

  /// No description provided for @friends_goalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached — keep going!'**
  String get friends_goalReached;

  /// No description provided for @running_tabShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get running_tabShared;

  /// No description provided for @sharedRuns_tabHint.
  ///
  /// In en, this message translates to:
  /// **'See friends who are running live. Tap a profile icon for pace and route details.'**
  String get sharedRuns_tabHint;

  /// No description provided for @sharedRuns_empty.
  ///
  /// In en, this message translates to:
  /// **'No friends are running right now.'**
  String get sharedRuns_empty;

  /// No description provided for @sharedRuns_homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends running live'**
  String get sharedRuns_homeTitle;

  /// No description provided for @sharedRuns_liveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} live'**
  String sharedRuns_liveCount(int count);

  /// No description provided for @sharedRuns_distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get sharedRuns_distance;

  /// No description provided for @sharedRuns_currentPace.
  ///
  /// In en, this message translates to:
  /// **'Current pace'**
  String get sharedRuns_currentPace;

  /// No description provided for @sharedRuns_avgPace.
  ///
  /// In en, this message translates to:
  /// **'Average pace'**
  String get sharedRuns_avgPace;

  /// No description provided for @onTheGo_exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get onTheGo_exercises;

  /// No description provided for @onTheGo_search.
  ///
  /// In en, this message translates to:
  /// **'Search exercises…'**
  String get onTheGo_search;

  /// No description provided for @onTheGo_select.
  ///
  /// In en, this message translates to:
  /// **'Tap muscles to select'**
  String get onTheGo_select;

  /// No description provided for @onTheGo_show.
  ///
  /// In en, this message translates to:
  /// **'Show exercises'**
  String get onTheGo_show;

  /// No description provided for @onTheGo_noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching exercises found.'**
  String get onTheGo_noMatches;

  /// No description provided for @onTheGo_empty.
  ///
  /// In en, this message translates to:
  /// **'Your workout is empty. Add exercises from the list on the right.'**
  String get onTheGo_empty;

  /// No description provided for @onTheGo_generate.
  ///
  /// In en, this message translates to:
  /// **'Generate workout'**
  String get onTheGo_generate;

  /// No description provided for @onTheGo_moreExercises.
  ///
  /// In en, this message translates to:
  /// **'More exercises'**
  String get onTheGo_moreExercises;

  /// No description provided for @onTheGo_complement.
  ///
  /// In en, this message translates to:
  /// **'Complement for the same body area'**
  String get onTheGo_complement;

  /// No description provided for @onTheGo_saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the workout. Please try again.'**
  String get onTheGo_saveFailed;

  /// No description provided for @workoutHub_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search workouts…'**
  String get workoutHub_searchHint;

  /// No description provided for @workoutHub_filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get workoutHub_filter;

  /// No description provided for @workoutHub_filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get workoutHub_filterTitle;

  /// No description provided for @workoutHub_filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get workoutHub_filterApply;

  /// No description provided for @workoutHub_filterKind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get workoutHub_filterKind;

  /// No description provided for @workoutHub_filterMuscles.
  ///
  /// In en, this message translates to:
  /// **'Muscle groups'**
  String get workoutHub_filterMuscles;

  /// No description provided for @workoutHub_kindGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get workoutHub_kindGym;

  /// No description provided for @workoutHub_kindCalisthenics.
  ///
  /// In en, this message translates to:
  /// **'Calisthenics'**
  String get workoutHub_kindCalisthenics;

  /// No description provided for @workoutHub_kindStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get workoutHub_kindStretch;

  /// No description provided for @workoutHub_quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick start'**
  String get workoutHub_quickAccess;

  /// No description provided for @workoutHub_myWorkouts.
  ///
  /// In en, this message translates to:
  /// **'My workouts'**
  String get workoutHub_myWorkouts;

  /// No description provided for @workoutHub_presets.
  ///
  /// In en, this message translates to:
  /// **'Preset workouts'**
  String get workoutHub_presets;

  /// No description provided for @workoutHub_favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get workoutHub_favorites;

  /// No description provided for @workoutHub_empty.
  ///
  /// In en, this message translates to:
  /// **'No workouts match your search.'**
  String get workoutHub_empty;

  /// No description provided for @workoutHub_startAsYouGo.
  ///
  /// In en, this message translates to:
  /// **'Start empty workout'**
  String get workoutHub_startAsYouGo;

  /// No description provided for @workoutHub_startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get workoutHub_startWorkout;

  /// No description provided for @workoutHub_favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get workoutHub_favorite;

  /// No description provided for @workoutHub_unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Unpin favorite'**
  String get workoutHub_unfavorite;

  /// No description provided for @running_startFree.
  ///
  /// In en, this message translates to:
  /// **'Start right away'**
  String get running_startFree;

  /// No description provided for @running_freeRunName.
  ///
  /// In en, this message translates to:
  /// **'Free run'**
  String get running_freeRunName;

  /// No description provided for @running_savedFreeRun.
  ///
  /// In en, this message translates to:
  /// **'Run saved'**
  String get running_savedFreeRun;

  /// No description provided for @strength_setsMaxHint.
  ///
  /// In en, this message translates to:
  /// **'Up to 100 sets'**
  String get strength_setsMaxHint;

  /// No description provided for @strength_editSetReps.
  ///
  /// In en, this message translates to:
  /// **'Edit reps'**
  String get strength_editSetReps;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
