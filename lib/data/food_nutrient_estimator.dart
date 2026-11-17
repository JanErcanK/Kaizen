import '../models/food_nutrients.dart';

/// Derives extra macros, micronutrients and amino acids from P/C/F plus the
/// food name/tags. Values are typical USDA/BLS ranges by food family — not lab
/// assays and not the full USDA FoodData Central dump (that would be too large
/// and slow). The ~300-item catalog stays instant this way.
class FoodNutrientEstimator {
  FoodNutrientEstimator._();

  /// [proteinG]/[carbsG]/[fatsG] are already scaled to [grams] (the portion).
  static FoodNutrients forPortion({
    required String name,
    required double grams,
    required double proteinG,
    required double carbsG,
    required double fatsG,
    List<String> tags = const [],
  }) {
    final per100 = forPer100g(
      name: name,
      proteinG: grams <= 0 ? proteinG : proteinG * 100 / grams,
      carbsG: grams <= 0 ? carbsG : carbsG * 100 / grams,
      fatsG: grams <= 0 ? fatsG : fatsG * 100 / grams,
      tags: tags,
    );
    if (grams <= 0) {
      return FoodNutrients(
        proteinG: proteinG,
        carbsG: carbsG,
        fatsG: fatsG,
      );
    }
    final factor = grams / 100.0;
    return FoodNutrients(
      proteinG: proteinG,
      carbsG: carbsG,
      fatsG: fatsG,
      fiberG: per100.fiberG * factor,
      sugarG: per100.sugarG * factor,
      satFatG: per100.satFatG * factor,
      cholesterolMg: per100.cholesterolMg * factor,
      sodiumMg: per100.sodiumMg * factor,
      micros: {
        for (final e in per100.micros.entries) e.key: e.value * factor,
      },
      aminos: {
        for (final e in per100.aminos.entries) e.key: e.value * factor,
      },
    );
  }

  static FoodNutrients forPer100g({
    required String name,
    required double proteinG,
    required double carbsG,
    required double fatsG,
    List<String> tags = const [],
  }) {
    final n = name.toLowerCase();
    final t = tags.map((e) => e.toLowerCase()).toSet();
    final cat = _category(n, t);

    final fiber = _fiber(cat, carbsG, t);
    final sugar = _sugar(cat, carbsG);
    final sat = _satFat(cat, fatsG);
    final chol = _cholesterol(cat, proteinG);
    final sodium = _sodium(cat);

    return FoodNutrients(
      proteinG: proteinG,
      carbsG: carbsG,
      fatsG: fatsG,
      fiberG: fiber.clamp(0, carbsG),
      sugarG: sugar.clamp(0, carbsG),
      satFatG: sat.clamp(0, fatsG),
      cholesterolMg: chol.clamp(0, 800),
      sodiumMg: sodium.clamp(0, 4000),
      micros: _micros(cat),
      aminos: _aminos(cat, proteinG),
    );
  }

