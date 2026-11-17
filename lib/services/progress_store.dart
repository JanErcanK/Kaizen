import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

import '../data/hercules_default_exercises.dart';
import '../data/standard_food_dishes.dart';
import '../data/food_nutrient_estimator.dart';
import '../models/body_map_view_mode.dart';
import '../models/food_nutrients.dart';
import '../models/ai_chat.dart';
import '../models/social_models.dart';
import '../models/shared_content.dart';
import '../models/training_schedule.dart';
import '../models/shopping_list.dart';
import '../models/health_dashboard.dart';
import '../utils/strength_exercise_config.dart';
import 'calorie_burn_service.dart';
import 'nutrition_calculator.dart';

typedef AnalyticsChartPoint = ({DateTime day, double value});

class ProgressStore {
  static const String _boxName =
      'fitflow_progress'; // kept for existing user data
  static const String keyLastCategory = 'last_category';
  static const String keyHomeOpens = 'home_opens';
  static const String keyProfileAnalyticsStart = 'profile_analytics_start';
  static const String keyProfileName = 'profile_name';
  static const String keyUserLevel = 'user_level';
  static const String keyWorkoutStreakDays = 'workout_streak_days';
  static const String keyLastWorkoutDay = 'last_workout_day';
  static const String keyWorkoutCompletedDays = 'workout_completed_days';
  static const String keyWeightEntries = 'weight_entries';
  static const String keyWorkoutEvents = 'workout_events';
  static const String keyProfileAge = 'profile_age';
  static const String keyProfileHeightCm = 'profile_height_cm';
  static const String keyProfileGender = 'profile_gender';
  static const String keyProfileBodyFatPercent = 'profile_body_fat_percent';
  static const String keyProfileMuscleMassKg = 'profile_muscle_mass_kg';
  static const String keyProfileBoneMassKg = 'profile_bone_mass_kg';
  static const String keyProfileActivityLevel = 'profile_activity_level';
  static const String keyProfileGoal = 'profile_goal';
  static const String keyHasCompletedOnboarding = 'has_completed_onboarding';
  static const String keyWeeklyTrainingSchedule = 'weekly_training_schedule';
  static const String keyTrainingNotificationsEnabled =
      'training_notifications_enabled';
  static const String keyFastingHudEnabled = 'fasting_hud_enabled';
  static const String keyEatingWindowConfigured = 'eating_window_configured';
  static const String keyEatingWindowStartMinutes =
      'eating_window_start_minutes';
  static const String keyEatingWindowEndMinutes = 'eating_window_end_minutes';
  static const String keyFastingRemindersEnabled = 'fasting_reminders_enabled';
  static const String keyProfileAvatarPath = 'profile_avatar_path';
  static const String keyHeroBackgroundPath = 'hero_background_path';
  static const String keyProfileGalleryItems = 'profile_gallery_items';
  static const String keyWorkoutVoiceEnabled = 'workout_voice_enabled';
  static const String keyWorkoutVoiceGender = 'workout_voice_gender';
  static const String keyUseLightTheme = 'use_light_theme';
  static const String keyAppLocale = 'app_locale';
  static const String keyHasSeenInstallHint = 'has_seen_install_hint';
  static const String keyHasCompletedAppTour = 'has_completed_app_tour';
  static const String keyHasCompletedHomeIntro = 'has_completed_home_intro';
  static const String keyBodyMapTabIntrosSeen = 'body_map_tab_intros_seen';
  static const String keyTodaySteps = 'today_steps';
  static const String keyTodayStepsDate = 'today_steps_date';
  static const String keyTodayStepsSyncedAt = 'today_steps_synced_at';
  static const String keyStepsHistory = 'steps_history';
  static const String keyLastNightSleepMinutes = 'last_night_sleep_minutes';
  static const String keyLastNightSleepDate = 'last_night_sleep_date';
  static const String keyLastNightSleepSyncedAt = 'last_night_sleep_synced_at';
  static const String keySleepHistory = 'sleep_history';
  static const String keyEarnedBadges = 'earned_badges';
  static const String keyTotalGymWorkoutsCompleted =
      'total_gym_workouts_completed';
  static const String keyTotalCalisthenicsWorkoutsCompleted =
      'total_calisthenics_workouts_completed';
  static const String _workoutExerciseSecondsPrefix =
      'workout_exercise_seconds_';
  static const String keyMorningWorkoutExerciseOrder =
      'morning_workout_exercise_order';
  static const String keyGymWorkouts = 'gym_workouts';
  static const String keyLastGymWorkoutId = 'last_gym_workout_id';
  static const String keyCalisthenicsWorkouts = 'calisthenics_workouts';
  static const String keyLastCalisthenicsWorkoutId =
      'last_calisthenics_workout_id';
  static const String keyRunningRoutes = 'running_routes';
  static const String keyFoodDishes = 'food_dishes';
  static const String keyFoodIntake = 'food_intake';
  static const String keyFavoriteWorkoutIds = 'favorite_workout_ids';
  static const String keyWaterTrackingEnabled = 'water_tracking_enabled';
  static const String keyWaterGoalMl = 'water_goal_ml';
  static const String keyTodayWaterMl = 'today_water_ml';
  static const String keyTodayWaterDate = 'today_water_date';
  static const String keyWaterHistory = 'water_history';
  static const String keySupplementIntake = 'supplement_intake';
  static const String keyExerciseLiftLog = 'exercise_lift_log';
  static const String _categoryPrefix = 'category_open_count_';

  static const int waterGlassMl = 500;
  static const int waterGoalStepMl = 250;

  static Box<dynamic>? _box;
  static final ValueNotifier<int> _changeTick = ValueNotifier<int>(0);
  static int _batchDepth = 0;
  static bool _pendingNotify = false;

  static void _notifyChanged() {
    if (_batchDepth > 0) {
      _pendingNotify = true;
      return;
    }
    _changeTick.value++;
  }

  static Future<void> batch(Future<void> Function() action) async {
    _batchDepth++;
    try {
      await action();
    } finally {
      _batchDepth--;
      if (_batchDepth == 0 && _pendingNotify) {
        _pendingNotify = false;
        _changeTick.value++;
      }
    }
  }

  static Box<dynamic> get _safeBox {
    final box = _box;
    if (box == null) {
      throw StateError('ProgressStore.init() must be called before use.');
    }
    return box;
  }

  static String get storageDirectory => File(_safeBox.path!).parent.path;

  static bool get healthDashboardConnected =>
      _safeBox.get('health_dashboard_connected', defaultValue: false) == true;
  static HealthDashboardSnapshot get healthDashboard {
    final raw = _safeBox.get('health_dashboard_v1');
    return raw is Map
        ? HealthDashboardSnapshot.fromJson(raw)
        : const HealthDashboardSnapshot();
  }

  static Future<void> setHealthDashboardConnected(bool value) async {
    await _safeBox.put('health_dashboard_connected', value);
    _notifyChanged();
  }

  static Future<void> saveHealthDashboard(
    HealthDashboardSnapshot snapshot,
  ) async {
    await _safeBox.put('health_dashboard_v1', snapshot.toJson());
    _notifyChanged();
  }

  static Future<void> clearHealthDashboard() async {
    await _safeBox.delete('health_dashboard_v1');
    await _safeBox.put('health_dashboard_connected', false);
    _notifyChanged();
  }

  // Draft and archive share one write, so saving/clearing cannot lose either.
  static const keyShoppingLists = 'shopping_lists_v1';

  static ShoppingList get shoppingDraft {
    final data = _safeBox.get(keyShoppingLists);
    final raw = data is Map ? data['draft'] : null;
    return raw is Map ? ShoppingList.fromJson(raw) : ShoppingList.empty();
  }

  static List<ShoppingList> get shoppingHistory {
    final data = _safeBox.get(keyShoppingLists);
    final raw = data is Map ? data['history'] : null;
    return raw is List
        ? raw.whereType<Map>().map(ShoppingList.fromJson).toList()
        : [];
  }

  static Future<void> _writeShopping(
    ShoppingList draft,
    List<ShoppingList> history,
  ) async {
    await _safeBox.put(keyShoppingLists, {
      'draft': draft.toJson(),
      'history': history.map((list) => list.toJson()).toList(),
    });
    _notifyChanged();
  }

  static Future<void> updateShoppingDraft(ShoppingList draft) =>
      _writeShopping(draft, shoppingHistory);

  static ShoppingList _namedShoppingList(ShoppingList list) {
    if (list.name.trim().isNotEmpty) return list;
    final date = list.updatedAt;
    return list.copyWith(
      name:
          '${useGerman ? 'Einkauf' : 'Shopping'} '
          '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.${date.year}',
    );
  }

  static List<ShoppingList> _archiveShopping(
    ShoppingList list,
    List<ShoppingList> history,
  ) {
    if (list.isEmpty) return history;
    final named = _namedShoppingList(list);
    final index = history.indexWhere((entry) => entry.id == list.id);
    if (index < 0) {
      history.insert(0, named);
    } else {
      history[index] = named;
    }
    return history;
  }

  static Future<void> saveShoppingDraft() async {
    final draft = shoppingDraft;
    if (draft.isEmpty) return;
    final named = _namedShoppingList(draft);
    await _writeShopping(named, _archiveShopping(named, shoppingHistory));
  }

  static Future<void> saveAiShoppingList({
    required String sourceId,
    required String name,
    required List<String> items,
    String targetId = '',
  }) async {
    if (hasAiChatAction(sourceId)) return;
    if (name.trim().isEmpty || items.isEmpty || items.length > 80) {
      throw ArgumentError('Invalid shopping list');
    }
    final history = shoppingHistory;
    final current = shoppingDraft;
    if (targetId.isNotEmpty &&
        current.id != targetId &&
        !history.any((s) => s.id == targetId)) {
      throw StateError('Target no longer exists');
    }
    final id = targetId.isEmpty ? 'ai_s_$sourceId' : targetId;
    final previousList = current.id == id
        ? current
        : history.where((s) => s.id == id).firstOrNull;
    final list = ShoppingList(
      id: id,
      name: name.trim(),
      updatedAt: DateTime.now(),
      items: [
        for (var i = 0; i < items.length; i++)
          ShoppingItem(
            id: '${id}_$i',
            text: items[i].trim(),
            checked:
                previousList?.items.any(
                  (old) => old.text == items[i].trim() && old.checked,
                ) ==
                true,
          ),
      ],
    );
    _archiveShopping(current, history);
    _archiveShopping(list, history);
    await _safeBox.putAll({
      keyShoppingLists: {
        'draft': list.toJson(),
        'history': history.map((s) => s.toJson()).toList(),
      },
      _aiActionReceiptKey(sourceId): id,
    });
    _notifyChanged();
  }

  static Future<void> clearShoppingDraft() =>
      _writeShopping(ShoppingList.empty(), shoppingHistory);

  static Future<void> openShoppingList(String id) async {
    final history = shoppingHistory;
    final index = history.indexWhere((list) => list.id == id);
    if (index < 0) return;
    final current = shoppingDraft;
    if (current.id == id) return;
    final selected = history[index];
    // Preserve unfinished writing when switching to another saved purchase.
    await _writeShopping(selected, _archiveShopping(current, history));
  }

  static Future<void> renameShoppingList(String id, String name) async {
    if (name.trim().isEmpty) return;
    final history = shoppingHistory
        .map((list) => list.id == id ? list.copyWith(name: name.trim()) : list)
        .toList();
    final draft = shoppingDraft;
    await _writeShopping(
      draft.id == id ? draft.copyWith(name: name.trim()) : draft,
      history,
    );
  }

  static Future<void> deleteShoppingList(String id) => _writeShopping(
    shoppingDraft.id == id ? ShoppingList.empty() : shoppingDraft,
    shoppingHistory.where((list) => list.id != id).toList(),
  );

  static Future<void> reorderShoppingLists(int oldIndex, int newIndex) async {
    final history = shoppingHistory;
    if (oldIndex < 0 ||
        oldIndex >= history.length ||
        newIndex < 0 ||
        newIndex >= history.length) {
      return;
    }
    history.insert(newIndex, history.removeAt(oldIndex));
    await _writeShopping(shoppingDraft, history);
  }

