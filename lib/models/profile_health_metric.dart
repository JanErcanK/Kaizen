import 'health_dashboard.dart';

/// Profile categories include local tracking without requesting extra health APIs.
enum ProfileHealthMetric {
  sleep,
  steps,
  activeEnergy,
  workouts,
  restingHeartRate,
  hrv,
  weight,
  calorieBurn,
  water,
  afterburn,
  calorieIntake,
  protein,
  fat,
  carbs;

  HealthMetric? get importedMetric => switch (this) {
    sleep => HealthMetric.sleep,
    steps => HealthMetric.steps,
    activeEnergy => HealthMetric.activeEnergy,
    workouts => HealthMetric.workouts,
    restingHeartRate => HealthMetric.restingHeartRate,
    hrv => HealthMetric.hrv,
    weight => HealthMetric.weight,
    _ => null,
  };
}
