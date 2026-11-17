/// A bilingual grocery with sourced macros per 100 g edible portion.
class StandardFoodEntry {
  const StandardFoodEntry({
    required this.nameDe,
    required this.nameEn,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    required this.categoryDe,
    required this.categoryEn,
    required this.aliases,
    required this.source,
  });

  final String nameDe;
  final String nameEn;
  final double proteinG;
  final double carbsG;
  final double fatsG;
  final String categoryDe;
  final String categoryEn;
  final String aliases;
  final String source;

  String get macro => fatsG * 9 > proteinG * 4 && fatsG * 9 > carbsG * 4
      ? 'fats'
      : proteinG > carbsG
      ? 'protein'
      : 'carbs';
  String get subtitleDe => '$categoryDe. Richtwerte pro 100 g.';
  String get subtitleEn => '$categoryEn. Typical values per 100 g.';
}
