// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Generates lib/l10n/catalog_localizations.dart from screen catalogs.
void main() {
  final foodSrc = File('lib/screens/food_screen.dart').readAsStringSync();
  final gymSrc = File('lib/screens/gym_screen.dart').readAsStringSync();
  final caliSrc = File('lib/screens/calisthenics_screen.dart').readAsStringSync();
  final workoutSrc =
      File('lib/screens/category_detail_screen.dart').readAsStringSync();

  final foodItems = _extractFoodItems(foodSrc);
  final foodTags = _extractFoodTags(foodSrc);
  final gymExercises = _extractExercises(gymSrc, '_GymExercise');
  final caliExercises = _extractExercises(caliSrc, '_CaliExercise');
  final workoutData = _extractWorkoutExercises(workoutSrc);

  final foodEn = {for (final e in foodItems.entries) e.key: _foodEnglish(e.key)};
  final foodSubDe = Map<String, String>.from(foodItems);
  final foodSubEn = {
    for (final e in foodItems.entries) e.key: _translateFreeText(e.value),
  };

  final gymEn = {
    for (final e in gymExercises) e.name: _gymEnglish(e.name),
  };
  final gymDescDe = {
    for (final e in gymExercises) e.name: e.description,
  };
  final gymDescEn = {
    for (final e in gymExercises) e.name: _translateFreeText(e.description),
  };

  final caliEn = {
    for (final e in caliExercises) e.name: _caliEnglish(e.name),
  };
  final caliDescDe = {
    for (final e in caliExercises) e.name: e.description,
  };
  final caliDescEn = {
    for (final e in caliExercises) e.name: _translateFreeText(e.description),
  };

  final muscleTerms = <String>{
    'Alle',
    ...gymExercises.map((e) => e.mainGroup),
    ...caliExercises.map((e) => e.mainGroup),
    ...gymExercises.expand((e) => e.tags),
    ...caliExercises.expand((e) => e.tags),
  };
  final muscleEn = {
    for (final t in muscleTerms) t: _muscleEnglish(t),
  };

  final workoutNameEn = {
    for (final n in workoutData.names) n: _workoutExerciseEnglish(n),
  };
  final workoutBenefitEn = {
    for (final b in workoutData.benefits) b: _translateFreeText(b),
  };

  final foodTagDe = {
    for (final t in foodTags) t: _foodTagGerman(t),
  };
  final foodTagEn = {
    for (final t in foodTags) t: _foodTagEnglish(t),
  };

  final out = StringBuffer('''
import '../services/progress_store.dart';

/// Displays catalog content (food names, exercise text) in the active locale.
/// German canonical strings are used as storage keys in Hive.
class CatalogLocalizations {
  const CatalogLocalizations._();

  static String text(String germanCanonical, {required String english}) {
    return ProgressStore.useGerman ? germanCanonical : english;
  }

  static String foodName(String germanCanonical) {
    return text(
      germanCanonical,
      english: foodEnglishNames[germanCanonical] ?? germanCanonical,
    );
  }

  static String foodSubtitle(String foodName) {
    final german = foodGermanSubtitles[foodName] ?? foodName;
    return text(
      german,
      english: foodEnglishSubtitles[foodName] ?? german,
    );
  }

  static String gymExerciseName(String germanCanonical) {
    return text(
      germanCanonical,
      english: gymExerciseEnglishNames[germanCanonical] ?? germanCanonical,
    );
  }

  static String gymDescription(String exerciseName) {
    final german = gymGermanDescriptions[exerciseName] ?? exerciseName;
    return text(
      german,
      english: gymEnglishDescriptions[exerciseName] ?? german,
    );
  }

  static String calisthenicsExerciseName(String germanCanonical) {
    return text(
      germanCanonical,
      english: calisthenicsExerciseEnglishNames[germanCanonical] ??
          germanCanonical,
    );
  }

  static String calisthenicsDescription(String exerciseName) {
    final german = calisthenicsGermanDescriptions[exerciseName] ?? exerciseName;
    return text(
      german,
      english: calisthenicsEnglishDescriptions[exerciseName] ?? german,
    );
  }

  static String muscleGroup(String germanTerm) {
    return text(
      germanTerm,
      english: muscleGroupEnglish[germanTerm] ?? germanTerm,
    );
  }

  static String muscleTag(String germanTag) {
    return text(
      germanTag,
      english: muscleGroupEnglish[germanTag] ?? germanTag,
    );
  }

  static String workoutExerciseName(String name) {
    return text(
      name,
      english: workoutExerciseEnglishNames[name] ?? name,
    );
  }

  static String workoutExerciseBenefit(String benefit) {
    return text(
      benefit,
      english: workoutExerciseEnglishBenefits[benefit] ?? benefit,
    );
  }

  /// Resolves gym, calisthenics, or timed-workout exercise names for display.
  static String anyExerciseName(String germanName) {
    if (ProgressStore.useGerman) return germanName;
    return workoutExerciseEnglishNames[germanName] ??
        gymExerciseEnglishNames[germanName] ??
        calisthenicsExerciseEnglishNames[germanName] ??
        germanName;
  }

  static String exerciseFallback() =>
      ProgressStore.useGerman ? 'Übung' : 'Exercise';

  static String foodTag(String tagId) {
    return text(
      foodTagGerman[tagId] ?? tagId,
      english: foodTagEnglish[tagId] ?? tagId,
    );
  }

  static String foodFocus(String focusId) {
    return switch (focusId) {
      'never_eat' => text('Nie essen', english: 'Never eat'),
      'healthy_brain' => text('Gehirngesund', english: 'Healthy brain'),
      _ => focusId.replaceAll('_', ' '),
    };
  }

  static const Map<String, String> foodEnglishNames = {
''');

  _writeMap(out, foodEn);
  out.writeln('  };\n');
  out.writeln('  static const Map<String, String> foodGermanSubtitles = {');
  _writeMap(out, foodSubDe);
  out.writeln('  };\n');
  out.writeln('  static const Map<String, String> foodEnglishSubtitles = {');
  _writeMap(out, foodSubEn);
  out.writeln('  };\n');
  out.writeln('  static const Map<String, String> gymExerciseEnglishNames = {');
  _writeMap(out, gymEn);
  out.writeln('  };\n');
  out.writeln('  static const Map<String, String> gymGermanDescriptions = {');
  _writeMap(out, gymDescDe);
  out.writeln('  };\n');
  out.writeln('  static const Map<String, String> gymEnglishDescriptions = {');
  _writeMap(out, gymDescEn);
  out.writeln('  };\n');
  out.writeln(
      '  static const Map<String, String> calisthenicsExerciseEnglishNames = {');
  _writeMap(out, caliEn);
  out.writeln('  };\n');
  out.writeln(
      '  static const Map<String, String> calisthenicsGermanDescriptions = {');
  _writeMap(out, caliDescDe);
  out.writeln('  };\n');
  out.writeln(
      '  static const Map<String, String> calisthenicsEnglishDescriptions = {');
  _writeMap(out, caliDescEn);
  out.writeln('  };\n');
  out.writeln('  static const Map<String, String> muscleGroupEnglish = {');
  _writeMap(out, muscleEn);
  out.writeln('  };\n');
  out.writeln('  static const Map<String, String> workoutExerciseEnglishNames = {');
  _writeMap(out, workoutNameEn);
  out.writeln('  };\n');
  out.writeln(
      '  static const Map<String, String> workoutExerciseEnglishBenefits = {');
  _writeMap(out, workoutBenefitEn);
  out.writeln('  };\n');
  out.writeln('  static const Map<String, String> foodTagGerman = {');
  _writeMap(out, foodTagDe);
  out.writeln('  };\n');
  out.writeln('  static const Map<String, String> foodTagEnglish = {');
  _writeMap(out, foodTagEn);
  out.writeln('  };');
  out.writeln('}');

  File('lib/l10n/catalog_localizations.dart').writeAsStringSync(out.toString());

  print('Wrote catalog_localizations.dart:');
  print('  foodEnglishNames: ${foodEn.length}');
  print('  foodEnglishSubtitles: ${foodSubEn.length}');
  print('  gymExerciseEnglishNames: ${gymEn.length}');
  print('  gymEnglishDescriptions: ${gymDescEn.length}');
  print('  calisthenicsExerciseEnglishNames: ${caliEn.length}');
  print('  calisthenicsEnglishDescriptions: ${caliDescEn.length}');
  print('  muscleGroupEnglish: ${muscleEn.length}');
  print('  workoutExerciseEnglishNames: ${workoutNameEn.length}');
  print('  workoutExerciseEnglishBenefits: ${workoutBenefitEn.length}');
  print('  foodTagGerman: ${foodTagDe.length}');
  print('  foodTagEnglish: ${foodTagEn.length}');
}

Set<String> _extractFoodTags(String src) {
  final tags = <String>{};
  final blocks = src.split('_FoodItem(');
  for (final block in blocks.skip(1)) {
    tags.addAll(_extractTags(block));
  }
  return tags;
}

String _foodTagGerman(String id) => _foodTagLabels[id]?.$1 ?? _slugToGerman(id);

String _foodTagEnglish(String id) => _foodTagLabels[id]?.$2 ?? id;

String _slugToGerman(String slug) => slug.replaceAll('_', ' ');

void _writeMap(StringBuffer out, Map<String, String> map) {
  for (final e in map.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
    out.writeln('    ${_quote(e.key)}: ${_quote(e.value)},');
  }
}

Map<String, String> _extractFoodItems(String src) {
  final items = <String, String>{};
  final blocks = src.split('_FoodItem(');
  for (final block in blocks.skip(1)) {
    final name = _extractField(block, 'name');
    final subtitle = _extractField(block, 'subtitle');
    if (name != null && subtitle != null) {
      items[name] = subtitle;
    }
  }
  return items;
}

