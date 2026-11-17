/// Macro + micro + amino totals for a portion or a daily/period average.
class FoodNutrients {
  const FoodNutrients({
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatsG = 0,
    this.fiberG = 0,
    this.sugarG = 0,
    this.satFatG = 0,
    this.cholesterolMg = 0,
    this.sodiumMg = 0,
    this.micros = const {},
    this.aminos = const {},
  });

  final double proteinG;
  final double carbsG;
  final double fatsG;
  final double fiberG;
  final double sugarG;
  final double satFatG;
  final double cholesterolMg;
  final double sodiumMg;

  /// Vitamins and minerals (see [MicroKeys]). Units: mg, mcg or IU as documented.
  final Map<String, double> micros;

  /// Amino acids in milligrams (see [AminoKeys]).
  final Map<String, double> aminos;

  int get kcal => (proteinG * 4 + carbsG * 4 + fatsG * 9).round();

  double micro(String key) => micros[key] ?? 0;
  double amino(String key) => aminos[key] ?? 0;

  bool get isEmpty =>
      proteinG == 0 &&
      carbsG == 0 &&
      fatsG == 0 &&
      fiberG == 0 &&
      sugarG == 0 &&
      satFatG == 0 &&
      cholesterolMg == 0 &&
      sodiumMg == 0 &&
      micros.isEmpty &&
      aminos.isEmpty;

  FoodNutrients operator +(FoodNutrients other) => FoodNutrients(
        proteinG: proteinG + other.proteinG,
        carbsG: carbsG + other.carbsG,
        fatsG: fatsG + other.fatsG,
        fiberG: fiberG + other.fiberG,
        sugarG: sugarG + other.sugarG,
        satFatG: satFatG + other.satFatG,
        cholesterolMg: cholesterolMg + other.cholesterolMg,
        sodiumMg: sodiumMg + other.sodiumMg,
        micros: _addMaps(micros, other.micros),
        aminos: _addMaps(aminos, other.aminos),
      );

  FoodNutrients scaled(double factor) => FoodNutrients(
        proteinG: proteinG * factor,
        carbsG: carbsG * factor,
        fatsG: fatsG * factor,
        fiberG: fiberG * factor,
        sugarG: sugarG * factor,
        satFatG: satFatG * factor,
        cholesterolMg: cholesterolMg * factor,
        sodiumMg: sodiumMg * factor,
        micros: {
          for (final e in micros.entries) e.key: e.value * factor,
        },
        aminos: {
          for (final e in aminos.entries) e.key: e.value * factor,
        },
      );

  Map<String, double> toStorageFields() => {
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatsG': fatsG,
        'fiberG': fiberG,
        'sugarG': sugarG,
        'satFatG': satFatG,
        'cholesterolMg': cholesterolMg,
        'sodiumMg': sodiumMg,
      };

  static FoodNutrients fromMap(Map<String, dynamic> e) {
    double read(String k) {
      final v = e[k];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
      return 0;
    }

    return FoodNutrients(
      proteinG: read('proteinG'),
      carbsG: read('carbsG'),
      fatsG: read('fatsG'),
      fiberG: read('fiberG'),
      sugarG: read('sugarG'),
      satFatG: read('satFatG'),
      cholesterolMg: read('cholesterolMg'),
      sodiumMg: read('sodiumMg'),
    );
  }
}

Map<String, double> _addMaps(Map<String, double> a, Map<String, double> b) {
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  final out = Map<String, double>.from(a);
  for (final e in b.entries) {
    out[e.key] = (out[e.key] ?? 0) + e.value;
  }
  return out;
}

/// Micronutrient keys. Units are daily-goal units (mg or mcg).
abstract final class MicroKeys {
  static const vitaminA = 'vitaminA'; // mcg RAE
  static const vitaminC = 'vitaminC'; // mg
  static const vitaminD = 'vitaminD'; // mcg
  static const vitaminE = 'vitaminE'; // mg
  static const vitaminK = 'vitaminK'; // mcg
  static const thiamin = 'thiamin'; // mg B1
  static const riboflavin = 'riboflavin'; // mg B2
  static const niacin = 'niacin'; // mg B3
  static const pantothenic = 'pantothenic'; // mg B5
  static const vitaminB6 = 'vitaminB6'; // mg
  static const biotin = 'biotin'; // mcg B7
  static const folate = 'folate'; // mcg B9
  static const vitaminB12 = 'vitaminB12'; // mcg
  static const potassium = 'potassium'; // mg
  static const calcium = 'calcium'; // mg
  static const magnesium = 'magnesium'; // mg
  static const iron = 'iron'; // mg
  static const zinc = 'zinc'; // mg
  static const selenium = 'selenium'; // mcg
  static const iodine = 'iodine'; // mcg
  static const phosphorus = 'phosphorus'; // mg

  static const vitamins = [
    vitaminA,
    vitaminC,
    vitaminD,
    vitaminE,
    vitaminK,
    thiamin,
    riboflavin,
    niacin,
    pantothenic,
    vitaminB6,
    biotin,
    folate,
    vitaminB12,
  ];

  static const minerals = [
    potassium,
    calcium,
    magnesium,
    iron,
    zinc,
    selenium,
    iodine,
    phosphorus,
  ];
}

/// 20 proteinogenic amino acids (mg). Asn/Gln are estimated splits of Asp/Glu.
abstract final class AminoKeys {
  static const his = 'his';
  static const ile = 'ile';
  static const leu = 'leu';
  static const lys = 'lys';
  static const met = 'met';
  static const cys = 'cys';
  static const phe = 'phe';
  static const tyr = 'tyr';
  static const thr = 'thr';
  static const trp = 'trp';
  static const val = 'val';
  static const ala = 'ala';
  static const arg = 'arg';
  static const asn = 'asn';
  static const asp = 'asp';
  static const gln = 'gln';
  static const glu = 'glu';
  static const gly = 'gly';
  static const pro = 'pro';
  static const ser = 'ser';

  static const essential = [
    his,
    ile,
    leu,
    lys,
    met,
    phe,
    thr,
    trp,
    val,
  ];

  static const all = [
    his,
    ile,
    leu,
    lys,
    met,
    cys,
    phe,
    tyr,
    thr,
    trp,
    val,
    ala,
    arg,
    asn,
    asp,
    gln,
    glu,
    gly,
    pro,
    ser,
  ];
}
