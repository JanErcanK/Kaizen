import '../l10n/catalog_localizations.dart';
import 'progress_store.dart';

/// Organs shown on the home body "Organs" tab.
enum Organ { brain, heart, lungs, liver, stomach, intestines, kidneys }

/// Overall nutrition status for an organ derived from the last 30 days.
enum OrganStatus { good, mixed, careful, noData }

class OrganAnalysis {
  const OrganAnalysis({
    required this.status,
    required this.goodFoods,
    required this.badFoods,
  });

  final OrganStatus status;

  /// Distinct localized food names eaten in the window that help this organ.
  final List<String> goodFoods;

  /// Distinct localized food names eaten in the window that strain this organ.
  final List<String> badFoods;
}

/// Analyzes food intake and rates each organ for display on the home body map.
class OrganHealthService {
  OrganHealthService._();

  static const int windowDays = 30;
  static const Duration greenGlowDuration = Duration(hours: 24);

  /// Nutrient / food-quality groups → substring keywords (lowercased, ASCII).
  static const Map<String, List<String>> _groupKeywords = {
    'omega3': [
      'lachs', 'makrele', 'hering', 'sardin', 'sardell', 'forelle',
      'saibling', 'aal', 'thunfisch', 'leinoel', 'leinöl', 'leinsamen', 'chiasamen',
      'chia', 'walnuss', 'hanf',
    ],
    'fiber': [
      'hafer', 'vollkorn', 'linsen', 'bohnen', 'kichererbsen', 'erbsen',
      'brokkoli', 'apfel', 'beere', 'birne', 'karotte', 'moehre', 'gemuese',
      'kohl', 'spinat', 'salat', 'quinoa', 'dinkel', 'roggen',
    ],
    'antioxidants': [
      'beere', 'heidelbeere', 'blaubeere', 'himbeere', 'brombeere',
      'olivenoel', 'olivenöl', 'olive', 'tee', 'kakao', 'zartbitter', 'kurkuma',
      'gruenkohl', 'paprika', 'tomate', 'granatapfel',
    ],
    'protein': [
      'ei', 'eier', 'huhn', 'haehnchen', 'hähnchen', 'pute', 'rind', 'fisch', 'lachs',
      'quark', 'skyr', 'joghurt', 'linsen', 'bohnen', 'tofu', 'tempeh',
      'garnel', 'huettenkaese',
    ],
    'healthyfats': [
      'olivenoel', 'olivenöl', 'avocado', 'mandel', 'nuss', 'nuesse', 'nüsse', 'walnuss',
      'kerne', 'samen', 'rapsoel', 'leinoel',
    ],
    'leafygreens': [
      'spinat', 'gruenkohl', 'salat', 'brokkoli', 'rucola', 'mangold',
      'feldsalat',
    ],
    'probiotics': [
      'joghurt', 'kefir', 'sauerkraut', 'kimchi', 'quark', 'skyr', 'miso',
    ],
    'vitaminc': [
      'orange', 'zitrone', 'paprika', 'kiwi', 'beere', 'brokkoli',
      'grapefruit', 'acerola', 'sanddorn',
    ],
    'hydrating': [
      'gurke', 'wassermelone', 'melone', 'sellerie', 'tomate', 'zucchini',
    ],
    // ── Quality issues ──
    'sugar': [
      'zucker', 'cola', 'limo', 'gummi', 'bonbon', 'kuchen', 'keks',
      'donut', 'eis', 'riegel', 'nutella', 'sirup', 'energy', 'schokoriegel',
      'marmelade', 'honig',
    ],
    'fried': ['pommes', 'fritten', 'frittiert', 'chips', 'nugget'],
    'processed': [
      'wurst', 'salami', 'leberkaese', 'fast', 'burger', 'doener',
      'fertig', 'pizza', 'hotdog', 'bratwurst', 'speck',
    ],
    'alcohol': [
      'bier', 'wein', 'schnaps', 'wodka', 'vodka', 'alkohol', 'likoer',
      'sekt', 'cocktail', 'rum', 'whisky',
    ],
  };

  static const Map<Organ, ({Set<String> good, Set<String> bad})> _organGroups =
      {
    Organ.brain: (
      good: {'omega3', 'antioxidants', 'leafygreens', 'healthyfats'},
      bad: {'sugar', 'alcohol', 'fried'},
    ),
    Organ.heart: (
      good: {'omega3', 'healthyfats', 'fiber', 'antioxidants'},
      bad: {'sugar', 'fried', 'processed', 'alcohol'},
    ),
    Organ.lungs: (
      good: {'antioxidants', 'vitaminc'},
      bad: {'fried', 'processed'},
    ),
    Organ.liver: (
      good: {'leafygreens', 'antioxidants', 'fiber'},
      bad: {'alcohol', 'sugar', 'fried'},
    ),
    Organ.stomach: (
      good: {'fiber', 'probiotics'},
      bad: {'fried', 'alcohol', 'sugar'},
    ),
    Organ.intestines: (
      good: {'fiber', 'probiotics', 'hydrating'},
      bad: {'processed', 'sugar', 'fried'},
    ),
    Organ.kidneys: (
      good: {'hydrating', 'antioxidants'},
      bad: {'processed', 'alcohol', 'sugar'},
    ),
  };