List<_ExerciseRecord> _extractExercises(String src, String marker) {
  final records = <_ExerciseRecord>[];
  final blocks = src.split('$marker(');
  for (final block in blocks.skip(1)) {
    final name = _extractField(block, 'name');
    final description = _extractField(block, 'description');
    final mainGroup = _extractField(block, 'mainGroup');
    if (name == null || description == null || mainGroup == null) continue;
    records.add(_ExerciseRecord(
      name: name,
      description: description,
      mainGroup: mainGroup,
      tags: _extractTags(block),
    ));
  }
  return records;
}

({Set<String> names, Set<String> benefits}) _extractWorkoutExercises(
  String src,
) {
  final names = <String>{};
  final benefits = <String>{};
  final blocks = src.split('WorkoutExercise(');
  for (final block in blocks.skip(1)) {
    final name = _extractField(block, 'name');
    final benefit = _extractField(block, 'benefit');
    if (name != null) names.add(name);
    if (benefit != null) benefits.add(benefit);
  }
  return (names: names, benefits: benefits);
}

String? _extractField(String block, String field) {
  final multiline = RegExp(
    "$field:\\s*\\n\\s*'((?:[^'\\\\]|\\\\.)*)'",
    dotAll: true,
  ).firstMatch(block);
  if (multiline != null) {
    return _unescapeDartString(multiline.group(1)!);
  }
  final inline = RegExp(
    "$field:\\s*'((?:[^'\\\\]|\\\\.)*)'",
  ).firstMatch(block);
  if (inline != null) {
    return _unescapeDartString(inline.group(1)!);
  }
  return null;
}

List<String> _extractTags(String block) {
  final m = RegExp(r'tags:\s*\[(.*?)\]', dotAll: true).firstMatch(block);
  if (m == null) return [];
  return RegExp(r"'([^']*)'")
      .allMatches(m.group(1)!)
      .map((x) => x.group(1)!)
      .toList();
}