  static _Cat _category(String n, Set<String> tags) {
    bool has(List<String> keys) =>
        keys.any((k) => n.contains(k) || tags.contains(k));

    if (has(['eier', 'hühnerei', 'wachtelei', 'gänseei'])) return _Cat.egg;
    if (has(['butter', 'sahne', 'schmalz'])) return _Cat.butter;
    if (has(['öl', 'oel', 'olive'])) return _Cat.oil;
    if (has(['käse', 'kaese', 'parmesan', 'gouda', 'feta', 'mozzarella'])) {
      return _Cat.cheese;
    }
    if (has(['joghurt', 'quark', 'skyr', 'milch', 'kefir', 'buttermilch'])) {
      return _Cat.dairy;
    }
    if (has(['lachs', 'fisch', 'hering', 'makrele', 'thun', 'forelle', 'garnelen'])) {
      return _Cat.fish;
    }
    if (has(['hähnchen', 'haehnchen', 'pute', 'huhn', 'geflügel'])) {
      return _Cat.poultry;
    }
    if (has(['rind', 'schwein', 'hack', 'steak', 'wurst', 'salami', 'schinken'])) {
      return _Cat.meat;
    }
    if (has(['linse', 'bohne', 'kicher', 'erbsen', 'tofu', 'tempeh', 'edamame'])) {
      return _Cat.legume;
    }
    if (has(['nuss', 'nüsse', 'mandel', 'walnuss', 'cashew', 'erdnuss', 'samen', 'leinsamen', 'chia'])) {
      return _Cat.nut;
    }
    if (has(['avocado'])) return _Cat.avocado;
    if (has(['beere', 'apfel', 'banane', 'birne', 'traube', 'orange', 'mango', 'kiwi', 'obst'])) {
      return _Cat.fruit;
    }
    if (has(['vollkorn', 'hafer', 'quinoa', 'dinkel', 'roggen', 'gerste'])) {
      return _Cat.wholeGrain;
    }
    if (has(['reis', 'nudel', 'pasta', 'brot', 'kartoffel', 'carbs'])) {
      return _Cat.starch;
    }
    if (has(['gemüse', 'gemuese', 'spinat', 'brokkoli', 'kohl', 'salat', 'gurke', 'tomate', 'zucchini', 'fiber'])) {
      return _Cat.veg;
    }
    if (has(['zucker', 'schoko', 'kuchen', 'limo', 'cola', 'süß'])) return _Cat.sweet;
    return _Cat.other;
  }

  static double _fiber(_Cat cat, double carbs, Set<String> tags) {
    if (tags.contains('fiber') && cat == _Cat.other) {
      return (carbs * 0.25).clamp(1, 12);
    }
    return switch (cat) {
      _Cat.legume => 7.5,
      _Cat.nut => 8,
      _Cat.wholeGrain => 7,
      _Cat.veg => 2.8,
      _Cat.fruit => 2.2,
      _Cat.avocado => 6.7,
      _Cat.starch => 1.4,
      _Cat.other => carbs > 5 ? carbs * 0.08 : 0,
      _ => 0,
    };
  }

  static double _sugar(_Cat cat, double carbs) {
    return switch (cat) {
      _Cat.fruit => carbs * 0.72,
      _Cat.dairy => carbs * 0.85,
      _Cat.sweet => carbs * 0.9,
      _Cat.veg => carbs * 0.35,
      _Cat.legume => carbs * 0.12,
      _Cat.starch => carbs * 0.04,
      _Cat.wholeGrain => carbs * 0.06,
      _ => 0,
    };
  }

  static double _satFat(_Cat cat, double fats) {
    final ratio = switch (cat) {
      _Cat.butter => 0.52,
      _Cat.cheese => 0.58,
      _Cat.dairy => 0.55,
      _Cat.egg => 0.32,
      _Cat.meat => 0.40,
      _Cat.poultry => 0.28,
      _Cat.fish => 0.22,
      _Cat.oil => 0.14,
      _Cat.nut => 0.10,
      _Cat.avocado => 0.15,
      _ => 0.25,
    };
    return fats * ratio;
  }

  static double _cholesterol(_Cat cat, double protein) {
    return switch (cat) {
      _Cat.egg => 370,
      _Cat.butter => 215,
      _Cat.cheese => 90,
      _Cat.meat => 80,
      _Cat.poultry => 75,
      _Cat.fish => 60,
      _Cat.dairy => 15,
      _ => 0,
    };
  }

  static double _sodium(_Cat cat) {
    return switch (cat) {
      _Cat.cheese => 700,
      _Cat.meat => 70,
      _Cat.fish => 80,
      _Cat.poultry => 65,
      _Cat.dairy => 50,
      _Cat.egg => 140,
      _Cat.butter => 10,
      _Cat.legume => 5,
      _Cat.veg => 20,
      _Cat.starch => 5,
      _ => 30,
    };
  }

