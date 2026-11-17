import '../l10n/app_localizations.dart';
import 'nutrition_calculator.dart';
import 'progress_store.dart';

class HomeHudSnapshot {
  const HomeHudSnapshot({
    required this.tip,
    required this.steps,
    required this.stepsGoal,
    required this.availableKcal,
    required this.calorieTarget,
    this.waterEnabled = false,
    this.waterMl = 0,
    this.waterGoalMl = 2500,
    this.burnedKcal = 0,
    this.eatenKcal = 0,
    this.burnGoalKcal = 500,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatsG = 0,
  });

  final String tip;
  final int steps;
  final int stepsGoal;
  final int? availableKcal;
  final int? calorieTarget;
  final bool waterEnabled;
  final int waterMl;
  final int waterGoalMl;
  final int burnedKcal;
  final int eatenKcal;
  final double proteinG;
  final double carbsG;
  final double fatsG;

  /// Display reference for active energy, excluding resting metabolism.
  final int burnGoalKcal;

  double get stepsProgress {
    if (stepsGoal <= 0) return 0;
    return (steps / stepsGoal).clamp(0.0, 1.0);
  }

  double get availableProgress {
    final target = calorieTarget;
    final available = availableKcal;
    if (target == null || target <= 0 || available == null) return 0;
    // Fill left→right as calories are consumed (consumed / target).
    return (1.0 - available / target).clamp(0.0, 1.0);
  }

  double get waterProgress {
    if (waterGoalMl <= 0) return 0;
    return (waterMl / waterGoalMl).clamp(0.0, 1.0);
  }
}

/// Short coaching + daily glance metrics for the home body HUD.
class HomeWeeklySummaryService {
  HomeWeeklySummaryService._();

  static const int defaultStepsGoal = 10000;

  static HomeHudSnapshot snapshot(AppLocalizations l10n) {
    final today = DateTime.now();
    final workoutCount = ProgressStore.workoutSessionsForDay(today).length;
    final tip = switch (workoutCount) {
      0 => l10n.home_hudSummaryNoneToday,
      1 => l10n.home_hudSummaryOneToday,
      _ => l10n.home_hudSummaryTwoPlusToday,
    };

    final targets = _calorieTargets();
    final foodTotals = ProgressStore.todayFoodTotals;
    final eaten = foodTotals.kcal;
    final available = targets == null
        ? null
        : (targets.calories - eaten).clamp(0, 99999);

    return HomeHudSnapshot(
      tip: tip,
      steps: ProgressStore.todaySteps ?? 0,
      stepsGoal: defaultStepsGoal,
      availableKcal: available,
      calorieTarget: targets?.calories,
      waterEnabled: ProgressStore.waterTrackingEnabled,
      waterMl: ProgressStore.todayWaterMl,
      waterGoalMl: ProgressStore.waterGoalMl,
      burnedKcal: ProgressStore.totalBurnKcalForDay(today),
      eatenKcal: eaten,
      proteinG: foodTotals.p,
      carbsG: foodTotals.c,
      fatsG: foodTotals.f,
    );
  }

  /// Kept for callers that still expect plain tip text only.
  static List<String> lines(AppLocalizations l10n) => [snapshot(l10n).tip];

  static DailyNutritionTargets? _calorieTargets() {
    final age = ProgressStore.profileAge;
    final heightCm = ProgressStore.profileHeightCm;
    final weightKg = ProgressStore.currentWeightKg;
    final gender = ProgressStore.profileGender;
    if (age == null || heightCm == null || weightKg == null || gender == null) {
      return null;
    }
    return NutritionCalculator.calculate(
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      gender: gender,
      activityLevel: ProgressStore.profileActivityLevel,
      goal: ProgressStore.profileGoal,
    );
  }
}
