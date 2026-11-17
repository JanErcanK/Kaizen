import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../models/food_nutrients.dart';
import '../services/nutrition_calculator.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';

class NutrientTargets {
  const NutrientTargets({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.carbsMinG,
    required this.carbsMaxG,
    required this.fatG,
    required this.fiberG,
    required this.satFatG,
    required this.cholesterolMg,
    required this.sugarG,
    required this.sodiumMg,
    required this.micros,
    required this.aminos,
  });

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double carbsMinG;
  final double carbsMaxG;
  final double fatG;
  final double fiberG;
  final double satFatG;
  final double cholesterolMg;
  final double sugarG;
  final double sodiumMg;
  final Map<String, double> micros;
  final Map<String, double> aminos;

  factory NutrientTargets.fromProfile() {
    final age = ProgressStore.profileAge;
    final height = ProgressStore.profileHeightCm;
    final weight = ProgressStore.currentWeightKg;
    final gender = ProgressStore.profileGender ?? 'male';
    DailyNutritionTargets? macros;
    if (age != null && height != null && weight != null) {
      macros = NutritionCalculator.calculate(
        age: age,
        heightCm: height,
        weightKg: weight,
        gender: gender,
        activityLevel: ProgressStore.profileActivityLevel ?? 'moderate',
        goal: ProgressStore.profileGoal ?? 'maintain',
      );
    }
    final kcal = (macros?.calories ?? 2200).toDouble();
    final fat = (macros?.fatGrams ?? 70).toDouble();
    final carbs = (macros?.carbsGrams ?? 220).toDouble();
    final protein = (macros?.proteinGrams ?? 140).toDouble();
    final isFemale = gender == 'female';
    return NutrientTargets(
      kcal: kcal,
      proteinG: protein,
      carbsG: carbs,
      carbsMinG: kcal * 0.25 / 4,
      carbsMaxG: kcal * 0.45 / 4,
      fatG: fat,
      fiberG: 30,
      satFatG: (kcal * 0.10 / 9).clamp(12, fat),
      cholesterolMg: 300,
      sugarG: (kcal * 0.10 / 4).clamp(25, 60),
      sodiumMg: 2000,
      micros: {
        MicroKeys.vitaminA: 800,
        MicroKeys.vitaminC: isFemale ? 95 : 110,
        MicroKeys.vitaminD: 20,
        MicroKeys.vitaminE: 13,
        MicroKeys.vitaminK: 70,
        MicroKeys.thiamin: 1.2,
        MicroKeys.riboflavin: 1.3,
        MicroKeys.niacin: 15,
        MicroKeys.pantothenic: 6,
        MicroKeys.vitaminB6: 1.5,
        MicroKeys.biotin: 40,
        MicroKeys.folate: 300,
        MicroKeys.vitaminB12: 4,
        MicroKeys.potassium: 3500,
        MicroKeys.calcium: 1000,
        MicroKeys.magnesium: isFemale ? 300 : 350,
        MicroKeys.iron: isFemale ? 15 : 10,
        MicroKeys.zinc: isFemale ? 8 : 11,
        MicroKeys.selenium: 70,
        MicroKeys.iodine: 150,
        MicroKeys.phosphorus: 700,
      },
      aminos: {
        AminoKeys.his: protein * 15,
        AminoKeys.ile: protein * 30,
        AminoKeys.leu: protein * 59,
        AminoKeys.lys: protein * 45,
        AminoKeys.met: protein * 16,
        AminoKeys.cys: protein * 6,
        AminoKeys.phe: protein * 25,
        AminoKeys.tyr: protein * 13,
        AminoKeys.thr: protein * 23,
        AminoKeys.trp: protein * 6,
        AminoKeys.val: protein * 39,
        AminoKeys.ala: protein * 50,
        AminoKeys.arg: protein * 40,
        AminoKeys.asn: protein * 35,
        AminoKeys.asp: protein * 50,
        AminoKeys.gln: protein * 50,
        AminoKeys.glu: protein * 70,
        AminoKeys.gly: protein * 30,
        AminoKeys.pro: protein * 40,
        AminoKeys.ser: protein * 40,
      },
    );
  }
}

/// Cronometer-style nutrient rows: macros, micros, amino acids.
class DailyNutrientsPanel extends StatelessWidget {
  const DailyNutrientsPanel({
    super.key,
    required this.totals,
    this.targets,
    this.title,
    this.infoOnly = false,
  });

  final FoodNutrients totals;
  final NutrientTargets? targets;
  final String? title;
  final bool infoOnly;

