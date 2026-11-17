import 'dart:io';

/// Longest-first German ASCII → umlaut replacements.
final List<(String, String)> replacements = () {
  final pairs = <(String, String)>[
    ('Fruehstuecks', 'Frühstücks'),
    ('Fruehstueck', 'Frühstück'),
    ('Fruehlingszwiebeln', 'Frühlingszwiebeln'),
    ('Fruehkartoffeln', 'Frühkartoffeln'),
    ('Suesskartoffeln', 'Süßkartoffeln'),
    ('Suesskartoffel', 'Süßkartoffel'),
    ('Handstandliegestuetz', 'Handstandliegestütz'),
    ('Knieuebung', 'Knieübung'),
    ('Unterarmstuetz', 'Unterarmstütz'),
    ('Liegestuetz', 'Liegestütz'),
    ('Kraeuterseitlinge', 'Kräuterseitlinge'),
    ('Koerniger Frischkaese', 'Körniger Frischkäse'),
    ('Koerniger', 'Körniger'),
    ('Frischkaese', 'Frischkäse'),
    ('Huettenkaese', 'Hüttenkäse'),
    ('Handkaese', 'Handkäse'),
    ('Harzer Kaese', 'Harzer Käse'),
    ('Butterkaese', 'Butterkäse'),
    ('Haehnchenfluegel', 'Hähnchenflügel'),
    ('Haehnchenschenkel', 'Hähnchenschenkel'),
    ('Haehnchenkeule', 'Hähnchenkeule'),
    ('Haehnchenbrust', 'Hähnchenbrust'),
    ('Haehnchen', 'Hähnchen'),
    ('Huehnereier', 'Hühnereier'),
    ('Gaenseeier', 'Gänseeier'),
    ('Rinderhuefte', 'Rinderhüfte'),
    ('TK-Gemuesemischung', 'TK-Gemüsemischung'),
    ('Ofengemuese', 'Ofengemüse'),
    ('Salatgemuese', 'Salatgemüse'),
    ('Gemuese', 'Gemüse'),
    ('Gruene Erbsen', 'Grüne Erbsen'),
    ('Gruenkern', 'Grünkern'),
    ('Gruenkohl', 'Grünkohl'),
    ('Gruene', 'Grüne'),
    ('gruen', 'grün'),
    ('Kuerbiskerne', 'Kürbiskerne'),
    ('Kuerbis', 'Kürbis'),
    ('Macadamianuesse', 'Macadamianüsse'),
    ('Pecannuesse', 'Pecannüsse'),
    ('Paranuesse', 'Paranüsse'),
    ('Haselnuesse', 'Haselnüsse'),
    ('Walnuesse', 'Walnüsse'),
    ('Erdnuesse', 'Erdnüsse'),
    ('Nuesse', 'Nüsse'),
    ('Broetchen', 'Brötchen'),
    ('Algenoel', 'Algenöl'),
    ('Avocadooel', 'Avocadoöl'),
    ('Walnussoel', 'Walnussöl'),
    ('Olivenoel', 'Olivenöl'),
    ('Leinoel', 'Leinöl'),
    ('Rapsoel', 'Rapsöl'),
    ('Kokosoel', 'Kokosöl'),
    ('Hanfoel', 'Hanföl'),
    ('Aepfel', 'Äpfel'),
    ('Muesli', 'Müsli'),
    ('Suesses', 'Süßes'),
    ('suess', 'süß'),
    ('Suess', 'Süß'),
    ('Weisse', 'Weiße'),
    ('Weisser', 'Weißer'),
    ('weiss', 'weiß'),
    ('Weiss', 'Weiß'),
    ('geraeuchert', 'geräuchert'),
    ('geschaelt', 'geschält'),
    ('ungeschaelt', 'ungeschält'),
    ('Koerner', 'Körner'),
    ('Koerper', 'Körper'),
    ('Gesaess', 'Gesäß'),
    ('Hueften', 'Hüften'),
    ('Huefte', 'Hüfte'),
    ('Fuesse', 'Füße'),
    ('Gleichmaessig', 'Gleichmäßig'),
    ('gleichmaessig', 'gleichmäßig'),
    ('ausfuehren', 'ausführen'),
    ('Ausfuehren', 'Ausführen'),
    ('oeffnen', 'öffnen'),
    ('Oeffnen', 'Öffnen'),
    ('Staerkt', 'Stärkt'),
    ('staerkt', 'stärkt'),
    ('Foerdert', 'Fördert'),
    ('foerdert', 'fördert'),
    ('Entzuendungs', 'Entzündungs'),
    ('entzuendungs', 'entzündungs'),
    ('ungesaettigt', 'ungesättigt'),
    ('Ungesaettigt', 'Ungesättigt'),
    ('saettigend', 'sättigend'),
    ('Saettigung', 'Sättigung'),
    ('saettigung', 'sättigung'),
    ('Mikronaehr', 'Mikronähr'),
    ('naehrstoff', 'nährstoff'),
    ('Naehrstoff', 'Nährstoff'),
    ('Eiweiss', 'Eiweiß'),
    ('eiweiss', 'eiweiß'),
    ('voluminoes', 'voluminös'),
    ('bekoemmlich', 'bekömmlich'),
    ('Bekoemmlich', 'Bekömmlich'),
    ('Pueree', 'Püree'),
    ('Eintoepfe', 'Eintöpfe'),
    ('Gefluegel', 'Geflügel'),
    ('gefluegel', 'geflügel'),
    ('Wuerzig', 'Würzig'),
    ('wuerzig', 'würzig'),
    ('Guenstig', 'Günstig'),
    ('guenstig', 'günstig'),
    ('Kuehl', 'Kühl'),
    ('kuehl', 'kühl'),
    ('Tuerkisches', 'Türkisches'),
    ('tuerkisches', 'türkisches'),
    ('fuer', 'für'),
    ('Fuer', 'Für'),
    // trailing oil suffix after more specific *oel handled
    ('oel', 'öl'),
  ];
  pairs.sort((a, b) => b.$1.length.compareTo(a.$1.length));
  return pairs;
}();