  /// Typical USDA values per 100 g by food family — not a lab assay.
  static Map<String, double> _micros(_Cat cat) {
    return switch (cat) {
      _Cat.egg => {
          MicroKeys.vitaminA: 160,
          MicroKeys.vitaminD: 2.2,
          MicroKeys.vitaminE: 1.1,
          MicroKeys.vitaminK: 0.3,
          MicroKeys.riboflavin: 0.46,
          MicroKeys.pantothenic: 1.5,
          MicroKeys.vitaminB6: 0.17,
          MicroKeys.biotin: 20,
          MicroKeys.folate: 47,
          MicroKeys.vitaminB12: 1.1,
          MicroKeys.potassium: 138,
          MicroKeys.calcium: 56,
          MicroKeys.magnesium: 12,
          MicroKeys.iron: 1.8,
          MicroKeys.zinc: 1.3,
          MicroKeys.selenium: 30,
          MicroKeys.iodine: 48,
          MicroKeys.phosphorus: 198,
        },
      _Cat.fish => {
          MicroKeys.vitaminA: 40,
          MicroKeys.vitaminD: 8,
          MicroKeys.vitaminE: 1.5,
          MicroKeys.vitaminK: 0.1,
          MicroKeys.niacin: 6,
          MicroKeys.vitaminB6: 0.4,
          MicroKeys.vitaminB12: 4.5,
          MicroKeys.potassium: 380,
          MicroKeys.calcium: 20,
          MicroKeys.magnesium: 30,
          MicroKeys.iron: 0.8,
          MicroKeys.zinc: 0.6,
          MicroKeys.selenium: 36,
          MicroKeys.iodine: 50,
          MicroKeys.phosphorus: 250,
        },
      _Cat.poultry => {
          MicroKeys.vitaminA: 15,
          MicroKeys.niacin: 8,
          MicroKeys.vitaminB6: 0.5,
          MicroKeys.vitaminB12: 0.3,
          MicroKeys.potassium: 250,
          MicroKeys.magnesium: 25,
          MicroKeys.iron: 0.9,
          MicroKeys.zinc: 1.2,
          MicroKeys.selenium: 22,
          MicroKeys.phosphorus: 180,
        },
      _Cat.meat => {
          MicroKeys.vitaminA: 8,
          MicroKeys.niacin: 5,
          MicroKeys.vitaminB6: 0.35,
          MicroKeys.vitaminB12: 2.0,
          MicroKeys.potassium: 300,
          MicroKeys.magnesium: 20,
          MicroKeys.iron: 2.4,
          MicroKeys.zinc: 4.5,
          MicroKeys.selenium: 20,
          MicroKeys.phosphorus: 180,
        },
      _Cat.cheese => {
          MicroKeys.vitaminA: 250,
          MicroKeys.vitaminD: 0.2,
          MicroKeys.riboflavin: 0.4,
          MicroKeys.vitaminB12: 1.2,
          MicroKeys.potassium: 90,
          MicroKeys.calcium: 700,
          MicroKeys.magnesium: 25,
          MicroKeys.zinc: 3.0,
          MicroKeys.phosphorus: 500,
        },
      _Cat.dairy => {
          MicroKeys.vitaminA: 50,
          MicroKeys.riboflavin: 0.2,
          MicroKeys.vitaminB12: 0.4,
          MicroKeys.potassium: 150,
          MicroKeys.calcium: 120,
          MicroKeys.magnesium: 12,
          MicroKeys.phosphorus: 95,
        },
      _Cat.legume => {
          MicroKeys.vitaminC: 2,
          MicroKeys.thiamin: 0.2,
          MicroKeys.folate: 150,
          MicroKeys.potassium: 400,
          MicroKeys.magnesium: 50,
          MicroKeys.iron: 2.5,
          MicroKeys.zinc: 1.2,
          MicroKeys.phosphorus: 140,
        },
      _Cat.nut => {
          MicroKeys.vitaminE: 8,
          MicroKeys.thiamin: 0.3,
          MicroKeys.folate: 40,
          MicroKeys.potassium: 500,
          MicroKeys.magnesium: 160,
          MicroKeys.iron: 2.5,
          MicroKeys.zinc: 2.5,
          MicroKeys.selenium: 8,
          MicroKeys.phosphorus: 350,
        },
      _Cat.veg => {
          MicroKeys.vitaminA: 400,
          MicroKeys.vitaminC: 40,
          MicroKeys.vitaminK: 140,
          MicroKeys.folate: 60,
          MicroKeys.potassium: 300,
          MicroKeys.calcium: 40,
          MicroKeys.magnesium: 25,
          MicroKeys.iron: 1.0,
        },
      _Cat.fruit => {
          MicroKeys.vitaminA: 30,
          MicroKeys.vitaminC: 35,
          MicroKeys.folate: 20,
          MicroKeys.potassium: 200,
          MicroKeys.magnesium: 12,
        },
      _Cat.avocado => {
          MicroKeys.vitaminE: 2.1,
          MicroKeys.vitaminK: 21,
          MicroKeys.folate: 81,
          MicroKeys.potassium: 485,
          MicroKeys.magnesium: 29,
        },
      _Cat.wholeGrain => {
          MicroKeys.thiamin: 0.4,
          MicroKeys.niacin: 1.5,
          MicroKeys.vitaminB6: 0.12,
          MicroKeys.folate: 30,
          MicroKeys.magnesium: 80,
          MicroKeys.iron: 2.5,
          MicroKeys.zinc: 2.0,
          MicroKeys.phosphorus: 250,
        },
      _Cat.starch => {
          MicroKeys.thiamin: 0.08,
          MicroKeys.niacin: 1.0,
          MicroKeys.potassium: 180,
          MicroKeys.magnesium: 18,
          MicroKeys.iron: 0.5,
          MicroKeys.phosphorus: 50,
        },
      _Cat.oil => {
          MicroKeys.vitaminE: 14,
          MicroKeys.vitaminK: 60,
        },
      _Cat.butter => {
          MicroKeys.vitaminA: 680,
          MicroKeys.vitaminD: 1.5,
          MicroKeys.vitaminE: 2.3,
          MicroKeys.vitaminK: 7,
        },
      _ => {
          MicroKeys.potassium: 80,
          MicroKeys.magnesium: 10,
        },
    };
  }

