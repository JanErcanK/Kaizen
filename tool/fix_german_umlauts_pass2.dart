import 'dart:io';

void main() {
  final files = [
    'lib/screens/food_screen.dart',
    'lib/data/german_supermarket_foods.dart',
    'lib/data/standard_food_dishes.dart',
    'lib/l10n/catalog_localizations.dart',
    'lib/data/hercules_default_exercises.dart',
    'lib/data/yoga_stretch_exercises.dart',
    'lib/screens/category_detail_screen.dart',
  ];
  final pairs = <(String, String)>[
    ('Avocado (Fürte)', 'Avocado (Fuerte)'),
    ('Saettigend', 'Sättigend'),
    ('saettigend', 'sättigend'),
    ('Aehnlich', 'Ähnlich'),
    ('aehnlich', 'ähnlich'),
    ('Haerter Kaese', 'Härter Käse'),
    ('Haerter', 'Härter'),
    (' Kaese', ' Käse'),
    ('Kaese:', 'Käse:'),
    ('Fettsaeure', 'Fettsäure'),
    ('fatsaeure', 'Fettsäure'),
    ('Fruehstueck', 'Frühstück'),
    ('Eintoepfe', 'Eintöpfe'),
    ('Pueree', 'Püree'),
    ('Ofengemuese', 'Ofengemüse'),
    ('Salatgemuese', 'Salatgemüse'),
    ('Gemuese', 'Gemüse'),
    ('Wuerziges', 'Würziges'),
    ('Wuerzig', 'Würzig'),
    ('Guenstig', 'Günstig'),
    ('Gefluegel', 'Geflügel'),
    ('Staerkehaltiges', 'Stärkehaltiges'),
    ('voluminoes', 'voluminös'),
  ];
  pairs.sort((a, b) => b.$1.length.compareTo(a.$1.length));

  for (final path in files) {
    final file = File(path);
    var text = file.readAsStringSync();
    final before = text;
    for (final pair in pairs) {
      text = text.replaceAll(pair.$1, pair.$2);
    }
    if (text != before) {
      file.writeAsStringSync(text);
      stdout.writeln('UPDATED $path');
    } else {
      stdout.writeln('unchanged $path');
    }
  }
}