String applyReplacements(String text) {
  var out = text;
  for (final pair in replacements) {
    out = out.replaceAll(pair.$1, pair.$2);
  }
  return out;
}

/// Transform only double-quoted keys in map entries: "KEY": "value"
/// Optionally also transform German values when [transformValues] is true.
String transformMapKeysAndMaybeValues(
  String content, {
  required bool transformValues,
}) {
  final pattern = RegExp(r'"([^"\\]*(?:\\.[^"\\]*)*)"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"');
  return content.replaceAllMapped(pattern, (m) {
    final key = applyReplacements(m.group(1)!);
    final value = transformValues
        ? applyReplacements(m.group(2)!)
        : m.group(2)!;
    return '"$key": "$value"';
  });
}

void main() {
  final root = Directory.current.path;
  final plainFiles = [
    'lib/screens/food_screen.dart',
    'lib/data/german_supermarket_foods.dart',
    'lib/data/standard_food_dishes.dart',
    'lib/data/hercules_default_exercises.dart',
    'lib/data/yoga_stretch_exercises.dart',
    'lib/screens/category_detail_screen.dart',
  ];

  for (final rel in plainFiles) {
    final file = File('$root/$rel');
    final raw = file.readAsStringSync();
    final next = applyReplacements(raw);
    if (next != raw) {
      file.writeAsStringSync(next);
      stdout.writeln('UPDATED $rel');
    } else {
      stdout.writeln('unchanged $rel');
    }
  }

  // catalog_localizations: transform keys always; German subtitle values yes;
  // English map values no.
  final catalog = File('$root/lib/l10n/catalog_localizations.dart');
  var cat = catalog.readAsStringSync();

  // Split by known map declarations and process sections differently.
  final markers = <String, bool>{
    'foodEnglishNames': false,
    'foodGermanSubtitles': true,
    'foodEnglishSubtitles': false,
    'gymExerciseEnglishNames': false,
    'gymGermanDescriptions': true,
    'gymEnglishDescriptions': false,
    'calisthenicsExerciseEnglishNames': false,
    'calisthenicsGermanDescriptions': true,
    'calisthenicsEnglishDescriptions': false,
    'muscleGroupEnglish': false,
    'workoutExerciseEnglishNames': false,
    'workoutExerciseEnglishBenefits': false, // keys only (German benefits as keys)
    'foodTagGerman': true,
    'foodTagEnglish': false,
  };

  // Simpler approach: transform ALL map keys in the file; transform values only
  // inside German maps by processing the whole file keys-only first, then
  // re-apply value transforms on German map bodies.
  cat = transformMapKeysAndMaybeValues(cat, transformValues: false);

  // Re-read sections for German value maps and transform values too.
  for (final entry in markers.entries) {
    if (!entry.value) continue;
    final name = entry.key;
    final start = cat.indexOf('static const Map<String, String> $name');
    if (start < 0) continue;
    final brace = cat.indexOf('{', start);
    if (brace < 0) continue;
    var depth = 0;
    var end = brace;
    for (var i = brace; i < cat.length; i++) {
      final ch = cat[i];
      if (ch == '{') depth++;
      if (ch == '}') {
        depth--;
        if (depth == 0) {
          end = i;
          break;
        }
      }
    }
    final body = cat.substring(brace, end + 1);
    final newBody = transformMapKeysAndMaybeValues(body, transformValues: true);
    cat = cat.replaceRange(brace, end + 1, newBody);
  }

  // Also transform German string literals outside maps carefully:
  // foodFocus / switch cases already use proper umlauts mostly.
  // Apply replacements to remaining German display helpers that use literals.
  catalog.writeAsStringSync(cat);
  stdout.writeln('UPDATED lib/l10n/catalog_localizations.dart');

  // Dual-alias organ/muscle matchers: add umlaut forms alongside ASCII if needed.
  stdout.writeln('done');
}