  static String _normalize(String raw) {
    var s = raw.toLowerCase();
    s = s
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
    return s;
  }

  /// All distinct eaten food entries (raw name) within the window.
  static List<String> _eatenNamesLastDays(int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final names = <String>{};
    for (final e in ProgressStore.foodIntake) {
      final at = DateTime.tryParse(e['recordedAt']?.toString() ?? '');
      if (at == null || at.isBefore(start)) continue;
      for (final name in _namesFromEntry(e)) {
        names.add(name);
      }
    }
    return names.toList();
  }

  static Iterable<String> _namesFromEntry(Map<String, dynamic> e) sync* {
    final kind = e['kind']?.toString();
    if (kind == 'dish') {
      final items = e['items'];
      if (items is List) {
        for (final it in items) {
          if (it is Map) {
            final n = it['foodName']?.toString();
            if (n != null && n.isNotEmpty) yield n;
          }
        }
      }
      return;
    }
    final n = e['name']?.toString();
    if (n != null && n.isNotEmpty) yield n;
  }

  static bool _nameHelpsOrgan(String rawName, Organ organ) {
    final mapping = _organGroups[organ]!;
    final groups = _groupsForName(_normalize(rawName));
    return groups.any(mapping.good.contains);
  }

  static bool _nameStrainsOrgan(String rawName, Organ organ) {
    final mapping = _organGroups[organ]!;
    final groups = _groupsForName(_normalize(rawName));
    return groups.any(mapping.bad.contains);
  }

  static DateTime? lastHelpfulFoodAt(Organ organ) {
    DateTime? latest;
    for (final e in ProgressStore.foodIntake) {
      final at = DateTime.tryParse(e['recordedAt']?.toString() ?? '');
      if (at == null) continue;
      for (final name in _namesFromEntry(e)) {
        if (!_nameHelpsOrgan(name, organ)) continue;
        if (latest == null || at.isAfter(latest)) {
          latest = at;
        }
      }
    }
    return latest;
  }

  static bool isGreenGlowActive(Organ organ) {
    final lastGood = lastHelpfulFoodAt(organ);
    if (lastGood == null) return false;
    return DateTime.now().difference(lastGood) <= greenGlowDuration;
  }

  /// Status used for coloring organs on the home body map.
  static OrganStatus displayStatus(Organ organ) {
    if (isGreenGlowActive(organ)) {
      return OrganStatus.good;
    }

    final analysis = analyze(organ);
    if (analysis.status == OrganStatus.good) {
      return OrganStatus.noData;
    }
    return analysis.status;
  }

  static List<String> helpfulFoodsLast24h(Organ organ) {
    final cutoff = DateTime.now().subtract(greenGlowDuration);
    final foods = <String>[];
    for (final e in ProgressStore.foodIntake) {
      final at = DateTime.tryParse(e['recordedAt']?.toString() ?? '');
      if (at == null || at.isBefore(cutoff)) continue;
      for (final raw in _namesFromEntry(e)) {
        if (!_nameHelpsOrgan(raw, organ)) continue;
        final display = CatalogLocalizations.foodName(raw);
        if (!foods.contains(display)) foods.add(display);
      }
    }
    foods.sort();
    return foods;
  }

  static Set<String> _groupsForName(String normalizedName) {
    final groups = <String>{};
    _groupKeywords.forEach((group, keywords) {
      for (final kw in keywords) {
        if (normalizedName.contains(kw)) {
          groups.add(group);
          break;
        }
      }
    });
    return groups;
  }

  static OrganAnalysis analyze(Organ organ) {
    final eaten = _eatenNamesLastDays(windowDays);

    final good = <String>[];
    final bad = <String>[];

    for (final raw in eaten) {
      final groups = _groupsForName(_normalize(raw));
      if (groups.isEmpty) continue;
      final display = CatalogLocalizations.foodName(raw);
      final isGood = _nameHelpsOrgan(raw, organ);
      final isBad = _nameStrainsOrgan(raw, organ);
      if (isGood && !good.contains(display)) good.add(display);
      if (isBad && !bad.contains(display)) bad.add(display);
    }

    good.sort();
    bad.sort();

    final OrganStatus status;
    if (good.isEmpty && bad.isEmpty) {
      status = OrganStatus.noData;
    } else if (bad.isEmpty) {
      status = OrganStatus.good;
    } else if (good.isEmpty) {
      status = OrganStatus.careful;
    } else {
      status = OrganStatus.mixed;
    }

    return OrganAnalysis(status: status, goodFoods: good, badFoods: bad);
  }
}