  static Future<void> addShoppingItem(String name, {double? grams}) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final amount = grams != null && grams.isFinite && grams > 0
        ? ' · ${grams.toStringAsFixed(grams == grams.roundToDouble() ? 0 : 1)} g'
        : '';
    final draft = shoppingDraft;
    await updateShoppingDraft(
      draft.copyWith(
        items: [
          ...draft.items,
          ShoppingItem(id: newShoppingId('item'), text: '$clean$amount'),
        ],
      ),
    );
  }

  static List<Map<String, dynamic>> get savedChats =>
      (_safeBox.get('ai_chats', defaultValue: <dynamic>[]) as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

  static Future<void> saveChats(List<Map<String, dynamic>> chats) =>
      _safeBox.put('ai_chats', chats);

  static Map<String, dynamic> get chatSettings => Map<String, dynamic>.from(
    _safeBox.get('ai_chat_settings', defaultValue: <String, dynamic>{}) as Map,
  );

  static Future<void> saveChatSettings(Map<String, dynamic> settings) =>
      _safeBox.put('ai_chat_settings', settings);

  static bool hasChatMeal(String sourceId) =>
      _safeBox.containsKey('ai_meal_$sourceId') ||
      foodIntake.any((entry) => entry['chatSourceId'] == sourceId);

  static String _aiActionReceiptKey(String sourceId) =>
      'ai_chat_action_$sourceId';

  static bool hasAiChatAction(String sourceId) =>
      _safeBox.containsKey(_aiActionReceiptKey(sourceId));

  static final Set<String> _chatMealWrites = {};

  /// A confirmation writes all portions and its durable receipt together.
  /// The receipt prevents re-logging after a restart, even if intake was deleted.
  static Future<void> confirmChatMeal({
    required String sourceId,
    required MealDraft meal,
    required DateTime at,
  }) async {
    if (hasChatMeal(sourceId) || !_chatMealWrites.add(sourceId)) return;
    try {
      if (meal.foods.isEmpty ||
          meal.foods.length > 30 ||
          meal.foods.any((food) => !food.isValid)) {
        throw ArgumentError('Invalid meal');
      }
      final next = foodIntake.toList();
      for (var i = 0; i < meal.foods.length; i++) {
        final food = meal.foods[i];
        next.add({
          'id': 'ai_${sourceId}_$i',
          'recordedAt': at.toIso8601String(),
          'kind': 'food',
          ...food.toJson(),
          'source': 'ai_estimate',
          'chatSourceId': sourceId,
        });
      }
      await _safeBox.putAll({
        keyFoodIntake: next,
        'ai_meal_$sourceId': at.toIso8601String(),
      });
      _notifyChanged();
    } finally {
      _chatMealWrites.remove(sourceId);
    }
  }

  static Future<void> init({String? storageRootPath}) async {
    String baseDirPath;
    if (storageRootPath != null) {
      baseDirPath = storageRootPath;
    } else if (Platform.isWindows) {
      baseDirPath =
          Platform.environment['LOCALAPPDATA'] ??
          Platform.environment['APPDATA'] ??
          Directory.current.path;
    } else {
      final dir = await getApplicationSupportDirectory();
      baseDirPath = dir.path;
    }

    final hiveDir = Directory('$baseDirPath/Kaizen/hive_data');
    if (!hiveDir.existsSync()) {
      hiveDir.createSync(recursive: true);
    }
    Hive.init(hiveDir.path);
    final existingInstall = await Hive.boxExists(_boxName);
    _box = await Hive.openBox<dynamic>(_boxName);
    if (!_safeBox.containsKey(keyAppLocale)) {
      // Older installs used German implicitly. Preserve that language on
      // update; persist English for new installs so later restarts keep it.
      await _safeBox.put(keyAppLocale, existingInstall ? 'de' : 'en');
    }
    await ensureStandardFoodDishes();
    _migrateLegacyOnboardingIfNeeded();
    await pruneEmptyStrengthWorkouts();
  }

  @visibleForTesting
  static Future<void> closeForTesting() async {
    await _box?.close();
    _box = null;
  }

  static bool _strengthWorkoutHasExercises(Map<String, dynamic> workout) {
    final raw = workout['exercises'];
    return raw is List && raw.isNotEmpty;
  }

  /// Removes gym/calisthenics workouts that have no exercises.
  static Future<void> pruneEmptyStrengthWorkouts() async {
    final gym = gymWorkouts;
    final gymKept = gym
        .where(_strengthWorkoutHasExercises)
        .toList(growable: false);
    final cali = calisthenicsWorkouts;
    final caliKept = cali
        .where(_strengthWorkoutHasExercises)
        .toList(growable: false);
    var changed = false;
    if (gymKept.length != gym.length) {
      await _safeBox.put(keyGymWorkouts, gymKept);
      final lastGym = lastGymWorkoutId;
      if (lastGym != null &&
          gymKept.every((w) => w['id']?.toString() != lastGym)) {
        await _safeBox.delete(keyLastGymWorkoutId);
      }
      changed = true;
    }
    if (caliKept.length != cali.length) {
      await _safeBox.put(keyCalisthenicsWorkouts, caliKept);
      final lastCali = lastCalisthenicsWorkoutId;
      if (lastCali != null &&
          caliKept.every((w) => w['id']?.toString() != lastCali)) {
        await _safeBox.delete(keyLastCalisthenicsWorkoutId);
      }
      changed = true;
    }
    if (changed) _notifyChanged();
  }

  static void _migrateLegacyOnboardingIfNeeded() {
    if (hasCompletedOnboarding) return;
    if (hasProfileName &&
        profileAge != null &&
        profileHeightCm != null &&
        currentWeightKg != null) {
      _safeBox.put(keyHasCompletedOnboarding, true);
    }
  }

  static ValueListenable<int> listenable() => _changeTick;

  static bool get workoutVoiceEnabled {
    final v = _safeBox.get(keyWorkoutVoiceEnabled, defaultValue: true);
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v == '1' || v == 'true';
  }

  /// `female` (default), `male`, or `system`.
  static String get workoutVoiceGender {
    final v = _safeBox.get(keyWorkoutVoiceGender, defaultValue: 'female');
    final raw = v?.toString().trim().toLowerCase() ?? 'female';
    if (raw == 'male' || raw == 'system') return raw;
    return 'female';
  }

  static bool get useLightTheme {
    final v = _safeBox.get(keyUseLightTheme, defaultValue: true);
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v == '1' || v == 'true';
  }

  /// `en` (default) or `de`.
  static String get appLocaleCode {
    final v = _safeBox.get(keyAppLocale, defaultValue: 'en')?.toString();
    if (v == 'de') return 'de';
    return 'en';
  }

  static bool get useGerman => appLocaleCode == 'de';

  static Future<void> setWorkoutVoiceEnabled(bool value) async {
    await _safeBox.put(keyWorkoutVoiceEnabled, value);
    _notifyChanged();
  }

  static Future<void> setWorkoutVoiceGender(String value) async {
    final raw = value.trim().toLowerCase();
    final stored = raw == 'male' || raw == 'system' ? raw : 'female';
    await _safeBox.put(keyWorkoutVoiceGender, stored);
    _notifyChanged();
  }

  static Future<void> setUseLightTheme(bool value) async {
    await _safeBox.put(keyUseLightTheme, value);
    _notifyChanged();
  }

  static Future<void> setAppLocaleCode(String code) async {
    await _safeBox.put(keyAppLocale, code == 'de' ? 'de' : 'en');
    _notifyChanged();
  }

  static Future<void> setUseGerman(bool value) async {
    await setAppLocaleCode(value ? 'de' : 'en');
  }

  static bool get hasSeenInstallHint {
    final v = _safeBox.get(keyHasSeenInstallHint, defaultValue: false);
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v == '1' || v == 'true';
  }

  static Future<void> setHasSeenInstallHint(bool value) async {
    await _safeBox.put(keyHasSeenInstallHint, value);
    _notifyChanged();
  }

  static bool get hasCompletedAppTour {
    final v = _safeBox.get(keyHasCompletedAppTour, defaultValue: false);
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v == '1' || v == 'true';
  }

  static Future<void> setHasCompletedAppTour(bool value) async {
    await _safeBox.put(keyHasCompletedAppTour, value);
    _notifyChanged();
  }

  /// One-time home intro (app tour + schedule/reminders). Missing key means
  /// a legacy install that already finished onboarding — treat as completed.
  static bool get hasCompletedHomeIntro {
    if (!_safeBox.containsKey(keyHasCompletedHomeIntro)) {
      return hasCompletedOnboarding;
    }
    final v = _safeBox.get(keyHasCompletedHomeIntro, defaultValue: false);
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v == '1' || v == 'true';
  }

  static bool get needsHomeIntro => !hasCompletedHomeIntro;

  static Future<void> setHasCompletedHomeIntro(bool value) async {
    await _safeBox.put(keyHasCompletedHomeIntro, value);
    _notifyChanged();
  }

  static Set<String> get seenBodyMapTabIntros {
    final raw = _safeBox.get(keyBodyMapTabIntrosSeen, defaultValue: const []);
    if (raw is List) {
      return raw.map((e) => e.toString()).toSet();
    }
    return <String>{};
  }

  static bool hasSeenBodyMapTabIntro(BodyMapViewMode mode) {
    return seenBodyMapTabIntros.contains(mode.name);
  }

  static Future<void> markBodyMapTabIntroSeen(BodyMapViewMode mode) async {
    final seen = seenBodyMapTabIntros..add(mode.name);
    await _safeBox.put(keyBodyMapTabIntrosSeen, seen.toList());
    _notifyChanged();
  }

  static int? get todaySteps {
    final today = _dateKey(DateTime.now());
    if (_safeBox.get(keyTodayStepsDate)?.toString() != today) return null;
    final raw = _safeBox.get(keyTodaySteps);
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  static DateTime? get todayStepsSyncedAt {
    final raw = _safeBox.get(keyTodayStepsSyncedAt)?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static Future<void> setTodaySteps(int steps, {DateTime? syncedAt}) async {
    final now = syncedAt ?? DateTime.now();
    final clamped = steps.clamp(0, 1000000);
    final dateKey = _dateKey(now);
    await _safeBox.put(keyTodaySteps, clamped);
    await _safeBox.put(keyTodayStepsDate, dateKey);
    await _safeBox.put(keyTodayStepsSyncedAt, now.toIso8601String());
    await _cacheStepsHistory(dateKey, clamped);
    _notifyChanged();
  }

  static Future<void> _cacheStepsHistory(String dateKey, int steps) async {
    final raw = _safeBox.get(keyStepsHistory, defaultValue: const {});
    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    map[dateKey] = steps;
    await _safeBox.put(keyStepsHistory, map);
  }

  static Future<void> setStepsForDay(DateTime day, int steps) async {
    await _cacheStepsHistory(_dateKey(day), steps.clamp(0, 1000000));
    _notifyChanged();
  }

  static int? stepsForDay(DateTime day) {
    final key = _dateKey(day);
    if (_safeBox.get(keyTodayStepsDate)?.toString() == key) {
      return todaySteps;
    }
    final raw = _safeBox.get(keyStepsHistory, defaultValue: const {});
    if (raw is! Map) return null;
    final value = raw[key];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static int? get lastNightSleepMinutes {
    final today = _dateKey(DateTime.now());
    if (_safeBox.get(keyLastNightSleepDate)?.toString() != today) return null;
    final raw = _safeBox.get(keyLastNightSleepMinutes);
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  static DateTime? get lastNightSleepSyncedAt {
    final raw = _safeBox.get(keyLastNightSleepSyncedAt)?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static Future<void> setLastNightSleep(
    int minutes, {
    DateTime? syncedAt,
  }) async {
    final now = syncedAt ?? DateTime.now();
    final wakeDay = DateTime(now.year, now.month, now.day);
    final clamped = minutes.clamp(0, 24 * 60);
    final dateKey = _dateKey(wakeDay);
    await _safeBox.put(keyLastNightSleepMinutes, clamped);
    await _safeBox.put(keyLastNightSleepDate, dateKey);
    await _safeBox.put(keyLastNightSleepSyncedAt, now.toIso8601String());
    await _cacheSleepHistory(dateKey, clamped);
    _notifyChanged();
  }

  static Future<void> _cacheSleepHistory(String dateKey, int minutes) async {
    final raw = _safeBox.get(keySleepHistory, defaultValue: const {});
    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    map[dateKey] = minutes;
    await _safeBox.put(keySleepHistory, map);
  }

  static Future<void> setSleepForWakeDay(DateTime wakeDay, int minutes) async {
    await _cacheSleepHistory(_dateKey(wakeDay), minutes.clamp(0, 24 * 60));
    _notifyChanged();
  }

  static int? sleepForWakeDay(DateTime wakeDay) {
    final key = _dateKey(wakeDay);
    if (_safeBox.get(keyLastNightSleepDate)?.toString() == key) {
      return lastNightSleepMinutes;
    }
    final raw = _safeBox.get(keySleepHistory, defaultValue: const {});
    if (raw is! Map) return null;
    final value = raw[key];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static List<int> recentSleepMinutes({int days = 7}) {
    final now = DateTime.now();
    return List<int>.generate(days, (index) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: days - 1 - index));
      return sleepForWakeDay(day) ?? 0;
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Gym workouts (Hive persisted)
  // Shape:
  // [
  //   {
  //     'id': 'g_...',
  //     'name': 'Push Day',
  //     'createdAt': ISO_STRING,
  //     'updatedAt': ISO_STRING,
  //     'exercises': [
  //        {'name': ..., 'description': ..., 'mainGroup': ..., 'tags': [...]},
  //     ],
  //   }
  // ]
  // ───────────────────────────────────────────────────────────────────────────

  static String? get lastGymWorkoutId {
    final v = (_safeBox.get(keyLastGymWorkoutId) as String?)?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  static List<Map<String, dynamic>> get gymWorkouts {
    final raw = _safeBox.get(keyGymWorkouts, defaultValue: const []);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e['id'] != null && e['name'] != null)
        .toList();
  }

  static Map<String, dynamic>? gymWorkoutById(String id) {
    for (final w in gymWorkouts) {
      if (w['id']?.toString() == id) return w;
    }
    return null;
  }

  static Future<String> createGymWorkout(String name) async {
    final now = DateTime.now().toIso8601String();
    final id = 'g_${DateTime.now().microsecondsSinceEpoch}';
    final next = gymWorkouts.toList();
    next.add({
      'id': id,
      'name': name.trim().isEmpty ? 'My Workout' : name.trim(),
      'createdAt': now,
      'updatedAt': now,
      'exercises': <Map<String, dynamic>>[],
    });
    await _safeBox.put(keyGymWorkouts, next);
    await _safeBox.put(keyLastGymWorkoutId, id);
    _notifyChanged();
    return id;
  }

  static Future<void> renameGymWorkout({
    required String workoutId,
    required String newName,
  }) async {
    final name = newName.trim();
    if (name.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final next = gymWorkouts.toList();
    for (var i = 0; i < next.length; i++) {
      if (next[i]['id']?.toString() != workoutId) continue;
      next[i] = {...next[i], 'name': name, 'updatedAt': now};
      break;
    }
    await _safeBox.put(keyGymWorkouts, next);
    _notifyChanged();
  }

  static Future<void> deleteGymWorkout(String workoutId) async {
    final next = gymWorkouts
        .where((w) => w['id']?.toString() != workoutId)
        .toList();
    await _safeBox.put(keyGymWorkouts, next);
    if (lastGymWorkoutId == workoutId) {
      await _safeBox.delete(keyLastGymWorkoutId);
    }
    _notifyChanged();
  }

  static Future<void> addExerciseToGymWorkout({
    required String workoutId,
    required Map<String, dynamic> exercise,
  }) async {
    final now = DateTime.now().toIso8601String();
    final next = gymWorkouts.toList();
    for (var i = 0; i < next.length; i++) {
      if (next[i]['id']?.toString() != workoutId) continue;
      final raw = next[i]['exercises'];
      final exercises = <Map<String, dynamic>>[];
      if (raw is List) {
        exercises.addAll(
          raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
      }
      exercises.add(
        StrengthExerciseConfig.applyDefaults({
          'name': exercise['name']?.toString() ?? 'Exercise',
          'description': exercise['description']?.toString() ?? '',
          'mainGroup': exercise['mainGroup']?.toString() ?? 'Other',
          'tags': (exercise['tags'] is List)
              ? List<String>.from(
                  (exercise['tags'] as List).map((e) => e.toString()),
                )
              : <String>[],
          for (final key in ['sets', 'setReps', 'setSeconds', 'weight'])
            if (exercise[key] != null) key: exercise[key],
          if (exercise['reps'] != null) 'reps': exercise['reps'],
        }),
      );
      next[i] = {...next[i], 'exercises': exercises, 'updatedAt': now};
      break;
    }
    await _safeBox.put(keyGymWorkouts, next);
    await _safeBox.put(keyLastGymWorkoutId, workoutId);
    _notifyChanged();
  }

  static Future<void> setGymWorkoutExercises({
    required String workoutId,
    required List<Map<String, dynamic>> exercises,
  }) async {
    if (exercises.isEmpty) {
      await deleteGymWorkout(workoutId);
      return;
    }
    final now = DateTime.now().toIso8601String();
    final next = gymWorkouts.toList();
    for (var i = 0; i < next.length; i++) {
      if (next[i]['id']?.toString() != workoutId) continue;
      next[i] = {...next[i], 'exercises': exercises, 'updatedAt': now};
      break;
    }
    await _safeBox.put(keyGymWorkouts, next);
    _notifyChanged();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Calisthenics workouts (Hive persisted) - same shape as gymWorkouts
  // ───────────────────────────────────────────────────────────────────────────

  static String? get lastCalisthenicsWorkoutId {
    final v = (_safeBox.get(keyLastCalisthenicsWorkoutId) as String?)?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  static List<Map<String, dynamic>> get calisthenicsWorkouts {
    final raw = _safeBox.get(keyCalisthenicsWorkouts, defaultValue: const []);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e['id'] != null && e['name'] != null)
        .toList();
  }

  static Map<String, dynamic>? calisthenicsWorkoutById(String id) {
    for (final w in calisthenicsWorkouts) {
      if (w['id']?.toString() == id) return w;
    }
    return null;
  }

  static Future<String> createCalisthenicsWorkout(String name) async {
    final now = DateTime.now().toIso8601String();
    final id = 'c_${DateTime.now().microsecondsSinceEpoch}';
    final next = calisthenicsWorkouts.toList();
    next.add({
      'id': id,
      'name': name.trim().isEmpty ? 'My Workout' : name.trim(),
      'createdAt': now,
      'updatedAt': now,
      'exercises': <Map<String, dynamic>>[],
    });
    await _safeBox.put(keyCalisthenicsWorkouts, next);
    await _safeBox.put(keyLastCalisthenicsWorkoutId, id);
    _notifyChanged();
    return id;
  }

  static Future<void> renameCalisthenicsWorkout({
    required String workoutId,
    required String newName,
  }) async {
    final name = newName.trim();
    if (name.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final next = calisthenicsWorkouts.toList();
    for (var i = 0; i < next.length; i++) {
      if (next[i]['id']?.toString() != workoutId) continue;
      next[i] = {...next[i], 'name': name, 'updatedAt': now};
      break;
    }
    await _safeBox.put(keyCalisthenicsWorkouts, next);
    _notifyChanged();
  }

  static Future<void> deleteCalisthenicsWorkout(String workoutId) async {
    final next = calisthenicsWorkouts
        .where((w) => w['id']?.toString() != workoutId)
        .toList();
    await _safeBox.put(keyCalisthenicsWorkouts, next);
    if (lastCalisthenicsWorkoutId == workoutId) {
      await _safeBox.delete(keyLastCalisthenicsWorkoutId);
    }
    _notifyChanged();
  }

  static Future<void> addExerciseToCalisthenicsWorkout({
    required String workoutId,
    required Map<String, dynamic> exercise,
  }) async {
    final now = DateTime.now().toIso8601String();
    final next = calisthenicsWorkouts.toList();
    for (var i = 0; i < next.length; i++) {
      if (next[i]['id']?.toString() != workoutId) continue;
      final raw = next[i]['exercises'];
      final exercises = <Map<String, dynamic>>[];
      if (raw is List) {
        exercises.addAll(
          raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
      }
      exercises.add(
        StrengthExerciseConfig.applyDefaults({
          'name': exercise['name']?.toString() ?? 'Exercise',
          'description': exercise['description']?.toString() ?? '',
          'mainGroup': exercise['mainGroup']?.toString() ?? 'Other',
          'tags': (exercise['tags'] is List)
              ? List<String>.from(
                  (exercise['tags'] as List).map((e) => e.toString()),
                )
              : <String>[],
          for (final key in ['sets', 'setReps', 'setSeconds', 'weight'])
            if (exercise[key] != null) key: exercise[key],
          if (exercise['reps'] != null) 'reps': exercise['reps'],
        }),
      );
      next[i] = {...next[i], 'exercises': exercises, 'updatedAt': now};
      break;
    }
    await _safeBox.put(keyCalisthenicsWorkouts, next);
    await _safeBox.put(keyLastCalisthenicsWorkoutId, workoutId);
    _notifyChanged();
  }

  static Future<void> setCalisthenicsWorkoutExercises({
    required String workoutId,
    required List<Map<String, dynamic>> exercises,
  }) async {
    if (exercises.isEmpty) {
      await deleteCalisthenicsWorkout(workoutId);
      return;
    }
    final now = DateTime.now().toIso8601String();
    final next = calisthenicsWorkouts.toList();
    for (var i = 0; i < next.length; i++) {
      if (next[i]['id']?.toString() != workoutId) continue;
      next[i] = {...next[i], 'exercises': exercises, 'updatedAt': now};
      break;
    }
    await _safeBox.put(keyCalisthenicsWorkouts, next);
    _notifyChanged();
  }

  /// Adds an AI-generated reusable routine with a stored calorie estimate.
  static Future<({String id, int calories, int durationSeconds})>
  saveAiWorkout({
    required String sourceId,
    required String name,
    required String category,
    required List<Map<String, dynamic>> exercises,
    String targetId = '',
    String? sourceUrl,
  }) async {
    final receiptKey = _aiActionReceiptKey(sourceId);
    final previous = _safeBox.get(receiptKey)?.toString();
    if (previous != null && previous.isNotEmpty) {
      final existing =
          gymWorkoutById(previous) ?? calisthenicsWorkoutById(previous);
      return (
        id: previous,
        calories: _readEntryInt(existing?['estimatedCalories']),
        durationSeconds: _readEntryInt(existing?['estimatedDurationSeconds']),
      );
    }
    if (sourceId.isEmpty ||
        sourceId.length > 120 ||
        name.trim().isEmpty ||
        !{'gym', 'calisthenics'}.contains(category) ||
        exercises.isEmpty ||
        exercises.length > 30) {
      throw ArgumentError('Invalid AI workout');
    }
    final existing = targetId.isEmpty
        ? null
        : (category == 'gym'
              ? gymWorkoutById(targetId)
              : calisthenicsWorkoutById(targetId));
    if (targetId.isNotEmpty && existing == null) {
      throw StateError('Workout no longer exists');
    }
    final oldExercises = (existing?['exercises'] as List? ?? [])
        .whereType<Map>();
    final normalized = exercises
        .map((exercise) {
          final sets = _readEntryInt(exercise['sets']).clamp(1, 100);
          final reps = _readEntryInt(exercise['reps']).clamp(1, 999);
          final old = oldExercises
              .where(
                (e) =>
                    e['name']?.toString().toLowerCase() ==
                    exercise['name']?.toString().toLowerCase(),
              )
              .firstOrNull;
          final keepReps =
              old != null &&
              _readEntryInt(old['sets']) == sets &&
              _readEntryInt(old['reps']) == reps &&
              old['setReps'] is List;
          return <String, dynamic>{
            if (old != null)
              ...(Map<String, dynamic>.from(old)..remove('setSeconds')),
            ...exercise,
            'description': {
              old?['description']?.toString() ?? '',
              exercise['description']?.toString() ?? '',
            }.where((s) => s.isNotEmpty).join('\n'),
            'sets': sets,
            'reps': reps,
            'setReps': keepReps
                ? List<dynamic>.from(old['setReps'] as List)
                : List<int>.filled(sets, reps),
            'tags': (exercise['tags'] is List)
                ? List<String>.from(
                    (exercise['tags'] as List).map((e) => e.toString()),
                  )
                : <String>[],
          };
        })
        .toList(growable: false);
    final burn = CalorieBurnService.strengthSession(exercises: normalized);
    final now = DateTime.now().toIso8601String();
    final id = targetId.isNotEmpty
        ? targetId
        : category == 'gym'
        ? 'ai_g_$sourceId'
        : 'ai_c_$sourceId';
    final entry = <String, dynamic>{
      ...?existing,
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
      'id': id,
      'name': name.trim(),
      'createdAt': existing?['createdAt'] ?? now,
      'updatedAt': now,
      'aiGenerated': true,
      'aiSourceId': sourceId,
      'estimatedCalories': burn.totalKcal,
      'estimatedDurationSeconds': burn.durationSeconds,
      'muscleGroups': normalized
          .expand(
            (exercise) => [
              exercise['mainGroup']?.toString() ?? '',
              ...(exercise['tags'] as List).map((tag) => tag.toString()),
            ],
          )
          .where((group) => group.isNotEmpty)
          .toSet()
          .toList(),
      'exercises': normalized,
    };
    final isGym = category == 'gym';
    final all = isGym ? gymWorkouts : calisthenicsWorkouts;
    final next = all.where((workout) => workout['id'] != id).toList()
      ..add(entry);
    await _safeBox.putAll({
      (isGym ? keyGymWorkouts : keyCalisthenicsWorkouts): next,
      receiptKey: id,
      if (isGym) keyLastGymWorkoutId: id,
      if (!isGym) keyLastCalisthenicsWorkoutId: id,
    });
    _notifyChanged();
    return (
      id: id,
      calories: burn.totalKcal,
      durationSeconds: burn.durationSeconds,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Running routes (Hive persisted)
  //
  // Shape:
  // [
  //   {
  //     'id': 'r_...',
  //     'name': 'Park-Runde',
  //     'createdAt': ISO_STRING,
  //     'distanceMeters': double,
  //     'ascentMeters': double,
  //     'descentMeters': double,
  //     // Decoded route polyline (lat, lon pairs).
  //     'points': [[lat, lon], ...],
  //     // Original waypoints the user picked (lat, lon pairs).
  //     'waypoints': [[lat, lon], ...],
  //   }
  // ]
  // ───────────────────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> get runningRoutes {
    final raw = _safeBox.get(keyRunningRoutes, defaultValue: const []);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e['id'] != null && e['name'] != null)
        .toList();
  }

  static Map<String, dynamic>? runningRouteById(String id) {
    for (final r in runningRoutes) {
      if (r['id']?.toString() == id) return r;
    }
    return null;
  }

  static Future<String> saveRunningRoute({
    required String name,
    required double distanceMeters,
    required double ascentMeters,
    required double descentMeters,
    required List<List<double>> points,
    required List<List<double>> waypoints,
    List<Map<String, dynamic>> steps = const [],
    Map<String, dynamic>? activity,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = 'r_${DateTime.now().microsecondsSinceEpoch}';
    final next = runningRoutes.toList();
    next.add({
      'id': id,
      'name': name.trim().isEmpty ? 'Neue Route' : name.trim(),
      'createdAt': now,
      'distanceMeters': distanceMeters,
      'ascentMeters': ascentMeters,
      'descentMeters': descentMeters,
      'points': points,
      'waypoints': waypoints,
      // steps: [{ 'instruction': str, 'distanceMeters': num, 'endIndex': int }]
      'steps': steps,
      if (activity != null) 'activity': activity,
    });
    await _safeBox.put(keyRunningRoutes, next);
    _notifyChanged();
    return id;
  }

  static Future<void> renameRunningRoute({
    required String routeId,
    required String newName,
  }) async {
    final name = newName.trim();
    if (name.isEmpty) return;
    final next = runningRoutes.toList();
    for (var i = 0; i < next.length; i++) {
      if (next[i]['id']?.toString() != routeId) continue;
      next[i] = {...next[i], 'name': name};
      break;
    }
    await _safeBox.put(keyRunningRoutes, next);
    _notifyChanged();
  }

  static Future<void> deleteRunningRoute(String routeId) async {
    final next = runningRoutes
        .where((r) => r['id']?.toString() != routeId)
        .toList();
    await _safeBox.put(keyRunningRoutes, next);
    _notifyChanged();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Food dishes (Hive persisted)
  //
  // Shape:
  // [
  //   {
  //     'id': 'd_...',
  //     'name': 'Bowl',
  //     'createdAt': ISO_STRING,
  //     'updatedAt': ISO_STRING,
  //     // Each item stores absolute (already grams-scaled) macro values.
  //     'description': 'Optional notes / preparation steps',
  //     'items': [
  //       {
  //         'foodName': 'Eier',
  //         'grams': 150,
  //         'proteinG': 19.5,
  //         'carbsG': 1.5,
  //         'fatsG': 16.5,
  //       },
  //       ...
  //     ],
  //   }
  // ]
  // kcal is computed on read (4/4/9 rule).
  // ───────────────────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> get foodDishes {
    final raw = _safeBox.get(keyFoodDishes, defaultValue: const []);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e['id'] != null && e['name'] != null)
        .toList();
  }

  static Map<String, dynamic>? foodDishById(String id) {
    for (final d in foodDishes) {
      if (d['id']?.toString() == id) return d;
    }
    return null;
  }

  static Future<String> createFoodDish(String name) async {
    final now = DateTime.now().toIso8601String();
    final id = 'd_${DateTime.now().microsecondsSinceEpoch}';
    final next = foodDishes.toList();
    next.add({
      'id': id,
      'name': name.trim().isEmpty ? 'Neues Gericht' : name.trim(),
      'createdAt': now,
      'updatedAt': now,
      'items': <Map<String, dynamic>>[],
    });
    await _safeBox.put(keyFoodDishes, next);
    _notifyChanged();
    return id;
  }

  /// Saves an AI-created recipe in the user's dish library exactly once.
  /// Macro totals are retained and extra/micronutrients are stored from the
  /// app's local food-family estimator so the dish detail can show them.
  static Future<String> saveAiFoodDish({
    required String sourceId,
    required MealDraft meal,
    String targetId = '',
  }) async {
    final receiptKey = _aiActionReceiptKey(sourceId);
    final previous = _safeBox.get(receiptKey)?.toString();
    if (previous != null && previous.isNotEmpty) return previous;
    if (sourceId.isEmpty ||
        sourceId.length > 120 ||
        meal.name.trim().isEmpty ||
        meal.name.length > 120 ||
        meal.foods.isEmpty ||
        meal.foods.length > 30 ||
        meal.foods.any((food) => !food.isValid)) {
      throw ArgumentError('Invalid AI recipe');
    }

    final now = DateTime.now().toIso8601String();
    final existing = targetId.isEmpty ? null : foodDishById(targetId);
    if (targetId.isNotEmpty && existing == null) {
      throw StateError('Dish no longer exists');
    }
    final id = targetId.isEmpty ? 'ai_d_$sourceId' : targetId;
    final items = meal.foods
        .map((food) {
          final estimated = FoodNutrientEstimator.forPortion(
            name: food.name,
            grams: food.grams,
            proteinG: food.proteinG,
            carbsG: food.carbsG,
            fatsG: food.fatsG,
          );
          return <String, dynamic>{
            'foodName': food.name,
            'grams': food.grams,
            'proteinG': food.proteinG,
            'carbsG': food.carbsG,
            'fatsG': food.fatsG,
            ...estimated.toStorageFields(),
            'micros': estimated.micros,
            'aminos': estimated.aminos,
          };
        })
        .toList(growable: false);
    final details = [
      meal.recipe.trim(),
      if (meal.assumptions.trim().isNotEmpty)
        'Estimated portions and nutrients: ${meal.assumptions.trim()}',
      'Nutrition values are estimates.',
    ].where((value) => value.isNotEmpty).join('\n\n');
    final next = foodDishes.where((dish) => dish['id'] != id).toList();
    next.add({
      ...?existing,
      'id': id,
      'name': meal.name.trim(),
      'description': details,
      'createdAt': existing?['createdAt'] ?? now,
      'updatedAt': now,
      'aiGenerated': true,
      'aiSourceId': sourceId,
      'items': items,
    });
    await _safeBox.putAll({keyFoodDishes: next, receiptKey: id});
    _notifyChanged();
    return id;
  }

  /// Adds built-in meal templates once (chicken rice bowl, menemen, etc.).
  static Future<void> ensureStandardFoodDishes() async {
    final existing = foodDishes;
    final existingPresetIds = existing
        .map((d) => d['presetId']?.toString())
        .whereType<String>()
        .toSet();
    final next = existing.toList();
    var changed = false;
    final now = DateTime.now().toIso8601String();

    for (final preset in standardFoodDishes) {
      if (existingPresetIds.contains(preset.id)) continue;
      next.add({
        'id': preset.id,
        'presetId': preset.id,
        'preset': true,
        'name': preset.nameDe,
        'description': preset.descriptionDe,
        'createdAt': now,
        'updatedAt': now,
        'items': preset.items.map((item) => item.toJson()).toList(),
      });
      changed = true;
    }

    if (changed) {
      await _safeBox.put(keyFoodDishes, next);
      _notifyChanged();
    }
  }

  static String _dishPhotoKey(String dishId) => 'dish_photo_$dishId';

  static Uint8List? foodDishPhoto(String dishId) =>
      _safeBox.get(_dishPhotoKey(dishId)) as Uint8List?;

  static Future<void> saveFoodDishPhoto(String dishId, Uint8List bytes) async {
    if (foodDishById(dishId) == null) return;
    await _safeBox.put(_dishPhotoKey(dishId), bytes);
    _notifyChanged();
  }

  static Future<void> updateFoodDishDescription({
    required String dishId,
    required String description,
  }) async {
    final now = DateTime.now().toIso8601String();
    final next = foodDishes.toList();
    for (var i = 0; i < next.length; i++) {
      if (next[i]['id']?.toString() != dishId) continue;
      next[i] = {
        ...next[i],
        'description': description.trim(),
        'updatedAt': now,
      };
      break;
    }
    await _safeBox.put(keyFoodDishes, next);
    _notifyChanged();
  }

  static Future<void> renameFoodDish({
    required String dishId,
    required String newName,
  }) async {
    final name = newName.trim();
    if (name.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final next = foodDishes.toList();
    for (var i = 0; i < next.length; i++) {
      if (next[i]['id']?.toString() != dishId) continue;
      next[i] = {...next[i], 'name': name, 'updatedAt': now};
      break;
    }
    await _safeBox.put(keyFoodDishes, next);
    _notifyChanged();
  }

  static Future<void> deleteFoodDish(String dishId) async {
    final next = foodDishes
        .where((d) => d['id']?.toString() != dishId)
        .toList();
    await _safeBox.put(keyFoodDishes, next);
    await _safeBox.delete(_dishPhotoKey(dishId));
    _notifyChanged();
  }

  static Future<void> addItemToFoodDish({
    required String dishId,
    required String foodName,
    required double grams,
    required double proteinG,
    required double carbsG,
    required double fatsG,
  }) async {
    final now = DateTime.now().toIso8601String();
    final next = foodDishes.toList();
    for (var i = 0; i < next.length; i++) {
      if (next[i]['id']?.toString() != dishId) continue;
      final raw = next[i]['items'];
      final items = <Map<String, dynamic>>[];
      if (raw is List) {
        items.addAll(
          raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
      }
      items.add({
        'foodName': foodName,
        'grams': grams,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatsG': fatsG,
        ...FoodNutrientEstimator.forPortion(
          name: foodName,
          grams: grams,
          proteinG: proteinG,
          carbsG: carbsG,
          fatsG: fatsG,
        ).toStorageFields(),
      });
      next[i] = {...next[i], 'items': items, 'updatedAt': now};
      break;
    }
    await _safeBox.put(keyFoodDishes, next);
    _notifyChanged();
  }

  static Future<void> removeItemFromFoodDish({
    required String dishId,
    required int itemIndex,
  }) async {
    final now = DateTime.now().toIso8601String();
    final next = foodDishes.toList();
    for (var i = 0; i < next.length; i++) {
      if (next[i]['id']?.toString() != dishId) continue;
      final raw = next[i]['items'];
      final items = <Map<String, dynamic>>[];
      if (raw is List) {
        items.addAll(
          raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
      }
      if (itemIndex < 0 || itemIndex >= items.length) return;
      items.removeAt(itemIndex);
      next[i] = {...next[i], 'items': items, 'updatedAt': now};
      break;
    }
    await _safeBox.put(keyFoodDishes, next);
    _notifyChanged();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Food intake (per-day log of eaten foods and dishes)
  //
  // Shape:
  // [
  //   {
  //     'id': 'fi_...',
  //     'recordedAt': ISO_STRING,
  //     'kind': 'food' | 'dish',
  //     'name': 'Eier' | 'Frühstücks-Bowl',
  //     'grams': 100.0,        // null for dishes (items have grams instead)
  //     'proteinG': 12.5,
  //     'carbsG': 1.1,
  //     'fatsG': 11.0,
  //     'dishId': 'd_...',     // when kind == 'dish'
  //     'items': [             // ingredient snapshot for dishes
  //       {'foodName': 'Eier', 'grams': 100, 'proteinG': 12.5,
  //        'carbsG': 1.1, 'fatsG': 11.0},
  //       ...
  //     ],
  //   }
  // ]
  // ───────────────────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> get foodIntake {
    final raw = _safeBox.get(keyFoodIntake, defaultValue: const []);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e['recordedAt'] != null)
        .toList();
  }

  static List<Map<String, dynamic>> foodIntakeForDay(DateTime day) {
    final key = _dateKey(day);
    return foodIntake.where((e) {
      final at = DateTime.tryParse(e['recordedAt']?.toString() ?? '');
      if (at == null) return false;
      return _dateKey(at) == key;
    }).toList()..sort(
      (a, b) => (a['recordedAt'] ?? '').toString().compareTo(
        (b['recordedAt'] ?? '').toString(),
      ),
    );
  }

  /// Average daily macros over the last [days] calendar days (inclusive of today).
  static FoodNutrients foodAverageDailyNutrientsLastDays(int days) {
    if (days <= 0) return const FoodNutrients();
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    var sum = const FoodNutrients();
    for (var i = 0; i < days; i++) {
      sum += foodNutrientsForDay(start.subtract(Duration(days: i)));
    }
    return sum.scaled(1 / days);
  }

  /// Workout events within the last [days] calendar days (inclusive of today).
  static List<Map<String, dynamic>> workoutEventsLastDays(int days) {
    if (days <= 0) return const [];
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: days - 1));
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);
    final list = workoutEvents.where((e) {
      final at = DateTime.tryParse(e['recordedAt']?.toString() ?? '');
      if (at == null) return false;
      return !at.isBefore(start) && !at.isAfter(end);
    }).toList();
    list.sort(
      (a, b) => (b['recordedAt'] ?? '').toString().compareTo(
        (a['recordedAt'] ?? '').toString(),
      ),
    );
    return list;
  }

  /// Totals (kcal, protein/carbs/fats plus extra macros) for the entries on [day].
  static FoodNutrients foodNutrientsForDay(DateTime day) {
    var sum = const FoodNutrients();
    for (final e in foodIntakeForDay(day)) {
      sum += _nutrientsForIntakeEntry(e);
    }
    return sum;
  }

  static FoodNutrients _nutrientsForIntakeEntry(Map<String, dynamic> e) {
    final stored = FoodNutrients.fromMap(e);
    final items = e['items'];
    if (items is List && items.isNotEmpty) {
      var estimated = const FoodNutrients();
      for (final entry in items.whereType<Map>()) {
        final m = Map<String, dynamic>.from(entry);
        estimated += FoodNutrientEstimator.forPortion(
          name: m['foodName']?.toString() ?? '',
          grams: _readEntryDouble(m['grams']) > 0
              ? _readEntryDouble(m['grams'])
              : 100,
          proteinG: _readEntryDouble(m['proteinG']),
          carbsG: _readEntryDouble(m['carbsG']),
          fatsG: _readEntryDouble(m['fatsG']),
        );
      }
      return _mergeStoredMacros(stored, estimated);
    }
    final name = e['name']?.toString() ?? '';
    final grams = _readEntryDouble(e['grams']);
    final estimated = FoodNutrientEstimator.forPortion(
      name: name,
      grams: grams > 0 ? grams : 100,
      proteinG: stored.proteinG,
      carbsG: stored.carbsG,
      fatsG: stored.fatsG,
    );
    return _mergeStoredMacros(stored, estimated);
  }

  static FoodNutrients _mergeStoredMacros(
    FoodNutrients stored,
    FoodNutrients estimated,
  ) {
    return FoodNutrients(
      proteinG: stored.proteinG,
      carbsG: stored.carbsG,
      fatsG: stored.fatsG,
      fiberG: stored.fiberG > 0 ? stored.fiberG : estimated.fiberG,
      sugarG: stored.sugarG > 0 ? stored.sugarG : estimated.sugarG,
      satFatG: stored.satFatG > 0 ? stored.satFatG : estimated.satFatG,
      cholesterolMg: stored.cholesterolMg > 0
          ? stored.cholesterolMg
          : estimated.cholesterolMg,
      sodiumMg: stored.sodiumMg > 0 ? stored.sodiumMg : estimated.sodiumMg,
      micros: estimated.micros,
      aminos: estimated.aminos,
    );
  }

  /// Totals (kcal, protein/carbs/fats in grams) for the entries on [day].
  static ({int kcal, double p, double c, double f}) foodTotalsForDay(
    DateTime day,
  ) {
    final n = foodNutrientsForDay(day);
    return (kcal: n.kcal, p: n.proteinG, c: n.carbsG, f: n.fatsG);
  }

  /// Convenience getter for today's totals.
  static ({int kcal, double p, double c, double f}) get todayFoodTotals =>
      foodTotalsForDay(DateTime.now());

  /// Default window for profile analytics charts (days, inclusive of today).
  static const int profileAnalyticsDays = 30;

  static DateTime _analyticsDayStart(int days) {
    final today = DateTime.now();
    return DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: days - 1));
  }

  static DateTime? get _storedProfileAnalyticsStart {
    final raw = _safeBox.get(keyProfileAnalyticsStart)?.toString();
    if (raw == null || raw.isEmpty) return null;
    return _dateFromKey(raw);
  }

  /// First day shown on profile charts — today on first launch, then grows right.
  static DateTime get profileAnalyticsTrackingStart {
    final stored = _storedProfileAnalyticsStart;
    if (stored != null) return stored;
    return profileAnalyticsRangeEnd;
  }

  static DateTime get profileAnalyticsRangeEnd {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day);
  }

  static DateTime get profileAnalyticsRangeStart {
    final end = profileAnalyticsRangeEnd;
    final tracking = profileAnalyticsTrackingStart;
    final maxLookback = end.subtract(Duration(days: profileAnalyticsDays - 1));
    final start = tracking.isBefore(maxLookback) ? maxLookback : tracking;
    return DateTime(start.year, start.month, start.day);
  }

  static int get profileAnalyticsVisibleDayCount {
    final start = profileAnalyticsRangeStart;
    final end = profileAnalyticsRangeEnd;
    return end.difference(start).inDays + 1;
  }

  static List<AnalyticsChartPoint> dailyAnalyticsSeries(
    double Function(DateTime day) valueForDay,
  ) {
    final count = profileAnalyticsVisibleDayCount;
    if (count <= 0) return const [];
    final start = profileAnalyticsRangeStart;
    return List.generate(count, (i) {
      final day = DateTime(start.year, start.month, start.day + i);
      return (day: day, value: valueForDay(day));
    });
  }

  static List<AnalyticsChartPoint> weightAnalyticsSeries() {
    final count = profileAnalyticsVisibleDayCount;
    if (count <= 0) return const [];
    final start = profileAnalyticsRangeStart;
    final endExclusive = profileAnalyticsRangeEnd.add(const Duration(days: 1));
    final byDay = <DateTime, double>{};
    for (final entry in weightEntries) {
      final dateStr = entry['date']?.toString();
      final recordedAtRaw = entry['recordedAt']?.toString();
      final weightRaw = entry['weight'];
      if (dateStr == null) continue;
      final recordedAt =
          DateTime.tryParse(recordedAtRaw ?? '') ?? _dateFromKey(dateStr);
      if (recordedAt == null) continue;
      final day = DateTime(recordedAt.year, recordedAt.month, recordedAt.day);
      if (day.isBefore(start) || !day.isBefore(endExclusive)) continue;
      final weight = weightRaw is num
          ? weightRaw.toDouble()
          : double.tryParse(weightRaw.toString());
      if (weight == null) continue;
      byDay[day] = weight;
    }
    return List.generate(count, (i) {
      final day = DateTime(start.year, start.month, start.day + i);
      return (day: day, value: byDay[day] ?? 0);
    });
  }

  static List<AnalyticsChartPoint> stepsAnalyticsSeries() =>
      dailyAnalyticsSeries((day) => (stepsForDay(day) ?? 0).toDouble());

  static List<AnalyticsChartPoint> calorieIntakeAnalyticsSeries() =>
      dailyAnalyticsSeries((day) => foodTotalsForDay(day).kcal.toDouble());

  static List<AnalyticsChartPoint> calorieBurnAnalyticsSeries() =>
      dailyAnalyticsSeries((day) => totalBurnKcalForDay(day).toDouble());

  static List<AnalyticsChartPoint> waterAnalyticsSeries() =>
      dailyAnalyticsSeries((day) => waterMlForDay(day).toDouble());

  static List<AnalyticsChartPoint> proteinAnalyticsSeries() =>
      dailyAnalyticsSeries((day) => foodTotalsForDay(day).p);

  static List<AnalyticsChartPoint> fatAnalyticsSeries() =>
      dailyAnalyticsSeries((day) => foodTotalsForDay(day).f);

  static List<AnalyticsChartPoint> carbAnalyticsSeries() =>
      dailyAnalyticsSeries((day) => foodTotalsForDay(day).c);

  static List<AnalyticsChartPoint> workoutCountAnalyticsSeries() =>
      dailyAnalyticsSeries(
        (day) => workoutSessionsForDay(day).length.toDouble(),
      );

  static DateTime? _dateFromKey(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static double _readEntryDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  /// Adds a single food (grams-scaled) to the daily intake log.
  static Future<String> addFoodIntakeFood({
    required String name,
    required double grams,
    required double proteinG,
    required double carbsG,
    required double fatsG,
    double? fiberG,
    double? sugarG,
    double? satFatG,
    double? cholesterolMg,
    double? sodiumMg,
    DateTime? at,
  }) async {
    final extras = FoodNutrientEstimator.forPortion(
      name: name,
      grams: grams,
      proteinG: proteinG,
      carbsG: carbsG,
      fatsG: fatsG,
    );
    final id = 'fi_${DateTime.now().microsecondsSinceEpoch}';
    final recordedAt = (at ?? DateTime.now()).toIso8601String();
    final next = foodIntake.toList();
    next.add({
      'id': id,
      'recordedAt': recordedAt,
      'kind': 'food',
      'name': name,
      'grams': grams,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatsG': fatsG,
      'fiberG': fiberG ?? extras.fiberG,
      'sugarG': sugarG ?? extras.sugarG,
      'satFatG': satFatG ?? extras.satFatG,
      'cholesterolMg': cholesterolMg ?? extras.cholesterolMg,
      'sodiumMg': sodiumMg ?? extras.sodiumMg,
    });
    await _safeBox.put(keyFoodIntake, next);
    _notifyChanged();
    return id;
  }

  static List<Map<String, dynamic>> get supplementIntake {
    final raw = _safeBox.get(keySupplementIntake, defaultValue: const []);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  static const List<String> supplementSlots = ['morning', 'midday', 'evening'];

  static String normalizeSupplementSlot(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (supplementSlots.contains(v)) return v;
    return 'morning';
  }

  static List<Map<String, dynamic>> supplementIntakeForDay(DateTime day) {
    final key = _dateKey(day);
    final items = supplementIntake.where((e) {
      final at = DateTime.tryParse(e['recordedAt']?.toString() ?? '');
      if (at == null) return false;
      return _dateKey(at) == key;
    }).toList();
    items.sort((a, b) {
      final slotA = normalizeSupplementSlot(a['slot']?.toString());
      final slotB = normalizeSupplementSlot(b['slot']?.toString());
      final slotCmp = supplementSlots
          .indexOf(slotA)
          .compareTo(supplementSlots.indexOf(slotB));
      if (slotCmp != 0) return slotCmp;
      final orderA = (a['order'] is num)
          ? (a['order'] as num).toInt()
          : int.tryParse(a['order']?.toString() ?? '') ?? 0;
      final orderB = (b['order'] is num)
          ? (b['order'] as num).toInt()
          : int.tryParse(b['order']?.toString() ?? '') ?? 0;
      if (orderA != orderB) return orderA.compareTo(orderB);
      return (a['recordedAt']?.toString() ?? '').compareTo(
        b['recordedAt']?.toString() ?? '',
      );
    });
    return items;
  }

  static List<Map<String, dynamic>> get todaySupplementIntake =>
      supplementIntakeForDay(DateTime.now());

  static List<Map<String, dynamic>> todaySupplementsForSlot(String slot) {
    final normalized = normalizeSupplementSlot(slot);
    return todaySupplementIntake
        .where(
          (e) => normalizeSupplementSlot(e['slot']?.toString()) == normalized,
        )
        .toList(growable: false);
  }

  static Future<String> addSupplementIntake({
    required String name,
    required double mg,
    String slot = 'morning',
    DateTime? at,
  }) async {
    final id = 'sup_${DateTime.now().microsecondsSinceEpoch}';
    final recordedAt = (at ?? DateTime.now()).toIso8601String();
    final normalizedSlot = normalizeSupplementSlot(slot);
    final dayItems = supplementIntakeForDay(at ?? DateTime.now())
        .where(
          (e) =>
              normalizeSupplementSlot(e['slot']?.toString()) == normalizedSlot,
        )
        .toList();
    final nextOrder = dayItems.isEmpty
        ? 0
        : dayItems
                  .map(
                    (e) => (e['order'] is num)
                        ? (e['order'] as num).toInt()
                        : int.tryParse(e['order']?.toString() ?? '') ?? 0,
                  )
                  .fold<int>(0, (a, b) => a > b ? a : b) +
              1;
    final next = supplementIntake.toList();
    next.add({
      'id': id,
      'recordedAt': recordedAt,
      'name': name,
      'mg': mg.clamp(0, 1000000),
      'slot': normalizedSlot,
      'order': nextOrder,
    });
    await _safeBox.put(keySupplementIntake, next);
    _notifyChanged();
    return id;
  }

  static Future<void> removeSupplementIntake(String id) async {
    final next = supplementIntake
        .where((e) => e['id']?.toString() != id)
        .toList();
    await _safeBox.put(keySupplementIntake, next);
    _notifyChanged();
  }

  /// Moves a supplement into [targetSlot] at [targetIndex] within that slot
  /// for its recorded day (defaults to today).
  static Future<void> moveSupplementIntake({
    required String id,
    required String targetSlot,
    required int targetIndex,
  }) async {
    final all = supplementIntake.toList();
    final itemIndex = all.indexWhere((e) => e['id']?.toString() == id);
    if (itemIndex < 0) return;

    final item = Map<String, dynamic>.from(all[itemIndex]);
    final dayKey = _dateKey(
      DateTime.tryParse(item['recordedAt']?.toString() ?? '') ?? DateTime.now(),
    );
    final normalizedTarget = normalizeSupplementSlot(targetSlot);

    // Collect same-day items excluding the moved one, grouped by slot.
    final bySlot = <String, List<Map<String, dynamic>>>{
      for (final s in supplementSlots) s: <Map<String, dynamic>>[],
    };
    for (final e in all) {
      final eid = e['id']?.toString();
      if (eid == null || eid == id) continue;
      final at = DateTime.tryParse(e['recordedAt']?.toString() ?? '');
      if (at == null || _dateKey(at) != dayKey) continue;
      final slot = normalizeSupplementSlot(e['slot']?.toString());
      bySlot[slot]!.add(Map<String, dynamic>.from(e));
    }
    for (final slot in supplementSlots) {
      bySlot[slot]!.sort((a, b) {
        final orderA = (a['order'] is num)
            ? (a['order'] as num).toInt()
            : int.tryParse(a['order']?.toString() ?? '') ?? 0;
        final orderB = (b['order'] is num)
            ? (b['order'] as num).toInt()
            : int.tryParse(b['order']?.toString() ?? '') ?? 0;
        return orderA.compareTo(orderB);
      });
    }

    final targetList = bySlot[normalizedTarget]!;
    final insertAt = targetIndex.clamp(0, targetList.length);
    item['slot'] = normalizedTarget;
    targetList.insert(insertAt, item);

    for (final slot in supplementSlots) {
      final list = bySlot[slot]!;
      for (var i = 0; i < list.length; i++) {
        list[i]['order'] = i;
      }
    }

    // Rebuild full intake: keep other days untouched, replace same-day entries.
    final rebuilt = <Map<String, dynamic>>[];
    for (final e in all) {
      final at = DateTime.tryParse(e['recordedAt']?.toString() ?? '');
      if (at != null && _dateKey(at) == dayKey) continue;
      rebuilt.add(Map<String, dynamic>.from(e));
    }
    for (final slot in supplementSlots) {
      rebuilt.addAll(bySlot[slot]!);
    }

    await _safeBox.put(keySupplementIntake, rebuilt);
    _notifyChanged();
  }

  /// Adds an entire dish (with an ingredient snapshot) to the daily intake.
  static Future<String> addFoodIntakeDish({
    required String dishId,
    DateTime? at,
  }) async {
    final dish = foodDishById(dishId);
    if (dish == null) return '';
    final raw = dish['items'];
    final items = <Map<String, dynamic>>[];
    double p = 0, c = 0, f = 0;
    var extras = const FoodNutrients();
    if (raw is List) {
      for (final entry in raw.whereType<Map>()) {
        final m = Map<String, dynamic>.from(entry);
        final ip = _readEntryDouble(m['proteinG']);
        final ic = _readEntryDouble(m['carbsG']);
        final iff = _readEntryDouble(m['fatsG']);
        final grams = _readEntryDouble(m['grams']);
        p += ip;
        c += ic;
        f += iff;
        extras += FoodNutrientEstimator.forPortion(
          name: m['foodName']?.toString() ?? '',
          grams: grams > 0 ? grams : 100,
          proteinG: ip,
          carbsG: ic,
          fatsG: iff,
        );
        items.add({
          'foodName': m['foodName'],
          'grams': m['grams'],
          'proteinG': m['proteinG'],
          'carbsG': m['carbsG'],
          'fatsG': m['fatsG'],
        });
      }
    }
    final id = 'fi_${DateTime.now().microsecondsSinceEpoch}';
    final recordedAt = (at ?? DateTime.now()).toIso8601String();
    final next = foodIntake.toList();
    next.add({
      'id': id,
      'recordedAt': recordedAt,
      'kind': 'dish',
      'name': dish['name']?.toString() ?? 'Gericht',
      'dishId': dishId,
      'proteinG': p,
      'carbsG': c,
      'fatsG': f,
      'fiberG': extras.fiberG,
      'sugarG': extras.sugarG,
      'satFatG': extras.satFatG,
      'cholesterolMg': extras.cholesterolMg,
      'sodiumMg': extras.sodiumMg,
      'items': items,
    });
    await _safeBox.put(keyFoodIntake, next);
    _notifyChanged();
    return id;
  }

  static Future<void> removeFoodIntake(String entryId) async {
    final next = foodIntake
        .where((e) => e['id']?.toString() != entryId)
        .toList();
    await _safeBox.put(keyFoodIntake, next);
    _notifyChanged();
  }

  /// Validate every target before changing the log; never partially apply a
  /// stale proposal. The receipt makes retrying a saved chat action harmless.
  static Future<void> changeChatFoodEntries({
    required String sourceId,
    required List<String> entryIds,
    MealDraft? replacement,
  }) async {
    if (hasAiChatAction(sourceId)) return;
    final ids = entryIds.toSet();
    if (ids.isEmpty || ids.length > 60 || ids.length != entryIds.length) {
      throw ArgumentError('Invalid food entry IDs');
    }
    final all = foodIntake;
    final targets = all.where((e) => ids.contains(e['id'])).toList();
    if (targets.length != ids.length) {
      throw StateError('Food entry no longer exists');
    }
    final next = all.where((e) => !ids.contains(e['id'])).toList();
    if (replacement != null) {
      final dates = targets
          .map((e) => DateTime.tryParse(e['recordedAt']?.toString() ?? ''))
          .toList();
      if (dates.any((d) => d == null) ||
          dates.map((d) => _dateKey(d!)).toSet().length != 1 ||
          replacement.foods.isEmpty ||
          replacement.foods.length > 30 ||
          replacement.foods.any((f) => !f.isValid)) {
        throw ArgumentError('Invalid food replacement');
      }
      for (var i = 0; i < replacement.foods.length; i++) {
        next.add({
          'id': 'ai_edit_${sourceId}_$i',
          'recordedAt': targets.first['recordedAt'],
          'kind': 'food',
          ...replacement.foods[i].toJson(),
          'source': 'ai_estimate',
          'chatSourceId': sourceId,
        });
      }
    }
    await _safeBox.putAll({
      keyFoodIntake: next,
      _aiActionReceiptKey(sourceId): DateTime.now().toIso8601String(),
    });
    _notifyChanged();
  }

  static int get homeOpens =>
      (_safeBox.get(keyHomeOpens, defaultValue: 0) as int);

  static Future<void> markHomeOpened() async {
    final opens = homeOpens;
    final updates = <String, dynamic>{keyHomeOpens: opens + 1};
    if (_storedProfileAnalyticsStart == null) {
      final start = opens == 0
          ? DateTime.now()
          : _analyticsDayStart(profileAnalyticsDays);
      updates[keyProfileAnalyticsStart] = _dateKey(start);
    }
    // Queue both values before yielding: closing the store can otherwise
    // interrupt the second read/write after the Home counter has been saved.
    await _safeBox.putAll(updates);
    _notifyChanged();
  }

  static String? get lastCategory => _safeBox.get(keyLastCategory) as String?;

  static String get profileName {
    final saved = (_safeBox.get(keyProfileName, defaultValue: '') as String)
        .trim();
    return saved.isEmpty ? 'Athlete' : saved;
  }

  static bool get hasProfileName {
    final saved = (_safeBox.get(keyProfileName, defaultValue: '') as String)
        .trim();
    return saved.isNotEmpty;
  }

  static int get userLevel {
    final raw = _safeBox.get(keyUserLevel, defaultValue: 0);
    final value = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
    if (value <= 0) return 0;
    if (value >= 10000) return 10000;
    return value;
  }

  static Future<void> setUserLevel(int value) async {
    final clamped = value.clamp(0, 10000);
    await _safeBox.put(keyUserLevel, clamped);
    _notifyChanged();
  }

  static Future<void> addUserLevel(int delta) async {
    if (delta == 0) return;
    final next = (userLevel + delta).clamp(0, 10000);
    await _safeBox.put(keyUserLevel, next);
    _notifyChanged();
  }

  static int get totalGymWorkoutsCompleted =>
      (_safeBox.get(keyTotalGymWorkoutsCompleted, defaultValue: 0) as int);

  static int get totalCalisthenicsWorkoutsCompleted =>
      (_safeBox.get(keyTotalCalisthenicsWorkoutsCompleted, defaultValue: 0)
          as int);

  static Set<String> get earnedBadges {
    final raw = _safeBox.get(keyEarnedBadges, defaultValue: const []);
    if (raw is List) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toSet();
    }
    return <String>{};
  }

  static Future<void> _addBadge(String badgeId) async {
    final id = badgeId.trim();
    if (id.isEmpty) return;
    final next = earnedBadges;
    if (!next.add(id)) return;
    await _safeBox.put(keyEarnedBadges, next.toList()..sort());
    _notifyChanged();
  }

  static Future<void> _addBadges(Iterable<String> badgeIds) async {
    final next = earnedBadges;
    var changed = false;
    for (final raw in badgeIds) {
      final id = raw.trim();
      if (id.isEmpty) continue;
      if (next.add(id)) changed = true;
    }
    if (!changed) return;
    await _safeBox.put(keyEarnedBadges, next.toList()..sort());
    _notifyChanged();
  }

  static Future<void> markGymWorkoutCompleted() async {
    await _safeBox.put(
      keyTotalGymWorkoutsCompleted,
      totalGymWorkoutsCompleted + 1,
    );
    _notifyChanged();
  }

  static Future<void> markCalisthenicsWorkoutCompleted() async {
    await _safeBox.put(
      keyTotalCalisthenicsWorkoutsCompleted,
      totalCalisthenicsWorkoutsCompleted + 1,
    );
    _notifyChanged();
  }

  static int get workoutStreakDays =>
      (_safeBox.get(keyWorkoutStreakDays, defaultValue: 0) as int);

  static int categoryOpenCount(String categoryId) {
    return (_safeBox.get('$_categoryPrefix$categoryId', defaultValue: 0)
        as int);
  }

  static Future<void> markCategoryOpened(String categoryId) async {
    final key = '$_categoryPrefix$categoryId';
    final current = (_safeBox.get(key, defaultValue: 0) as int);
    await _safeBox.put(key, current + 1);
    // Food should not affect the "Start now" last-workout shortcut.
    if (categoryId != 'food') {
      await _safeBox.put(keyLastCategory, categoryId);
    }
    _notifyChanged();
  }

  static Future<void> setProfileName(String name) async {
    await _safeBox.put(keyProfileName, name.trim());
    _notifyChanged();
  }

  static String? get profileAvatarPath {
    final value = (_safeBox.get(keyProfileAvatarPath) as String?)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static Future<void> setProfileAvatarPath(String? path) async {
    await _putNullable(keyProfileAvatarPath, path?.trim());
  }

  /// Optional user-supplied background image for the hero card on the start
  /// screen. When null/empty, the default gendered hero asset is used.
  static String? get heroBackgroundPath {
    final value = (_safeBox.get(keyHeroBackgroundPath) as String?)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static Future<void> setHeroBackgroundPath(String? path) async {
    await _putNullable(keyHeroBackgroundPath, path?.trim());
  }

  static List<Map<String, dynamic>> get profileGalleryItems {
    final raw = _safeBox.get(keyProfileGalleryItems, defaultValue: const []);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['path'] != null && e['createdAt'] != null)
          .toList()
        ..sort(
          (a, b) =>
              b['createdAt'].toString().compareTo(a['createdAt'].toString()),
        );
    }
    return const [];
  }

  static Future<void> addProfileGalleryItem({
    required String path,
    required DateTime createdAt,
  }) async {
    final items = profileGalleryItems.toList();
    items.add({'path': path, 'createdAt': createdAt.toIso8601String()});
    items.sort(
      (a, b) => b['createdAt'].toString().compareTo(a['createdAt'].toString()),
    );
    await _safeBox.put(keyProfileGalleryItems, items);
    _notifyChanged();
  }

  static Future<void> setWorkoutStreakDays(int days) async {
    await _safeBox.put(keyWorkoutStreakDays, days);
    _notifyChanged();
  }

  static Future<void> markWorkoutCompletedToday() async {
    final now = DateTime.now();
    final todayKey = _dateKey(now);

    // Always record the completion day for the calendar UI.
    final completed = _completedWorkoutDays;
    if (completed.add(todayKey)) {
      await _safeBox.put(keyWorkoutCompletedDays, completed.toList()..sort());
    }

    final lastDay =
        (_safeBox.get(keyLastWorkoutDay, defaultValue: '') as String);
    if (lastDay == todayKey) {
      _notifyChanged();
      return;
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayKey = _dateKey(yesterday);
    final nextStreak = lastDay == yesterdayKey ? workoutStreakDays + 1 : 1;

    await _safeBox.put(keyWorkoutStreakDays, nextStreak);
    await _safeBox.put(keyLastWorkoutDay, todayKey);

    // Streak bonus levels (only granted when the streak increases to the threshold).
    final bonus = switch (nextStreak) {
      10 => 1,
      30 => 30,
      100 => 50,
      365 => 300,
      1000 => 1000,
      _ => 0,
    };
    if (bonus > 0) {
      await addUserLevel(bonus);
    }

    // Streak badges (earned once when reaching the threshold).
    final streakBadgeIds = <int, String>{
      30: 'streak_30_discipline_month',
      100: 'streak_100_discipline_medal',
      365: 'streak_365_iron_discipline',
      500: 'streak_500_warrior_mindset',
      1000: 'streak_1000_demigod_mindset',
    };
    final streakBadge = streakBadgeIds[nextStreak];
    if (streakBadge != null) {
      await _addBadge(streakBadge);
    }

    _notifyChanged();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Workout events (for calendar + multiple sessions/day)
  //
  // Shape:
  // [
  //   {
  //     'id': 'we_...',
  //     'type': 'nine_min' | 'hercules' | 'stretch' | 'gym' | 'calisthenics' | 'run',
  //     'recordedAt': ISO_STRING,
  //     'mood': 1..5 (optional)
  //   }
  // ]
  // ───────────────────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> get workoutEvents {
    final raw = _safeBox.get(keyWorkoutEvents, defaultValue: const []);
    if (raw is! List) return const [];
    final list = raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    list.sort(
      (a, b) => (a['recordedAt'] ?? '').toString().compareTo(
        (b['recordedAt'] ?? '').toString(),
      ),
    );
    return list;
  }

  static List<Map<String, dynamic>> workoutEventsForDay(DateTime day) {
    final key = _dateKey(day);
    return workoutEvents.where((e) {
      final at = DateTime.tryParse(e['recordedAt']?.toString() ?? '');
      if (at == null) return false;
      return _dateKey(at) == key;
    }).toList()..sort(
      (a, b) => (a['recordedAt'] ?? '').toString().compareTo(
        (b['recordedAt'] ?? '').toString(),
      ),
    );
  }

  static int workoutEventBurnKcal(Map<String, dynamic> event) {
    final stored = _readEntryInt(event['caloriesBurned']);
    if (stored > 0) return stored;

    final rawBreakdown = event['calorieBreakdown'];
    if (rawBreakdown is List && rawBreakdown.isNotEmpty) {
      var total = 0;
      for (final item in rawBreakdown) {
        if (item is Map) total += _readEntryInt(item['kcal']);
      }
      if (total > 0) return total;
    }

    final type = (event['type'] ?? '').toString();
    final durationSeconds = _readEntryInt(event['durationSeconds']);

    if (type == 'run') {
      final meters = (event['runMeters'] as num?)?.toDouble() ?? 0;
      if (meters > 0 && durationSeconds > 0) {
        return CalorieBurnService.runSession(
          meters: meters,
          durationSeconds: durationSeconds,
        ).totalKcal;
      }
    }

    if (durationSeconds > 0) {
      return CalorieBurnService.durationBurn(
        met: CalorieBurnService.metForWorkoutType(type),
        durationSeconds: durationSeconds,
      );
    }

    return 0;
  }

  static List<Map<String, dynamic>> workoutSessionsForDay(DateTime day) {
    final events = workoutEventsForDay(day);
    if (events.isNotEmpty) return events;
    if (!isWorkoutCompletedOn(day)) return const [];

    return [
      {
        'id': 'legacy_${_dateKey(day)}',
        'type': 'legacy',
        'recordedAt': DateTime(
          day.year,
          day.month,
          day.day,
          12,
        ).toIso8601String(),
      },
    ];
  }

  static int workoutBurnKcalForDay(DateTime day) {
    var total = 0;
    for (final event in workoutSessionsForDay(day)) {
      total += workoutEventBurnKcal(event);
    }
    return total;
  }

  static int stepsBurnKcalForDay(DateTime day) {
    final steps = stepsForDay(day);
    if (steps == null || steps <= 0) return 0;
    return CalorieBurnService.stepsBurn(steps);
  }

  static int totalBurnKcalForDay(DateTime day) {
    return workoutBurnKcalForDay(day) + stepsBurnKcalForDay(day);
  }

  static double runMetersForDay(DateTime day) {
    var total = 0.0;
    for (final event in workoutEventsForDay(day)) {
      if (event['type']?.toString() != 'run') continue;
      total += (event['runMeters'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  /// Completed runs, newest first.
  static List<Map<String, dynamic>> get runEvents {
    final runs = workoutEvents
        .where((e) => e['type']?.toString() == 'run')
        .toList();
    runs.sort(
      (a, b) => (b['recordedAt'] ?? '').toString().compareTo(
        (a['recordedAt'] ?? '').toString(),
      ),
    );
    return runs;
  }

  /// Aggregate distance, moving time and count for a calendar month.
  static ({double meters, int durationSeconds, int runCount})
  runSummaryForMonth(DateTime when) {
    final year = when.year;
    final month = when.month;
    var meters = 0.0;
    var durationSeconds = 0;
    var runCount = 0;
    for (final event in runEvents) {
      final at = DateTime.tryParse(event['recordedAt']?.toString() ?? '');
      if (at == null || at.year != year || at.month != month) continue;
      final m = (event['runMeters'] as num?)?.toDouble() ?? 0;
      if (m <= 0) continue;
      meters += m;
      durationSeconds += _readEntryInt(event['durationSeconds']);
      runCount++;
    }
    return (
      meters: meters,
      durationSeconds: durationSeconds,
      runCount: runCount,
    );
  }

  static int _readEntryInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  /// Logs an AI-described one-off workout to history/calendar without adding
  /// it to the reusable workout library.
  static Future<int> logAiWorkout({
    required String sourceId,
    required String name,
    required String category,
    required int durationMinutes,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final receiptKey = _aiActionReceiptKey(sourceId);
    if (hasAiChatAction(sourceId)) return 0;
    if (sourceId.isEmpty ||
        sourceId.length > 120 ||
        name.trim().isEmpty ||
        !{'gym', 'calisthenics'}.contains(category) ||
        durationMinutes < 1 ||
        durationMinutes > 360 ||
        exercises.isEmpty ||
        exercises.length > 30) {
      throw ArgumentError('Invalid AI workout log');
    }
    final seconds = durationMinutes * 60;
    final calories = CalorieBurnService.durationBurn(
      met: CalorieBurnService.metForWorkoutType(category),
      durationSeconds: seconds,
    );
    final totalVolume = exercises.fold<int>(
      0,
      (sum, exercise) =>
          sum +
          (_readEntryInt(exercise['sets']).clamp(1, 100) *
              _readEntryInt(exercise['reps']).clamp(1, 999)),
    );
    var allocatedKcal = 0;
    var allocatedSeconds = 0;
    final breakdown = <Map<String, dynamic>>[];
    for (var i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final volume =
          _readEntryInt(exercise['sets']).clamp(1, 100) *
          _readEntryInt(exercise['reps']).clamp(1, 999);
      final last = i == exercises.length - 1;
      final kcal = last
          ? calories - allocatedKcal
          : (calories * volume / totalVolume).round();
      final exerciseSeconds = last
          ? seconds - allocatedSeconds
          : (seconds * volume / totalVolume).round();
      allocatedKcal += kcal;
      allocatedSeconds += exerciseSeconds;
      breakdown.add({
        'label': exercise['name']?.toString() ?? 'Workout',
        'seconds': exerciseSeconds,
        'met': CalorieBurnService.metForWorkoutType(category),
        'kcal': kcal,
        'mainGroup': exercise['mainGroup']?.toString() ?? '',
        'tags': (exercise['tags'] is List)
            ? List<String>.from(
                (exercise['tags'] as List).map((e) => e.toString()),
              )
            : <String>[],
      });
    }
    await applyWorkoutRewards(
      workoutType: 'sport',
      caloriesBurned: calories,
      durationSeconds: seconds,
      workoutName: name.trim(),
      workoutCategory: category,
      exercises: exercises,
      calorieBreakdown: breakdown,
      sourceId: sourceId,
    );
    // applyWorkoutRewards stores the idempotency receipt with the calendar
    // event. This fallback covers an unexpectedly empty event list.
    if (!hasAiChatAction(sourceId)) {
      await _safeBox.put(receiptKey, 'logged');
    }
    return calories;
  }

  static Future<void> addWorkoutEvent({
    required String type,
    required DateTime recordedAt,
    int? mood,
    int? workoutIntensity,
    int? caloriesBurned,
    int? durationSeconds,
    double? runMeters,
    String? workoutName,
    String? workoutId,
    String? workoutCategory,
    String? sourceId,
    List<Map<String, dynamic>>? exercises,
    List<Map<String, dynamic>>? calorieBreakdown,
    Map<String, dynamic>? runRecord,
  }) async {
    final t = type.trim();
    if (t.isEmpty) return;
    if (sourceId != null && hasAiChatAction(sourceId)) return;
    final m = mood;
    final clampedMood = (m == null) ? null : m.clamp(1, 5);
    final events = workoutEvents.toList();
    events.add({
      'id': sourceId == null
          ? 'we_${DateTime.now().microsecondsSinceEpoch}'
          : 'we_ai_$sourceId',
      'type': t,
      'recordedAt': recordedAt.toIso8601String(),
      if (sourceId != null) 'aiSourceId': sourceId,
      if (clampedMood != null) 'mood': clampedMood,
      if (workoutIntensity != null)
        'workoutIntensity': workoutIntensity.clamp(1, 3),
      if (caloriesBurned != null) 'caloriesBurned': caloriesBurned,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (runMeters != null) 'runMeters': runMeters,
      if (runRecord != null) 'runRecord': runRecord,
      if (workoutName != null && workoutName.trim().isNotEmpty)
        'workoutName': workoutName.trim(),
      if (workoutCategory != null && workoutCategory.trim().isNotEmpty)
        'workoutCategory': workoutCategory.trim(),
      if (workoutId != null && workoutId.trim().isNotEmpty)
        'workoutId': workoutId.trim(),
      if (exercises != null && exercises.isNotEmpty)
        'exercises': [
          for (final exercise in exercises)
            {
              ...exercise,
              if (exercise['setReps'] is List)
                'setReps': List<dynamic>.from(exercise['setReps']),
              if (exercise['tags'] is List)
                'tags': List<dynamic>.from(exercise['tags']),
            },
        ],
      if (calorieBreakdown != null && calorieBreakdown.isNotEmpty)
        'calorieBreakdown': calorieBreakdown,
    });
    events.sort(
      (a, b) => (a['recordedAt'] ?? '').toString().compareTo(
        (b['recordedAt'] ?? '').toString(),
      ),
    );
    await _safeBox.putAll({
      keyWorkoutEvents: events,
      if (sourceId != null) _aiActionReceiptKey(sourceId): 'logged',
    });
    _notifyChanged();
  }

  static Future<void> applyWorkoutRewards({
    required String workoutType,
    int? mood,
    int? workoutIntensity,
    double? runMeters,
    int? caloriesBurned,
    int? durationSeconds,
    String? workoutName,
    String? workoutId,
    String? workoutCategory,
    String? sourceId,
    List<Map<String, dynamic>>? exercises,
    List<Map<String, dynamic>>? calorieBreakdown,
    Map<String, dynamic>? runRecord,
  }) async {
    if (sourceId != null && hasAiChatAction(sourceId)) return;
    // NOTE: workoutType is a semantic key, not a category title.
    // Supported values: stretch, nine_min, hercules, run, gym, calisthenics, sport
    //
    // For runs the reward is distance-based: +1 level per full 5 km completed.
    // Anything below 5 km still counts toward the daily streak but gives 0 XP.
    final delta = switch (workoutType) {
      'stretch' => 1,
      'nine_min' => 2,
      'hercules' => 3,
      'run' => ((runMeters ?? 0) ~/ 5000),
      'gym' => 5,
      'calisthenics' => 5,
      'sport' => 2,
      _ => 0,
    };

    final now = DateTime.now();
    await batch(() async {
      await markWorkoutCompletedToday();
      if (delta > 0) {
        await addUserLevel(delta);
      }
      if (workoutType == 'gym') {
        await markGymWorkoutCompleted();
      } else if (workoutType == 'calisthenics') {
        await markCalisthenicsWorkoutCompleted();
      }

      // Level milestone badges (awarded once).
      final levelMilestones = <int, String>{
        0: 'level_0_rookie',
        20: 'level_20_student',
        50: 'level_50_trainee',
        100: 'level_100_performer',
        300: 'level_300_profi',
        500: 'level_500_athlet',
        1000: 'level_1000_krieger',
        2500: 'level_2500_elite',
        5000: 'level_5000_champion',
        7500: 'level_7500_goat',
        10000: 'level_10000_halbgott',
      };
      final earnedNow = <String>[];
      for (final entry in levelMilestones.entries) {
        if (userLevel >= entry.key) earnedNow.add(entry.value);
      }
      await _addBadges(earnedNow);

      // Specialization badges (gym/calisthenics total completed).
      final gymMilestones = <int, String>{
        50: 'gym_50_junior',
        100: 'gym_100_profi',
        500: 'gym_500_bodybuilding_junior',
        1000: 'gym_1000_bodybuilder',
      };
      final caliMilestones = <int, String>{
        50: 'cali_50_junior',
        100: 'cali_100_profi',
        500: 'cali_500_bodybuilding_junior',
        1000: 'cali_1000_bodybuilder',
      };

      final gymTotal = totalGymWorkoutsCompleted;
      final caliTotal = totalCalisthenicsWorkoutsCompleted;
      final earnedSpec = <String>[];
      for (final entry in gymMilestones.entries) {
        if (gymTotal >= entry.key) earnedSpec.add(entry.value);
      }
      for (final entry in caliMilestones.entries) {
        if (caliTotal >= entry.key) earnedSpec.add(entry.value);
      }
      await _addBadges(earnedSpec);

      // Persist the session for calendar/history (supports multiple per day).
      await addWorkoutEvent(
        type: workoutType,
        recordedAt: now,
        mood: mood,
        workoutIntensity: workoutIntensity,
        caloriesBurned: caloriesBurned,
        durationSeconds: durationSeconds,
        runMeters: runMeters,
        workoutName: workoutName,
        workoutId: workoutId,
        workoutCategory: workoutCategory,
        sourceId: sourceId,
        exercises: exercises,
        calorieBreakdown: calorieBreakdown,
        runRecord: runRecord,
      );
    });
  }

  static Map<String, int> workoutExerciseSecondsOverrides(String workoutType) {
    final key = '$_workoutExerciseSecondsPrefix${workoutType.trim()}';
    final raw = _safeBox.get(key, defaultValue: const {});
    if (raw is Map) {
      final result = <String, int>{};
      raw.forEach((k, v) {
        final name = k?.toString().trim() ?? '';
        if (name.isEmpty) return;
        final seconds = v is int ? v : int.tryParse(v.toString());
        if (seconds == null) return;
        if (seconds <= 0) return;
        result[name] = seconds;
      });
      return result;
    }
    return const <String, int>{};
  }

  static int workoutExerciseSeconds({
    required String workoutType,
    required String exerciseName,
    required int defaultSeconds,
  }) {
    final map = workoutExerciseSecondsOverrides(workoutType);
    return map[exerciseName.trim()] ?? defaultSeconds;
  }

  static Future<void> setWorkoutExerciseSeconds({
    required String workoutType,
    required String exerciseName,
    required int seconds,
  }) async {
    final type = workoutType.trim();
    final name = exerciseName.trim();
    if (type.isEmpty || name.isEmpty) return;
    final clamped = seconds.clamp(1, 3600);
    final key = '$_workoutExerciseSecondsPrefix$type';
    final next = workoutExerciseSecondsOverrides(type);
    next[name] = clamped;
    await _safeBox.put(key, next);
    _notifyChanged();
  }

  static Future<void> clearWorkoutExerciseSeconds({
    required String workoutType,
    required String exerciseName,
  }) async {
    final type = workoutType.trim();
    final name = exerciseName.trim();
    if (type.isEmpty || name.isEmpty) return;
    final key = '$_workoutExerciseSecondsPrefix$type';
    final next = workoutExerciseSecondsOverrides(type);
    if (!next.containsKey(name)) return;
    next.remove(name);
    await _safeBox.put(key, next);
    _notifyChanged();
  }

  static List<String> morningWorkoutExerciseOrder() {
    final raw = _safeBox.get(keyMorningWorkoutExerciseOrder);
    if (raw is List) {
      final names = <String>[];
      for (final item in raw) {
        final name = item?.toString().trim() ?? '';
        if (name.isNotEmpty) names.add(name);
      }
      if (names.isNotEmpty) return names;
    }
    return herculesDefaultExercises.map((e) => e.name).toList();
  }

  static Future<void> setMorningWorkoutExerciseOrder(List<String> names) async {
    final cleaned = <String>[];
    for (final name in names) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      if (cleaned.contains(trimmed)) continue;
      cleaned.add(trimmed);
    }
    if (cleaned.isEmpty) return;
    await _safeBox.put(keyMorningWorkoutExerciseOrder, cleaned);
    _notifyChanged();
  }

  static Future<void> removeMorningWorkoutExercise(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final order = morningWorkoutExerciseOrder();
    if (order.length <= 1) return;
    if (!order.contains(trimmed)) return;
    await setMorningWorkoutExerciseOrder(
      order.where((n) => n != trimmed).toList(),
    );
  }

  static Future<void> addMorningWorkoutExercise(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final order = morningWorkoutExerciseOrder();
    if (order.contains(trimmed)) return;
    await setMorningWorkoutExerciseOrder([...order, trimmed]);
    await setWorkoutExerciseSeconds(
      workoutType: 'hercules',
      exerciseName: trimmed,
      seconds: 30,
    );
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static Set<String> get _completedWorkoutDays {
    final raw = _safeBox.get(keyWorkoutCompletedDays, defaultValue: const []);
    if (raw is List) {
      return raw.map((e) => e.toString()).toSet();
    }
    return <String>{};
  }

  static bool isWorkoutCompletedOn(DateTime date) {
    return _completedWorkoutDays.contains(_dateKey(date));
  }

  static List<DateTime> completedWorkoutDaysForMonth({
    required int year,
    required int month,
  }) {
    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-';
    final result = <DateTime>[];
    for (final key in _completedWorkoutDays) {
      if (!key.startsWith(prefix)) continue;
      final parts = key.split('-');
      if (parts.length != 3) continue;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y == null || m == null || d == null) continue;
      result.add(DateTime(y, m, d));
    }
    result.sort((a, b) => a.compareTo(b));
    return result;
  }

  static List<Map<String, dynamic>> get weightEntries {
    final raw = _safeBox.get(keyWeightEntries, defaultValue: const []);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['date'] != null && e['weight'] != null)
          .toList();
    }
    return const [];
  }

  static double? get currentWeightKg {
    final entries = weightEntries;
    if (entries.isEmpty) return null;
    entries.sort(_compareWeightEntries);
    final last = entries.last;
    final weight = last['weight'];
    if (weight is num) return weight.toDouble();
    return double.tryParse(weight.toString());
  }

  static Future<void> setWeightForToday(double weightKg) async {
    final now = DateTime.now();
    final key = _dateKey(now);
    final recordedAt = now.toIso8601String();
    final entries = weightEntries;
    final updated = <Map<String, dynamic>>[];

    bool replaced = false;
    for (final entry in entries) {
      final date = entry['date']?.toString();
      if (date == key) {
        updated.add({
          'date': key,
          'weight': weightKg,
          'recordedAt': recordedAt,
        });
        replaced = true;
      } else {
        updated.add(entry);
      }
    }
    if (!replaced) {
      updated.add({'date': key, 'weight': weightKg, 'recordedAt': recordedAt});
    }
    updated.sort(_compareWeightEntries);
    await _safeBox.put(keyWeightEntries, updated);
    _notifyChanged();
  }

  static int _compareWeightEntries(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aRecorded = a['recordedAt']?.toString();
    final bRecorded = b['recordedAt']?.toString();
    if (aRecorded != null && bRecorded != null) {
      return aRecorded.compareTo(bRecorded);
    }
    return a['date'].toString().compareTo(b['date'].toString());
  }

  // ─── Exercise Lift Log ──────────────────────────────────────────────────────

  /// Returns all logged lift sessions for [exerciseName], oldest first.
  /// Each entry: {date, sets, reps, weight, volume}
  static List<Map<String, dynamic>> liftLogForExercise(String exerciseName) {
    final raw = _safeBox.get(keyExerciseLiftLog, defaultValue: const {});
    if (raw is! Map) return const [];
    final list = raw[exerciseName];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Appends a lift session for [exerciseName].
  static Future<void> addLiftEntry({
    required String exerciseName,
    required int sets,
    required int reps,
    required double weight,
  }) async {
    final rawAll = _safeBox.get(
      keyExerciseLiftLog,
      defaultValue: <String, dynamic>{},
    );
    final all = rawAll is Map
        ? Map<String, dynamic>.from(rawAll)
        : <String, dynamic>{};

    final existing = all[exerciseName];
    final entries = existing is List
        ? List<Map<String, dynamic>>.from(
            existing.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
          )
        : <Map<String, dynamic>>[];

    final now = DateTime.now();
    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    // Replace same-day entry so each day shows the latest performance.
    entries.removeWhere((e) => e['date']?.toString() == dateKey);
    entries.add({
      'date': dateKey,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'volume': sets * reps * weight,
      'recordedAt': now.toIso8601String(),
    });
    entries.sort(
      (a, b) => a['date'].toString().compareTo(b['date'].toString()),
    );

    all[exerciseName] = entries;
    await _safeBox.put(keyExerciseLiftLog, all);
    _notifyChanged();
  }

  static int? get profileAge {
    final value = _safeBox.get(keyProfileAge);
    return value is int ? value : null;
  }

  static double? get profileHeightCm => _readDouble(keyProfileHeightCm);

  static String? get profileGender {
    final value = (_safeBox.get(keyProfileGender) as String?)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static double? get profileBodyFatPercent =>
      _readDouble(keyProfileBodyFatPercent);

  static double? get profileMuscleMassKg => _readDouble(keyProfileMuscleMassKg);

  static double? get profileBoneMassKg => _readDouble(keyProfileBoneMassKg);

  static String get profileActivityLevel {
    final value =
        (_safeBox.get(keyProfileActivityLevel, defaultValue: 'moderate')
                as String)
            .trim();
    return value.isEmpty ? 'moderate' : value;
  }

  static String get profileGoal {
    final value =
        (_safeBox.get(keyProfileGoal, defaultValue: 'maintain') as String)
            .trim();
    return value.isEmpty ? 'maintain' : value;
  }

  static Future<void> setProfileAge(int? value) async {
    await _putNullable(keyProfileAge, value);
  }

  static Future<void> setProfileHeightCm(double? value) async {
    await _putNullable(keyProfileHeightCm, value);
  }

  static Future<void> setProfileGender(String? value) async {
    await _putNullable(keyProfileGender, value?.trim());
  }

  static Future<void> setProfileBodyFatPercent(double? value) async {
    await _putNullable(keyProfileBodyFatPercent, value);
  }

  static Future<void> setProfileMuscleMassKg(double? value) async {
    await _putNullable(keyProfileMuscleMassKg, value);
  }

  static Future<void> setProfileBoneMassKg(double? value) async {
    await _putNullable(keyProfileBoneMassKg, value);
  }

  static Future<void> setProfileActivityLevel(String value) async {
    await _safeBox.put(keyProfileActivityLevel, value.trim());
    _notifyChanged();
  }

  static Future<void> setProfileGoal(String value) async {
    await _safeBox.put(keyProfileGoal, value.trim());
    _notifyChanged();
  }

  static bool get hasCompletedOnboarding {
    final v = _safeBox.get(keyHasCompletedOnboarding, defaultValue: false);
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v == '1' || v == 'true';
  }

  static bool get needsOnboarding => !hasCompletedOnboarding;

  static Future<void> setHasCompletedOnboarding(bool value) async {
    await _safeBox.put(keyHasCompletedOnboarding, value);
    _notifyChanged();
  }

  static WeeklyTrainingSchedule get weeklyTrainingSchedule {
    final raw = _safeBox.get(keyWeeklyTrainingSchedule);
    if (raw is List) return WeeklyTrainingSchedule.fromStored(raw);
    return WeeklyTrainingSchedule.empty();
  }

  static Future<void> setWeeklyTrainingSchedule(
    WeeklyTrainingSchedule schedule,
  ) async {
    await _safeBox.put(keyWeeklyTrainingSchedule, schedule.toJsonList());
    _notifyChanged();
  }

  static bool get trainingNotificationsEnabled {
    final v = _safeBox.get(
      keyTrainingNotificationsEnabled,
      defaultValue: false,
    );
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v == '1' || v == 'true';
  }

  static Future<void> setTrainingNotificationsEnabled(bool value) async {
    await _safeBox.put(keyTrainingNotificationsEnabled, value);
    _notifyChanged();
  }

  static bool get fastingHudEnabled {
    final v = _safeBox.get(keyFastingHudEnabled, defaultValue: false);
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v == '1' || v == 'true';
  }

  static Future<void> setFastingHudEnabled(bool value) async {
    await _safeBox.put(keyFastingHudEnabled, value);
    _notifyChanged();
  }

  static bool get waterTrackingEnabled {
    final v = _safeBox.get(keyWaterTrackingEnabled, defaultValue: false);
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v == '1' || v == 'true';
  }

  static Future<void> setWaterTrackingEnabled(bool value) async {
    await _safeBox.put(keyWaterTrackingEnabled, value);
    if (value && waterGoalMlOverride == null) {
      await setWaterGoalMl(recommendedWaterGoalMl);
    }
    _notifyChanged();
  }

  /// User override for daily water goal (ml). Null → use biometric recommendation.
  static int? get waterGoalMlOverride {
    final raw = _safeBox.get(keyWaterGoalMl);
    if (raw == null) return null;
    final v = raw is int ? raw : int.tryParse(raw.toString());
    if (v == null || v <= 0) return null;
    return v.clamp(waterGoalStepMl, 8000);
  }

  static Future<void> setWaterGoalMl(int ml) async {
    final clamped = ((ml / waterGoalStepMl).round() * waterGoalStepMl).clamp(
      waterGoalStepMl,
      8000,
    );
    await _safeBox.put(keyWaterGoalMl, clamped);
    _notifyChanged();
  }

  static int get recommendedWaterGoalMl {
    final weight = currentWeightKg;
    final height = profileHeightCm;
    final gender = profileGender;
    if (weight == null || height == null || gender == null) {
      return 2500;
    }
    return NutritionCalculator.estimateWaterMl(
      weightKg: weight,
      heightCm: height,
      gender: gender,
      activityLevel: profileActivityLevel,
    );
  }

  static int get waterGoalMl => waterGoalMlOverride ?? recommendedWaterGoalMl;

  static int get todayWaterMl {
    final today = _dateKey(DateTime.now());
    if (_safeBox.get(keyTodayWaterDate)?.toString() != today) return 0;
    final raw = _safeBox.get(keyTodayWaterMl);
    if (raw is int) return raw.clamp(0, 20000);
    return (int.tryParse(raw?.toString() ?? '') ?? 0).clamp(0, 20000);
  }

  static Future<void> setTodayWaterMl(int ml) async {
    final now = DateTime.now();
    final clamped = ml.clamp(0, 20000);
    final dateKey = _dateKey(now);
    await _safeBox.put(keyTodayWaterMl, clamped);
    await _safeBox.put(keyTodayWaterDate, dateKey);
    await _cacheWaterHistory(dateKey, clamped);
    _notifyChanged();
  }

  static Future<void> addWaterGlass({int glasses = 1}) async {
    await setTodayWaterMl(todayWaterMl + glasses * waterGlassMl);
  }

  static Future<void> removeWaterGlass({int glasses = 1}) async {
    await setTodayWaterMl(todayWaterMl - glasses * waterGlassMl);
  }

  static Future<void> _cacheWaterHistory(String dateKey, int ml) async {
    final raw = _safeBox.get(keyWaterHistory, defaultValue: const {});
    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    map[dateKey] = ml;
    await _safeBox.put(keyWaterHistory, map);
  }

  static int waterMlForDay(DateTime day) {
    final key = _dateKey(day);
    if (_safeBox.get(keyTodayWaterDate)?.toString() == key) {
      return todayWaterMl;
    }
    final raw = _safeBox.get(keyWaterHistory, defaultValue: const {});
    if (raw is! Map) return 0;
    final value = raw[key];
    if (value is int) return value.clamp(0, 20000);
    return (int.tryParse(value?.toString() ?? '') ?? 0).clamp(0, 20000);
  }

  static bool get eatingWindowConfigured {
    final v = _safeBox.get(keyEatingWindowConfigured, defaultValue: false);
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v == '1' || v == 'true';
  }

  static int get eatingWindowStartMinutes {
    final v = _safeBox.get(keyEatingWindowStartMinutes, defaultValue: 12 * 60);
    if (v is int) return v.clamp(0, 24 * 60 - 1);
    if (v is num) return v.toInt().clamp(0, 24 * 60 - 1);
    return 12 * 60;
  }

  static int get eatingWindowEndMinutes {
    final v = _safeBox.get(keyEatingWindowEndMinutes, defaultValue: 20 * 60);
    if (v is int) return v.clamp(1, 24 * 60);
    if (v is num) return v.toInt().clamp(1, 24 * 60);
    return 20 * 60;
  }

  static bool get fastingRemindersEnabled {
    final v = _safeBox.get(keyFastingRemindersEnabled, defaultValue: false);
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v == '1' || v == 'true';
  }

  static Future<void> saveEatingWindow({
    required int startMinutes,
    required int endMinutes,
    required bool remindersEnabled,
  }) async {
    await _safeBox.put(keyEatingWindowStartMinutes, startMinutes);
    await _safeBox.put(keyEatingWindowEndMinutes, endMinutes);
    await _safeBox.put(keyFastingRemindersEnabled, remindersEnabled);
    await _safeBox.put(keyEatingWindowConfigured, true);
    _notifyChanged();
  }

  static Future<void> setFastingRemindersEnabled(bool value) async {
    await _safeBox.put(keyFastingRemindersEnabled, value);
    _notifyChanged();
  }

  static double? _readDouble(String key) {
    final value = _safeBox.get(key);
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static Future<void> _putNullable(String key, Object? value) async {
    if (value == null || (value is String && value.trim().isEmpty)) {
      await _safeBox.delete(key);
    } else {
      await _safeBox.put(key, value);
    }
    _notifyChanged();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Shared content imports (friends inbox accept)
  // ───────────────────────────────────────────────────────────────────────────

  static Future<void> _sharedImportQueue = Future.value();

  /// A stable source receipt prevents duplicate imports after a tap, retry,
  /// failed remote acknowledgement, restart, or local deletion of the template.
  static Future<String> importSharedMessage(InboxMessage message) {
    final result = Completer<String>();
    _sharedImportQueue = _sharedImportQueue.then((_) async {
      try {
        result.complete(await _importSharedMessage(message));
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  static Future<String> _importSharedMessage(InboxMessage message) async {
    final source = '${message.fromUid}/${message.id}';
    final raw = _safeBox.get('social_import_receipts');
    final receipts = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    if (receipts[source] is String) return receipts[source] as String;
    final content = normalizeSharedContent(message.type, message.payload);
    final (key, items) = switch (message.type) {
      ShareContentType.gymWorkout => (keyGymWorkouts, gymWorkouts),
      ShareContentType.calisthenicsWorkout => (
        keyCalisthenicsWorkouts,
        calisthenicsWorkouts,
      ),
      ShareContentType.foodDish => (keyFoodDishes, foodDishes),
      ShareContentType.runningRoute => (keyRunningRoutes, runningRoutes),
      _ => throw const FormatException('This message is not importable'),
    };
    final existing = items
        .where((item) => item['sharedSource'] == source)
        .firstOrNull;
    if (existing != null) return existing['id'] as String;
    final id = 'shared_${newChatId()}';
    final now = DateTime.now().toIso8601String();
    final next = [
      ...items,
      {
        ...content,
        'id': id,
        'createdAt': now,
        'updatedAt': now,
        'sharedSource': source,
      },
    ];
    receipts[source] = id;
    await _safeBox.putAll({key: next, 'social_import_receipts': receipts});
    _notifyChanged();
    return id;
  }

  static Future<String> importSharedGymWorkout(
    Map<String, dynamic> payload,
  ) async {
    final name = payload['name']?.toString().trim();
    final id = await createGymWorkout(
      name == null || name.isEmpty ? 'Shared workout' : name,
    );
    final rawExercises = payload['exercises'];
    if (rawExercises is List) {
      final exercises = rawExercises
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (exercises.isNotEmpty) {
        await setGymWorkoutExercises(workoutId: id, exercises: exercises);
        return id;
      }
    }
    await deleteGymWorkout(id);
    return id;
  }

  static Future<String> importSharedCalisthenicsWorkout(
    Map<String, dynamic> payload,
  ) async {
    final name = payload['name']?.toString().trim();
    final id = await createCalisthenicsWorkout(
      name == null || name.isEmpty ? 'Shared workout' : name,
    );
    final rawExercises = payload['exercises'];
    if (rawExercises is List) {
      final exercises = rawExercises
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (exercises.isNotEmpty) {
        await setCalisthenicsWorkoutExercises(
          workoutId: id,
          exercises: exercises,
        );
        return id;
      }
    }
    await deleteCalisthenicsWorkout(id);
    return id;
  }

  static Future<String> importSharedRunningRoute(
    Map<String, dynamic> payload,
  ) async {
    List<List<double>> decodePoints(dynamic raw) {
      if (raw is! List) return const [];
      final out = <List<double>>[];
      for (final entry in raw) {
        if (entry is List && entry.length >= 2) {
          final lat = (entry[0] as num?)?.toDouble();
          final lon = (entry[1] as num?)?.toDouble();
          if (lat != null && lon != null) out.add([lat, lon]);
        }
      }
      return out;
    }

    List<Map<String, dynamic>> decodeSteps(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return saveRunningRoute(
      name: payload['name']?.toString() ?? 'Shared route',
      distanceMeters: (payload['distanceMeters'] as num?)?.toDouble() ?? 0,
      ascentMeters: (payload['ascentMeters'] as num?)?.toDouble() ?? 0,
      descentMeters: (payload['descentMeters'] as num?)?.toDouble() ?? 0,
      points: decodePoints(payload['points']),
      waypoints: decodePoints(payload['waypoints']),
      steps: decodeSteps(payload['steps']),
      activity: payload['activity'] is Map
          ? Map<String, dynamic>.from(payload['activity'] as Map)
          : null,
    );
  }

  static Future<String> importSharedFoodDish(
    Map<String, dynamic> payload,
  ) async {
    final name = payload['name']?.toString().trim();
    final id = await createFoodDish(
      name == null || name.isEmpty ? 'Shared dish' : name,
    );
    final description = payload['description']?.toString().trim();
    if (description != null && description.isNotEmpty) {
      await updateFoodDishDescription(dishId: id, description: description);
    }
    final rawItems = payload['items'];
    if (rawItems is List) {
      for (final item in rawItems.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        await addItemToFoodDish(
          dishId: id,
          foodName: map['foodName']?.toString() ?? 'Food',
          grams: (map['grams'] as num?)?.toDouble() ?? 0,
          proteinG: (map['proteinG'] as num?)?.toDouble() ?? 0,
          carbsG: (map['carbsG'] as num?)?.toDouble() ?? 0,
          fatsG: (map['fatsG'] as num?)?.toDouble() ?? 0,
        );
      }
    }
    return id;
  }

  // ─── Favorite workouts ───────────────────────────────────────────────────

  static Set<String> get favoriteWorkoutIds {
    final raw = _safeBox.get(keyFavoriteWorkoutIds, defaultValue: const []);
    if (raw is! List) return <String>{};
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet();
  }

  static bool isFavoriteWorkout(String id) => favoriteWorkoutIds.contains(id);

  static Future<void> toggleFavoriteWorkout(String id) async {
    final next = favoriteWorkoutIds.toSet();
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    await _safeBox.put(keyFavoriteWorkoutIds, next.toList());
    _notifyChanged();
  }
}