String _unescapeDartString(String s) =>
    s.replaceAll(r"\'", "'").replaceAll(r'\\', r'\');

String _quote(String s) => jsonEncode(s);

String _foodEnglish(String de) {
  if (_foodDict.containsKey(de)) return _foodDict[de]!;
  final paren = RegExp(r'\(([^)]+)\)').firstMatch(de);
  if (paren != null) {
    final inner = paren.group(1)!;
    if (_looksEnglish(inner)) {
      final base = de.replaceAll(RegExp(r'\s*\([^)]+\)'), '').trim();
      return '${_translateCompound(base)} ($inner)';
    }
  }
  return _translateCompound(de);
}

bool _looksEnglish(String s) =>
    !RegExp(r'[äöüÄÖÜß]').hasMatch(s) && RegExp(r'[A-Za-z]').hasMatch(s);

String _translateCompound(String de) {
  var s = de;
  for (final e in _sortedWordDict) {
    s = s.replaceAll(e.key, e.value);
  }
  return s
      .split(' ')
      .map(_titleWord)
      .join(' ')
      .replaceAllMapped(RegExp(r'\(([^)]+)\)'), (m) => '(${m[1]})');
}

String _translateWord(String w) {
  if (_wordDict.containsKey(w)) return _wordDict[w]!;
  return _titleWord(w);
}

String _titleWord(String w) {
  if (w.isEmpty) return w;
  return w[0].toUpperCase() + w.substring(1);
}

String _gymEnglish(String de) =>
    _gymDict[de] ?? _extractParenEnglish(de, _gymDict) ?? _translateCompound(de);

String _caliEnglish(String de) =>
    _caliDict[de] ?? _extractParenEnglish(de, _caliDict) ?? _translateCompound(de);

String? _extractParenEnglish(String de, Map<String, String> dict) {
  final m = RegExp(r'\(([^)]+)\)').firstMatch(de);
  if (m == null) return null;
  final inner = m.group(1)!;
  if (!_looksEnglish(inner)) return null;
  final base = de.replaceAll(RegExp(r'\s*\([^)]+\)'), '').trim();
  final baseEn = dict[base] ?? _translateCompound(base);
  if (baseEn == base) {
    return inner.contains('/') ? '$baseEn ($inner)' : inner;
  }
  return '$baseEn ($inner)';
}

String _muscleEnglish(String de) {
  if (_muscleDict.containsKey(de)) return _muscleDict[de]!;
  if (de.startsWith('Skill:')) {
    final skill = de.substring('Skill:'.length);
    return 'Skill: ${_looksEnglish(skill) ? skill : _translateCompound(skill)}';
  }
  return _translateCompound(de);
}

String _workoutExerciseEnglish(String name) {
  if (_workoutNameDict.containsKey(name)) return _workoutNameDict[name]!;
  if (_looksEnglish(name.replaceAll('-', ' '))) return name;
  return _translateCompound(name);
}

String _translateFreeText(String de) {
  var s = de;
  for (final e in _sortedFreeTextDict) {
    s = s.replaceAll(e.key, e.value);
  }
  return s;
}

List<MapEntry<String, String>> _sortedEntries(Map<String, String> dict) {
  return dict.entries.toList()
    ..sort((a, b) => b.key.length.compareTo(a.key.length));
}

final _sortedWordDict = _sortedEntries(_wordDict);
final _sortedFreeTextDict = _sortedEntries(_freeTextDict);

class _ExerciseRecord {
  const _ExerciseRecord({
    required this.name,
    required this.description,
    required this.mainGroup,
    required this.tags,
  });

  final String name;
  final String description;
  final String mainGroup;
  final List<String> tags;
}

final _foodTagLabels = <String, (String, String)>{
  'algen': ('Algen', 'Seaweed'),
  'amaranth': ('Amaranth', 'Amaranth'),
  'antioxidants': ('Antioxidantien', 'Antioxidants'),
  'avocado': ('Avocado', 'Avocado'),
  'basmati': ('Basmati', 'Basmati'),
  'beeren': ('Beeren', 'Berries'),
  'blattgemuese': ('Blattgemüse', 'Leafy greens'),
  'bohnen': ('Bohnen', 'Beans'),
  'buchweizen': ('Buchweizen', 'Buckwheat'),
  'calamari': ('Calamari', 'Calamari'),
  'calcium': ('Calcium', 'Calcium'),
  'carbs': ('Kohlenhydrate', 'Carbs'),
  'casein': ('Casein', 'Casein'),
  'choline': ('Cholin', 'Choline'),
  'dinkel': ('Dinkel', 'Spelt'),
  'easy': ('Leicht verdaulich', 'Easy digest'),
  'edamame': ('Edamame', 'Edamame'),
  'ei': ('Ei', 'Egg'),
  'energy': ('Energie', 'Energy'),
  'erbsen': ('Erbsen', 'Peas'),
  'exoten': ('Exoten', 'Exotic'),
  'fats': ('Fette', 'Fats'),
  'fermented': ('Fermentiert', 'Fermented'),
  'fettfisch': ('Fettfisch', 'Fatty fish'),
  'fiber': ('Ballaststoffe', 'Fiber'),
  'fisch': ('Fisch', 'Fish'),
  'flohsamen': ('Flohsamen', 'Psyllium'),
  'fruchtgemuese': ('Fruchtgemüse', 'Fruit vegetables'),
  'gefluegel': ('Geflügel', 'Poultry'),
  'gemuese': ('Gemüse', 'Vegetables'),
  'gerste': ('Gerste', 'Barley'),
  'getreide': ('Getreide', 'Grains'),
  'glutenfrei': ('Glutenfrei', 'Gluten-free'),
  'gruenkern': ('Grünkern', 'Green spelt'),
  'gurke': ('Gurke', 'Cucumber'),
  'hanf': ('Hanf', 'Hemp'),
  'healthy': ('Gesund', 'Healthy'),
  'hirse': ('Hirse', 'Millet'),
  'huelsenfrucht': ('Hülsenfrucht', 'Legume'),
  'huelsenfruechte': ('Hülsenfrüchte', 'Legumes'),
  'kalb': ('Kalb', 'Veal'),
  'kartoffeln': ('Kartoffeln', 'Potatoes'),
  'kerne': ('Kerne', 'Seeds'),
  'kernobst': ('Kernobst', 'Pome fruit'),
  'knoblauch': ('Knoblauch', 'Garlic'),
  'kohl': ('Kohl', 'Cabbage'),
  'kokos': ('Kokos', 'Coconut'),
  'kraeuter': ('Kräuter', 'Herbs'),
  'kreuzblütler': ('Kreuzblütler', 'Cruciferous'),
  'kreuzblütler': ('Kreuzblütler', 'Cruciferous'),
  'kuerbis': ('Kürbis', 'Squash'),
  'lamm': ('Lamm', 'Lamb'),
  'lauchgewaechse': ('Lauchgewächse', 'Alliums'),
  'lean': ('Mager', 'Lean'),
  'linsen': ('Linsen', 'Lentils'),
  'lowfat': ('Fettarm', 'Low fat'),
  'lupine': ('Lupine', 'Lupin'),
  'magerfisch': ('Magerfisch', 'Lean fish'),
  'mais': ('Mais', 'Corn'),
  'maniok': ('Maniok', 'Cassava'),
  'mealprep': ('Meal Prep', 'Meal prep'),
  'meeresfruechte': ('Meeresfrüchte', 'Seafood'),
  'melone': ('Melone', 'Melon'),
  'mikros': ('Mikros', 'Microgreens'),
  'milchprodukte': ('Milchprodukte', 'Dairy'),
  'mohn': ('Mohn', 'Poppy'),
  'muFA': ('Ungesättigte Fette', 'MUFA'),
  'muscheln': ('Muscheln', 'Shellfish'),
  'muscle': ('Muskelaufbau', 'Muscle'),
  'nevereat': ('Nie essen', 'Never eat'),
  'nuesse': ('Nüsse', 'Nuts'),
  'obst': ('Obst', 'Fruit'),
  'oel': ('Öl', 'Oil'),
  'oktopus': ('Oktopus', 'Octopus'),
  'oliven': ('Oliven', 'Olives'),
  'olivenoel': ('Olivenöl', 'Olive oil'),
  'omega3': ('Omega-3', 'Omega-3'),
  'pastinaken': ('Pastinaken', 'Parsnips'),
  'pflanzlich': ('Pflanzlich', 'Plant-based'),
  'pilze': ('Pilze', 'Mushrooms'),
  'polenta': ('Polenta', 'Polenta'),
  'polyphenols': ('Polyphenole', 'Polyphenols'),
  'potassium': ('Kalium', 'Potassium'),
  'probiotics': ('Probiotika', 'Probiotics'),
  'processed': ('Verarbeitet', 'Processed'),
  'protein': ('Protein', 'Protein'),
  'quinoa': ('Quinoa', 'Quinoa'),
  'reis': ('Reis', 'Rice'),
  'rettich': ('Rettich', 'Radish'),
  'rind': ('Rind', 'Beef'),
  'roggen': ('Roggen', 'Rye'),
  'salat': ('Salat', 'Salad'),
  'samen': ('Samen', 'Seeds'),
  'seitan': ('Seitan', 'Seitan'),
  'sellerie': ('Sellerie', 'Celery'),
  'sesam': ('Sesam', 'Sesame'),
  'slow': ('Langsame Kohlenhydrate', 'Slow carbs'),
  'snack': ('Snack', 'Snack'),
  'soja': ('Soja', 'Soy'),
  'spargel': ('Spargel', 'Asparagus'),
  'staerke': ('Stärke', 'Starch'),
  'steinobst': ('Steinobst', 'Stone fruit'),
  'suesskartoffel': ('Süßkartoffel', 'Sweet potato'),
  'sugar': ('Zucker', 'Sugar'),
  'supplement': ('Supplement', 'Supplement'),
  'teff': ('Teff', 'Teff'),
  'tempeh': ('Tempeh', 'Tempeh'),
  'tierisch': ('Tierisch', 'Animal'),
  'tofu': ('Tofu', 'Tofu'),
  'tomaten': ('Tomaten', 'Tomatoes'),
  'topinambur': ('Topinambur', 'Jerusalem artichoke'),
  'topping': ('Topping', 'Topping'),
  'transfat': ('Transfette', 'Trans fat'),
  'tvp': ('TVP', 'TVP'),
  'verdauung': ('Verdauung', 'Digestion'),
  'vollkorn': ('Vollkorn', 'Whole grain'),
  'walnuss': ('Walnuss', 'Walnut'),
  'weizen': ('Weizen', 'Wheat'),
  'wild': ('Wild', 'Game'),
  'wok': ('Wok', 'Wok'),
  'wurzel': ('Wurzelgemüse', 'Root vegetables'),
  'yams': ('Yams', 'Yams'),
  'zitrus': ('Zitrus', 'Citrus'),
  'zwiebelgemuese': ('Zwiebelgemüse', 'Onion vegetables'),
  'zwiebeln': ('Zwiebeln', 'Onions'),
};

final _muscleDict = <String, String>{
  'Alle': 'All',
  'Brust': 'Chest',
  'Schultern': 'Shoulders',
  'Rücken': 'Back',
  'Trizeps': 'Triceps',
  'Bizeps': 'Biceps',
  'Bauch': 'Abs',
  'Beine': 'Legs',
  'Nacken': 'Neck',
  'Unterarme': 'Forearms',
  'mittlere Brust': 'Mid chest',
  'obere Brust': 'Upper chest',
  'untere Brust': 'Lower chest',
  'oberer Rücken': 'Upper back',
  'unterer Rücken': 'Lower back',
  'breiter Rücken': 'Lats',
  'vordere Schulter': 'Front delts',
  'hintere Schulter': 'Rear delts',
  'mittlere Schulter': 'Side delts',
  'obere Bauchmuskeln': 'Upper abs',
  'untere Bauchmuskeln': 'Lower abs',
  'schräge Bauchmuskeln': 'Obliques',
  'oberer Oberschenkel': 'Quads',
  'hinterer Oberschenkel': 'Hamstrings',
  'Hintern': 'Glutes',
  'Hüfte': 'Hips',
  'Hüftbeuger': 'Hip flexors',
  'Hüftabduktoren': 'Hip abductors',
  'Adduktoren': 'Adductors',
  'Waden': 'Calves',
  'Schienbein': 'Shins',
  'Knie': 'Knees',
  'Fuß': 'Feet',
  'kleiner Trizepskopf': 'Triceps (lateral head)',
  'großer Trizepskopf': 'Triceps (long head)',
  'Brachialis': 'Brachialis',
};

final _workoutNameDict = <String, String>{
  'Hampelmann': 'Jumping Jacks',
  'Wandsitzen': 'Wall Sit',
  'Liegestuetz': 'Push-Up',
  'Liegestuetz mit Drehen': 'Push-Up with Rotation',
  'Bauchpresse': 'Crunch',
  'Bauchpresse/Rolle': 'Crunch / Ab Rollout',
  'Stuhl-Step-Up': 'Chair Step-Up',
  'Stuhl Step Up': 'Chair Step-Up',
  'Kniebeugen': 'Squats',
  'Trizeps-Dip': 'Triceps Dip',
  'Unterarmstuetz': 'Forearm Plank',
  'Knien hochziehen': 'High Knees',
  'Knie hochziehen': 'High Knees',
  'Ausfallschritt': 'Lunge',
  'Seitlicher Unterarmstuetz rechts': 'Side Plank (Right)',
  'Seitlicher Unterarmstuetz links': 'Side Plank (Left)',
  'Seitliche Unterarmstuetz rechts': 'Side Plank (Right)',
  'Seitliche Unterarmstuetz links': 'Side Plank (Left)',
  'Wandhaltung mit Chin Tucks': 'Wall Hold with Chin Tucks',
  'Handstandliegestuetz': 'Handstand Push-Up',
  'Wadenheben mit gebeugtem Knie (Soleus)': 'Calf Raises (Bent Knee / Soleus)',
  'Becken in Reverse Plank und runter in L-Sit':
      'Pelvis Reverse Plank to L-Sit',
  'Knieuebung im Knien langsam nach hinten': 'Kneeling Lean-Back',
  'Untere Beinsehne Hold (Fuesse halten)': 'Hamstring Hold (Feet Grab)',
  'Kindstellung': "Child's Pose",
  'Elefant Walk (Waden)': 'Elephant Walk (Calves)',
  'Hipflexor stretch rechts': 'Hip Flexor Stretch (Right)',
  'Hipflexor stretch links': 'Hip Flexor Stretch (Left)',
  'Hipflexor Stretch rechts': 'Hip Flexor Stretch (Right)',
  'Hipflexor Stretch links': 'Hip Flexor Stretch (Left)',
  'Pigeon stretch rechts': 'Pigeon Stretch (Right)',
  'Pigeon stretch links': 'Pigeon Stretch (Left)',
  'Pigeon Stretch rechts': 'Pigeon Stretch (Right)',
  'Pigeon Stretch links': 'Pigeon Stretch (Left)',
  'Worlds greatest stretch rechts': "World's Greatest Stretch (Right)",
  'Worlds greatest stretch links': "World's Greatest Stretch (Left)",
  'Worlds Greatest Stretch rechts': "World's Greatest Stretch (Right)",
  'Worlds Greatest Stretch links': "World's Greatest Stretch (Left)",
};

final _freeTextDict = <String, String>{
  // Long phrases first (also sorted at runtime by length).
  'Komplette Proteinquelle fuer Muskelaufbau und Saettigung.':
      'Complete protein source for muscle building and satiety.',
  'Allrounder: hochwertiges Protein und gute Mikronaehrstoffe.':
      'All-rounder: high-quality protein and good micronutrients.',
  'Klein, naehrstoffdicht und proteinstark.':
      'Small, nutrient-dense and high in protein.',
  'Sehr naehrstoffreich; eher als gelegentliche Option.':
      'Very nutrient-rich; better as an occasional option.',
  'Omega-3-reich und stark fuer Regeneration und Gehirn.':
      'Rich in omega-3 and great for recovery and brain health.',
  'Sehr magerer Fisch: viel Protein, wenig Fett.':
      'Very lean fish: lots of protein, little fat.',
  'Magerer Fisch mit mildem Geschmack und hohem Proteingehalt.':
      'Lean fish with mild flavor and high protein content.',
  'Leicht verdaulich und ideal fuer saubere Mahlzeiten.':
      'Easy to digest and ideal for clean meals.',
  'Alltagstauglicher, magerer Fisch fuer viel Protein.':
      'Everyday lean fish for plenty of protein.',
  'Magerer Fisch fuer leichte, proteinreiche Gerichte.':
      'Lean fish for light, protein-rich dishes.',
  'Magerfisch fuer Protein ohne viel Fett.':
      'Lean fish for protein without much fat.',
  'Sehr mager und gut fuer eine kalorienarme Proteinbasis.':
      'Very lean and good for a low-calorie protein base.',
  'Milder, magerer Fisch fuer schnelle Proteinmahlzeiten.':
      'Mild lean fish for quick protein meals.',
  'Fettfisch mit viel Omega-3 fuer Gehirn und Entzuendungsbalance.':
      'Fatty fish with lots of omega-3 for brain and inflammation balance.',
  'Sehr omega-3-reich und naehrstoffdicht.':
      'Very rich in omega-3 and nutrient-dense.',
  'Fettfisch mit Omega-3 und viel Protein.':
      'Fatty fish with omega-3 and lots of protein.',
  'Gute Mischung aus Protein und gesunden Fetten.':
      'Good mix of protein and healthy fats.',
  'Aehnlich wie Forelle: Protein plus gute Fette.':
      'Similar to trout: protein plus healthy fats.',
  'Fettfisch; eher in kleineren Portionen wegen hoher Kaloriendichte.':
      'Fatty fish; better in smaller portions due to high calorie density.',
  'Intensiver Geschmack, omega-3-reich, gut als Topping.':
      'Intense flavor, rich in omega-3, good as a topping.',
  'Sehr mager und proteinreich.': 'Very lean and high in protein.',
  'Proteinreich und mager; gut fuer schnelle Pfannengerichte.':
      'High in protein and lean; good for quick pan dishes.',
  'Sehr mageres Protein aus dem Meer.':
      'Very lean protein from the sea.',
  'Mageres Protein (Calamari/Oktopus) fuer Abwechslung.':
      'Lean protein (calamari/octopus) for variety.',
  'Protein plus Mikronaehrstoffe; gut in Eintoepfen.':
      'Protein plus micronutrients; good in stews.',
  'Mager und proteinreich, schnell zubereitet.':
      'Lean and high in protein, quick to prepare.',
  'Naehrstoffdicht und proteinreich; eher als Special.':
      'Nutrient-dense and high in protein; more of a special treat.',
  'Proteinreich und gut fuer mediterrane Gerichte.':
      'High in protein and good for Mediterranean dishes.',
  'Viel Protein bei wenig Kalorien.':
      'Lots of protein with few calories.',
  'Sehr proteinreich und meist fettarm.':
      'Very high in protein and usually low in fat.',
  'Proteinreich, gut fuer schnelle Bowls und Snacks.':
      'High in protein, good for quick bowls and snacks.',
  'Sehr mageres Eiweiss fuer saubere Mahlzeiten.':
      'Very lean protein for clean meals.',
  'Mageres Gefluegel mit viel Protein.':
      'Lean poultry with lots of protein.',
  'Kontrolliert ausfuehren, gleichmaessig atmen.':
      'Execute with control, breathe evenly.',
  'Bringt den Kreislauf schnell in Schwung und aktiviert den ganzen Koerper.':
      'Gets circulation going quickly and activates the whole body.',
  'Staerkt Oberschenkel und Gesaessmuskeln fuer mehr Stabilitaet in den Beinen.':
      'Strengthens thighs and glutes for more stability in the legs.',
  'Baut Kraft in Brust, Schultern und Trizeps auf und fordert den Rumpf mit.':
      'Builds strength in chest, shoulders and triceps and challenges the core.',
  'Trainiert die Bauchmuskulatur und verbessert die Rumpfkontrolle.':
      'Trains the abdominal muscles and improves core control.',
  'Staerkt Sehnen am Bein und das Knie; langsame saubere Ausfuehrung ist wichtig.':
      'Strengthens leg tendons and the knee; slow clean execution is important.',
  'Foerdert funktionelle Kraft in Beinen und Gesaess fuer Alltagsbewegungen.':
      'Promotes functional strength in legs and glutes for everyday movement.',
  'Kraeftigt die Rueckseite der Arme und verbessert die Druckkraft.':
      'Strengthens the back of the arms and improves pressing strength.',
  'Staerkt den gesamten Core und unterstuetzt eine stabile Haltung.':
      'Strengthens the entire core and supports stable posture.',
  'Aktiviert unteren Bauch und Hueftbeuger und foerdert Koordination.':
      'Activates lower abs and hip flexors and promotes coordination.',
  'Verbessert Gleichgewicht und trainiert Beine einseitig gegen Dysbalancen.':
      'Improves balance and trains legs unilaterally against imbalances.',
  'Kombiniert Oberkoerperkraft mit Rotationsstabilitaet im Rumpf.':
      'Combines upper-body strength with rotational core stability.',
  'Staerkt schraege Bauchmuskeln und die seitliche Rumpfstabilitaet rechts.':
      'Strengthens obliques and lateral core stability on the right.',
  'Staerkt schraege Bauchmuskeln und die seitliche Rumpfstabilitaet links.':
      'Strengthens obliques and lateral core stability on the left.',
  'Ruhig atmen und Spannung ohne Schmerzen halten.':
      'Breathe calmly and hold tension without pain.',
  'Sanft dynamisch bewegen, in die Wadenlaenge reinfinden.':
      'Move gently and dynamically, finding your calf stretch.',
  'Becken stabil, Dehnung vorne an der Huefte spuern.':
      'Keep pelvis stable, feel the stretch at the front of the hip.',
  'Gesaess/Huefte oeffnen, keine Spannung im Knie erzwingen.':
      'Open glutes/hips, do not force tension in the knee.',
  'Brust oeffnen, Ruecken lang; nur so hoch wie angenehm.':
      'Open chest, long spine; only as high as comfortable.',
  'Ganzkoerper-Mobilitaet: Huefte, Wirbelsaeule und Schultern.':
      'Full-body mobility: hips, spine and shoulders.',
  'Haende hinter dem Ruecken verschraenken, Arme lang und Brust oeffnen.':
      'Interlace hands behind back, arms long and open the chest.',
  'Laenger ausatmen, Ruecken lang; Dehnung in Rueckseite spuern.':
      'Exhale longer, long spine; feel the stretch in the back of the body.',
  'Runterfahren, gleichmaessig atmen und entspannen.':
      'Wind down, breathe evenly and relax.',
  // Gym / cali description phrases.
  'Klassische Grundübung. Schulterbreiter Griff, Ellbogen 45° zum Körper, kontrolliert absenken.':
      'Classic foundational exercise. Shoulder-width grip, elbows 45° to the body, lower with control.',
  'Größere Bewegungsamplitude als Langhantel. Ideal für symmetrische Kraftentwicklung.':
      'Greater range of motion than barbell. Ideal for symmetrical strength development.',
  'Bank auf 30–45° einstellen. Betont den oberen Brustbereich und die Klavikularportion.':
      'Set bench to 30–45°. Emphasizes the upper chest and clavicular portion.',
  'Bank abwärts geneigt. Isoliert den unteren Brustbereich stark.':
      'Bench declined. Strongly isolates the lower chest.',
  'Arme leicht gebeugt halten, weite Bewegungsbahn. Dehnt die Brust maximal.':
      'Keep arms slightly bent, wide arc. Maximally stretches the chest.',
  'Wie Flys flach, aber mit positiver Neigung für obere Brust.':
      'Like flat flyes, but with incline for upper chest.',
  'Kabel auf höchste Position, Hände treffen sich unterhalb der Hüfte. Betont untere Brust.':
      'Cables at highest position, hands meet below hips. Emphasizes lower chest.',
  'Kabel auf niedrigste Position, Hände treffen sich auf Brusthöhe. Betont obere Brust.':
      'Cables at lowest position, hands meet at chest height. Emphasizes upper chest.',
  'Körper leicht nach vorne neigen, Ellbogen weit auseinander. Belastet stark die untere Brust.':
      'Lean body slightly forward, elbows wide apart. Heavily loads the lower chest.',
  'Bodyweight-Klassiker. Körper in einer Linie, Brust bis kurz vor den Boden, sauberer Core.':
      'Bodyweight classic. Body in a line, chest to just above the floor, tight core.',
  'Isolationsübung an der Maschine. Arme gestreckt halten und langsam zusammenführen.':
      'Machine isolation exercise. Keep arms extended and bring together slowly.',
  'Liegt quer auf der Bank. Trainiert gleichzeitig Brust und Lats, guter Stretch.':
      'Lies across the bench. Trains chest and lats simultaneously, good stretch.',
  'Untergriff betont Bizeps. Körper stabil, kontrollierte Wiederholungen.':
      'Underhand grip emphasizes biceps. Stable body, controlled reps.',
  'Körper in Linie, Core fest. Brust bis kurz vor den Boden, sauber drücken.':
      'Body in line, core tight. Chest to just above floor, press cleanly.',
  'Füße erhöht. Mehr Last auf obere Brust und vordere Schulter.':
      'Feet elevated. More load on upper chest and front delts.',
  'Hände eng. Sehr trizepslastig, Ellbogen nah am Körper.':
      'Hands close. Very triceps-dominant, elbows close to body.',
  'Auf Bank/Barre abstützen. Vorsicht Schulter – kontrolliert und schmerzfrei.':
      'Support on bench/bar. Shoulder caution – controlled and pain-free.',
  'Hüfte hoch, Kopf Richtung Boden. Sehr guter Schulterdrück-Ersatz.':
      'Hips high, head toward floor. Excellent overhead press substitute.',
  'Stabil an der Wand halten. Fokus auf Core-Spannung und Schulter-Stack.':
      'Hold stable against wall. Focus on core tension and shoulder stack.',
  'Nur so tief wie kontrolliert. Alternative: Negative langsam ablassen.':
      'Only as deep as controlled. Alternative: slow negative lowering.',
  'Im Hang Knie anheben. Unterer Bauch + Hüftbeuger. Ohne Schwung.':
      'Raise knees in hang. Lower abs + hip flexors. No momentum.',
  'Gestreckte Beine heben. Sehr intensiv für unteren Bauch. Langsam ablassen.':
      'Raise straight legs. Very intense for lower abs. Lower slowly.',
  'Fortgeschritten: Füße zur Stange. Core maximal, sauber ohne Kipping.':
      'Advanced: feet to bar. Maximum core, clean without kipping.',
  'Unterarme am Boden, Körper in Linie, Bauch fest. Ruhig atmen.':
      'Forearms on floor, body in line, abs tight. Breathe calmly.',
  'Auf dem Barren halten, Beine gestreckt. Sehr starker Core + Hüftbeuger.':
      'Hold on bars, legs straight. Very strong core + hip flexors.',
  'Saubere Tiefe, Knie stabil. Ideal als Basis für Sprünge und Pistols.':
      'Clean depth, stable knees. Ideal base for jumps and pistols.',
  'Großer Schritt, Oberkörper aufrecht. Stabilität + Po/Beine.':
      'Large step, torso upright. Stability + glutes/legs.',
  'Einbeinige Kniebeuge mit Support (Pfosten/Barre). Kontrolliert, Knie ausrichten.':
      'Single-leg squat with support (post/bar). Controlled, align knees.',
  'Oberschenkelrückseite brutal effektiv. Nur so weit ablassen wie kontrolliert.':
      'Hamstrings brutally effective. Only lower as far as controlled.',
  'Volle Streckung und maximal ablassen. Langsam für saubere Spannung.':
      'Full extension and maximum lowering. Slowly for clean tension.',
  'Ferse am Boden, Zehen hochziehen. Stärkt Schienbein und unterstützt das Knie.':
      'Heel on floor, pull toes up. Strengthens shins and supports the knee.',
  // Word / phrase replacements (German ascii + umlaut forms).
  'Muskelaufbau': 'muscle building',
  'Saettigung': 'satiety',
  'Mikronaehrstoffe': 'micronutrients',
  'naehrstoffdicht': 'nutrient-dense',
  'proteinstark': 'high in protein',
  'naehrstoffreich': 'nutrient-rich',
  'gelegentliche': 'occasional',
  'Regeneration': 'recovery',
  'Gehirn': 'brain',
  'Entzuendungsbalance': 'inflammation balance',
  'verdaulich': 'digestible',
  'Mahlzeiten': 'meals',
  'Alltagstauglicher': 'Everyday',
  'Kaloriendichte': 'calorie density',
  'Mikronährstoffe': 'micronutrients',
  'nährstoffdicht': 'nutrient-dense',
  'nährstoffreich': 'nutrient-rich',
  'Entzündungsbalance': 'inflammation balance',
  'Protein': 'protein',
  'Proteingehalt': 'protein content',
  'Proteinquelle': 'protein source',
  'Eiweiss': 'protein',
  'Eiweiß': 'protein',
  'Kohlenhydrate': 'carbohydrates',
  'Fette': 'fats',
  'Fett': 'fat',
  'fettarm': 'low-fat',
  'mager': 'lean',
  'magerer': 'lean',
  'Magerer': 'Lean',
  'Magerfisch': 'lean fish',
  'Fettfisch': 'fatty fish',
  'Omega-3': 'omega-3',
  'omega-3': 'omega-3',
  'Kreislauf': 'circulation',
  'Koerper': 'body',
  'Körper': 'body',
  'Rumpf': 'core',
  'Core': 'core',
  'Oberkoerper': 'upper body',
  'Oberkörper': 'upper body',
  'Unterarme': 'forearms',
  'Bauchmuskulatur': 'abdominal muscles',
  'Bauchmuskeln': 'abs',
  'Oberschenkel': 'thighs',
  'Gesaessmuskeln': 'glutes',
  'Gesäßmuskeln': 'glutes',
  'Gesaess': 'glutes',
  'Gesäß': 'glutes',
  'Stabilitaet': 'stability',
  'Stabilität': 'stability',
  'Hueftbeuger': 'hip flexors',
  'Hüftbeuger': 'hip flexors',
  'Huefte': 'hip',
  'Hüfte': 'hip',
  'Koordination': 'coordination',
  'Gleichgewicht': 'balance',
  'Dysbalancen': 'imbalances',
  'Rotationsstabilitaet': 'rotational stability',
  'Rotationsstabilität': 'rotational stability',
  'schraege': 'oblique',
  'schräge': 'oblique',
  'Druckkraft': 'pressing strength',
  'Kraft': 'strength',
  'Kraeftigt': 'Strengthens',
  'Kräftigt': 'Strengthens',
  'Staerkt': 'Strengthens',
  'Stärkt': 'Strengthens',
  'Foerdert': 'Promotes',
  'Fördert': 'Promotes',
  'Trainiert': 'Trains',
  'Baut': 'Builds',
  'Aktiviert': 'Activates',
  'Verbessert': 'Improves',
  'unterstuetzt': 'supports',
  'unterstützt': 'supports',
  'ausfuehren': 'execute',
  'ausführen': 'execute',
  'gleichmaessig': 'evenly',
  'gleichmäßig': 'evenly',
  'atmen': 'breathe',
  'Kontrolliert': 'Controlled',
  'kontrolliert': 'controlled',
  'sauber': 'clean',
  'saubere': 'clean',
  'Ausfuehrung': 'execution',
  'Ausführung': 'execution',
  'Sehnen': 'tendons',
  'funktionelle': 'functional',
  'Alltagsbewegungen': 'everyday movement',
  'Haltung': 'posture',
  'einseitig': 'unilaterally',
  'seitliche': 'lateral',
  'rechts': 'right',
  'links': 'left',
  'Dehnung': 'stretch',
  'dehnen': 'stretch',
  'Mobilitaet': 'mobility',
  'Mobilität': 'mobility',
  'Wirbelsaeule': 'spine',
  'Wirbelsäule': 'spine',
  'Schultern': 'shoulders',
  'Brust': 'chest',
  'Trizeps': 'triceps',
  'Ruecken': 'back',
  'Rücken': 'back',
  'Arme': 'arms',
  'Beine': 'legs',
  'Wadenlaenge': 'calf stretch',
  'Wadenlänge': 'calf stretch',
  'Spannung': 'tension',
  'Schmerzen': 'pain',
  'entspannen': 'relax',
  'Runterfahren': 'Wind down',
  'oeffnen': 'open',
  'öffnen': 'open',
  'angenehm': 'comfortable',
  'vorne': 'front',
  'spuern': 'feel',
  'verschraenken': 'interlace',
  'verschränken': 'interlace',
  'ausatmen': 'exhale',
  'lang': 'long',
  'Rueckseite': 'back of the body',
  'Rückseite': 'back of the body',
  'Grundübung': 'foundational exercise',
  'Bewegungsamplitude': 'range of motion',
  'Langhantel': 'barbell',
  'Kurzhantel': 'dumbbell',
  'Ellbogen': 'elbows',
  'Schulterbreiter': 'shoulder-width',
  'Griff': 'grip',
  'Brustbereich': 'chest area',
  'obere': 'upper',
  'untere': 'lower',
  'mittlere': 'mid',
  'vordere': 'front',
  'hintere': 'rear',
  'Wiederholungen': 'reps',
  'Wiederholung': 'rep',
  'Maschine': 'machine',
  'Isolationsübung': 'isolation exercise',
  'Stretch': 'stretch',
  'Knie': 'knee',
  'Kniebeuge': 'squat',
  'Kniebeugen': 'squats',
  'Bein': 'leg',
  'Po': 'glutes',
  'Po/Beine': 'glutes/legs',
  'Schienbein': 'shins',
  'Waden': 'calves',
  'Ferse': 'heel',
  'Zehen': 'toes',
  'Stange': 'bar',
  'Barren': 'parallel bars',
  'Hang': 'hang',
  'Schwung': 'momentum',
  'Kipping': 'kipping',
  'Fortgeschritten': 'Advanced',
  'Basis': 'base',
  'ideal': 'ideal',
  'Ideal': 'Ideal',
  'gut': 'good',
  'Gut': 'Good',
  'sehr': 'very',
  'Sehr': 'Very',
  'viel': 'lots of',
  'wenig': 'little',
  'hoch': 'high',
  'tief': 'deep',
  'langsam': 'slowly',
  'Langsam': 'Slowly',
  'ruhig': 'calm',
  'Ruhig': 'Calm',
  'stark': 'strong',
  'maximal': 'maximum',
  'sauberer': 'tight',
  'fest': 'tight',
  'stabil': 'stable',
  'Stabil': 'Stable',
  'Alternative': 'Alternative',
  'Negative': 'Negative',
  'negativ': 'negative',
  'Support': 'support',
  'effektiv': 'effective',
  'brutal': 'brutally',
  'Volle': 'Full',
  'Streckung': 'extension',
  'ablassen': 'lowering',
  'heben': 'raise',
  'anheben': 'raise',
  'drücken': 'press',
  'absenken': 'lower',
  'senken': 'lower',
  'halten': 'hold',
  'Halten': 'Hold',
  'Fokus': 'Focus',
  'Vorsicht': 'Caution',
  'schmerzfrei': 'pain-free',
  'Schulter': 'shoulder',
  'Schulterdrück': 'overhead press',
  'Kopf': 'head',
  'Boden': 'floor',
  'Wand': 'wall',
  'Bank': 'bench',
  'Hände': 'hands',
  'Haende': 'hands',
  'Hand': 'hand',
  'Füße': 'feet',
  'Fuesse': 'feet',
  'Beinpresse': 'leg press',
  'Kreuzheben': 'deadlift',
  'Klimmzüge': 'pull-ups',
  'Klimmzuege': 'pull-ups',
  'Liegestütze': 'push-ups',
  'Liegestuetze': 'push-ups',
  'Dips': 'dips',
  'Plank': 'plank',
  'Crunch': 'crunch',
  'Crunches': 'crunches',
};

final _wordDict = <String, String>{
  'Rote': 'Red',
  'Gelbe': 'Yellow',
  'Braune': 'Brown',
  'Gruene': 'Green',
  'Grüne': 'Green',
  'Weisse': 'White',
  'Schwarze': 'Black',
  'Roter': 'Red',
  'Gelbe Spalterbsen': 'Yellow Split Peas',
  'Linsen': 'Lentils',
  'Bohnen': 'Beans',
  'Erbsen': 'Peas',
  'Kartoffeln': 'Potatoes',
  'Kartoffel': 'Potato',
  'Fruehkartoffeln': 'New Potatoes',
  'Frühkartoffeln': 'New Potatoes',
  'Suesskartoffeln': 'Sweet Potatoes',
  'Süßkartoffeln': 'Sweet Potatoes',
  'Reis': 'Rice',
  'Haferflocken': 'Oat Flakes',
  'Haferkleie': 'Oat Bran',
  'Quinoa': 'Quinoa',
  'Dinkel': 'Spelt',
  'Roggen': 'Rye',
  'Gerste': 'Barley',
  'Hirse': 'Millet',
  'Buchweizen': 'Buckwheat',
  'Amaranth': 'Amaranth',
  'Teff': 'Teff',
  'Mais': 'Corn',
  'Maiskolben': 'Corn on the Cob',
  'Spinat': 'Spinach',
  'Brokkoli': 'Broccoli',
  'Tomaten': 'Tomatoes',
  'Paprika': 'Bell Pepper',
  'Zucchini': 'Zucchini',
  'Aubergine': 'Eggplant',
  'Gurke': 'Cucumber',
  'Karotten': 'Carrots',
  'Moehren': 'Carrots',
  'Möhren': 'Carrots',
  'Apfel': 'Apple',
  'Aepfel': 'Apples',
  'Äpfel': 'Apples',
  'Banane': 'Banana',
  'Bananen': 'Bananas',
  'Beeren': 'Berries',
  'Nuesse': 'Nuts',
  'Nüsse': 'Nuts',
  'Mandeln': 'Almonds',
  'Walnuesse': 'Walnuts',
  'Walnüsse': 'Walnuts',
  'Haselnuesse': 'Hazelnuts',
  'Haselnüsse': 'Hazelnuts',
  'Cashewkerne': 'Cashews',
  'Erdnuesse': 'Peanuts',
  'Erdnüsse': 'Peanuts',
  'Paranuesse': 'Brazil Nuts',
  'Paranüsse': 'Brazil Nuts',
  'Pekannuesse': 'Pecans',
  'Pekannüsse': 'Pecans',
  'Macadamia': 'Macadamia',
  'Pistazien': 'Pistachios',
  'Kuerbis': 'Pumpkin',
  'Kürbis': 'Pumpkin',
  'Kuerbiskerne': 'Pumpkin Seeds',
  'Kürbiskerne': 'Pumpkin Seeds',
  'Lachs': 'Salmon',
  'Kabeljau': 'Cod',
  'Zander': 'Pike-Perch',
  'Scholle': 'Plaice',
  'Seelachs': 'Pollock',
  'Flunder': 'Flounder',
  'Hecht': 'Pike',
  'Makrele': 'Mackerel',
  'Hering': 'Herring',
  'Forelle': 'Trout',
  'Aal': 'Eel',
  'Garnelen': 'Shrimp',
  'Hummer': 'Lobster',
  'Tintenfisch': 'Squid',
  'Austern': 'Oysters',
  'Austernpilze': 'Oyster Mushrooms',
  'Eier': 'Eggs',
  'Huehnereier': 'Chicken Eggs',
  'Hühnereier': 'Chicken Eggs',
  'Wachteleier': 'Quail Eggs',
  'Gaenseeier': 'Goose Eggs',
  'Gänseeier': 'Goose Eggs',
  'Magerquark': 'Low-Fat Quark',
  'Skyr': 'Skyr',
  'Huettenkaese': 'Cottage Cheese',
  'Hüttenkäse': 'Cottage Cheese',
  'Haehnchenbrust': 'Chicken Breast',
  'Hähnchenbrust': 'Chicken Breast',
  'Putenbrust': 'Turkey Breast',
  'Rinderfilet': 'Beef Tenderloin',
  'Roastbeef': 'Roast Beef',
  'Rinderhuefte': 'Beef Hip',
  'Rinderhüfte': 'Beef Hip',
  'Tatar': 'Lean Tartare',
  'Kalbsschnitzel': 'Veal Schnitzel',
  'Lammfilet': 'Lamb Fillet',
  'Tofu': 'Tofu',
  'Tempeh': 'Tempeh',
  'Seitan': 'Seitan',
  'Kichererbsen': 'Chickpeas',
  'Kidneybohnen': 'Kidney Beans',
  'Olivenoel': 'Olive Oil',
  'Olivenöl': 'Olive Oil',
  'Butter': 'Butter',
  'Ghee': 'Ghee',
  'Avocado': 'Avocado',
  'Avocadooel': 'Avocado Oil',
  'Avocadoöl': 'Avocado Oil',
  'Ingwer': 'Ginger',
  'Knoblauch': 'Garlic',
  'Zwiebel': 'Onion',
  'Fruehlingszwiebeln': 'Spring Onions',
  'Frühlingszwiebeln': 'Spring Onions',
  'Softdrinks': 'Soft Drinks',
  'mager': 'lean',
  'geraeuchert': 'smoked',
  'geräuchert': 'smoked',
  'Natur': 'plain',
  'Vollkorn': 'whole grain',
  'Frisch': 'fresh',
  'Wild': 'wild',
  'Suesses': 'Sweet',
  'Süßes': 'Sweet',
  'Fruehstuecks': 'Breakfast',
  'Frühstücks': 'Breakfast',
  'Muesli': 'Muesli',
  'Frittierte': 'Fried',
  'Snacks': 'Snacks',
  'Ananas': 'Pineapple',
  'Aprikosen': 'Apricots',
  'Artischocken': 'Artichokes',
  'Algen': 'Seaweed',
  'Algenoel': 'Algae Oil',
  'Algenöl': 'Algae Oil',
  'Birnen': 'Pears',
  'Blaubeeren': 'Blueberries',
  'Blumenkohl': 'Cauliflower',
  'Blutorangen': 'Blood Oranges',
  'Brombeeren': 'Blackberries',
  'Champignons': 'Button Mushrooms',
  'Chiasamen': 'Chia Seeds',
  'Chicoree': 'Chicory',
  'Chinakohl': 'Napa Cabbage',
  'Clementinen': 'Clementines',
  'Cranberries': 'Cranberries',
  'Datteln': 'Dates',
  'Drachenfrucht': 'Dragon Fruit',
  'Eisbergsalat': 'Iceberg Lettuce',
  'Endivie': 'Endive',
  'Erdbeeren': 'Strawberries',
  'Feigen': 'Figs',
  'Feldsalat': 'Lamb\'s Lettuce',
  'Fenchel': 'Fennel',
  'Flohsamen': 'Psyllium Husk',
  'Galia': 'Galia Melon',
  'Grapefruit': 'Grapefruit',
  'Gruenkohl': 'Kale',
  'Grünkohl': 'Kale',
  'Honigmelone': 'Honeydew Melon',
  'Johannisbeeren': 'Currants',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kaki': 'Persimmon',
  'Kiwi': 'Kiwi',
  'Kohlrabi': 'Kohlrabi',
  'Kokosnuss': 'Coconut',
  'Kokosmilch': 'Coconut Milk',
  'Kokoswasser': 'Coconut Water',
  'Koriander': 'Cilantro',
  'Leinsamen': 'Flax Seeds',
  'Limette': 'Lime',
  'Limone': 'Lemon',
  'Mango': 'Mango',
  'Melone': 'Melon',
  'Mirabellen': 'Mirabelle Plums',
  'Nektarinen': 'Nectarines',
  'Oliven': 'Olives',
  'Orangen': 'Oranges',
  'Papaya': 'Papaya',
  'Passionsfrucht': 'Passion Fruit',
  'Pastinaken': 'Parsnips',
  'Pfirsiche': 'Peaches',
  'Pflaumen': 'Plums',
  'Petersilie': 'Parsley',
  'Radieschen': 'Radishes',
  'Rhabarber': 'Rhubarb',
  'Rosenkohl': 'Brussels Sprouts',
  'Rote Bete': 'Beetroot',
  'Rucola': 'Arugula',
  'Salat': 'Lettuce',
  'Salatgurke': 'Cucumber',
  'Sauerkraut': 'Sauerkraut',
  'Sellerie': 'Celery',
  'Sesam': 'Sesame',
  'Sonnenblumenkerne': 'Sunflower Seeds',
  'Spargel': 'Asparagus',
  'Stachelbeeren': 'Gooseberries',
  'Suesskartoffel': 'Sweet Potato',
  'Süßkartoffel': 'Sweet Potato',
  'Trauben': 'Grapes',
  'Wassermelone': 'Watermelon',
  'Weintrauben': 'Grapes',
  'Weisskohl': 'White Cabbage',
  'Weißkohl': 'White Cabbage',
  'Weissbrot': 'White Bread',
  'Weißbrot': 'White Bread',
  'Zitrone': 'Lemon',
  'Zitronen': 'Lemons',
  'Zucchini': 'Zucchini',
  'Hampelmann': 'Jumping Jacks',
  'Wandsitzen': 'Wall Sit',
  'Liegestuetz': 'Push-Up',
  'Kniebeugen': 'Squats',
  'Unterarmstuetz': 'Forearm Plank',
  'Ausfallschritt': 'Lunge',
  'Kindstellung': "Child's Pose",
};

final _foodDict = <String, String>{
  'Eier': 'Eggs',
  'Huehnereier': 'Chicken Eggs',
  'Wachteleier': 'Quail Eggs',
  'Gaenseeier': 'Goose Eggs',
  'Lachs': 'Salmon',
  'Kabeljau': 'Cod',
  'Zander': 'Pike-Perch',
  'Scholle': 'Plaice',
  'Seelachs': 'Pollock',
  'Flunder': 'Flounder',
  'Hecht': 'Pike',
  'Schellfisch': 'Haddock',
  'Pangasius': 'Pangasius',
  'Makrele': 'Mackerel',
  'Hering': 'Herring',
  'Sardinen': 'Sardines',
  'Forelle': 'Trout',
  'Saibling': 'Arctic Char',
  'Aal': 'Eel',
  'Sardellen': 'Anchovies',
  'Garnelen': 'Shrimp',
  'Scampi': 'Langoustines',
  'Hummer': 'Lobster',
  'Tintenfisch': 'Squid',
  'Miesmuscheln': 'Mussels',
  'Jakobsmuscheln': 'Scallops',
  'Austern': 'Oysters',
  'Venusmuscheln': 'Clams',
  'Magerquark': 'Low-Fat Quark',
  'Skyr': 'Skyr',
  'Huettenkaese': 'Cottage Cheese',
  'Haehnchenbrust': 'Chicken Breast',
  'Putenbrust': 'Turkey Breast',
  'Wachtel': 'Quail',
  'Fasan': 'Pheasant',
  'Strauss': 'Ostrich',
  'Rinderfilet': 'Beef Tenderloin',
  'Roastbeef': 'Roast Beef',
  'Rinderhuefte': 'Beef Hip',
  'Tatar (mager)': 'Lean Tartare',
  'Kalbsschnitzel': 'Veal Schnitzel',
  'Hirsch': 'Venison (Deer)',
  'Reh': 'Venison (Roe)',
  'Wildschwein': 'Wild Boar',
  'Hase': 'Hare',
  'Kaninchen': 'Rabbit',
  'Lammfilet': 'Lamb Fillet',
  'Griechischer Joghurt': 'Greek Yogurt',
  'Naturjoghurt': 'Plain Yogurt',
  'Kefir': 'Kefir',
  'Buttermilch': 'Buttermilk',
  'Harzer Kaese': 'Harzer Cheese',
  'Handkaese': 'Hand Cheese',
  'Koerniger Frischkaese': 'Curd Cheese',
  'Rote Linsen': 'Red Lentils',
  'Gelbe Linsen': 'Yellow Lentils',
  'Braune Linsen': 'Brown Lentils',
  'Tellerlinsen': 'Plate Lentils',
  'Beluga-Linsen': 'Beluga Lentils',
  'Puy-Linsen': 'Puy Lentils',
  'Berglinsen': 'Mountain Lentils',
  'Kidneybohnen': 'Kidney Beans',
  'Schwarze Bohnen': 'Black Beans',
  'Weisse Bohnen (Cannellini)': 'White Beans (Cannellini)',
  'Wachtelbohnen (Pinto)': 'Pinto Beans',
  'Dicke Bohnen (Saubohnen)': 'Broad Beans',
  'Adzukibohnen': 'Adzuki Beans',
  'Mungbohnen': 'Mung Beans',
  'Limabohnen': 'Lima Beans',
  'Sojabohnen (Edamame)': 'Soybeans (Edamame)',
  'Kichererbsen': 'Chickpeas',
  'Lupinenkerne': 'Lupin Seeds',
  'Gruene Erbsen': 'Green Peas',
  'Gelbe Spalterbsen': 'Yellow Split Peas',
  'Tofu (Natur)': 'Tofu (Plain)',
  'Tofu (geraeuchert)': 'Tofu (Smoked)',
  'Tempeh': 'Tempeh',
  'Seitan': 'Seitan',
  'Sojaschnetzel (TVP)': 'Soy Chunks (TVP)',
  'Lupinen-Geschnetzeltes': 'Lupin Strips',
  'Haferflocken': 'Oat Flakes',
  'Haferkleie': 'Oat Bran',
  'Dinkel (Koerner)': 'Spelt (Grains)',
  'Dinkel (Mehl)': 'Spelt (Flour)',
  'Vollkornweizen': 'Whole Wheat',
  'Roggen': 'Rye',
  'Gerste': 'Barley',
  'Gruenkern': 'Green Spelt',
  'Quinoa (weiss)': 'Quinoa (White)',
  'Quinoa (rot)': 'Quinoa (Red)',
  'Quinoa (schwarz)': 'Quinoa (Black)',
  'Amaranth': 'Amaranth',
  'Buchweizen': 'Buckwheat',
  'Hirse': 'Millet',
  'Teff': 'Teff',
  'Mais (Polenta)': 'Corn (Polenta)',
  'Maiskolben': 'Corn on the Cob',
  'Naturreis (Vollkorn)': 'Brown Rice (Whole Grain)',
  'Roter Reis': 'Red Rice',
  'Schwarzer Reis': 'Black Rice',
  'Wildreis': 'Wild Rice',
  'Basmati-Vollkorn': 'Whole-Grain Basmati',
  'Reis': 'Rice',
  'Softdrinks': 'Soft Drinks',
  'Frittierte Snacks': 'Fried Snacks',
  'Suesses Fruehstuecks-Muesli': 'Sweet Breakfast Muesli',
  'Flohsamen': 'Psyllium Husk',
  'Aepfel': 'Apples',
  'Ananas': 'Pineapple',
  'Aprikosen': 'Apricots',
  'Artischocken': 'Artichokes',
  'Algen (Nori)': 'Seaweed (Nori)',
  'Algen (Wakame)': 'Seaweed (Wakame)',
  'Algenoel (Omega-3)': 'Algae Oil (Omega-3)',
  'Austernpilze': 'Oyster Mushrooms',
  'Avocado (Fuerte)': 'Avocado (Fuerte)',
  'Avocado (Hass)': 'Avocado (Hass)',
  'Avocadooel': 'Avocado Oil',
  'Bambussprossen': 'Bamboo Shoots',
  'Bananen': 'Bananas',
  'Birnen': 'Pears',
  'Blaubeeren': 'Blueberries',
  'Blumenkohl': 'Cauliflower',
  'Blutorangen': 'Blood Oranges',
  'Brombeeren': 'Blackberries',
  'Cantaloupe': 'Cantaloupe Melon',
  'Champignons': 'Button Mushrooms',
  'Chiasamen': 'Chia Seeds',
  'Chicoree': 'Chicory',
  'Chinakohl': 'Napa Cabbage',
  'Clementinen': 'Clementines',
  'Cranberries': 'Cranberries',
  'Datteln (frisch)': 'Dates (Fresh)',
  'Drachenfrucht': 'Dragon Fruit',
  'Eisbergsalat': 'Iceberg Lettuce',
  'Endivie': 'Endive',
  'Erdbeeren': 'Strawberries',
  'Feigen': 'Figs',
  'Feldsalat': 'Lamb\'s Lettuce',
  'Fenchel': 'Fennel',
  'Fruehkartoffeln': 'New Potatoes',
  'Fruehlingszwiebeln': 'Spring Onions',
  'Galia': 'Galia Melon',
};

final _gymDict = <String, String>{
  'Bankdrücken (Langhantel)': 'Barbell Bench Press',
  'Bankdrücken (Kurzhantel)': 'Dumbbell Bench Press',
  'Schrägbankdrücken (positiv)': 'Incline Bench Press',
  'Schrägbankdrücken (negativ)': 'Decline Bench Press',
  'Kurzhantel-Flys (flach)': 'Flat Dumbbell Flyes',
  'Kurzhantel-Flys (Schrägbank)': 'Incline Dumbbell Flyes',
  'Kabelcrossover (oben nach unten)': 'Cable Crossover (High to Low)',
  'Kabelcrossover (unten nach oben)': 'Cable Crossover (Low to High)',
  'Dips (Brust-Variante)': 'Chest Dips',
  'Liegestütze': 'Push-Ups',
  'Pec Deck / Butterfly': 'Pec Deck / Butterfly',
  'Langhantel Pullover': 'Barbell Pullover',
  'Schulterdrücken (Langhantel, stehend)': 'Standing Barbell Overhead Press',
  'Schulterdrücken (Kurzhantel, sitzend)': 'Seated Dumbbell Shoulder Press',
  'Seitheben (Kurzhantel)': 'Dumbbell Lateral Raises',
  'Seitheben (Kabel)': 'Cable Lateral Raises',
  'Frontheben': 'Front Raises',
  'Reverse Fly (hintere Schulter)': 'Reverse Fly (Rear Delts)',
  'Arnold Press': 'Arnold Press',
  'Face Pulls': 'Face Pulls',
  'Upright Row': 'Upright Row',
  'Klimmzüge (weiter Griff)': 'Wide-Grip Pull-Ups',
  'Latzug (weiter Griff)': 'Wide-Grip Lat Pulldown',
  'Latzug (enger Untergriff)': 'Close-Grip Lat Pulldown',
  'Langhantel-Rudern': 'Barbell Row',
  'Kurzhantel-Rudern (einarmig)': 'One-Arm Dumbbell Row',
  'Sitzrudern (Kabel, enger Griff)': 'Seated Cable Row (Close Grip)',
  'T-Bar Rudern': 'T-Bar Row',
  'Kreuzheben (konventionell)': 'Conventional Deadlift',
  'Kreuzheben (Sumo)': 'Sumo Deadlift',
  'Hyperextensions': 'Hyperextensions',
  'Trizepsdrücken (Kabel, Stange)': 'Cable Triceps Pushdown (Bar)',
  'Trizepsdrücken (Kabel, Seil)': 'Cable Triceps Pushdown (Rope)',
  'Skull Crushers (EZ-Stange)': 'Skull Crushers (EZ-Bar)',
  'Overhead Trizepsdrücken (Kurzhantel)': 'Overhead Dumbbell Triceps Extension',
  'Trizeps Kickback': 'Triceps Kickback',
  'Dips (enge Griffvariante)': 'Close-Grip Dips',
  'JM Press': 'JM Press',
  'Enges Bankdrücken (Close Grip Bench Press)': 'Close-Grip Bench Press',
  'Bizepscurls (Langhantel)': 'Barbell Biceps Curls',
  'Bizepscurls (EZ-Stange)': 'EZ-Bar Biceps Curls',
  'Bizepscurls (Kurzhantel, alternierend)': 'Alternating Dumbbell Curls',
  'Konzentrationscurls': 'Concentration Curls',
  'Hammer Curls': 'Hammer Curls',
  'Spider Curls': 'Spider Curls',
  'Kabelcurls': 'Cable Curls',
  'Preacher Curls (Scottbank)': 'Preacher Curls',
  'Kabelzug Crunches': 'Cable Crunches',
  'Leg Raises (hängend)': 'Hanging Leg Raises',
  'Decline Crunches': 'Decline Crunches',
  'Russian Twists (mit Gewicht)': 'Weighted Russian Twists',
  'Ab Wheel Rollout': 'Ab Wheel Rollout',
  'Dragon Flag': 'Dragon Flag',
  'Pallof Press': 'Pallof Press',
  'Plank': 'Plank',
  'Kniebeugen (Langhantel, High Bar)': 'High-Bar Back Squat',
  'Kniebeugen (Langhantel, Low Bar)': 'Low-Bar Back Squat',
  'Beinpresse': 'Leg Press',
  'Bulgarische Ausfallschritte': 'Bulgarian Split Squats',
  'Beinstrecker (Maschine)': 'Leg Extension',
  'Bein Curl (liegend)': 'Lying Leg Curl',
  'Romanian Deadlift': 'Romanian Deadlift',
  'Hip Thrust (Langhantel)': 'Barbell Hip Thrust',
  'Adduktorenmaschine': 'Adductor Machine',
  'Abduktorenmaschine': 'Abductor Machine',
  'Wadenheben stehend (Maschine)': 'Standing Calf Raise (Machine)',
  'Wadenheben sitzend': 'Seated Calf Raise',
  'Tibialis Raises': 'Tibialis Raises',
  'Poliquin Step-Up': 'Poliquin Step-Up',
  'Hack Squat (Maschine)': 'Hack Squat',
  'Neck Curls (liegend)': 'Lying Neck Curls',
  'Neck Extensions (liegend)': 'Lying Neck Extensions',
  'Neck Harness (Stirnband)': 'Neck Harness',
  'Shrugs (Langhantel)': 'Barbell Shrugs',
  'Shrugs (Kurzhantel)': 'Dumbbell Shrugs',
  'Handgelenk Curls (Langhantel)': 'Wrist Curls (Barbell)',
  'Reverse Curls': 'Reverse Curls',
  "Farmer's Walk": "Farmer's Walk",
  'Plate Pinch': 'Plate Pinch',
  'Dead Hang': 'Dead Hang',
};

final _caliDict = <String, String>{
  'Klimmzüge (Pull-Ups)': 'Pull-Ups',
  'Chin-Ups (Untergriff)': 'Chin-Ups (Underhand)',
  'Australische Klimmzüge (Inverted Rows)': 'Inverted Rows',
  'Muscle-Up (Strict / Assist)': 'Muscle-Up (Strict / Assisted)',
  'Scap Pull-Ups': 'Scapular Pull-Ups',
  'Dead Hang': 'Dead Hang',
  'Dips (Barren)': 'Bar Dips',
  'Liegestütze (Push-Ups)': 'Push-Ups',
  'Decline Push-Ups': 'Decline Push-Ups',
  'Diamond Push-Ups': 'Diamond Push-Ups',
  'Bench Dips': 'Bench Dips',
  'Pike Push-Ups': 'Pike Push-Ups',
  'Handstand Hold (Wand)': 'Wall Handstand Hold',
  'Handstand Push-Ups (Wand / Negativ)': 'Wall Handstand Push-Ups (Negative)',
  'Planche Lean': 'Planche Lean',
  'Tuck Front Lever Hold': 'Tuck Front Lever Hold',
  'Front Lever Raises (Tuck)': 'Front Lever Raises (Tuck)',
  'Skin the Cat': 'Skin the Cat',
  'Tuck Back Lever Hold': 'Tuck Back Lever Hold',
  'Hanging Knee Raises': 'Hanging Knee Raises',
  'Hanging Leg Raises': 'Hanging Leg Raises',
  'Toes-to-Bar': 'Toes-to-Bar',
  'Plank': 'Plank',
  'L-Sit (Barren)': 'L-Sit (Parallel Bars)',
  'Bodyweight Squats': 'Bodyweight Squats',
  'Ausfallschritte (Walking Lunges)': 'Walking Lunges',
  'Pistol Squat (Assist)': 'Assisted Pistol Squat',
  'Nordic Curl (Partner/Bar Fix)': 'Nordic Curl (Partner/Bar)',
  'Wadenheben (einbeinig)': 'Single-Leg Calf Raises',
  'Tibialis Raises': 'Tibialis Raises',
  'Klimmzüge mit weitem Griff (Wide Pull-Ups)': 'Wide Pull-Ups',
  'Klimmzüge mit engem Griff (Hammergriff)': 'Close-Grip Pull-Ups (Hammer)',
  'Commando Pull-Ups': 'Commando Pull-Ups',
  'Archer Pull-Ups': 'Archer Pull-Ups',
  'Typewriter Pull-Ups': 'Typewriter Pull-Ups',
  'L-Sit Pull-Ups': 'L-Sit Pull-Ups',
  'Chest-to-Bar Pull-Ups': 'Chest-to-Bar Pull-Ups',
  'Negative Pull-Ups': 'Negative Pull-Ups',
  'Assistierte Klimmzüge (Band/Fuß)': 'Assisted Pull-Ups (Band/Foot)',
  'Active Hang': 'Active Hang',
  'One-Arm Pull-Up Negativ': 'One-Arm Pull-Up Negative',
  'Wide Inverted Row': 'Wide Inverted Row',
  'Archer Inverted Row': 'Archer Inverted Row',
  'Bar Bicep Curls (an niedriger Stange)': 'Bar Bicep Curls (Low Bar)',
  'Wide Push-Ups': 'Wide Push-Ups',
  'Close Push-Ups': 'Close Push-Ups',
  'Archer Push-Ups': 'Archer Push-Ups',
  'Typewriter Push-Ups': 'Typewriter Push-Ups',
  'Pseudo Planche Push-Ups': 'Pseudo Planche Push-Ups',
  'Hindu Push-Ups': 'Hindu Push-Ups',
  'Plyometrische Push-Ups (Clap)': 'Plyometric Push-Ups (Clap)',
  'Spider-Man Push-Ups': 'Spider-Man Push-Ups',
  'Incline Push-Ups (Hände erhöht)': 'Incline Push-Ups (Hands Elevated)',
  'One-Arm Push-Up (Elevated)': 'One-Arm Push-Up (Elevated)',
  'One-Arm Push-Up (Boden)': 'One-Arm Push-Up (Floor)',
  'Korean Dips': 'Korean Dips',
  'Russian Dips': 'Russian Dips',
  'Straight Bar Dips': 'Straight Bar Dips',
  'Pseudo Planche Dips (Barren)': 'Pseudo Planche Dips',
  'Bulgarian Dips (tief)': 'Deep Bulgarian Dips',
  'Bench Triceps Extension (Stange)': 'Bench Triceps Extension (Bar)',
  'Box Pike Push-Ups': 'Box Pike Push-Ups',
  'Pike Push-Up Negativ': 'Pike Push-Up Negative',
  'Crow Pose (Frog Stand)': 'Crow Pose (Frog Stand)',
  'Wall Walks': 'Wall Walks',
  'Wall Handstand (Bauch zur Wand)': 'Wall Handstand (Chest to Wall)',
  'Negative Handstand Push-Up (Wand)': 'Negative Handstand Push-Up (Wall)',
  'Tuck Planche Hold': 'Tuck Planche Hold',
  'Advanced Tuck Planche': 'Advanced Tuck Planche',
  'Side Lever / Human Flag Vorstufen': 'Side Lever / Human Flag Progressions',
  'Schulter-Dislokationen (Stab/Tuch)': 'Shoulder Dislocates (Stick/Towel)',
  'Hollow Body Hold': 'Hollow Body Hold',
  'Hollow Body Rock': 'Hollow Body Rock',
  'Superman Hold (Arch)': 'Superman Hold (Arch)',
  'V-Ups': 'V-Ups',
  'Sit-Ups': 'Sit-Ups',
  'Bicycle Crunches': 'Bicycle Crunches',
  'Russian Twists': 'Russian Twists',
  'Mountain Climbers': 'Mountain Climbers',
  'Side Plank': 'Side Plank',
  'Plank to Push-Up': 'Plank to Push-Up',
  'Bird Dog': 'Bird Dog',
  'Dead Bug': 'Dead Bug',
  'Flutter Kicks': 'Flutter Kicks',
  'Hanging Windshield Wipers': 'Hanging Windshield Wipers',
  'Dragon Flag Negativ': 'Dragon Flag Negative',
  'Dragon Flag': 'Dragon Flag',
  'Reverse Crunch': 'Reverse Crunch',
  'Wall Sit': 'Wall Sit',
  'Jump Squats': 'Jump Squats',
  'Bulgarian Split Squat': 'Bulgarian Split Squat',
  'Cossack Squats': 'Cossack Squats',
  'Shrimp Squat (Assist)': 'Assisted Shrimp Squat',
  'Step-Ups (Bank/Pfosten)': 'Step-Ups (Bench/Post)',
  'Glute Bridge': 'Glute Bridge',
  'Glute Bridge einbeinig': 'Single-Leg Glute Bridge',
  'Hip Thrust (Schultern auf Bank)': 'Hip Thrust (Shoulders on Bench)',
  'Reverse Lunges': 'Reverse Lunges',
  'Lateral Lunges (Seitlicher Ausfallschritt)': 'Lateral Lunges',
  'Side-Lying Leg Raises': 'Side-Lying Leg Raises',
  'Donkey Kicks': 'Donkey Kicks',
  'Broad Jumps': 'Broad Jumps',
  'Sprint-Bursts': 'Sprint Bursts',
  'High Knees': 'High Knees',
  'Sissy Squat': 'Sissy Squat',
  'Box Jumps': 'Box Jumps',
  'Towel Hangs': 'Towel Hangs',
  'One-Arm Hang (Assist)': 'Assisted One-Arm Hang',
  'Fingertip Hangs': 'Fingertip Hangs',
  'Knuckle Push-Ups': 'Knuckle Push-Ups',
  'Wrist Warm-Up (CARs)': 'Wrist Warm-Up (CARs)',
  'Neck Curls (Nacken-Crunch)': 'Neck Curls',
  'Neck Extensions': 'Neck Extensions',
};
