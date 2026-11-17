class DailyNutritionTargets {
  const DailyNutritionTargets({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.waterLiters,
  });

  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final double? waterLiters;

  bool get isComplete => calories > 0;
}

class NutritionCalculator {
  NutritionCalculator._();

  static DailyNutritionTargets calculate({
    required int age,
    required double heightCm,
    required double weightKg,
    required String gender,
    String activityLevel = 'moderate',
    String goal = 'maintain',
  }) {
    final bmrBase = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    final bmr = gender == 'female' ? bmrBase - 161 : bmrBase + 5;
    final activity = switch (activityLevel) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'high' => 1.725,
      'athlete' => 1.9,
      _ => 1.55,
    };

    final goalAdjustment = switch (goal) {
      'lose' => -450,
      'gain' => 300,
      _ => 0,
    };

    final dailyCalories = (bmr * activity + goalAdjustment).round();
    final proteinFactor = switch (goal) {
      'lose' => 2.2,
      'gain' => 2.0,
      _ => 1.8,
    };
    final fatFactor = switch (goal) {
      'lose' => 0.8,
      'gain' => 1.0,
      _ => 0.9,
    };

    final proteinGrams = (weightKg * proteinFactor).round();
    final fatGrams = (weightKg * fatFactor).round();
    final remainingCalories =
        dailyCalories - (proteinGrams * 4) - (fatGrams * 9);
    final carbsGrams =
        remainingCalories > 0 ? (remainingCalories / 4).round() : 0;

    final water = estimateWaterLiters(
      weightKg: weightKg,
      heightCm: heightCm,
      gender: gender,
      activityLevel: activityLevel,
    );

    return DailyNutritionTargets(
      calories: dailyCalories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      waterLiters: water,
    );
  }

  /// Daily water need in liters, rounded to 0.25 L (250 ml glasses).
  ///
  /// Base ~35 ml/kg, plus height/gender/activity adjustments (EFSA-style).
  static double estimateWaterLiters({
    required double weightKg,
    required double heightCm,
    required String gender,
    String activityLevel = 'moderate',
  }) {
    return estimateWaterMl(
          weightKg: weightKg,
          heightCm: heightCm,
          gender: gender,
          activityLevel: activityLevel,
        ) /
        1000.0;
  }

  static int estimateWaterMl({
    required double weightKg,
    required double heightCm,
    required String gender,
    String activityLevel = 'moderate',
  }) {
    var ml = weightKg * 35.0;
    ml += ((heightCm - 165) * 3).clamp(-150.0, 300.0);
    if (gender == 'male') ml += 250;
    if (gender == 'female') ml += 0;
    ml += switch (activityLevel) {
      'sedentary' => 0.0,
      'light' => 200.0,
      'high' => 500.0,
      'athlete' => 700.0,
      _ => 350.0,
    };
    final rounded = ((ml / 250).round() * 250).clamp(1500, 5000);
    return rounded.toInt();
  }
}
