/// Canonical storage keys remain stable for previously logged meals and dishes.
const foodIdentityAliases = <String, String>{
  'Ei': 'Hühnereier',
  'Eier': 'Hühnereier',
  'Hühnerei': 'Hühnereier',
  'Körniger Frischkäse': 'Hüttenkäse',
  'Hähnchenschenkel': 'Hähnchenkeule',
};

const foodSearchAliases = <String, String>{
  'Hühnereier': 'ei eier hühnerei hühnereier egg eggs chicken hen eggs',
  'Hüttenkäse': 'körniger frischkäse cottage cheese',
  'Hähnchenkeule': 'hähnchenschenkel chicken leg chicken thigh',
  'Äpfel': 'apfel apples',
  'Bananen': 'banane bananas',
  'Blaubeeren': 'heidelbeere heidelbeeren blaubeere blueberries',
  'Karotten': 'möhre möhren karotte carrots',
  'Rucola': 'rauke arugula rocket',
  'Aubergine': 'eggplant aubergines',
  'Zucchini': 'courgette zucchini',
  'Kichererbsen': 'kichererbse chickpea chickpeas garbanzo beans',
  'Paprika': 'bell pepper sweet pepper capsicum',
  'Haferflocken': 'hafer rolled oats oatmeal',
  'Magerquark': 'quark low fat fat free',
  'Hähnchenbrust': 'hähnchen chicken breast',
  'Pecannüsse': 'pekannüsse pecan nuts',
};

String canonicalFoodName(String name) => foodIdentityAliases[name] ?? name;

/// Match umlauts, ASCII transliterations, punctuation and common accents alike.
String normalizeFoodSearch(String value) {
  var text = value.toLowerCase();
  const replacements = {
    'ä': 'a',
    'ö': 'o',
    'ü': 'u',
    'ß': 'ss',
    'ae': 'a',
    'oe': 'o',
    'ue': 'u',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ó': 'o',
    'ô': 'o',
    'í': 'i',
    'ï': 'i',
    'ú': 'u',
    'ç': 'c',
  };
  for (final entry in replacements.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }
  return text.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

bool matchesFoodSearch(String searchableText, String query) {
  final normalizedQuery = normalizeFoodSearch(query);
  if (normalizedQuery.isEmpty) return true;
  final text = normalizeFoodSearch(searchableText);
  final words = text.split(' ').toSet();
  return normalizedQuery
      .split(' ')
      .every(
        (term) => term.length <= 2 ? words.contains(term) : text.contains(term),
      );
}

/// Merge legacy spelling/synonym duplicates without rewriting stored history.
List<T> uniqueCatalogFoods<T>(Iterable<T> foods, String Function(T) name) {
  final seen = <String>{};
  return foods
      .where(
        (food) => seen.add(normalizeFoodSearch(canonicalFoodName(name(food)))),
      )
      .toList();
}