  @override
  Widget build(BuildContext context) {
    final t = targets ?? NutrientTargets.fromProfile();
    final isDe = context.l10n.localeName.startsWith('de');

    Widget row({
      required String name,
      required String info,
      required double value,
      required double goal,
      required String unit,
      Color? fill,
      bool plusGoal = false,
      String? goalDisplay,
    }) {
      return _NutrientRow(
        name: name,
        info: info,
        value: value,
        goal: goal,
        unit: unit,
        fill: fill,
        plusGoal: plusGoal,
        infoOnly: infoOnly,
        goalDisplay: goalDisplay,
      );
    }

    String fmt(double v) {
      if (v >= 100) return v.round().toString();
      if (v >= 10) return v.toStringAsFixed(0);
      return v.toStringAsFixed(1);
    }

    List<Widget> microRows(List<String> keys) {
      return [
        for (final key in keys)
          row(
            name: _microName(key, isDe),
            info: _microInfo(key, isDe),
            value: totals.micro(key),
            goal: t.micros[key] ?? 1,
            unit: _microUnit(key),
            plusGoal: true,
          ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
        ],
        _SectionHeader(
          label: isDe ? 'Makronährstoffe' : 'Macronutrients',
          info: isDe
              ? 'Kalorien, Protein, Kohlenhydrate, Fett und verwandte Größen. Schätzwerte aus Nährwerttabellen (USDA/BLS).'
              : 'Calories, protein, carbs, fat and related amounts. Estimates from nutrition tables (USDA/BLS).',
        ),
        _SectionCard(
          child: Column(
            children: [
              row(
                name: isDe ? 'Kalorien' : 'Calories',
                info: isDe
                    ? 'Energie aus Protein, Kohlenhydraten und Fett.'
                    : 'Energy from protein, carbs and fat.',
                value: totals.kcal.toDouble(),
                goal: t.kcal,
                unit: 'kcal',
                fill: AppColors.primary,
              ),
              row(
                name: isDe ? 'Protein' : 'Protein',
                info: isDe
                    ? 'Baustoff für Muskeln. Ziel hängt von Gewicht und Ziel ab.'
                    : 'Building block for muscle. Target depends on weight and goal.',
                value: totals.proteinG,
                goal: t.proteinG,
                unit: 'g',
                plusGoal: true,
                fill: AppColors.nutrition,
              ),
              row(
                name: isDe ? 'Kohlenhydrate' : 'Carbohydrates',
                info: isDe
                    ? 'Hauptenergiequelle. Spanne je nach Kalorienziel.'
                    : 'Main energy source. Range depends on calorie target.',
                value: totals.carbsG,
                goal: t.carbsMaxG,
                unit: 'g',
                fill: const Color(0xFF43B86B),
                goalDisplay:
                    '${fmt(totals.carbsG)} / ${fmt(t.carbsMinG)}-${fmt(t.carbsMaxG)}g',
              ),
              row(
                name: isDe ? 'Fett' : 'Fat',
                info: isDe
                    ? 'Hormone, Vitamine, Sättigung. Nicht unter das Ziel drücken.'
                    : 'Hormones, vitamins, satiety. Do not go far below target.',
                value: totals.fatsG,
                goal: t.fatG,
                unit: 'g',
              ),
              row(
                name: isDe ? 'Ballaststoffe' : 'Fiber',
                info: isDe
                    ? 'Fördern Verdauung und Sättigung. Ziel ca. 30 g/Tag.'
                    : 'Supports digestion and satiety. Target about 30 g/day.',
                value: totals.fiberG,
                goal: t.fiberG,
                unit: 'g',
                plusGoal: true,
              ),
              row(
                name: isDe ? 'Gesättigte Fettsäuren' : 'Saturated fat',
                info: isDe
                    ? 'Möglichst unter 10 % der Kalorien halten.'
                    : 'Keep below about 10% of calories.',
                value: totals.satFatG,
                goal: t.satFatG,
                unit: 'g',
              ),
              row(
                name: isDe ? 'Cholesterin' : 'Cholesterol',
                info: isDe
                    ? 'Vor allem in Eiern, Fleisch und Milchprodukten. Orientierung 300 mg.'
                    : 'Mostly in eggs, meat and dairy. Guideline 300 mg.',
                value: totals.cholesterolMg,
                goal: t.cholesterolMg,
                unit: 'mg',
              ),
              row(
                name: isDe ? 'Zucker' : 'Sugar',
                info: isDe
                    ? 'Freier und natürlicher Zucker. Orientierung unter 10 % der Kalorien.'
                    : 'Free and natural sugars. Guideline under 10% of calories.',
                value: totals.sugarG,
                goal: t.sugarG,
                unit: 'g',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionHeader(
          label: isDe ? 'Mikronährstoffe' : 'Micronutrients',
          info: isDe
              ? 'Vitamine und Mineralstoffe. Typische Werte nach Lebensmittelgruppe (USDA), keine Laboranalyse. Volle USDA-FoodData-Central-Tabelle wäre zu groß für die App.'
              : 'Vitamins and minerals. Typical values by food family (USDA), not a lab assay. The full USDA FoodData Central table would be too large for the app.',
        ),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubLabel(isDe ? 'Vitamine' : 'Vitamins'),
              ...microRows(MicroKeys.vitamins),
              const SizedBox(height: 8),
              _SubLabel(isDe ? 'Mineralstoffe' : 'Minerals'),
              row(
                name: isDe ? 'Natrium' : 'Sodium',
                info: isDe
                    ? 'Salz. WHO-Orientierung unter 2 g Natrium (ca. 5 g Salz) pro Tag.'
                    : 'Salt. WHO guideline under 2 g sodium (~5 g salt) per day.',
                value: totals.sodiumMg,
                goal: t.sodiumMg,
                unit: 'mg',
              ),
              ...microRows(MicroKeys.minerals),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionHeader(
          label: isDe ? 'Aminosäuren' : 'Amino acids',
          info: isDe
              ? '20 proteinogene Aminosäuren. Profil je Lebensmittelgruppe, skaliert am Protein (USDA-typisch). Ziele der essenziellen nach WHO/FAO je Gramm Protein.'
              : '20 proteinogenic amino acids. Profile by food family, scaled to protein (USDA-typical). Essential targets follow WHO/FAO per gram of protein.',
        ),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubLabel(isDe ? 'Essenziell' : 'Essential'),
              for (final key in AminoKeys.essential)
                row(
                  name: _aminoName(key, isDe),
                  info: _aminoInfo(key, isDe),
                  value: totals.amino(key),
                  goal: t.aminos[key] ?? 1,
                  unit: 'mg',
                  plusGoal: true,
                ),
              const SizedBox(height: 8),
              _SubLabel(isDe ? 'Weitere' : 'Others'),
              for (final key in AminoKeys.all)
                if (!AminoKeys.essential.contains(key))
                  row(
                    name: _aminoName(key, isDe),
                    info: _aminoInfo(key, isDe),
                    value: totals.amino(key),
                    goal: t.aminos[key] ?? 1,
                    unit: 'mg',
                    plusGoal: true,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.info});
  final String label;
  final String info;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          _InfoIcon(text: info),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: child,
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({
    required this.name,
    required this.info,
    required this.value,
    required this.goal,
    required this.unit,
    required this.infoOnly,
    this.fill,
    this.plusGoal = false,
    this.goalDisplay,
  });

  final String name;
  final String info;
  final double value;
  final double goal;
  final String unit;
  final Color? fill;
  final bool plusGoal;
  final bool infoOnly;
  final String? goalDisplay;

  String _fmt(double v) {
    if (v >= 100) return v.round().toString();
    if (v >= 10) return v.toStringAsFixed(0);
    if (v >= 1) return v.toStringAsFixed(1);
    if (v <= 0) return '0';
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    final barColor = fill ??
        (progress >= 1 && !plusGoal
            ? const Color(0xFF8E8E93)
            : AppColors.textPrimary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _InfoIcon(text: info),
                  ],
                ),
              ),
              Text(
                infoOnly
                    ? '${_fmt(value)} $unit'
                    : (goalDisplay ??
                        '${_fmt(value)} / ${_fmt(goal)}$unit${plusGoal ? '+' : ''}'),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: infoOnly ? 1 : progress,
              minHeight: 5,
              backgroundColor: AppColors.stroke.withValues(alpha: 0.45),
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  const _InfoIcon({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            title: Icon(Icons.info_outline, color: AppColors.nutrition, size: 22),
            content: Text(
              text,
              style: TextStyle(color: AppColors.textPrimary, height: 1.35),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ctx.l10n.common_ok),
              ),
            ],
          ),
        );
      },
      child: Icon(
        Icons.info_outline,
        size: 14,
        color: AppColors.textMuted,
      ),
    );
  }
}

String _microUnit(String key) {
  const mcg = {
    MicroKeys.vitaminA,
    MicroKeys.vitaminD,
    MicroKeys.vitaminK,
    MicroKeys.biotin,
    MicroKeys.folate,
    MicroKeys.vitaminB12,
    MicroKeys.selenium,
    MicroKeys.iodine,
  };
  return mcg.contains(key) ? 'mcg' : 'mg';
}

String _microName(String key, bool isDe) {
  return switch (key) {
    MicroKeys.vitaminA => isDe ? 'Vitamin A' : 'Vitamin A',
    MicroKeys.vitaminC => isDe ? 'Vitamin C' : 'Vitamin C',
    MicroKeys.vitaminD => isDe ? 'Vitamin D' : 'Vitamin D',
    MicroKeys.vitaminE => isDe ? 'Vitamin E' : 'Vitamin E',
    MicroKeys.vitaminK => isDe ? 'Vitamin K' : 'Vitamin K',
    MicroKeys.thiamin => isDe ? 'Thiamin (B1)' : 'Thiamin (B1)',
    MicroKeys.riboflavin => isDe ? 'Riboflavin (B2)' : 'Riboflavin (B2)',
    MicroKeys.niacin => isDe ? 'Niacin (B3)' : 'Niacin (B3)',
    MicroKeys.pantothenic =>
      isDe ? 'Pantothensäure (B5)' : 'Pantothenic acid (B5)',
    MicroKeys.vitaminB6 => isDe ? 'Vitamin B6' : 'Vitamin B6',
    MicroKeys.biotin => isDe ? 'Biotin (B7)' : 'Biotin (B7)',
    MicroKeys.folate => isDe ? 'Folat (B9)' : 'Folate (B9)',
    MicroKeys.vitaminB12 => isDe ? 'Vitamin B12' : 'Vitamin B12',
    MicroKeys.potassium => isDe ? 'Kalium' : 'Potassium',
    MicroKeys.calcium => isDe ? 'Calcium' : 'Calcium',
    MicroKeys.magnesium => isDe ? 'Magnesium' : 'Magnesium',
    MicroKeys.iron => isDe ? 'Eisen' : 'Iron',
    MicroKeys.zinc => isDe ? 'Zink' : 'Zinc',
    MicroKeys.selenium => isDe ? 'Selen' : 'Selenium',
    MicroKeys.iodine => isDe ? 'Jod' : 'Iodine',
    MicroKeys.phosphorus => isDe ? 'Phosphor' : 'Phosphorus',
    _ => key,
  };
}

String _microInfo(String key, bool isDe) {
  return isDe
      ? 'Schätzwert nach Lebensmittelgruppe (USDA-typisch), skaliert auf die Portion.'
      : 'Estimate by food family (USDA-typical), scaled to the portion.';
}

String _aminoName(String key, bool isDe) {
  return switch (key) {
    AminoKeys.his => isDe ? 'Histidin' : 'Histidine',
    AminoKeys.ile => isDe ? 'Isoleucin' : 'Isoleucine',
    AminoKeys.leu => isDe ? 'Leucin' : 'Leucine',
    AminoKeys.lys => isDe ? 'Lysin' : 'Lysine',
    AminoKeys.met => isDe ? 'Methionin' : 'Methionine',
    AminoKeys.cys => isDe ? 'Cystein' : 'Cysteine',
    AminoKeys.phe => isDe ? 'Phenylalanin' : 'Phenylalanine',
    AminoKeys.tyr => isDe ? 'Tyrosin' : 'Tyrosine',
    AminoKeys.thr => isDe ? 'Threonin' : 'Threonine',
    AminoKeys.trp => isDe ? 'Tryptophan' : 'Tryptophan',
    AminoKeys.val => isDe ? 'Valin' : 'Valine',
    AminoKeys.ala => isDe ? 'Alanin' : 'Alanine',
    AminoKeys.arg => isDe ? 'Arginin' : 'Arginine',
    AminoKeys.asn => isDe ? 'Asparagin' : 'Asparagine',
    AminoKeys.asp => isDe ? 'Asparaginsäure' : 'Aspartic acid',
    AminoKeys.gln => isDe ? 'Glutamin' : 'Glutamine',
    AminoKeys.glu => isDe ? 'Glutaminsäure' : 'Glutamic acid',
    AminoKeys.gly => isDe ? 'Glycin' : 'Glycine',
    AminoKeys.pro => isDe ? 'Prolin' : 'Proline',
    AminoKeys.ser => isDe ? 'Serin' : 'Serine',
    _ => key,
  };
}

String _aminoInfo(String key, bool isDe) {
  final essential = AminoKeys.essential.contains(key);
  if (isDe) {
    return essential
        ? 'Essenzielle Aminosäure. Ziel nach WHO/FAO je Gramm Protein.'
        : 'Proteinogene Aminosäure. Schätzprofil der Lebensmittelgruppe.';
  }
  return essential
      ? 'Essential amino acid. Target follows WHO/FAO per gram of protein.'
      : 'Proteinogenic amino acid. Estimated from the food family profile.';
}