  /// mg amino acid per g protein (USDA-style profiles). Asn/Gln split from Asp/Glu.
  static Map<String, double> _aminos(_Cat cat, double proteinG) {
    if (proteinG <= 0) return const {};
    final complete = {
      AminoKeys.his: 24.0,
      AminoKeys.ile: 54.0,
      AminoKeys.leu: 86.0,
      AminoKeys.lys: 72.0,
      AminoKeys.met: 30.0,
      AminoKeys.cys: 22.0,
      AminoKeys.phe: 52.0,
      AminoKeys.tyr: 40.0,
      AminoKeys.thr: 46.0,
      AminoKeys.trp: 14.0,
      AminoKeys.val: 66.0,
      AminoKeys.ala: 60.0,
      AminoKeys.arg: 62.0,
      AminoKeys.asp: 60.0,
      AminoKeys.asn: 40.0,
      AminoKeys.glu: 75.0,
      AminoKeys.gln: 55.0,
      AminoKeys.gly: 36.0,
      AminoKeys.pro: 42.0,
      AminoKeys.ser: 72.0,
    };
    final grain = {
      ...complete,
      AminoKeys.lys: 32.0,
      AminoKeys.met: 22.0,
      AminoKeys.trp: 12.0,
    };
    final pulse = {
      ...complete,
      AminoKeys.lys: 70.0,
      AminoKeys.met: 12.0,
      AminoKeys.cys: 12.0,
      AminoKeys.trp: 10.0,
    };
    final plant = {
      ...complete,
      AminoKeys.lys: 40.0,
      AminoKeys.met: 14.0,
      AminoKeys.leu: 70.0,
    };
    final profile = switch (cat) {
      _Cat.egg ||
      _Cat.dairy ||
      _Cat.cheese ||
      _Cat.meat ||
      _Cat.poultry ||
      _Cat.fish =>
        complete,
      _Cat.legume => pulse,
      _Cat.wholeGrain || _Cat.starch => grain,
      _Cat.nut || _Cat.veg || _Cat.fruit || _Cat.avocado => plant,
      _ => complete,
    };
    return {
      for (final e in profile.entries) e.key: e.value * proteinG,
    };
  }
}

enum _Cat {
  egg,
  butter,
  oil,
  cheese,
  dairy,
  fish,
  poultry,
  meat,
  legume,
  nut,
  avocado,
  fruit,
  wholeGrain,
  starch,
  veg,
  sweet,
  other,
}
