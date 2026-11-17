import '../widgets/app_back_button.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/german_supermarket_foods.dart';
import '../data/food_search.dart';
import '../data/standard_food_catalog.dart';
import '../data/food_nutrient_estimator.dart';
import '../data/supplement_catalog.dart';
import '../l10n/catalog_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../models/food_nutrients.dart';
import '../models/social_models.dart';
import '../services/open_food_facts_service.dart';
import '../services/progress_store.dart';
import '../widgets/daily_nutrients_panel.dart';
import '../widgets/share_with_friends_sheet.dart';
import '../theme/app_colors.dart';
import '../theme/green_screen_style.dart';
import '../widgets/food_category_icon.dart';
import '../widgets/app_segmented_tabs.dart';
import '../widgets/home_edge_swipe_back.dart';
import 'food_barcode_lookup.dart';
import '../widgets/shopping_food_button.dart';

enum CatalogFoodAction { today, dish }

/// Chat and Food open the same product, portion and destination controls.
Future<void> showFoodBarcodeLookup(
  BuildContext context, {
  FoodBarcodeLookup? lookup,
}) async {
  final product = await scanFoodProduct(context, lookup: lookup);
  if (!context.mounted || product == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ScannedProductDetailSheet(product: product),
  );
}

/// Organ suggestions use the same catalog, portions and logging as Food.
Future<void> showCatalogFoodDetails(
  BuildContext context,
  String name, {
  CatalogFoodAction? action,
  double grams = 100,
}) async {
  final food = _FoodScreenState._allFoods
      .where((food) => food.name == canonicalFoodName(name))
      .firstOrNull;
  if (food == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _FoodDetailSheet(food: food, action: action, initialGrams: grams),
  );
}

bool catalogFoodHasMacros(String name) => _FoodScreenState._allFoods.any(
  (food) => food.name == canonicalFoodName(name) && food.macros != null,
);

/// Read-only catalog identities for integrations and integrity checks.
List<String> get catalogFoodNames =>
    List.unmodifiable(_FoodScreenState._allFoods.map((food) => food.name));

/// Per-100g macro values (protein/carbs/fats in grams) for common foods.
/// Curated from standard nutrition tables (USDA / BLS). When a food is not
/// in this map, the food detail sheet shows a manual entry form so the user
/// can still add it to a dish with their own values.
class _Macros {
  const _Macros(this.proteinG, this.carbsG, this.fatsG);
  final double proteinG;
  final double carbsG;
  final double fatsG;
  int get kcal => (proteinG * 4 + carbsG * 4 + fatsG * 9).round();
}

const Map<String, _Macros> _macroPer100g = {
  // ── Eier ──
  'Eier': _Macros(12.5, 1.1, 11),
  'Hühnereier': _Macros(12.5, 1.1, 11),
  'Wachteleier': _Macros(13, 0.4, 11),
  'Gänseeier': _Macros(13.9, 1.4, 13),

  // ── Fisch (mager) ──
  'Kabeljau': _Macros(17.8, 0, 0.7),
  'Zander': _Macros(19.5, 0, 0.7),
  'Scholle': _Macros(17, 0, 1.7),
  'Seelachs': _Macros(18.3, 0, 0.9),
  'Flunder': _Macros(17, 0, 1.7),
  'Hecht': _Macros(20.5, 0, 0.7),
  'Schellfisch': _Macros(18.3, 0, 0.6),
  'Pangasius': _Macros(14, 0, 3),

  // ── Fisch (fettig / omega-3) ──
  'Lachs': _Macros(20.4, 0, 13),
  'Makrele': _Macros(19, 0, 14),
  'Hering': _Macros(18, 0, 11),
  'Sardinen': _Macros(20, 0, 11),
  'Forelle': _Macros(20, 0, 5),
  'Saibling': _Macros(20, 0, 5),
  'Aal': _Macros(15, 0, 25),
  'Sardellen': _Macros(20, 0, 6),

  // ── Meeresfrüchte ──
  'Garnelen': _Macros(20, 0, 1.7),
  'Scampi': _Macros(20, 0, 1.7),
  'Hummer': _Macros(19, 0, 1),
  'Tintenfisch': _Macros(16, 3, 1.4),
  'Miesmuscheln': _Macros(12, 3.4, 2.2),
  'Jakobsmuscheln': _Macros(20, 3, 1),
  'Austern': _Macros(9, 4.9, 2),
  'Venusmuscheln': _Macros(15, 5, 1.5),

  // ── Milch / Quark / Joghurt ──
  'Magerquark': _Macros(12, 4, 0.3),
  'Skyr': _Macros(11, 4, 0.2),
  'Hüttenkäse': _Macros(12, 3.5, 4),
  'Griechischer Joghurt': _Macros(9, 4, 5),
  'Naturjoghurt': _Macros(3.5, 4, 3.5),
  'Kefir': _Macros(3.3, 4, 1.5),
  'Buttermilch': _Macros(3.5, 4, 0.5),
  'Harzer Käse': _Macros(30, 0.5, 0.7),
  'Handkäse': _Macros(30, 0.5, 0.7),
  'Körniger Frischkäse': _Macros(12, 3.5, 4),

  // ── Geflügel & mageres Fleisch ──
  'Hähnchenbrust': _Macros(23, 0, 1.5),
  'Putenbrust': _Macros(24, 0, 1),
  'Wachtel': _Macros(22, 0, 4),
  'Fasan': _Macros(22, 0, 3),
  'Strauss': _Macros(22, 0, 2),

  // ── Rind / Wild / Lamm ──
  'Rinderfilet': _Macros(22, 0, 5),
  'Roastbeef': _Macros(22, 0, 5),
  'Rinderhüfte': _Macros(22, 0, 4),
  'Tatar (mager)': _Macros(22, 0, 2),
  'Kalbsschnitzel': _Macros(21, 0, 1.5),
  'Hirsch': _Macros(22, 0, 3),
  'Reh': _Macros(22, 0, 3),
  'Wildschwein': _Macros(21, 0, 3.5),
  'Hase': _Macros(22, 0, 3),
  'Kaninchen': _Macros(22, 0, 3),
  'Lammfilet': _Macros(20, 0, 8),

  // ── Hülsenfrüchte (gekocht; trockene Werte sind ca. 3× höher) ──
  'Rote Linsen': _Macros(9, 20, 0.4),
  'Gelbe Linsen': _Macros(9, 20, 0.4),
  'Braune Linsen': _Macros(9, 20, 0.4),
  'Tellerlinsen': _Macros(9, 20, 0.4),
  'Beluga-Linsen': _Macros(9, 20, 0.4),
  'Puy-Linsen': _Macros(9, 20, 0.4),
  'Berglinsen': _Macros(9, 20, 0.4),
  'Kidneybohnen': _Macros(8.7, 22, 0.5),
  'Schwarze Bohnen': _Macros(8.9, 23, 0.5),
  'Weiße Bohnen (Cannellini)': _Macros(8.2, 22, 0.5),
  'Wachtelbohnen (Pinto)': _Macros(9, 26, 0.7),
  'Dicke Bohnen (Saubohnen)': _Macros(8, 12, 0.5),
  'Adzukibohnen': _Macros(7.5, 25, 0.2),
  'Mungbohnen': _Macros(7, 19, 0.4),
  'Limabohnen': _Macros(7.8, 20, 0.4),
  'Sojabohnen (Edamame)': _Macros(12, 8, 5),
  'Kichererbsen': _Macros(9, 27, 2.6),
  'Lupinenkerne': _Macros(15, 10, 5),
  'Grüne Erbsen': _Macros(5, 14, 0.4),
  'Gelbe Spalterbsen': _Macros(8, 21, 0.4),

  // ── Vegane Proteine ──
  'Tofu (Natur)': _Macros(8, 2, 4.8),
  'Tofu (geräuchert)': _Macros(16, 2, 9),
  'Tempeh': _Macros(19, 9, 11),
  'Seitan': _Macros(25, 14, 2),
  'Sojaschnetzel (TVP)': _Macros(50, 30, 1.5),
  'Lupinen-Geschnetzeltes': _Macros(16, 5, 3),

  // ── Getreide / Pseudogetreide (trocken) ──
  'Haferflocken': _Macros(13, 60, 7),
  'Haferkleie': _Macros(17, 50, 7),
  'Dinkel (Körner)': _Macros(14, 70, 2.7),
  'Dinkel (Mehl)': _Macros(13, 71, 2.5),
  'Vollkornweizen': _Macros(13, 71, 2),
  'Roggen': _Macros(10, 72, 1.7),
  'Gerste': _Macros(10, 73, 1.2),
  'Grünkern': _Macros(11, 67, 2.7),
  'Quinoa (weiß)': _Macros(14, 64, 6),
  'Quinoa (rot)': _Macros(14, 64, 6),
  'Quinoa (schwarz)': _Macros(14, 64, 6),
  'Amaranth': _Macros(14, 65, 7),
  'Buchweizen': _Macros(13, 72, 3.4),
  'Hirse': _Macros(11, 73, 4),
  'Teff': _Macros(13, 73, 2.4),
  'Mais (Polenta)': _Macros(7, 79, 1.7),
  'Maiskolben': _Macros(3.2, 19, 1.2),
  'Naturreis (Vollkorn)': _Macros(8, 75, 3),
  'Roter Reis': _Macros(8, 75, 2.5),
  'Schwarzer Reis': _Macros(9, 75, 2.5),
  'Wildreis': _Macros(14, 74, 1),
  'Basmati-Vollkorn': _Macros(8, 75, 2.5),
  'Reis': _Macros(7, 80, 0.7),

  // ── Knollen / Wurzeln ──
  'Kartoffeln': _Macros(2, 17, 0.1),
  'Kartoffeln (festkochend)': _Macros(2, 17, 0.1),
  'Kartoffeln (mehlig)': _Macros(2, 17, 0.1),
  'Frühkartoffeln': _Macros(2, 16, 0.1),
  'Süßkartoffeln (orange)': _Macros(1.6, 20, 0.1),
  'Süßkartoffeln (weiß)': _Macros(1.6, 20, 0.1),
  'Süßkartoffeln (violett)': _Macros(1.6, 20, 0.1),
  'Maniok': _Macros(1.4, 38, 0.3),
  'Yamswurzel': _Macros(1.5, 28, 0.2),
  'Topinambur': _Macros(2.4, 17, 0.4),
  'Pastinaken': _Macros(1.2, 18, 0.3),

  // ── Kürbis ──
  'Kürbis (Hokkaido)': _Macros(1.4, 9, 0.5),
  'Kürbis (Butternut)': _Macros(1, 12, 0.1),
  'Kürbis (Muskat)': _Macros(1, 11, 0.1),
  'Kürbis (Spaghetti)': _Macros(0.6, 7, 0.6),

  // ── Blattgemüse / Salat (Rohwerte) ──
  'Spinat': _Macros(2.9, 3.6, 0.4),
  'Mangold': _Macros(1.8, 3.7, 0.2),
  'Grünkohl': _Macros(4.3, 9, 0.9),
  'Schwarzkohl': _Macros(4, 9, 0.7),
  'Kopfsalat': _Macros(1.4, 2.9, 0.2),
  'Feldsalat': _Macros(2, 3.6, 0.4),
  'Rucola': _Macros(2.6, 3.7, 0.7),
  'Chicoree': _Macros(0.9, 4, 0.1),
  'Endivie': _Macros(1.2, 3.4, 0.2),
  'Radicchio': _Macros(1.4, 4.5, 0.3),
  'Lollo Rosso': _Macros(1.3, 2.9, 0.2),
  'Lollo Bionda': _Macros(1.3, 2.9, 0.2),
  'Eisbergsalat': _Macros(0.9, 2.9, 0.1),
  'Romanasalat': _Macros(1.2, 3.3, 0.3),
  'Postelein': _Macros(1.5, 3, 0.2),
  'Kresse': _Macros(2.6, 4.4, 0.7),

  // ── Kohl / Kreuzblütler ──
  'Brokkoli': _Macros(2.8, 7, 0.4),
  'Blumenkohl': _Macros(1.9, 5, 0.3),
  'Rosenkohl': _Macros(3.4, 9, 0.3),
  'Weißkohl': _Macros(1.3, 6, 0.1),
  'Rotkohl': _Macros(1.4, 7, 0.2),
  'Wirsing': _Macros(2.4, 6, 0.2),
  'Spitzkohl': _Macros(1.4, 4.5, 0.2),
  'Kohlrabi': _Macros(1.7, 6, 0.1),
  'Chinakohl': _Macros(1.2, 3.2, 0.2),
  'Pak Choi': _Macros(1.5, 2.2, 0.2),
  'Romanesco': _Macros(2.5, 5, 0.3),

  // ── Fruchtgemüse ──
  'Tomaten': _Macros(0.9, 3.9, 0.2),
  'Paprika': _Macros(1, 6, 0.3),
  'Zucchini': _Macros(1.2, 3.1, 0.3),
  'Aubergine': _Macros(1, 6, 0.2),
  'Gurke (Salatgurke)': _Macros(0.7, 3.6, 0.1),
  'Gurke (Einlegegurke)': _Macros(0.7, 2.3, 0.2),
  'Okra': _Macros(1.9, 7, 0.2),

  // ── Wurzel / Knolle ──
  'Karotten': _Macros(0.9, 10, 0.2),
  'Rote Bete': _Macros(1.6, 10, 0.2),
  'Radieschen': _Macros(0.7, 3.4, 0.1),
  'Rettich (weiß)': _Macros(0.7, 4, 0.1),
  'Rettich (schwarz)': _Macros(1.4, 9, 0.2),
  'Sellerie (Knolle)': _Macros(1.5, 7, 0.3),
  'Sellerie (Staude)': _Macros(0.7, 3, 0.2),
  'Fenchel': _Macros(1.2, 7.3, 0.2),

  // ── Lauchgewächse ──
  'Zwiebeln (gelb)': _Macros(1.1, 9, 0.1),
  'Zwiebeln (rot)': _Macros(1.1, 9, 0.1),
  'Schalotten': _Macros(2.5, 17, 0.1),
  'Knoblauch': _Macros(6.4, 33, 0.5),
  'Lauch (Porree)': _Macros(1.5, 14, 0.3),
  'Frühlingszwiebeln': _Macros(1.9, 7, 0.2),
  'Schnittlauch': _Macros(3.3, 4.4, 0.7),

  // ── Spargel & Co ──
  'Spargel (weiß)': _Macros(2.2, 3.9, 0.1),
  'Spargel (grün)': _Macros(2.2, 3.9, 0.1),
  'Artischocken': _Macros(3.3, 11, 0.2),
  'Bambussprossen': _Macros(2.6, 5, 0.3),
  'Algen (Nori)': _Macros(6, 5, 0.3),
  'Algen (Wakame)': _Macros(3, 9, 0.6),
  'Spirulina': _Macros(57, 24, 8),

  // ── Pilze ──
  'Champignons': _Macros(3.1, 3.3, 0.3),
  'Steinpilze': _Macros(3.7, 2.5, 0.4),
  'Pfifferlinge': _Macros(1.5, 1, 0.5),
  'Austernpilze': _Macros(3.3, 6, 0.4),
  'Shiitake': _Macros(2.2, 7, 0.5),
  'Kräuterseitlinge': _Macros(2.4, 4.5, 0.4),
  'Morcheln': _Macros(3.1, 5, 0.6),

  // ── Beeren / Obst ──
  'Beeren': _Macros(1.2, 12, 0.4),
  'Blaubeeren': _Macros(0.7, 14, 0.3),
  'Erdbeeren': _Macros(0.7, 8, 0.3),
  'Himbeeren': _Macros(1.2, 12, 0.7),
  'Brombeeren': _Macros(1.4, 10, 0.5),
  'Johannisbeeren': _Macros(1.4, 14, 0.2),
  'Heidelbeeren': _Macros(0.7, 14, 0.3),
  'Apfel': _Macros(0.3, 14, 0.2),
  'Äpfel': _Macros(0.3, 14, 0.2),
  'Birne': _Macros(0.4, 15, 0.1),
  'Banane': _Macros(1.1, 23, 0.3),
  'Bananen': _Macros(1.1, 23, 0.3),
  'Orange': _Macros(0.9, 12, 0.1),
  'Grapefruit': _Macros(0.8, 11, 0.1),
  'Zitrone': _Macros(1.1, 9, 0.3),
  'Mandarine': _Macros(0.8, 13, 0.3),
  'Kiwi': _Macros(1.1, 15, 0.5),
  'Ananas': _Macros(0.5, 13, 0.1),
  'Mango': _Macros(0.8, 15, 0.4),
  'Papaya': _Macros(0.5, 11, 0.3),
  'Wassermelone': _Macros(0.6, 8, 0.2),
  'Honigmelone': _Macros(0.5, 9, 0.1),
  'Trauben': _Macros(0.7, 17, 0.2),
  'Avocado': _Macros(2, 9, 15),

  // ── Nüsse & Samen ──
  'Mandeln': _Macros(21, 22, 49),
  'Walnüsse': _Macros(15, 14, 65),
  'Cashewkerne': _Macros(18, 30, 44),
  'Haselnüsse': _Macros(15, 17, 61),
  'Pistazien': _Macros(20, 28, 45),
  'Paranüsse': _Macros(14, 12, 66),
  'Pekannuesse': _Macros(9, 14, 72),
  'Macadamia': _Macros(8, 14, 76),
  'Erdnüsse': _Macros(26, 16, 49),
  'Erdnussbutter': _Macros(25, 20, 50),
  'Chiasamen': _Macros(17, 8, 31),
  'Leinsamen': _Macros(18, 1.6, 42),
  'Kürbiskerne': _Macros(30, 11, 49),
  'Sonnenblumenkerne': _Macros(21, 20, 51),
  'Sesam': _Macros(18, 24, 50),
  'Hanfsamen': _Macros(31, 9, 48),
  'Mohn': _Macros(18, 28, 42),
  'Flohsamen': _Macros(2.5, 8, 0.5),

  // ── Fette / Öle ──
  'Olivenöl': _Macros(0, 0, 100),
  'Rapsöl': _Macros(0, 0, 100),
  'Leinöl': _Macros(0, 0, 100),
  'Kokosöl': _Macros(0, 0, 100),
  'Butter': _Macros(0.8, 0.1, 81),
  'Ghee': _Macros(0.3, 0, 99),
};

_Macros? _macrosForFoodName(String name) {
  final standard = standardFoodsByName[canonicalFoodName(name)];
  if (standard != null) {
    return _Macros(standard.proteinG, standard.carbsG, standard.fatsG);
  }
  final base = _macroPer100g[name];
  if (base != null) return base;
  final sup = supermarketMacroPer100g[name];
  if (sup == null) return null;
  return _Macros(sup.$1, sup.$2, sup.$3);
}

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _supplementSearchController =
      TextEditingController();
  final TextEditingController _dishSearchController = TextEditingController();
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );
  String _selectedMacro = 'all';
  String _selectedFocus = 'all';
  String _query = '';
  String _supplementQuery = '';
  String _dishQuery = '';

  static const List<_FoodChipOption> _macroOptions = [
    _FoodChipOption('all', 'Alle'),
    _FoodChipOption('protein', 'Protein'),
    _FoodChipOption('carbs', 'Kohlenhydrate'),
    _FoodChipOption('fats', 'Fette'),
  ];

  static const List<_FoodChipOption> _focusOptions = [
    _FoodChipOption('all', 'Alle'),
    _FoodChipOption('never_eat', 'Never eat'),
    _FoodChipOption('healthy_brain', 'Healthy brain'),
  ];

  static const List<_FoodItem> _foods = [
    _FoodItem(
      name: 'Hühnereier',
      subtitle: 'Allrounder: hochwertiges Protein und gute Mikronährstoffe.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'fats', 'choline', 'ei'],
    ),
    _FoodItem(
      name: 'Wachteleier',
      subtitle: 'Klein, nährstoffdicht und proteinstark.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'fats', 'choline', 'ei'],
    ),
    _FoodItem(
      name: 'Gänseeier',
      subtitle: 'Sehr nährstoffreich; eher als gelegentliche Option.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'fats', 'choline', 'ei'],
    ),
    _FoodItem(
      name: 'Lachs',
      subtitle: 'Omega-3-reich und stark für Regeneration und Gehirn.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'fats', 'omega3'],
    ),
    _FoodItem(
      name: 'Kabeljau',
      subtitle: 'Sehr magerer Fisch: viel Protein, wenig Fett.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'fisch', 'magerfisch'],
    ),
    _FoodItem(
      name: 'Zander',
      subtitle: 'Magerer Fisch mit mildem Geschmack und hohem Proteingehalt.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'fisch', 'magerfisch'],
    ),
    _FoodItem(
      name: 'Scholle',
      subtitle: 'Leicht verdaulich und ideal für saubere Mahlzeiten.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'fisch', 'magerfisch'],
    ),
    _FoodItem(
      name: 'Seelachs',
      subtitle: 'Alltagstauglicher, magerer Fisch für viel Protein.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'fisch', 'magerfisch'],
    ),
    _FoodItem(
      name: 'Flunder',
      subtitle: 'Magerer Fisch für leichte, proteinreiche Gerichte.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'fisch', 'magerfisch'],
    ),
    _FoodItem(
      name: 'Hecht',
      subtitle: 'Magerfisch für Protein ohne viel Fett.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'fisch', 'magerfisch'],
    ),
    _FoodItem(
      name: 'Schellfisch',
      subtitle: 'Sehr mager und gut für eine kalorienarme Proteinbasis.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'fisch', 'magerfisch'],
    ),
    _FoodItem(
      name: 'Pangasius',
      subtitle: 'Milder, magerer Fisch für schnelle Proteinmahlzeiten.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'fisch', 'magerfisch'],
    ),
    _FoodItem(
      name: 'Makrele',
      subtitle: 'Fettfisch mit viel Omega-3 für Gehirn und Entzündungsbalance.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'fats', 'omega3', 'fisch', 'fettfisch'],
    ),
    _FoodItem(
      name: 'Hering',
      subtitle: 'Sehr omega-3-reich und nährstoffdicht.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'fats', 'omega3', 'fisch', 'fettfisch'],
    ),
    _FoodItem(
      name: 'Sardinen',
      subtitle: 'Fettfisch mit Omega-3 und viel Protein.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'fats', 'omega3', 'fisch', 'fettfisch'],
    ),
    _FoodItem(
      name: 'Forelle',
      subtitle: 'Gute Mischung aus Protein und gesunden Fetten.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'fats', 'omega3', 'fisch', 'fettfisch'],
    ),
    _FoodItem(
      name: 'Saibling',
      subtitle: 'Ähnlich wie Forelle: Protein plus gute Fette.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'fats', 'omega3', 'fisch', 'fettfisch'],
    ),
    _FoodItem(
      name: 'Aal',
      subtitle:
          'Fettfisch; eher in kleineren Portionen wegen hoher Kaloriendichte.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'fats', 'omega3', 'fisch', 'fettfisch'],
    ),
    _FoodItem(
      name: 'Sardellen',
      subtitle: 'Intensiver Geschmack, omega-3-reich, gut als Topping.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'fats', 'omega3', 'fisch', 'fettfisch'],
    ),
    _FoodItem(
      name: 'Garnelen',
      subtitle: 'Sehr mager und proteinreich.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'meeresfruechte'],
    ),
    _FoodItem(
      name: 'Scampi',
      subtitle: 'Proteinreich und mager; gut für schnelle Pfannengerichte.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'meeresfruechte'],
    ),
    _FoodItem(
      name: 'Hummer',
      subtitle: 'Sehr mageres Protein aus dem Meer.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'meeresfruechte'],
    ),
    _FoodItem(
      name: 'Tintenfisch',
      subtitle: 'Mageres Protein (Calamari/Oktopus) für Abwechslung.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'meeresfruechte', 'calamari', 'oktopus'],
    ),
    _FoodItem(
      name: 'Miesmuscheln',
      subtitle: 'Protein plus Mikronährstoffe; gut in Eintöpfen.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'meeresfruechte', 'muscheln'],
    ),
    _FoodItem(
      name: 'Jakobsmuscheln',
      subtitle: 'Mager und proteinreich, schnell zubereitet.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'meeresfruechte', 'muscheln'],
    ),
    _FoodItem(
      name: 'Austern',
      subtitle: 'Nährstoffdicht und proteinreich; eher als Special.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'meeresfruechte', 'muscheln'],
    ),
    _FoodItem(
      name: 'Venusmuscheln',
      subtitle: 'Proteinreich und gut für mediterrane Gerichte.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'meeresfruechte', 'muscheln'],
    ),
    _FoodItem(
      name: 'Magerquark',
      subtitle: 'Viel Protein bei wenig Kalorien.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'casein', 'lowfat'],
    ),
    _FoodItem(
      name: 'Skyr',
      subtitle: 'Sehr proteinreich und meist fettarm.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lowfat', 'milchprodukte'],
    ),
    _FoodItem(
      name: 'Hüttenkäse',
      subtitle: 'Proteinreich, gut für schnelle Bowls und Snacks.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lowfat', 'milchprodukte'],
    ),
    _FoodItem(
      name: 'Hähnchenbrust',
      subtitle: 'Sehr mageres Eiweiß für saubere Mahlzeiten.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'muscle'],
    ),
    _FoodItem(
      name: 'Putenbrust',
      subtitle: 'Mageres Geflügel mit viel Protein.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'geflügel', 'tierisch'],
    ),
    _FoodItem(
      name: 'Wachtel',
      subtitle: 'Mageres Geflügel für Abwechslung.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'geflügel', 'tierisch'],
    ),
    _FoodItem(
      name: 'Fasan',
      subtitle: 'Wildgeflügel: proteinreich und meist mager.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'geflügel', 'tierisch', 'wild'],
    ),
    _FoodItem(
      name: 'Strauss',
      subtitle: 'Sehr mageres rotes Fleisch mit viel Protein.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lean', 'tierisch'],
    ),
    _FoodItem(
      name: 'Rinderfilet',
      subtitle: 'Mageres Rind mit hohem Proteingehalt.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'tierisch', 'rind'],
    ),
    _FoodItem(
      name: 'Roastbeef',
      subtitle: 'Proteinreiches Rind; gut als saubere Mahlzeit.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'tierisch', 'rind'],
    ),
    _FoodItem(
      name: 'Rinderhüfte',
      subtitle: 'Relativ mager und sehr proteinreich.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'tierisch', 'rind', 'lean'],
    ),
    _FoodItem(
      name: 'Tatar (mager)',
      subtitle: 'Sehr mageres Rind; viel Protein bei wenig Fett.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'tierisch', 'rind', 'lean'],
    ),
    _FoodItem(
      name: 'Kalbsschnitzel',
      subtitle: 'Mageres Kalb als klassische Proteinquelle.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'tierisch', 'kalb'],
    ),
    _FoodItem(
      name: 'Hirsch',
      subtitle: 'Wild: proteinreich und meist mager.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'tierisch', 'wild'],
    ),
    _FoodItem(
      name: 'Reh',
      subtitle: 'Sehr mageres Wildfleisch mit viel Protein.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'tierisch', 'wild', 'lean'],
    ),
    _FoodItem(
      name: 'Wildschwein',
      subtitle: 'Wildfleisch mit gutem Proteinprofil.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'tierisch', 'wild'],
    ),
    _FoodItem(
      name: 'Hase',
      subtitle: 'Sehr mageres Wild, ideal für Protein bei wenig Fett.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'tierisch', 'wild', 'lean'],
    ),
    _FoodItem(
      name: 'Kaninchen',
      subtitle: 'Mageres Fleisch, gut verdaulich und proteinreich.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'tierisch', 'wild', 'lean'],
    ),
    _FoodItem(
      name: 'Lammfilet',
      subtitle: 'Proteinreich; achte auf fettarme Zuschnitte.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'tierisch', 'lamm'],
    ),
    _FoodItem(
      name: 'Griechischer Joghurt',
      subtitle: 'Proteinstark und vielseitig kombinierbar.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'probiotics', 'calcium'],
    ),
    _FoodItem(
      name: 'Naturjoghurt',
      subtitle: 'Einfach und vielseitig; gut für Darm und Alltag.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'probiotics', 'milchprodukte'],
    ),
    _FoodItem(
      name: 'Kefir',
      subtitle: 'Fermentiert, probiotisch und gut für Verdauung.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'probiotics', 'milchprodukte'],
    ),
    _FoodItem(
      name: 'Buttermilch',
      subtitle: 'Leicht, proteinreich und oft gut bekömmlich.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'milchprodukte', 'lowfat'],
    ),
    _FoodItem(
      name: 'Harzer Käse',
      subtitle: 'Extrem proteinreich und sehr fettarm.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lowfat', 'milchprodukte'],
    ),
    _FoodItem(
      name: 'Handkäse',
      subtitle: 'Proteinreich und fettarm; gut für leichte Mahlzeiten.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'lowfat', 'milchprodukte'],
    ),
    _FoodItem(
      name: 'Körniger Frischkäse',
      subtitle: 'Proteinreich und gut kombinierbar (süß/herzhaft).',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['protein', 'milchprodukte', 'lowfat'],
    ),

    // ── Pflanzlich: Huelsenfruechte & Produkte ──────────────────────────────
    _FoodItem(
      name: 'Rote Linsen',
      subtitle: 'Schnell gar, proteinreich und ballaststoffstark.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'linsen', 'protein', 'fiber'],
    ),
    _FoodItem(
      name: 'Gelbe Linsen',
      subtitle: 'Protein + Ballaststoffe, gut für Currys und Suppen.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'linsen', 'protein', 'fiber'],
    ),
    _FoodItem(
      name: 'Braune Linsen',
      subtitle: 'Sattmacher mit Protein und komplexen Carbs.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'linsen', 'protein', 'carbs'],
    ),
    _FoodItem(
      name: 'Tellerlinsen',
      subtitle: 'Klassiker für Salate/Eintöpfe: proteinreich und sättigend.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'linsen', 'protein', 'carbs'],
    ),
    _FoodItem(
      name: 'Beluga-Linsen',
      subtitle: 'Aromatisch, bleiben bissfest und sind proteinreich.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'linsen', 'protein', 'fiber'],
    ),
    _FoodItem(
      name: 'Puy-Linsen',
      subtitle: 'Bissfest, gut für Salate und Meal-Prep.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'linsen', 'protein', 'mealprep'],
    ),
    _FoodItem(
      name: 'Berglinsen',
      subtitle: 'Sattmacher: proteinreich und ballaststoffstark.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'linsen', 'protein', 'fiber'],
    ),
    _FoodItem(
      name: 'Kidneybohnen',
      subtitle: 'Protein + Ballaststoffe, perfekt für Bowls und Chili.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'bohnen', 'protein', 'fiber'],
    ),
    _FoodItem(
      name: 'Schwarze Bohnen',
      subtitle: 'Sehr ballaststoffreich und sättigend.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'bohnen', 'protein', 'fiber'],
    ),
    _FoodItem(
      name: 'Weiße Bohnen (Cannellini)',
      subtitle: 'Mild, cremig und ideal für Salate oder Eintöpfe.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'bohnen', 'protein', 'fiber'],
    ),
    _FoodItem(
      name: 'Wachtelbohnen (Pinto)',
      subtitle: 'Proteinreich und super für mexikanische Gerichte.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'bohnen', 'protein', 'fiber'],
    ),
    _FoodItem(
      name: 'Dicke Bohnen (Saubohnen)',
      subtitle: 'Protein + Ballaststoffe, gut in Eintöpfen.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'bohnen', 'protein', 'fiber'],
    ),
    _FoodItem(
      name: 'Adzukibohnen',
      subtitle: 'Proteinreich und beliebt für herzhafte Bowls.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'bohnen', 'protein', 'fiber'],
    ),
    _FoodItem(
      name: 'Mungbohnen',
      subtitle: 'Gute Proteinbasis, auch als Sprossen stark.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'bohnen', 'protein', 'fiber'],
    ),
    _FoodItem(
      name: 'Limabohnen',
      subtitle: 'Cremig, ballaststoffreich und sättigend.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'bohnen', 'protein', 'fiber'],
    ),
    _FoodItem(
      name: 'Sojabohnen (Edamame)',
      subtitle: 'Sehr proteinreich, ideal als Snack oder Bowl-Topping.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'soja', 'protein', 'fiber', 'edamame'],
    ),
    _FoodItem(
      name: 'Kichererbsen',
      subtitle: 'Protein + Carbs, stark für Hummus, Currys und Salate.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'protein', 'carbs', 'fiber'],
    ),
    _FoodItem(
      name: 'Lupinenkerne',
      subtitle: 'Sehr proteinreich und ballaststoffstark.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'lupine', 'protein', 'fiber'],
    ),
    _FoodItem(
      name: 'Grüne Erbsen',
      subtitle: 'Gute Kombi aus Carbs, Protein und Ballaststoffen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'huelsenfruechte', 'erbsen', 'carbs', 'protein'],
    ),
    _FoodItem(
      name: 'Gelbe Spalterbsen',
      subtitle: 'Perfekt für Suppen: ballaststoffreich und sättigend.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: [
        'pflanzlich',
        'huelsenfruechte',
        'erbsen',
        'carbs',
        'protein',
        'fiber',
      ],
    ),
    _FoodItem(
      name: 'Tofu (Natur)',
      subtitle: 'Viel Protein, neutral und extrem vielseitig.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'soja', 'tofu', 'protein'],
    ),
    _FoodItem(
      name: 'Tofu (geräuchert)',
      subtitle: 'Mehr Geschmack, weiterhin proteinreich.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'soja', 'tofu', 'protein'],
    ),
    _FoodItem(
      name: 'Tempeh',
      subtitle: 'Fermentiertes Sojaprodukt: proteinreich und sättigend.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'soja', 'tempeh', 'protein', 'fermented'],
    ),
    _FoodItem(
      name: 'Seitan',
      subtitle: 'Sehr proteinreich (Glutenbasis) für fleischartige Textur.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'seitan', 'protein'],
    ),
    _FoodItem(
      name: 'Sojaschnetzel (TVP)',
      subtitle: 'Sehr hoher Proteingehalt, ideal für Meal-Prep.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'soja', 'tvp', 'protein', 'mealprep'],
    ),
    _FoodItem(
      name: 'Lupinen-Geschnetzeltes',
      subtitle: 'Pflanzliche Proteinoption aus Lupine.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['pflanzlich', 'lupine', 'protein'],
    ),
    _FoodItem(
      name: 'Haferflocken',
      subtitle: 'Langsame Energie und gut für Verdauung und Sättigung.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'fiber', 'slow'],
    ),
    _FoodItem(
      name: 'Haferkleie',
      subtitle: 'Sehr ballaststoffreich, gut für Sättigung und Verdauung.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'fiber', 'vollkorn', 'getreide'],
    ),
    _FoodItem(
      name: 'Dinkel (Körner)',
      subtitle: 'Vollkorn-Getreide: komplexe Carbs plus Ballaststoffe.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'fiber', 'vollkorn', 'getreide', 'dinkel'],
    ),
    _FoodItem(
      name: 'Dinkel (Mehl)',
      subtitle: 'Besser als Weißmehl, aber achte auf Portionen/Verarbeitung.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'getreide', 'dinkel'],
    ),
    _FoodItem(
      name: 'Vollkornweizen',
      subtitle: 'Klassiker für langanhaltende Energie.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'fiber', 'vollkorn', 'getreide', 'weizen'],
    ),
    _FoodItem(
      name: 'Roggen',
      subtitle: 'Vollkorn-Option mit viel Ballaststoffen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'fiber', 'vollkorn', 'getreide', 'roggen'],
    ),
    _FoodItem(
      name: 'Gerste',
      subtitle: 'Ballaststoffreich und sättigend, gut für Eintöpfe.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'fiber', 'vollkorn', 'getreide', 'gerste'],
    ),
    _FoodItem(
      name: 'Grünkern',
      subtitle: 'Unreif geernteter Dinkel: herzhaft und sättigend.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'fiber', 'vollkorn', 'getreide', 'dinkel', 'grünkern'],
    ),

    // ── Glutenfrei: Pseudogetreide & Reisvarianten ─────────────────────────
    _FoodItem(
      name: 'Quinoa (weiß)',
      subtitle: 'Glutenfrei, gute Kombi aus Carbs, Protein und Mikros.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'glutenfrei', 'quinoa', 'fiber'],
    ),
    _FoodItem(
      name: 'Quinoa (rot)',
      subtitle: 'Bissfester als weiß, super für Salate und Meal-Prep.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'glutenfrei', 'quinoa', 'mealprep', 'fiber'],
    ),
    _FoodItem(
      name: 'Quinoa (schwarz)',
      subtitle: 'Sehr aromatisch, glutenfrei und sättigend.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'glutenfrei', 'quinoa', 'fiber'],
    ),
    _FoodItem(
      name: 'Amaranth',
      subtitle: 'Glutenfrei, nährstoffdicht und gut für Porridge/Bowls.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'glutenfrei', 'amaranth', 'fiber'],
    ),
    _FoodItem(
      name: 'Buchweizen',
      subtitle: 'Glutenfrei, herzhafter Geschmack und ballaststoffreich.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'glutenfrei', 'buchweizen', 'fiber'],
    ),
    _FoodItem(
      name: 'Hirse',
      subtitle: 'Glutenfrei und leicht kombinierbar.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'glutenfrei', 'hirse'],
    ),
    _FoodItem(
      name: 'Teff',
      subtitle: 'Glutenfrei, sehr nährstoffdicht und gut für Brei/Backen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'glutenfrei', 'teff', 'fiber'],
    ),
    _FoodItem(
      name: 'Mais (Polenta)',
      subtitle: 'Glutenfreie Carb-Basis; gut als Beilage.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'glutenfrei', 'mais', 'polenta'],
    ),
    _FoodItem(
      name: 'Maiskolben',
      subtitle: 'Gute Carb-Quelle; Portionen im Blick behalten.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'glutenfrei', 'mais'],
    ),
    _FoodItem(
      name: 'Naturreis (Vollkorn)',
      subtitle: 'Mehr Ballaststoffe als weißer Reis, stabilere Energie.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'reis', 'vollkorn', 'fiber'],
    ),
    _FoodItem(
      name: 'Roter Reis',
      subtitle: 'Aromatisch, vollkornnah und sättigend.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'reis', 'vollkorn', 'fiber'],
    ),
    _FoodItem(
      name: 'Schwarzer Reis',
      subtitle: 'Nährstoffdicht, vollkornnah und sehr sättigend.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'reis', 'vollkorn', 'fiber'],
    ),
    _FoodItem(
      name: 'Wildreis',
      subtitle: 'Bissfest, ballaststoffreich und gut für Meal-Prep.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'reis', 'fiber', 'mealprep'],
    ),
    _FoodItem(
      name: 'Basmati-Vollkorn',
      subtitle: 'Aromatisch und gut für eine “saubere” Carb-Beilage.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'reis', 'vollkorn', 'fiber', 'basmati'],
    ),
    _FoodItem(
      name: 'Reis',
      subtitle: 'Gut verdaulich und ideal rund ums Training.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'easy', 'energy'],
    ),
    _FoodItem(
      name: 'Kartoffeln',
      subtitle: 'Sättigend, mineralstoffreich und leicht bekömmlich.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'potassium', 'fiber'],
    ),
    _FoodItem(
      name: 'Kartoffeln (festkochend)',
      subtitle: 'Gute Alltags-Carb-Quelle, ideal als Beilage.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'kartoffeln', 'staerke', 'potassium'],
    ),
    _FoodItem(
      name: 'Kartoffeln (mehlig)',
      subtitle: 'Gut für Püree/Suppen; portioniert für leichte Mahlzeiten.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'kartoffeln', 'staerke'],
    ),
    _FoodItem(
      name: 'Frühkartoffeln',
      subtitle: 'Saisonale Variante, leicht und gut bekömmlich.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'kartoffeln', 'staerke'],
    ),
    _FoodItem(
      name: 'Süßkartoffeln (orange)',
      subtitle: 'Sättigend, gut für Meal-Prep und Trainingstage.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'süßkartoffel', 'staerke', 'mealprep'],
    ),
    _FoodItem(
      name: 'Süßkartoffeln (weiß)',
      subtitle: 'Ähnlich, aber milder; gute Carb-Basis.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'süßkartoffel', 'staerke'],
    ),
    _FoodItem(
      name: 'Süßkartoffeln (violett)',
      subtitle: 'Carb-Basis mit hohem Sättigungsfaktor.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'süßkartoffel', 'staerke'],
    ),
    _FoodItem(
      name: 'Kürbis (Hokkaido)',
      subtitle: 'Leicht, voluminös und gut für Suppen/Bowls.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'gemuese', 'kuerbis', 'fiber'],
    ),
    _FoodItem(
      name: 'Kürbis (Butternut)',
      subtitle: 'Süßlich, sättigend und gut im Ofen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'gemuese', 'kuerbis', 'fiber'],
    ),
    _FoodItem(
      name: 'Kürbis (Muskat)',
      subtitle: 'Aromatisch und gut für Eintöpfe.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'gemuese', 'kuerbis', 'fiber'],
    ),
    _FoodItem(
      name: 'Kürbis (Spaghetti)',
      subtitle: 'Leichte Alternative, gut für Volumen-Mahlzeiten.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'gemuese', 'kuerbis', 'fiber'],
    ),
    _FoodItem(
      name: 'Maniok',
      subtitle:
          'Sehr staerkehaltig; gute Carb-Quelle, Portionsgroesse beachten.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'wurzel', 'staerke', 'maniok'],
    ),
    _FoodItem(
      name: 'Yamswurzel',
      subtitle: 'Staerkehaltige Wurzel, gut als Carb-Beilage.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'wurzel', 'staerke', 'yams'],
    ),
    _FoodItem(
      name: 'Topinambur',
      subtitle: 'Ballaststoffreich (Inulin); langsam steigern für Verdauung.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'wurzel', 'fiber', 'topinambur'],
    ),
    _FoodItem(
      name: 'Pastinaken',
      subtitle: 'Stärkehaltiges Gemüse, gut für Ofengemüse.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'wurzel', 'staerke', 'pastinaken', 'fiber'],
    ),

    // ── Gemüse (Blatt/Salat/Kohl/Frucht/Wurzel/Pilze) ─────────────────────
    _FoodItem(
      name: 'Spinat',
      subtitle: 'Volumen, Mikros und gut für leichte Mahlzeiten.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'blattgemuese', 'fiber', 'mikros'],
    ),
    _FoodItem(
      name: 'Mangold',
      subtitle: 'Blattgemuese mit vielen Mikronährstoffen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'blattgemuese', 'fiber', 'mikros'],
    ),
    _FoodItem(
      name: 'Grünkohl',
      subtitle: 'Sehr nährstoffdicht, ballaststoffreich.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kohl', 'kreuzblütler', 'fiber'],
    ),
    _FoodItem(
      name: 'Schwarzkohl',
      subtitle: 'Nährstoffdichter Kohl, gut in Pfannen/Ofen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kohl', 'kreuzblütler', 'fiber'],
    ),

    // Salate
    _FoodItem(
      name: 'Kopfsalat',
      subtitle: 'Leicht und voluminös, perfekt für grosse Bowls.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'salat', 'fiber'],
    ),
    _FoodItem(
      name: 'Feldsalat',
      subtitle: 'Mild, voluminös und schnell für Salate.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'salat', 'fiber'],
    ),
    _FoodItem(
      name: 'Rucola',
      subtitle: 'Würzig, super als Topping für Bowls.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'salat', 'fiber'],
    ),
    _FoodItem(
      name: 'Chicoree',
      subtitle: 'Bitterstoffe, gut als Salat oder angebraten.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'salat', 'fiber'],
    ),
    _FoodItem(
      name: 'Endivie',
      subtitle: 'Bitterstoffe und Ballaststoffe für Sättigung.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'salat', 'fiber'],
    ),
    _FoodItem(
      name: 'Radicchio',
      subtitle: 'Kräftig, bitter, gut im Salat oder kurz gegrillt.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'salat', 'fiber'],
    ),
    _FoodItem(
      name: 'Lollo Rosso',
      subtitle: 'Leichtes Salatgemüse für Volumen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'salat', 'fiber'],
    ),
    _FoodItem(
      name: 'Lollo Bionda',
      subtitle: 'Leichtes Salatgemüse für Volumen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'salat', 'fiber'],
    ),
    _FoodItem(
      name: 'Eisbergsalat',
      subtitle: 'Sehr knackig, viel Volumen, wenig Kalorien.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'salat', 'fiber'],
    ),
    _FoodItem(
      name: 'Romanasalat',
      subtitle: 'Gute Basis für grosse Salate und Wraps.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'salat', 'fiber'],
    ),
    _FoodItem(
      name: 'Postelein',
      subtitle: 'Zartes Salatgemüse, gut für Abwechslung.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'salat', 'fiber'],
    ),
    _FoodItem(
      name: 'Kresse',
      subtitle: 'Würziges Topping, ideal für Bowls und Quark.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kraeuter', 'topping'],
    ),

    // Kohl & Kreuzblütler
    _FoodItem(
      name: 'Brokkoli',
      subtitle: 'Kreuzblütler, sehr sättigend und mikronährstoffreich.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kohl', 'kreuzblütler', 'fiber'],
    ),
    _FoodItem(
      name: 'Blumenkohl',
      subtitle: 'Volumen-Gemüse, gut als Reis-/Püree-Alternative.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kohl', 'kreuzblütler', 'fiber'],
    ),
    _FoodItem(
      name: 'Rosenkohl',
      subtitle: 'Sehr sättigend, ballaststoffreich.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kohl', 'kreuzblütler', 'fiber'],
    ),
    _FoodItem(
      name: 'Weißkohl',
      subtitle: 'Günstig, ballaststoffreich, top für Bowls/Salat.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kohl', 'fiber'],
    ),
    _FoodItem(
      name: 'Rotkohl',
      subtitle: 'Ballaststoffreich und gut für Salate.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kohl', 'fiber'],
    ),
    _FoodItem(
      name: 'Wirsing',
      subtitle: 'Weicher Kohl, gut für Pfannen/Eintöpfe.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kohl', 'fiber'],
    ),
    _FoodItem(
      name: 'Spitzkohl',
      subtitle: 'Zarter Kohl, leicht zuzubereiten.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kohl', 'fiber'],
    ),
    _FoodItem(
      name: 'Kohlrabi',
      subtitle: 'Knackig und leicht, gut für Volumen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kreuzblütler', 'fiber'],
    ),
    _FoodItem(
      name: 'Chinakohl',
      subtitle: 'Leicht, voluminös und gut im Wok.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kohl', 'fiber'],
    ),
    _FoodItem(
      name: 'Pak Choi',
      subtitle: 'Schnell im Wok, sehr leicht und mikroreich.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kohl', 'kreuzblütler', 'fiber'],
    ),
    _FoodItem(
      name: 'Romanesco',
      subtitle: 'Kreuzblütler-Variante, gut für Abwechslung.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kohl', 'kreuzblütler', 'fiber'],
    ),

    // Fruchtgemuese
    _FoodItem(
      name: 'Tomaten',
      subtitle: 'Allrounder: für Salat, Sauce und Bowls.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'fruchtgemuese', 'tomaten'],
    ),
    _FoodItem(
      name: 'Paprika',
      subtitle: 'Knackig, gut für Volumen und Meal-Prep.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'fruchtgemuese', 'fiber'],
    ),
    _FoodItem(
      name: 'Zucchini',
      subtitle: 'Sehr leicht, gut für Pfanne/Ofen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'fruchtgemuese'],
    ),
    _FoodItem(
      name: 'Aubergine',
      subtitle: 'Sattmachend im Ofen; nimmt Gewuerze gut auf.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'fruchtgemuese', 'fiber'],
    ),
    _FoodItem(
      name: 'Gurke (Salatgurke)',
      subtitle: 'Sehr leicht, perfekt für frische Salate.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'fruchtgemuese', 'gurke'],
    ),
    _FoodItem(
      name: 'Gurke (Einlegegurke)',
      subtitle: 'Als Topping/Snack; Salzgehalt beachten.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'fruchtgemuese', 'gurke'],
    ),
    _FoodItem(
      name: 'Okra',
      subtitle: 'Ballaststoffreich, gut in Currys/Eintöpfen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'fruchtgemuese', 'fiber'],
    ),

    // Wurzel-/Knollen-/Zwiebelgemuese
    _FoodItem(
      name: 'Karotten',
      subtitle: 'Alltagstauglich, gut roh oder gegart.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'wurzel', 'fiber'],
    ),
    _FoodItem(
      name: 'Rote Bete',
      subtitle: 'Nährstoffdicht; gut als Ofengemüse oder Salat.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'wurzel', 'fiber'],
    ),
    _FoodItem(
      name: 'Radieschen',
      subtitle: 'Knackig, leicht, super als Salat-Topping.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'wurzel', 'topping'],
    ),
    _FoodItem(
      name: 'Rettich (weiß)',
      subtitle: 'Scharf, knackig und gut für Salate.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'wurzel', 'rettich'],
    ),
    _FoodItem(
      name: 'Rettich (schwarz)',
      subtitle: 'Kraeftiger Geschmack, gut in Salaten.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'wurzel', 'rettich'],
    ),
    _FoodItem(
      name: 'Sellerie (Knolle)',
      subtitle: 'Aromatisch; gut für Suppen und Ofengemüse.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'wurzel', 'sellerie', 'fiber'],
    ),
    _FoodItem(
      name: 'Sellerie (Staude)',
      subtitle: 'Sehr leicht; top für kleine Snacks.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'sellerie', 'snack'],
    ),
    _FoodItem(
      name: 'Fenchel',
      subtitle: 'Aromatisch und leicht; gut im Ofen oder als Salat.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'zwiebelgemuese', 'fiber'],
    ),

    // Lauchgewaechse
    _FoodItem(
      name: 'Zwiebeln (gelb)',
      subtitle: 'Basis für fast alles; gut für Geschmack.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'lauchgewaechse', 'zwiebeln'],
    ),
    _FoodItem(
      name: 'Zwiebeln (rot)',
      subtitle: 'Milder/süßlicher; top in Salaten.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'lauchgewaechse', 'zwiebeln'],
    ),
    _FoodItem(
      name: 'Schalotten',
      subtitle: 'Feiner Geschmack, ideal für Saucen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'lauchgewaechse', 'zwiebeln'],
    ),
    _FoodItem(
      name: 'Knoblauch',
      subtitle: 'Geschmacks-Booster; gut in fast jeder herzhaften Mahlzeit.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'lauchgewaechse', 'knoblauch'],
    ),
    _FoodItem(
      name: 'Lauch (Porree)',
      subtitle: 'Aromatisch, gut für Suppen und Pfannen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'lauchgewaechse', 'fiber'],
    ),
    _FoodItem(
      name: 'Frühlingszwiebeln',
      subtitle: 'Leichtes Topping für Bowls und Omelett.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'lauchgewaechse', 'topping'],
    ),
    _FoodItem(
      name: 'Schnittlauch',
      subtitle: 'Einfaches Topping; perfekt zu Quark und Eiern.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'kraeuter', 'topping'],
    ),

    // Sonstige / Meer / Pilze
    _FoodItem(
      name: 'Spargel (weiß)',
      subtitle: 'Leicht und saisonal; gut für leichte Tage.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'spargel'],
    ),
    _FoodItem(
      name: 'Spargel (grün)',
      subtitle: 'Aromatischer als weiß; super aus Pfanne/Ofen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'spargel'],
    ),
    _FoodItem(
      name: 'Artischocken',
      subtitle: 'Ballaststoffreich und gut für Abwechslung.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'fiber'],
    ),
    _FoodItem(
      name: 'Bambussprossen',
      subtitle: 'Sehr leicht und knackig; gut im Wok.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'wok'],
    ),
    _FoodItem(
      name: 'Algen (Nori)',
      subtitle: 'Mineralstoffreich; gut als Snack oder für Sushi-Bowls.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'algen', 'mikros'],
    ),
    _FoodItem(
      name: 'Algen (Wakame)',
      subtitle: 'Leicht und mineralstoffreich; gut in Salaten/Suppen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'algen', 'mikros'],
    ),
    _FoodItem(
      name: 'Spirulina',
      subtitle: 'Nährstoffdicht; meist als Pulver/Supplement genutzt.',
      macro: 'protein',
      focuses: ['healthy_brain'],
      tags: ['algen', 'supplement', 'mikros'],
    ),
    _FoodItem(
      name: 'Champignons',
      subtitle: 'Alltagspilz, leicht und vielseitig.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'pilze'],
    ),
    _FoodItem(
      name: 'Steinpilze',
      subtitle: 'Aromatisch und gut für Pfannengerichte.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'pilze'],
    ),
    _FoodItem(
      name: 'Pfifferlinge',
      subtitle: 'Saisonal, aromatisch und leicht.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'pilze'],
    ),
    _FoodItem(
      name: 'Austernpilze',
      subtitle: 'Gute Textur, sehr vielseitig.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'pilze'],
    ),
    _FoodItem(
      name: 'Shiitake',
      subtitle: 'Aromatisch, gut im Wok und in Suppen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'pilze', 'wok'],
    ),
    _FoodItem(
      name: 'Kräuterseitlinge',
      subtitle: 'Fleischige Textur, super zum Anbraten.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'pilze'],
    ),
    _FoodItem(
      name: 'Morcheln',
      subtitle: 'Sehr aromatisch; eher als Special.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['gemuese', 'pilze'],
    ),
    _FoodItem(
      name: 'Beeren',
      subtitle: 'Antioxidantien und wenig Zucker bei viel Mikronährstoffen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'fiber', 'antioxidants'],
    ),
    // ── Obst (Beeren/Kern-Stein/Zitrus/Exoten/Melonen) ─────────────────────
    _FoodItem(
      name: 'Blaubeeren',
      subtitle: 'Antioxidantien-Bombe, gut für Gehirn und Regeneration.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'beeren', 'antioxidants', 'fiber'],
    ),
    _FoodItem(
      name: 'Himbeeren',
      subtitle: 'Sehr ballaststoffreich und leicht zu snacken.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'beeren', 'fiber', 'antioxidants'],
    ),
    _FoodItem(
      name: 'Erdbeeren',
      subtitle: 'Volumen + Geschmack bei relativ wenig Kalorien.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'beeren', 'fiber', 'antioxidants'],
    ),
    _FoodItem(
      name: 'Brombeeren',
      subtitle: 'Ballaststoffreich und antioxidativ.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'beeren', 'fiber', 'antioxidants'],
    ),
    _FoodItem(
      name: 'Johannisbeeren (rot)',
      subtitle: 'Saeuerlich, antioxidantienreich.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'beeren', 'antioxidants'],
    ),
    _FoodItem(
      name: 'Johannisbeeren (schwarz)',
      subtitle: 'Sehr antioxidantienreich, stark für Healthy-Brain.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'beeren', 'antioxidants'],
    ),
    _FoodItem(
      name: 'Johannisbeeren (weiß)',
      subtitle: 'Mildere Variante, gut im Joghurt.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'beeren'],
    ),
    _FoodItem(
      name: 'Stachelbeeren',
      subtitle: 'Saeuerlich, gut als Snack oder im Quark.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'beeren', 'fiber'],
    ),
    _FoodItem(
      name: 'Holunderbeeren',
      subtitle: 'Eher verarbeitet (Saft/Sirup); antioxidantienreich.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'beeren', 'antioxidants'],
    ),
    _FoodItem(
      name: 'Sanddorn',
      subtitle: 'Sehr sauer, nährstoffdicht und antioxidantienreich.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'beeren', 'antioxidants'],
    ),
    _FoodItem(
      name: 'Cranberries',
      subtitle: 'Achte bei getrockneten/saft auf Zuckerzusatz.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'beeren'],
    ),
    _FoodItem(
      name: 'Goji-Beeren',
      subtitle: 'Nährstoffdicht; oft getrocknet als Topping.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'beeren', 'topping'],
    ),

    // Kern- & Steinobst
    _FoodItem(
      name: 'Äpfel',
      subtitle: 'Alltagssnack mit Ballaststoffen, gut für Sättigung.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'kernobst', 'fiber'],
    ),
    _FoodItem(
      name: 'Birnen',
      subtitle: 'Saftig und ballaststoffreich.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'kernobst', 'fiber'],
    ),
    _FoodItem(
      name: 'Quitten',
      subtitle: 'Meist gekocht/verarbeitet; aromatisch und ballaststoffreich.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'kernobst'],
    ),
    _FoodItem(
      name: 'Aprikosen',
      subtitle: 'Gut als Snack; getrocknet: Zucker/Portion im Blick.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'steinobst'],
    ),
    _FoodItem(
      name: 'Pfirsiche',
      subtitle: 'Saftig und leicht, gut im Sommer.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'steinobst'],
    ),
    _FoodItem(
      name: 'Nektarinen',
      subtitle: 'Ähnlich wie Pfirsich, super als Snack.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'steinobst'],
    ),
    _FoodItem(
      name: 'Pflaumen',
      subtitle: 'Ballaststoffreich; gut für Verdauung.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'steinobst', 'fiber'],
    ),
    _FoodItem(
      name: 'Zwetschgen',
      subtitle: 'Wie Pflaumen: ballaststoffreich und gut bekömmlich.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'steinobst', 'fiber'],
    ),
    _FoodItem(
      name: 'Mirabellen',
      subtitle: 'Süß und saftig; portionieren.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'steinobst'],
    ),
    _FoodItem(
      name: 'Kirschen (süß)',
      subtitle: 'Lecker, aber zuckerreicher; gute Portionen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'steinobst'],
    ),
    _FoodItem(
      name: 'Kirschen (sauer)',
      subtitle: 'Beliebt für Regeneration; oft als Saft/Concentrate.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'steinobst'],
    ),

    // Zitrusfruechte
    _FoodItem(
      name: 'Orangen',
      subtitle: 'Frisch und gut für schnelle Carbs.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'zitrus'],
    ),
    _FoodItem(
      name: 'Blutorangen',
      subtitle: 'Wie Orange, aber aromatischer.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'zitrus'],
    ),
    _FoodItem(
      name: 'Zitronen',
      subtitle: 'Eher als Add-on (Wasser/Dressings).',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'zitrus', 'topping'],
    ),
    _FoodItem(
      name: 'Limetten',
      subtitle: 'Perfekt als Add-on für Bowls/Drinks.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'zitrus', 'topping'],
    ),
    _FoodItem(
      name: 'Grapefruits',
      subtitle: 'Saftig, leicht, gut als Frühstück.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'zitrus'],
    ),
    _FoodItem(
      name: 'Mandarinen',
      subtitle: 'Praktischer Snack mit schneller Energie.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'zitrus'],
    ),
    _FoodItem(
      name: 'Clementinen',
      subtitle: 'Wie Mandarine: super als Snack.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'zitrus'],
    ),
    _FoodItem(
      name: 'Satsumas',
      subtitle: 'Süß und leicht schaelbar.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'zitrus'],
    ),
    _FoodItem(
      name: 'Pomelo',
      subtitle: 'Grosse Zitrusfrucht, gut portionierbar.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'zitrus'],
    ),
    _FoodItem(
      name: 'Kumquats',
      subtitle: 'Klein, aromatisch; oft mit Schale.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'zitrus'],
    ),

    // Exoten & Melonen
    _FoodItem(
      name: 'Kiwi',
      subtitle: 'Frisch, saftig und gut als Snack.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'exoten'],
    ),
    _FoodItem(
      name: 'Mango',
      subtitle: 'Sehr lecker; zuckerreicher, Portionen beachten.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'exoten'],
    ),
    _FoodItem(
      name: 'Ananas',
      subtitle: 'Süß-sauer, gut als Snack oder im Joghurt.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'exoten'],
    ),
    _FoodItem(
      name: 'Papaya',
      subtitle: 'Mild und leicht; gut für Abwechslung.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'exoten'],
    ),
    _FoodItem(
      name: 'Granatapfel',
      subtitle: 'Antioxidativ; Kerne super als Topping.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'exoten', 'antioxidants', 'topping'],
    ),
    _FoodItem(
      name: 'Feigen',
      subtitle: 'Süß, gut portionieren; getrocknet besonders kaloriendicht.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'exoten'],
    ),
    _FoodItem(
      name: 'Datteln (frisch)',
      subtitle: 'Sehr süß; gut als schneller Carb-Boost.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'exoten', 'energy'],
    ),
    _FoodItem(
      name: 'Khaki (Sharon)',
      subtitle: 'Sehr süß und weich; portionieren.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'exoten'],
    ),
    _FoodItem(
      name: 'Passionsfrucht (Maracuja)',
      subtitle: 'Aromatisch; super als Topping für Joghurt.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'exoten', 'topping'],
    ),
    _FoodItem(
      name: 'Drachenfrucht',
      subtitle: 'Leicht und frisch; gut für Abwechslung.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'exoten'],
    ),
    _FoodItem(
      name: 'Lychee',
      subtitle: 'Süß und saftig; portionieren.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'exoten'],
    ),
    _FoodItem(
      name: 'Wassermelone',
      subtitle: 'Viel Volumen und sehr erfrischend.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'melone'],
    ),
    _FoodItem(
      name: 'Honigmelone',
      subtitle: 'Süß und erfrischend; gute Portionen.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'melone'],
    ),
    _FoodItem(
      name: 'Cantaloupe',
      subtitle: 'Aromatisch und erfrischend.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'melone'],
    ),
    _FoodItem(
      name: 'Galia',
      subtitle: 'Süß und sehr saftig.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['obst', 'melone'],
    ),
    _FoodItem(
      name: 'Bananen',
      subtitle: 'Schnelle Energie und gut vor oder nach dem Training.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['carbs', 'potassium', 'energy'],
    ),
    _FoodItem(
      name: 'Avocado',
      subtitle: 'Gute Fette für Hormonbalance und Gehirn.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'fiber', 'potassium'],
    ),
    _FoodItem(
      name: 'Avocado (Hass)',
      subtitle: 'Cremig, reich an einfach ungesättigten Fetten.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'avocado', 'muFA', 'fiber'],
    ),
    _FoodItem(
      name: 'Avocado (Fuerte)',
      subtitle: 'Milder, ebenfalls reich an guten Fetten.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'avocado', 'muFA', 'fiber'],
    ),
    _FoodItem(
      name: 'Oliven (grün)',
      subtitle: 'Gute Fette und Polyphenole; gut als Snack/Salat.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'oliven', 'polyphenols'],
    ),
    _FoodItem(
      name: 'Oliven (schwarz)',
      subtitle: 'Gute Fettquelle; ideal zu Bowls und Salaten.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'oliven', 'polyphenols'],
    ),
    _FoodItem(
      name: 'Nüsse',
      subtitle: 'Kaloriendicht und voller guter Fette und Mineralien.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'protein', 'fiber'],
    ),
    _FoodItem(
      name: 'Walnüsse',
      subtitle: 'Sehr gut für Healthy-Brain (Omega-3 ALA).',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'nuesse', 'omega3', 'fiber'],
    ),
    _FoodItem(
      name: 'Mandeln',
      subtitle: 'Gute Fette plus Ballaststoffe; sehr meal-prep-tauglich.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'nuesse', 'fiber'],
    ),
    _FoodItem(
      name: 'Cashewkerne',
      subtitle: 'Kaloriendicht; gut portionieren.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'nuesse'],
    ),
    _FoodItem(
      name: 'Haselnüsse',
      subtitle: 'Gute Fette und Mikronährstoffe.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'nuesse', 'fiber'],
    ),
    _FoodItem(
      name: 'Paranüsse',
      subtitle: 'Sehr nährstoffdicht; 1-2 Stueck reichen oft.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'nuesse'],
    ),
    _FoodItem(
      name: 'Pistazien',
      subtitle: 'Gute Fette; als Snack gut portionierbar.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'nuesse', 'protein'],
    ),
    _FoodItem(
      name: 'Pecannüsse',
      subtitle: 'Sehr fettbetont und kaloriendicht.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'nuesse'],
    ),
    _FoodItem(
      name: 'Macadamianüsse',
      subtitle: 'Sehr fettreich; kleine Portionen.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'nuesse'],
    ),
    _FoodItem(
      name: 'Erdnüsse',
      subtitle:
          'Botanisch Huelsenfrucht, kulinarisch Nuss: fett- und proteinreich.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'nuesse', 'protein', 'huelsenfrucht'],
    ),
    _FoodItem(
      name: 'Olivenöl',
      subtitle: 'Sauberes Fett für Herz und Entzündungsbalance.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'healthy', 'polyphenols'],
    ),
    _FoodItem(
      name: 'Olivenöl (Extra Vergine)',
      subtitle: 'Beste Wahl: polyphenolreich und stabil.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'öl', 'olivenöl', 'polyphenols'],
    ),
    _FoodItem(
      name: 'Leinöl',
      subtitle: 'Omega-3-reich; am besten kalt verwenden.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'öl', 'omega3'],
    ),
    _FoodItem(
      name: 'Rapsöl',
      subtitle: 'Gute Alltags-Option mit ordentlichem Fettsäureprofil.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'öl'],
    ),
    _FoodItem(
      name: 'Walnussöl',
      subtitle: 'Aromatisch; eher kalt nutzen (Salat/Bowls).',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'öl', 'walnuss'],
    ),
    _FoodItem(
      name: 'Hanföl',
      subtitle: 'Gutes Fettsäureprofil; kalt verwenden.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'öl', 'hanf'],
    ),
    _FoodItem(
      name: 'Avocadoöl',
      subtitle: 'Mild, gut zum Braten und für Dressings.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'öl', 'avocado'],
    ),
    _FoodItem(
      name: 'Kokosöl',
      subtitle: 'Sehr gesaettigt; sparsam einsetzen.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'öl', 'kokos'],
    ),
    _FoodItem(
      name: 'Algenöl (Omega-3)',
      subtitle: 'Direkte Omega-3-Quelle (DHA/EPA), oft als Supplement genutzt.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'öl', 'omega3'],
    ),
    _FoodItem(
      name: 'Chiasamen',
      subtitle: 'Ballaststoffe, Omega-3 und gute Sättigung.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'fiber', 'omega3'],
    ),
    _FoodItem(
      name: 'Leinsamen',
      subtitle: 'Unterstuetzt Verdauung und liefert pflanzliche Fette.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'fiber', 'omega3'],
    ),
    _FoodItem(
      name: 'Hanfsamen (geschält)',
      subtitle: 'Gute Fette plus etwas Protein; perfekt als Topping.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'samen', 'hanf', 'protein'],
    ),
    _FoodItem(
      name: 'Hanfsamen (ungeschält)',
      subtitle: 'Mehr Ballaststoffe; gut als Crunch in Bowls.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'samen', 'hanf', 'fiber'],
    ),
    _FoodItem(
      name: 'Kürbiskerne',
      subtitle: 'Mineralstoffreich und fettbetont.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'kerne', 'protein'],
    ),
    _FoodItem(
      name: 'Sonnenblumenkerne',
      subtitle: 'Gute Fette; super als Topping.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'kerne'],
    ),
    _FoodItem(
      name: 'Sesam',
      subtitle: 'Fettbetont; ideal als Topping oder Tahini.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'kerne', 'sesam'],
    ),
    _FoodItem(
      name: 'Pinienkerne',
      subtitle: 'Sehr fettbetont; kleine Portionen.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'kerne'],
    ),
    _FoodItem(
      name: 'Mohn',
      subtitle: 'Fettbetont; eher als Add-on.',
      macro: 'fats',
      focuses: ['healthy_brain'],
      tags: ['fats', 'samen', 'mohn'],
    ),
    _FoodItem(
      name: 'Flohsamen',
      subtitle: 'Extrem ballaststoffreich; top für Verdauung/Sättigung.',
      macro: 'carbs',
      focuses: ['healthy_brain'],
      tags: ['fiber', 'flohsamen', 'verdauung'],
    ),
    _FoodItem(
      name: 'Softdrinks',
      subtitle: 'Leere Kalorien, Blutzucker-Spikes und kaum Nährstoffe.',
      macro: 'carbs',
      focuses: ['never_eat'],
      tags: ['nevereat', 'sugar', 'processed'],
    ),
    _FoodItem(
      name: 'Frittierte Snacks',
      subtitle:
          'Hoch verarbeitet, schwer verdaulich und oft entzündungsfoerdernd.',
      macro: 'fats',
      focuses: ['never_eat'],
      tags: ['nevereat', 'processed', 'transfat'],
    ),
    _FoodItem(
      name: 'Süßes Frühstücks-Müsli',
      subtitle: 'Viel Zucker, wenig Protein und kurze Sättigung.',
      macro: 'carbs',
      focuses: ['never_eat'],
      tags: ['nevereat', 'sugar', 'processed'],
    ),
  ];

  static final List<_FoodItem> _allFoods = uniqueCatalogFoods([
    ..._foods,
    for (final entry in supermarketFoodEntries)
      _FoodItem(
        name: entry.name,
        subtitle: entry.subtitle,
        macro: entry.macro,
        focuses: entry.focuses,
        tags: entry.tags,
      ),
    for (final entry in standardFoodEntries)
      _FoodItem(
        name: entry.nameDe,
        subtitle: entry.subtitleDe,
        macro: entry.macro,
        focuses: const [],
        tags: const [],
      ),
  ], (food) => food.name);

  @override
  void dispose() {
    _searchController.dispose();
    _supplementSearchController.dispose();
    _dishSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<_FoodItem> get _filteredFoods {
    final normalizedQuery = _query.trim().toLowerCase();
    return _allFoods.where((food) {
      final matchesMacro =
          _selectedMacro == 'all' || food.macro == _selectedMacro;
      final matchesFocus =
          _selectedFocus == 'all' || food.focuses.contains(_selectedFocus);
      final matchesQuery = food.matchesQuery(normalizedQuery);
      return matchesMacro && matchesFocus && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return HomeEdgeSwipeBack(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: const AppBackButton(),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 58,
          toolbarHeight: 64,
          titleSpacing: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          title: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AppSegmentedTabs(
              controller: _tabController,
              accent: GreenScreenStyle.accent,
              softSelection: true,
              labels: [
                l10n.food_tabFoods,
                l10n.food_tabDishes,
                l10n.food_tabSupplements,
              ],
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLebensmittelTab(),
              _buildDishesTab(),
              _buildSupplementsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openBarcodeLookup() => showFoodBarcodeLookup(context);

  Future<void> _openFoodDetail(_FoodItem food) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FoodDetailSheet(food: food),
    );
  }

  Widget _buildLebensmittelTab() {
    final l10n = context.l10n;
    final foods = _filteredFoods;
    final macroChips = _macroOptions
        .where((option) => option.id != 'all')
        .toList();
    String macroLabel(String id) => switch (id) {
      'protein' => l10n.food_macroProtein,
      'carbs' => l10n.food_macroCarbs,
      _ => l10n.food_macroFat,
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              foods.isEmpty
                  ? l10n.food_noFoodsFound
                  : l10n.food_foodCount(foods.length),
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            key: const PageStorageKey('food-catalog-list'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: foods.length,
            separatorBuilder: (_, _) => const SizedBox(height: 9),
            itemBuilder: (_, i) => _FoodCard(
              food: foods[i],
              selectedFocus: _selectedFocus,
              onTap: () => _openFoodDetail(foods[i]),
            ),
          ),
        ),
        _floatingSearchPanel(
          panelKey: const Key('food-search-panel'),
          children: [
            _catalogSearchField(
              controller: _searchController,
              hint: l10n.food_searchHint,
              onChanged: (value) => setState(() => _query = value),
              onScan: _openBarcodeLookup,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final option in macroChips) ...[
                  Expanded(
                    child: _TopCategoryCard(
                      label: macroLabel(option.id),
                      selected: _selectedMacro == option.id,
                      onTap: () => setState(() {
                        _selectedMacro = _selectedMacro == option.id
                            ? 'all'
                            : option.id;
                      }),
                    ),
                  ),
                  const SizedBox(width: 7),
                ],
                _FocusFilterButton(
                  selectedFocus: _selectedFocus,
                  options: _focusOptions,
                  onSelected: (id) => setState(() => _selectedFocus = id),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _floatingSearchPanel({
    required Key panelKey,
    required List<Widget> children,
  }) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Container(
          key: panelKey,
          padding: const EdgeInsets.all(12),
          decoration: AppColors.surfaceDecoration(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }

  Widget _catalogSearchField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    VoidCallback? onScan,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      cursorColor: GreenScreenStyle.foreground,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors.textMuted,
          size: 23,
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.text.isNotEmpty)
              IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                  size: 19,
                ),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
            if (onScan != null)
              IconButton(
                tooltip: context.l10n.localeName.startsWith('de')
                    ? 'Barcode scannen'
                    : 'Scan barcode',
                onPressed: onScan,
                icon: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: GreenScreenStyle.foreground,
                  size: 21,
                ),
              ),
          ],
        ),
        filled: true,
        fillColor: GreenScreenStyle.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: GreenScreenStyle.accent),
        ),
      ),
    );
  }

  Widget _compactSearchField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: SizedBox(
        height: 38,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ProgressStore.useLightTheme
                ? const Color(0xFFF2F2F7)
                : const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDishesTab() {
    final l10n = context.l10n;
    return ValueListenableBuilder<int>(
      valueListenable: ProgressStore.listenable(),
      builder: (context, _, _) {
        final dishes = ProgressStore.foodDishes
            .where(
              (dish) =>
                  matchesFoodSearch(dish['name']?.toString() ?? '', _dishQuery),
            )
            .toList(growable: false);
        return Column(
          children: [
            Expanded(
              child: dishes.isEmpty
                  ? (ProgressStore.foodDishes.isEmpty
                        ? _DishesEmptyState(onCreate: _promptCreateDish)
                        : Center(
                            child: Text(
                              l10n.food_noFoodsFound,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ))
                  : ListView.separated(
                      key: const PageStorageKey('dish-catalog-list'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      itemCount: dishes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _DishCard(
                        dish: dishes[i],
                        onTap: () => _openDish(dishes[i]),
                        onLongPress: () => _confirmDeleteDish(dishes[i]),
                        onAddToToday: () => _addDishToToday(dishes[i]),
                      ),
                    ),
            ),
            _floatingSearchPanel(
              panelKey: const Key('dish-search-panel'),
              children: [
                _catalogSearchField(
                  controller: _dishSearchController,
                  hint: l10n.food_dishesSearchHint,
                  onChanged: (value) => setState(() => _dishQuery = value),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _promptCreateDish,
                    style: FilledButton.styleFrom(
                      backgroundColor: GreenScreenStyle.soft,
                      foregroundColor: GreenScreenStyle.foreground,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(l10n.food_newDish),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _promptCreateDish() async {
    final name = await _promptDishName(
      context,
      title: context.l10n.food_newDishTitle,
      initial: '',
    );
    if (name == null) return;
    final id = await ProgressStore.createFoodDish(name);
    if (!mounted) return;
    final dish = ProgressStore.foodDishById(id);
    if (dish == null) return;
    _openDish(dish);
  }

  Future<void> _openDish(Map<String, dynamic> dish) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DishDetailScreen(
          dishId: dish['id']?.toString() ?? '',
          allFoods: _allFoods,
        ),
      ),
    );
  }

  Future<void> _addDishToToday(Map<String, dynamic> dish) async {
    final dishId = dish['id']?.toString() ?? '';
    if (dishId.isEmpty) return;
    final items = _dishItems(dish);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.food_dishNoIngredients)),
      );
      return;
    }
    await ProgressStore.addFoodIntakeDish(dishId: dishId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.food_dishAddedToday(dish['name'] ?? '')),
      ),
    );
  }

  Future<void> _confirmDeleteDish(Map<String, dynamic> dish) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          l10n.food_deleteDishTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.food_deleteDishBody(dish['name'] ?? ''),
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.common_cancel,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.common_delete,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ProgressStore.deleteFoodDish(dish['id']?.toString() ?? '');
  }

  Widget _buildSupplementsTab() {
    final l10n = context.l10n;
    final german = l10n.localeName.startsWith('de');
    final suggestions = searchSupplementCatalog(
      _supplementQuery,
      german: german,
    );

    String slotLabel(String slot) => switch (slot) {
      'midday' => l10n.food_supplementSlotMidday,
      'evening' => l10n.food_supplementSlotEvening,
      _ => l10n.food_supplementSlotMorning,
    };

    return ValueListenableBuilder<int>(
      valueListenable: ProgressStore.listenable(),
      builder: (context, _, _) {
        final logged = ProgressStore.todaySupplementIntake;
        return Column(
          children: [
            _compactSearchField(
              controller: _supplementSearchController,
              hint: l10n.food_supplementsSearchHint,
              onChanged: (v) => setState(() => _supplementQuery = v),
            ),
            if (_supplementQuery.trim().isNotEmpty && suggestions.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final entry = suggestions[index];
                    final label = entry.localizedName(german);
                    return ActionChip(
                      label: Text(label),
                      onPressed: () => _promptAddSupplement(entry),
                      backgroundColor: AppColors.card,
                      side: BorderSide(color: AppColors.stroke),
                      labelStyle: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            if (_supplementQuery.trim().isNotEmpty && suggestions.isNotEmpty)
              const SizedBox(height: 6),
            Expanded(
              child: logged.isEmpty && _supplementQuery.trim().isEmpty
                  ? Center(
                      child: Text(
                        l10n.food_supplementsEmpty,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        if (logged.isNotEmpty) ...[
                          for (final slot in ProgressStore.supplementSlots) ...[
                            _SupplementSlotSection(
                              title: slotLabel(slot),
                              slot: slot,
                              items: ProgressStore.todaySupplementsForSlot(
                                slot,
                              ),
                              dropHint: l10n.food_supplementDropHere,
                              onAccept: (id, index) {
                                ProgressStore.moveSupplementIntake(
                                  id: id,
                                  targetSlot: slot,
                                  targetIndex: index,
                                );
                              },
                              onRemove: (id) =>
                                  ProgressStore.removeSupplementIntake(id),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],
                        if (_supplementQuery.trim().isNotEmpty) ...[
                          if (logged.isNotEmpty) const SizedBox(height: 4),
                          for (final entry in suggestions) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                entry.localizedName(german),
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: entry.typicalMg > 0
                                  ? Text(
                                      l10n.food_supplementMg(
                                        entry.typicalMg ==
                                                entry.typicalMg.roundToDouble()
                                            ? entry.typicalMg.round().toString()
                                            : entry.typicalMg.toStringAsFixed(
                                                1,
                                              ),
                                      ),
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    )
                                  : null,
                              trailing: Icon(
                                Icons.add_circle_outline,
                                color: GreenScreenStyle.accent,
                              ),
                              onTap: () => _promptAddSupplement(entry),
                            ),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _promptAddSupplement(SupplementCatalogEntry entry) async {
    final l10n = context.l10n;
    final german = l10n.localeName.startsWith('de');
    final name = entry.localizedName(german);
    final initialText = entry.typicalMg > 0
        ? (entry.typicalMg == entry.typicalMg.roundToDouble()
              ? '${entry.typicalMg.round()}'
              : entry.typicalMg.toStringAsFixed(1))
        : '';
    final result = await showDialog<({double mg, String slot})>(
      context: context,
      builder: (ctx) =>
          _SupplementAmountDialog(name: name, initialText: initialText),
    );
    if (result == null || !mounted) return;
    await ProgressStore.addSupplementIntake(
      name: name,
      mg: result.mg,
      slot: result.slot,
    );
    if (!mounted) return;
    _supplementQuery = '';
    _supplementSearchController.clear();
    setState(() {});
  }
}

class _SupplementDragData {
  const _SupplementDragData({
    required this.id,
    required this.fromSlot,
    required this.fromIndex,
  });

  final String id;
  final String fromSlot;
  final int fromIndex;
}

class _SupplementSlotSection extends StatelessWidget {
  const _SupplementSlotSection({
    required this.title,
    required this.slot,
    required this.items,
    required this.dropHint,
    required this.onAccept,
    required this.onRemove,
  });

  final String title;
  final String slot;
  final List<Map<String, dynamic>> items;
  final String dropHint;
  final void Function(String id, int index) onAccept;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_SupplementDragData>(
      onWillAcceptWithDetails: (details) => details.data.id.isNotEmpty,
      onAcceptWithDetails: (details) {
        onAccept(details.data.id, items.length);
      },
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
            color: hovering
                ? GreenScreenStyle.accent.withValues(alpha: 0.08)
                : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hovering
                  ? GreenScreenStyle.accent
                  : AppColors.stroke.withValues(alpha: 0.75),
              width: hovering ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    dropHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                )
              else
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _SupplementDropGap(onAccept: (id) => onAccept(id, i)),
                  _DraggableSupplementTile(
                    item: items[i],
                    slot: slot,
                    index: i,
                    onRemove: () => onRemove(items[i]['id']?.toString() ?? ''),
                  ),
                ],
              if (items.isNotEmpty) ...[
                const SizedBox(height: 4),
                _SupplementDropGap(
                  onAccept: (id) => onAccept(id, items.length),
                  tall: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SupplementDropGap extends StatelessWidget {
  const _SupplementDropGap({required this.onAccept, this.tall = false});

  final ValueChanged<String> onAccept;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_SupplementDragData>(
      onWillAcceptWithDetails: (details) => details.data.id.isNotEmpty,
      onAcceptWithDetails: (details) => onAccept(details.data.id),
      builder: (context, candidate, _) {
        final active = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: active ? (tall ? 28 : 18) : (tall ? 8 : 2),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: active
                ? GreenScreenStyle.accent.withValues(alpha: 0.55)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

class _DraggableSupplementTile extends StatelessWidget {
  const _DraggableSupplementTile({
    required this.item,
    required this.slot,
    required this.index,
    required this.onRemove,
  });

  final Map<String, dynamic> item;
  final String slot;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final id = item['id']?.toString() ?? '';
    final name = item['name']?.toString() ?? '';
    final mg = (item['mg'] is num)
        ? (item['mg'] as num).toDouble()
        : double.tryParse(item['mg']?.toString() ?? '') ?? 0;
    final data = _SupplementDragData(id: id, fromSlot: slot, fromIndex: index);

    final tile = _SupplementLogTile(
      name: name,
      mg: mg,
      onRemove: onRemove,
      showDragHandle: true,
    );

    return Draggable<_SupplementDragData>(
      data: data,
      maxSimultaneousDrags: 1,
      feedback: Material(
        color: Colors.transparent,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width - 64,
          child: Opacity(opacity: 0.92, child: tile),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );
  }
}

class _SupplementAmountDialog extends StatefulWidget {
  const _SupplementAmountDialog({
    required this.name,
    required this.initialText,
  });

  final String name;
  final String initialText;

  @override
  State<_SupplementAmountDialog> createState() =>
      _SupplementAmountDialogState();
}

class _SupplementAmountDialogState extends State<_SupplementAmountDialog> {
  late final TextEditingController _controller;
  String _slot = 'morning';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    if (parsed == null || parsed <= 0) return;
    Navigator.of(context).pop((mg: parsed, slot: _slot));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      title: Text(
        l10n.food_supplementAddTitle,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.name,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.food_supplementSlotLabel,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in ProgressStore.supplementSlots)
                ChoiceChip(
                  label: Text(switch (slot) {
                    'midday' => l10n.food_supplementSlotMidday,
                    'evening' => l10n.food_supplementSlotEvening,
                    _ => l10n.food_supplementSlotMorning,
                  }),
                  selected: _slot == slot,
                  onSelected: (_) => setState(() => _slot = slot),
                  selectedColor: GreenScreenStyle.accent.withValues(
                    alpha: 0.25,
                  ),
                  labelStyle: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: _slot == slot
                        ? GreenScreenStyle.accent
                        : AppColors.stroke,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AppColors.textPrimary),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.food_supplementAmountLabel,
              labelStyle: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: GreenScreenStyle.soft,
            foregroundColor: GreenScreenStyle.foreground,
          ),
          onPressed: _submit,
          child: Text(l10n.common_add),
        ),
      ],
    );
  }
}

class _SupplementLogTile extends StatelessWidget {
  const _SupplementLogTile({
    required this.name,
    required this.mg,
    required this.onRemove,
    this.showDragHandle = false,
    this.dragHandle,
  });

  final String name;
  final double mg;
  final VoidCallback onRemove;
  final bool showDragHandle;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mgLabel = mg == mg.roundToDouble()
        ? mg.round().toString()
        : mg.toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (showDragHandle) ...[
            dragHandle ??
                Icon(
                  Icons.drag_indicator_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.food_supplementMg(mgLabel),
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.remove_circle_outline, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _TopCategoryCard extends StatelessWidget {
  const _TopCategoryCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? GreenScreenStyle.accent.withValues(alpha: 0.12)
              : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? GreenScreenStyle.accent : AppColors.stroke,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.food,
    required this.selectedFocus,
    this.onTap,
  });
  final _FoodItem food;
  final String selectedFocus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tags = <String>{
      if (selectedFocus != 'all' && food.focuses.contains(selectedFocus))
        CatalogLocalizations.foodFocus(selectedFocus),
      ...food.tags
          .where((tag) => tag != 'ei')
          .map(CatalogLocalizations.foodTag),
      if (food.tags.isEmpty)
        switch (food.macro) {
          'protein' => context.l10n.food_macroProtein,
          'fats' => context.l10n.food_macroFat,
          _ => context.l10n.food_macroCarbs,
        },
    }.toList();
    return Container(
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                FoodCategoryIcon(name: food.name, tags: food.tags),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'Roboto',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        food.displaySubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: [
                            for (final tag in tags.take(4))
                              _TagPill(
                                label: tag,
                                accent:
                                    selectedFocus != 'all' &&
                                    tag ==
                                        CatalogLocalizations.foodFocus(
                                          selectedFocus,
                                        ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent
            ? GreenScreenStyle.accent.withValues(alpha: 0.14)
            : AppColors.background,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: accent
              ? GreenScreenStyle.accent.withValues(alpha: 0.35)
              : AppColors.stroke,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent ? GreenScreenStyle.accent : AppColors.textMuted,
          fontFamily: 'Roboto',
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FoodChipOption {
  const _FoodChipOption(this.id, this.label);

  final String id;
  final String label;
}

// ── Shared compact nav bar ──────────────────────────────────────────────────

class _FoodItem {
  const _FoodItem({
    required this.name,
    required this.subtitle,
    required this.macro,
    required this.focuses,
    required this.tags,
  });

  final String name;
  final String subtitle;
  final String macro;
  final List<String> focuses;
  final List<String> tags;

  /// Returns per-100g macros from the curated lookup table, or null if the
  /// food has no entry. When null, the detail sheet shows a manual entry form
  /// so the user can still add the food to a dish with their own values.
  _Macros? get macros => _macrosForFoodName(name);

  String get displayName => CatalogLocalizations.foodName(name);

  String get displaySubtitle => CatalogLocalizations.foodSubtitle(name);

  bool matchesQuery(String query) => CatalogLocalizations.matchesFoodQuery(
    name,
    query,
    subtitle: subtitle,
    tags: tags,
    focuses: focuses,
    macro: macro,
  );
}

// ─── Filter dropdown next to the macro chips ──────────────────────────────
class _FocusFilterButton extends StatelessWidget {
  const _FocusFilterButton({
    required this.selectedFocus,
    required this.options,
    required this.onSelected,
  });

  final String selectedFocus;
  final List<_FoodChipOption> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isActive = selectedFocus != 'all';
    String focusLabel(_FoodChipOption o) {
      switch (o.id) {
        case 'all':
          return l10n.food_macroAll;
        case 'never_eat':
          return CatalogLocalizations.foodFocus('never_eat');
        case 'healthy_brain':
          return CatalogLocalizations.foodFocus('healthy_brain');
        default:
          return o.label;
      }
    }

    return SizedBox(
      width: 46,
      child: PopupMenuButton<String>(
        position: PopupMenuPosition.under,
        tooltip: context.l10n.common_filter,
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: AppColors.surfaceBorderSide(),
        ),
        onSelected: onSelected,
        itemBuilder: (_) => options
            .map(
              (o) => PopupMenuItem<String>(
                value: o.id,
                child: Row(
                  children: [
                    Icon(
                      selectedFocus == o.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: selectedFocus == o.id
                          ? GreenScreenStyle.accent
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      focusLabel(o),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Roboto',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        child: Container(
          height: 47,
          decoration: BoxDecoration(
            color: isActive
                ? GreenScreenStyle.accent.withValues(alpha: 0.12)
                : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? GreenScreenStyle.accent : AppColors.stroke,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(Icons.tune, color: AppColors.textPrimary, size: 18),
              ),
              if (isActive)
                const Positioned(
                  top: 6,
                  right: 8,
                  child: SizedBox(width: 6, height: 6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Food detail bottom sheet ─────────────────────────────────────────────
class _FoodDetailSheet extends StatefulWidget {
  const _FoodDetailSheet({
    required this.food,
    this.action,
    this.initialGrams = 100,
  });

  final _FoodItem food;
  final CatalogFoodAction? action;
  final double initialGrams;

  @override
  State<_FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<_FoodDetailSheet> {
  late final TextEditingController _gramsCtrl = TextEditingController(
    text: widget.initialGrams.toStringAsFixed(0),
  );
  // Manual macro inputs (only used when no lookup data is available).
  // Values represent grams per 100 g, so they scale with the grams input.
  final TextEditingController _manualPCtrl = TextEditingController();
  final TextEditingController _manualCCtrl = TextEditingController();
  final TextEditingController _manualFCtrl = TextEditingController();

  @override
  void dispose() {
    _gramsCtrl.dispose();
    _manualPCtrl.dispose();
    _manualCCtrl.dispose();
    _manualFCtrl.dispose();
    super.dispose();
  }

  double get _grams {
    final value = double.tryParse(_gramsCtrl.text.replaceAll(',', '.'));
    return value != null && value.isFinite && value > 0 ? value : 0;
  }

  _Macros? get _effectivePer100g {
    final lookup = widget.food.macros;
    if (lookup != null) return lookup;
    final p = double.tryParse(_manualPCtrl.text.replaceAll(',', '.'));
    final c = double.tryParse(_manualCCtrl.text.replaceAll(',', '.'));
    final f = double.tryParse(_manualFCtrl.text.replaceAll(',', '.'));
    if (p == null && c == null && f == null) return null;
    return _Macros(p ?? 0, c ?? 0, f ?? 0);
  }

  ({double p, double c, double f, int kcal})? get _scaled {
    final per100 = _effectivePer100g;
    if (per100 == null) return null;
    final factor = _grams / 100.0;
    final p = per100.proteinG * factor;
    final c = per100.carbsG * factor;
    final f = per100.fatsG * factor;
    return (p: p, c: c, f: f, kcal: (p * 4 + c * 4 + f * 9).round());
  }

  bool _saving = false;

  Future<void> _runFoodAction(Future<void> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.localeName.startsWith('de')
                  ? 'Speichern fehlgeschlagen. Bitte erneut versuchen.'
                  : 'Could not save. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addToDishFlow() => _runFoodAction(_addToDish);
  Future<void> _addToTodayFlow() => _runFoodAction(_addToToday);

  Future<void> _addToDish() async {
    final l10n = context.l10n;
    final scaled = _scaled;
    if (scaled == null || _grams <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.food_enterGramsMacros)));
      return;
    }
    final dishes = ProgressStore.foodDishes;
    String? targetDishId;
    if (dishes.isEmpty) {
      final name = await _promptDishName(
        context,
        title: l10n.food_newDishTitle,
        initial: '',
      );
      if (name == null) return;
      targetDishId = await ProgressStore.createFoodDish(name);
    } else {
      targetDishId = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _DishPickerSheet(dishes: dishes),
      );
      if (targetDishId == null) return;
      if (targetDishId == '__new__') {
        if (!mounted) return;
        final name = await _promptDishName(
          context,
          title: l10n.food_newDishTitle,
          initial: '',
        );
        if (name == null) return;
        targetDishId = await ProgressStore.createFoodDish(name);
      }
    }
    await ProgressStore.addItemToFoodDish(
      dishId: targetDishId,
      foodName: widget.food.name,
      grams: _grams,
      proteinG: scaled.p,
      carbsG: scaled.c,
      fatsG: scaled.f,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.food_addedToDish(
            widget.food.displayName,
            _grams.toStringAsFixed(0),
          ),
        ),
      ),
    );
  }

  Future<void> _addToToday() async {
    final l10n = context.l10n;
    final scaled = _scaled;
    if (scaled == null || _grams <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.food_enterGramsMacros)));
      return;
    }
    await ProgressStore.addFoodIntakeFood(
      name: widget.food.name,
      grams: _grams,
      proteinG: scaled.p,
      carbsG: scaled.c,
      fatsG: scaled.f,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.food_addedToTodayFull(
            widget.food.displayName,
            _grams.toStringAsFixed(0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final food = widget.food;
    final lookup = food.macros;
    final scaled = _scaled;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: AppColors.surfaceDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.stroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  food.displayName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  food.displaySubtitle,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                if (lookup != null) ...[
                  Text(
                    l10n.food_per100g,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Just the four headline numbers here — fiber, sugar, sat.
                  // fat etc. would only repeat the full breakdown shown below.
                  _MacroChipsRow(
                    kcal: lookup.kcal,
                    proteinG: lookup.proteinG,
                    carbsG: lookup.carbsG,
                    fatsG: lookup.fatsG,
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.food_macrosNotStored,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.food_macrosManualHint,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _MacroInputField(
                                controller: _manualPCtrl,
                                label: l10n.food_macroProtein,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MacroInputField(
                                controller: _manualCCtrl,
                                label: l10n.food_macroCarbs,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MacroInputField(
                                controller: _manualFCtrl,
                                label: l10n.food_macroFat,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  l10n.food_amount,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _gramsCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Roboto',
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    suffixText: 'g',
                    suffixStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.stroke),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: GreenScreenStyle.accent),
                    ),
                  ),
                ),
                if (scaled != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.food_forGrams(_grams.toStringAsFixed(0)),
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MacroChipsRow(
                    kcal: scaled.kcal,
                    proteinG: scaled.p,
                    carbsG: scaled.c,
                    fatsG: scaled.f,
                  ),
                  const SizedBox(height: 18),
                ],
                // Actions sit right after the amount/macros you just set, not
                // below the full nutrient breakdown — no need to scroll past
                // micronutrients and amino acids just to log the food.
                if (widget.action != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving
                          ? null
                          : widget.action == CatalogFoodAction.today
                          ? _addToTodayFlow
                          : _addToDishFlow,
                      icon: Icon(
                        widget.action == CatalogFoodAction.today
                            ? Icons.today_outlined
                            : Icons.restaurant_menu,
                        size: 18,
                      ),
                      label: Text(
                        widget.action == CatalogFoodAction.today
                            ? l10n.food_eatToday
                            : l10n.food_addToDishBtn,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _addToTodayFlow,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: GreenScreenStyle.accent,
                            side: BorderSide(color: GreenScreenStyle.accent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.today_outlined, size: 18),
                          label: Text(
                            l10n.food_eatToday,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _addToDishFlow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GreenScreenStyle.soft,
                            foregroundColor: GreenScreenStyle.foreground,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.restaurant_menu, size: 18),
                          label: Text(
                            l10n.food_addToDishBtn,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                ShoppingFoodButton(
                  name: food.displayName,
                  grams: _grams,
                  onAdded: () => Navigator.of(context).pop(),
                ),
                if (scaled != null) ...[
                  const SizedBox(height: 20),
                  DailyNutrientsPanel(
                    totals: FoodNutrientEstimator.forPortion(
                      name: food.name,
                      grams: _grams,
                      proteinG: scaled.p,
                      carbsG: scaled.c,
                      fatsG: scaled.f,
                      tags: food.tags,
                    ),
                    infoOnly: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroChipsRow extends StatelessWidget {
  const _MacroChipsRow({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    this.extra,
  });

  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatsG;
  final FoodNutrients? extra;

  String _g(double v) => '${v.toStringAsFixed(v >= 10 ? 0 : 1)} g';
  String _mg(double v) => '${v.toStringAsFixed(0)} mg';

  @override
  Widget build(BuildContext context) {
    final isDe = context.l10n.localeName.startsWith('de');
    final chips = <(String, String)>[
      ('kcal', '$kcal'),
      (isDe ? 'Eiweiß' : 'Protein', _g(proteinG)),
      (isDe ? 'KH' : 'C', _g(carbsG)),
      (isDe ? 'Fett' : 'Fat', _g(fatsG)),
    ];
    if (extra != null) {
      chips.addAll([
        (isDe ? 'Ballastst.' : 'Fiber', _g(extra!.fiberG)),
        (isDe ? 'Zucker' : 'Sugar', _g(extra!.sugarG)),
        (isDe ? 'Ges. Fett' : 'Sat. fat', _g(extra!.satFatG)),
        (isDe ? 'Cholesterin' : 'Chol.', _mg(extra!.cholesterolMg)),
        (isDe ? 'Natrium' : 'Sodium', _mg(extra!.sodiumMg)),
      ]);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 6.0;
        final chipWidth = extra == null ? null : 72.0;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final chip in chips)
              SizedBox(
                width: chipWidth,
                child: _MacroChip(label: chip.$1, value: chip.$2),
              ),
          ],
        );
      },
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              color: AppColors.textMuted,
              fontFamily: 'Roboto',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroInputField extends StatelessWidget {
  const _MacroInputField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: 'Roboto',
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.textMuted,
          fontFamily: 'Roboto',
          fontSize: 11,
        ),
        suffixText: 'g',
        suffixStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
        filled: true,
        fillColor: AppColors.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: GreenScreenStyle.accent),
        ),
      ),
    );
  }
}

// ─── Dish picker bottom sheet ─────────────────────────────────────────────
class _DishPickerSheet extends StatelessWidget {
  const _DishPickerSheet({required this.dishes});

  final List<Map<String, dynamic>> dishes;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.surfaceDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.stroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.food_whichDish,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                physics: const ClampingScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                itemCount: dishes.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return InkWell(
                      onTap: () => Navigator.of(context).pop('__new__'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: GreenScreenStyle.accent.withValues(
                            alpha: 0.18,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: GreenScreenStyle.accent.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add,
                              color: GreenScreenStyle.accent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.food_newDishEllipsis,
                              style: TextStyle(
                                color: GreenScreenStyle.accent,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final dish = dishes[i - 1];
                  final totals = _dishTotals(dish);
                  return InkWell(
                    onTap: () =>
                        Navigator.of(context).pop(dish['id']?.toString() ?? ''),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.stroke),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dish['name']?.toString() ??
                                      context.l10n.food_dishFallback,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${totals.kcal} kcal · '
                                  'E ${totals.p.toStringAsFixed(0)} g · '
                                  'KH ${totals.c.toStringAsFixed(0)} g · '
                                  'F ${totals.f.toStringAsFixed(0)} g',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontFamily: 'Roboto',
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dishes tab: empty state + card ───────────────────────────────────────
class _DishesEmptyState extends StatelessWidget {
  const _DishesEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              l10n.food_emptyDishesTitle,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.food_emptyDishesBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontFamily: 'Roboto',
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onCreate,
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(
                  GreenScreenStyle.accent,
                ),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.pressed)) {
                    return GreenScreenStyle.accent.withValues(alpha: 0.10);
                  }
                  return Colors.transparent;
                }),
                side: WidgetStateProperty.all(
                  BorderSide(color: GreenScreenStyle.accent, width: 1.4),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              child: Text(
                l10n.food_newDish,
                style: TextStyle(
                  color: GreenScreenStyle.accent,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  const _DishCard({
    required this.dish,
    required this.onTap,
    required this.onLongPress,
    required this.onAddToToday,
  });
  final Map<String, dynamic> dish;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onAddToToday;

  @override
  Widget build(BuildContext context) {
    final totals = _dishTotals(dish);
    final description = dish['description']?.toString().trim() ?? '';
    final narrow = MediaQuery.sizeOf(context).width < 360;
    return Container(
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(narrow ? 12 : 14),
            child: Row(
              children: [
                SizedBox(
                  width: narrow ? 44 : 58,
                  height: narrow ? 50 : 64,
                  child: _DishPhoto(dishId: dish['id'].toString()),
                ),
                SizedBox(width: narrow ? 10 : 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CatalogLocalizations.normalizeGermanSpelling(
                          dish['name']?.toString() ??
                              context.l10n.food_dishFallback,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'Roboto',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          _TagPill(label: '${totals.kcal} kcal'),
                          _TagPill(
                            label:
                                '${context.l10n.food_macroProtein} ${totals.p.round()} g',
                          ),
                          _TagPill(
                            label:
                                '${context.l10n.food_macroCarbs} ${totals.c.round()} g',
                          ),
                          _TagPill(
                            label:
                                '${context.l10n.food_macroFat} ${totals.f.round()} g',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      tooltip: context.l10n.food_eatToday,
                      style: IconButton.styleFrom(
                        backgroundColor: GreenScreenStyle.soft,
                        foregroundColor: GreenScreenStyle.foreground,
                        minimumSize: const Size.square(40),
                        padding: const EdgeInsets.all(8),
                      ),
                      iconSize: 22,
                      onPressed: onAddToToday,
                      icon: const Icon(Icons.add_rounded),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 21,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DishPhoto extends StatelessWidget {
  const _DishPhoto({required this.dishId});

  final String dishId;

  @override
  Widget build(BuildContext context) {
    final photo = ProgressStore.foodDishPhoto(dishId);
    final placeholder = ColoredBox(
      color: GreenScreenStyle.accent.withValues(alpha: 0.09),
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: GreenScreenStyle.accent,
          size: 32,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: photo == null
          ? placeholder
          : Image.memory(
              photo,
              width: double.infinity,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}

// ─── Dish detail screen (with tappable ingredients) ───────────────────────
class _DishDetailScreen extends StatefulWidget {
  const _DishDetailScreen({required this.dishId, required this.allFoods});

  final String dishId;
  final List<_FoodItem> allFoods;

  @override
  State<_DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<_DishDetailScreen> {
  late final TextEditingController _descriptionController;
  String _lastSyncedDescription = '';
  Timer? _descriptionSaveTimer;

  Map<String, dynamic>? get _dish => ProgressStore.foodDishById(widget.dishId);

  @override
  void initState() {
    super.initState();
    final desc =
        ProgressStore.foodDishById(widget.dishId)?['description']?.toString() ??
        '';
    _lastSyncedDescription = desc;
    _descriptionController = TextEditingController(text: desc);
  }

  @override
  void dispose() {
    _descriptionSaveTimer?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncDescriptionFromStore(Map<String, dynamic> dish) {
    final desc = dish['description']?.toString() ?? '';
    if (desc == _lastSyncedDescription) return;
    if (_descriptionController.text == _lastSyncedDescription) {
      _descriptionController.text = desc;
    }
    _lastSyncedDescription = desc;
  }

  void _scheduleDescriptionSave() {
    _descriptionSaveTimer?.cancel();
    _descriptionSaveTimer = Timer(const Duration(milliseconds: 400), () {
      _saveDescription();
    });
  }

  Future<void> _saveDescription() async {
    final text = _descriptionController.text;
    if (text == _lastSyncedDescription) return;
    await ProgressStore.updateFoodDishDescription(
      dishId: widget.dishId,
      description: text,
    );
    _lastSyncedDescription = text;
  }

  Future<void> _choosePhoto() async {
    final l10n = context.l10n;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.avatar_takePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.avatar_pickGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final dishId = widget.dishId;
    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        maxWidth: 960,
        maxHeight: 960,
        imageQuality: 82,
      );
      if (photo == null) return;
      await ProgressStore.saveFoodDishPhoto(dishId, await photo.readAsBytes());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.gallery_saveFailed)));
    }
  }

  Future<void> _rename() async {
    final dish = _dish;
    if (dish == null) return;
    final name = await _promptDishName(
      context,
      title: context.l10n.food_renameDishTitle,
      initial: dish['name']?.toString() ?? '',
    );
    if (name == null) return;
    await ProgressStore.renameFoodDish(dishId: widget.dishId, newName: name);
  }

  Future<void> _delete() async {
    final dish = _dish;
    if (dish == null) return;
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          l10n.food_deleteDishTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.food_deleteDishBody(dish['name'] ?? ''),
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.common_cancel,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.common_delete,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ProgressStore.deleteFoodDish(widget.dishId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _addIngredient() async {
    final picked = await Navigator.of(context).push<_FoodItem>(
      MaterialPageRoute<_FoodItem>(
        builder: (_) => _IngredientPickerScreen(foods: widget.allFoods),
      ),
    );
    if (picked == null) return;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddIngredientSheet(food: picked, dishId: widget.dishId),
    );
  }

  /// Adds a food that is not in the catalog at all: the user names it and
  /// types its macros. A name that does happen to match a catalog entry still
  /// gets its macros filled in automatically by [_AddIngredientSheet].
  Future<void> _addManualIngredient() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          '${l10n.food_ingredientFood} (${l10n.food_manualEntry})',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(labelText: l10n.common_name),
          onSubmitted: (value) => Navigator.of(dialogCtx).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx).pop(controller.text.trim()),
            child: Text(l10n.common_add),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddIngredientSheet(
        food: _FoodItem(
          name: name,
          subtitle: '',
          macro: '',
          focuses: const [],
          tags: const [],
        ),
        dishId: widget.dishId,
      ),
    );
  }

  Future<void> _showIngredient(int index) async {
    final dish = _dish;
    if (dish == null) return;
    final items = _dishItems(dish);
    if (index < 0 || index >= items.length) return;
    final item = items[index];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _IngredientDetailSheet(
        item: item,
        onRemove: () async {
          Navigator.of(sheetCtx).pop();
          await ProgressStore.removeItemFromFoodDish(
            dishId: widget.dishId,
            itemIndex: index,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ProgressStore.listenable(),
      builder: (context, _, _) {
        final dish = _dish;
        if (dish == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              leading: const AppBackButton(),
              leadingWidth: 44,
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
            ),
            body: Center(
              child: Text(
                context.l10n.food_dishNotFound,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          );
        }
        _syncDescriptionFromStore(dish);
        final items = _dishItems(dish);
        final totals = _dishTotals(dish);
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: const AppBackButton(),
            leadingWidth: 44,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            title: Text(
              dish['name']?.toString() ?? context.l10n.food_dishFallback,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            actions: [
              IconButton(
                tooltip: context.l10n.social_shareAction,
                onPressed: () {
                  showShareWithFriendsSheet(
                    context: context,
                    type: ShareContentType.foodDish,
                    payload: Map<String, dynamic>.from(dish),
                  );
                },
                icon: const Icon(Icons.share_outlined),
              ),
              IconButton(
                tooltip: context.l10n.common_rename,
                onPressed: _rename,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: context.l10n.common_delete,
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          // Two ways in: pick from the catalogue on the right, or type a food
          // the catalogue does not know (with its own macros) on the left.
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FloatingActionButton.extended(
                    heroTag: 'dishIngredientManual',
                    onPressed: _addManualIngredient,
                    backgroundColor: AppColors.card,
                    foregroundColor: AppColors.textPrimary,
                    tooltip:
                        '${context.l10n.food_ingredientFood} '
                        '(${context.l10n.food_manualEntry})',
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      context.l10n.food_manualEntry,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FloatingActionButton.extended(
                    heroTag: 'dishIngredientCatalogue',
                    onPressed: _addIngredient,
                    backgroundColor: GreenScreenStyle.soft,
                    foregroundColor: GreenScreenStyle.foreground,
                    icon: const Icon(Icons.add),
                    label: Text(
                      context.l10n.food_ingredientFood,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                if (ProgressStore.foodDishPhoto(widget.dishId) != null)
                  SizedBox(
                    height: 180,
                    child: _DishPhoto(dishId: widget.dishId),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _choosePhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(context.l10n.food_dishPhotoAction),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppColors.surfaceDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gesamt',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Just the four headline numbers here — fiber, sugar,
                      // sat. fat etc. would only repeat the breakdown below.
                      _MacroChipsRow(
                        kcal: totals.kcal,
                        proteinG: totals.p,
                        carbsG: totals.c,
                        fatsG: totals.f,
                      ),
                      const SizedBox(height: 12),
                      DailyNutrientsPanel(
                        totals: _dishNutrients(dish),
                        infoOnly: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppColors.surfaceDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beschreibung/Zubereitung',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 8,
                        onChanged: (_) => _scheduleDescriptionSave(),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          height: 1.45,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Zutaten, Zubereitung oder Notizen hinzufügen…',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.7),
                            fontFamily: 'Roboto',
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: AppColors.background.withValues(
                            alpha: 0.45,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.stroke),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: GreenScreenStyle.accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  items.isEmpty
                      ? 'Noch keine Zutaten'
                      : '${items.length} Zutat${items.length == 1 ? '' : 'en'}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Center(
                      child: Text(
                        'Tippe auf "Lebensmittel" unten rechts,\num Zutaten hinzuzufügen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                for (var i = 0; i < items.length; i++) ...[
                  _IngredientCard(
                    item: items[i],
                    onTap: () => _showIngredient(i),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IngredientCard extends StatelessWidget {
  const _IngredientCard({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = item['foodName']?.toString() ?? '';
    final grams = _readDouble(item['grams']);
    final p = _readDouble(item['proteinG']);
    final c = _readDouble(item['carbsG']);
    final f = _readDouble(item['fatsG']);
    final kcal = (p * 4 + c * 4 + f * 9).round();
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: AppColors.surfaceDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${grams.toStringAsFixed(0)} g · $kcal kcal',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontFamily: 'Roboto',
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _allMacrosLine(
                        FoodNutrientEstimator.forPortion(
                          name: name,
                          grams: grams > 0 ? grams : 100,
                          proteinG: p,
                          carbsG: c,
                          fatsG: f,
                        ),
                        isDe: context.l10n.localeName.startsWith('de'),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontFamily: 'Roboto',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientDetailSheet extends StatelessWidget {
  const _IngredientDetailSheet({required this.item, required this.onRemove});

  final Map<String, dynamic> item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final name = item['foodName']?.toString() ?? '';
    final grams = _readDouble(item['grams']);
    final p = _readDouble(item['proteinG']);
    final c = _readDouble(item['carbsG']);
    final f = _readDouble(item['fatsG']);
    final kcal = (p * 4 + c * 4 + f * 9).round();
    return Container(
      decoration: AppColors.surfaceDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.stroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${grams.toStringAsFixed(0)} g',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: 'Roboto',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              _MacroChipsRow(
                kcal: kcal,
                proteinG: p,
                carbsG: c,
                fatsG: f,
                extra: FoodNutrientEstimator.forPortion(
                  name: name,
                  grams: grams > 0 ? grams : 100,
                  proteinG: p,
                  carbsG: c,
                  fatsG: f,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRemove,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(
                    context.l10n.food_removeFromDish,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ingredient picker (full food list, searchable) ───────────────────────
class _IngredientPickerScreen extends StatefulWidget {
  const _IngredientPickerScreen({required this.foods});

  final List<_FoodItem> foods;

  @override
  State<_IngredientPickerScreen> createState() =>
      _IngredientPickerScreenState();
}

class _IngredientPickerScreenState extends State<_IngredientPickerScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.foods
        : widget.foods.where((food) => food.matchesQuery(q)).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        leadingWidth: 44,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          context.l10n.food_pickIngredientTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Roboto',
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: context.l10n.common_search,
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.stroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: GreenScreenStyle.accent),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final food = filtered[i];
                  final m = food.macros;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(food),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: AppColors.surfaceDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              food.displayName,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontFamily: 'Roboto',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (m != null)
                            Text(
                              context.l10n.food_kcalPer100g('${m.kcal}'),
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontFamily: 'Roboto',
                                fontSize: 11,
                              ),
                            )
                          else
                            Text(
                              context.l10n.food_manualEntry,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add-ingredient sheet (re-uses food detail sheet for a chosen dish) ───
class _AddIngredientSheet extends StatefulWidget {
  const _AddIngredientSheet({required this.food, required this.dishId});

  final _FoodItem food;
  final String dishId;

  @override
  State<_AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends State<_AddIngredientSheet> {
  final TextEditingController _gramsCtrl = TextEditingController(text: '100');
  final TextEditingController _manualPCtrl = TextEditingController();
  final TextEditingController _manualCCtrl = TextEditingController();
  final TextEditingController _manualFCtrl = TextEditingController();

  @override
  void dispose() {
    _gramsCtrl.dispose();
    _manualPCtrl.dispose();
    _manualCCtrl.dispose();
    _manualFCtrl.dispose();
    super.dispose();
  }

  double get _grams =>
      double.tryParse(_gramsCtrl.text.replaceAll(',', '.')) ?? 0;

  _Macros? get _effectivePer100g {
    final lookup = widget.food.macros;
    if (lookup != null) return lookup;
    final p = double.tryParse(_manualPCtrl.text.replaceAll(',', '.'));
    final c = double.tryParse(_manualCCtrl.text.replaceAll(',', '.'));
    final f = double.tryParse(_manualFCtrl.text.replaceAll(',', '.'));
    if (p == null && c == null && f == null) return null;
    return _Macros(p ?? 0, c ?? 0, f ?? 0);
  }

  ({double p, double c, double f, int kcal})? get _scaled {
    final per100 = _effectivePer100g;
    if (per100 == null) return null;
    final factor = _grams / 100.0;
    final p = per100.proteinG * factor;
    final c = per100.carbsG * factor;
    final f = per100.fatsG * factor;
    return (p: p, c: c, f: f, kcal: (p * 4 + c * 4 + f * 9).round());
  }

  Future<void> _add() async {
    final scaled = _scaled;
    if (scaled == null || _grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.food_enterGramsMacros)),
      );
      return;
    }
    await ProgressStore.addItemToFoodDish(
      dishId: widget.dishId,
      foodName: widget.food.name,
      grams: _grams,
      proteinG: scaled.p,
      carbsG: scaled.c,
      fatsG: scaled.f,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final food = widget.food;
    final lookup = food.macros;
    final scaled = _scaled;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: AppColors.surfaceDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.stroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  food.displayName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 12),
                if (lookup != null) ...[
                  Text(
                    l10n.food_per100g,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MacroChipsRow(
                    kcal: lookup.kcal,
                    proteinG: lookup.proteinG,
                    carbsG: lookup.carbsG,
                    fatsG: lookup.fatsG,
                    extra: FoodNutrientEstimator.forPer100g(
                      name: food.name,
                      proteinG: lookup.proteinG,
                      carbsG: lookup.carbsG,
                      fatsG: lookup.fatsG,
                      tags: food.tags,
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.food_macrosManualHint,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _MacroInputField(
                                controller: _manualPCtrl,
                                label: l10n.food_macroProtein,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MacroInputField(
                                controller: _manualCCtrl,
                                label: l10n.food_macroCarbs,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MacroInputField(
                                controller: _manualFCtrl,
                                label: l10n.food_macroFat,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  l10n.food_amount,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _gramsCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Roboto',
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    suffixText: 'g',
                    suffixStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.stroke),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: GreenScreenStyle.accent),
                    ),
                  ),
                ),
                if (scaled != null) ...[
                  const SizedBox(height: 14),
                  _MacroChipsRow(
                    kcal: scaled.kcal,
                    proteinG: scaled.p,
                    carbsG: scaled.c,
                    fatsG: scaled.f,
                    extra: FoodNutrientEstimator.forPortion(
                      name: food.name,
                      grams: _grams,
                      proteinG: scaled.p,
                      carbsG: scaled.c,
                      fatsG: scaled.f,
                      tags: food.tags,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _add,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GreenScreenStyle.soft,
                      foregroundColor: GreenScreenStyle.foreground,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      l10n.common_add,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers (totals, parsing, dish name prompt) ──────────────────────────

List<Map<String, dynamic>> _dishItems(Map<String, dynamic> dish) {
  final raw = dish['items'];
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

({double p, double c, double f, int kcal}) _dishTotals(
  Map<String, dynamic> dish,
) {
  double p = 0, c = 0, f = 0;
  for (final item in _dishItems(dish)) {
    p += _readDouble(item['proteinG']);
    c += _readDouble(item['carbsG']);
    f += _readDouble(item['fatsG']);
  }
  return (p: p, c: c, f: f, kcal: (p * 4 + c * 4 + f * 9).round());
}

FoodNutrients _dishNutrients(Map<String, dynamic> dish) {
  var sum = const FoodNutrients();
  for (final item in _dishItems(dish)) {
    final grams = _readDouble(item['grams']);
    final estimated = FoodNutrientEstimator.forPortion(
      name: item['foodName']?.toString() ?? '',
      grams: grams > 0 ? grams : 100,
      proteinG: _readDouble(item['proteinG']),
      carbsG: _readDouble(item['carbsG']),
      fatsG: _readDouble(item['fatsG']),
    );
    Map<String, double> storedMap(String key) {
      final raw = item[key];
      if (raw is! Map) return const {};
      return {
        for (final entry in raw.entries)
          if (entry.value is num && (entry.value as num).isFinite)
            entry.key.toString(): (entry.value as num).toDouble(),
      };
    }

    final storedMicros = storedMap('micros');
    final storedAminos = storedMap('aminos');
    sum += FoodNutrients(
      proteinG: _readDouble(item['proteinG']),
      carbsG: _readDouble(item['carbsG']),
      fatsG: _readDouble(item['fatsG']),
      fiberG: _readDouble(item['fiberG']) > 0
          ? _readDouble(item['fiberG'])
          : estimated.fiberG,
      sugarG: _readDouble(item['sugarG']) > 0
          ? _readDouble(item['sugarG'])
          : estimated.sugarG,
      satFatG: _readDouble(item['satFatG']) > 0
          ? _readDouble(item['satFatG'])
          : estimated.satFatG,
      cholesterolMg: _readDouble(item['cholesterolMg']) > 0
          ? _readDouble(item['cholesterolMg'])
          : estimated.cholesterolMg,
      sodiumMg: _readDouble(item['sodiumMg']) > 0
          ? _readDouble(item['sodiumMg'])
          : estimated.sodiumMg,
      micros: {...estimated.micros, ...storedMicros},
      aminos: {...estimated.aminos, ...storedAminos},
    );
  }
  return sum;
}

String _allMacrosLine(FoodNutrients n, {required bool isDe}) {
  String g(double v) => v.toStringAsFixed(v >= 10 ? 0 : 1);
  String mg(double v) => v.toStringAsFixed(0);
  if (isDe) {
    return 'E ${g(n.proteinG)}  KH ${g(n.carbsG)}  F ${g(n.fatsG)}  '
        'Bal ${g(n.fiberG)}  Zu ${g(n.sugarG)}  GF ${g(n.satFatG)}  '
        'Chol ${mg(n.cholesterolMg)} mg  Na ${mg(n.sodiumMg)} mg';
  }
  return 'P ${g(n.proteinG)}  C ${g(n.carbsG)}  F ${g(n.fatsG)}  '
      'Fib ${g(n.fiberG)}  Sug ${g(n.sugarG)}  Sat ${g(n.satFatG)}  '
      'Chol ${mg(n.cholesterolMg)} mg  Na ${mg(n.sodiumMg)} mg';
}

double _readDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
  return 0;
}

class _ScannedProductDetailSheet extends StatefulWidget {
  const _ScannedProductDetailSheet({required this.product});

  final ScannedFoodProduct product;

  @override
  State<_ScannedProductDetailSheet> createState() =>
      _ScannedProductDetailSheetState();
}

class _ScannedProductDetailSheetState
    extends State<_ScannedProductDetailSheet> {
  final TextEditingController _gramsCtrl = TextEditingController(text: '100');

  @override
  void dispose() {
    _gramsCtrl.dispose();
    super.dispose();
  }

  double get _grams {
    final value = double.tryParse(_gramsCtrl.text.replaceAll(',', '.'));
    return value != null && value.isFinite && value > 0 ? value : 0;
  }

  ({double p, double c, double f, int kcal})? get _scaled {
    if (_grams <= 0) return null;
    final factor = _grams / 100.0;
    final p = widget.product.proteinPer100g * factor;
    final c = widget.product.carbsPer100g * factor;
    final f = widget.product.fatsPer100g * factor;
    return (p: p, c: c, f: f, kcal: (p * 4 + c * 4 + f * 9).round());
  }

  bool _saving = false;

  Future<void> _runFoodAction(Future<void> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.localeName.startsWith('de')
                  ? 'Speichern fehlgeschlagen. Bitte erneut versuchen.'
                  : 'Could not save. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addToDishFlow() => _runFoodAction(_addToDish);
  Future<void> _addToTodayFlow() => _runFoodAction(_addToToday);

  Future<void> _addToDish() async {
    final l10n = context.l10n;
    final scaled = _scaled;
    if (scaled == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.food_enterGramsMacros)));
      return;
    }
    final dishes = ProgressStore.foodDishes;
    String? targetDishId;
    if (dishes.isEmpty) {
      final name = await _promptDishName(
        context,
        title: l10n.food_newDishTitle,
        initial: '',
      );
      if (name == null) return;
      targetDishId = await ProgressStore.createFoodDish(name);
    } else {
      targetDishId = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _DishPickerSheet(dishes: dishes),
      );
      if (targetDishId == null) return;
      if (targetDishId == '__new__') {
        if (!mounted) return;
        final name = await _promptDishName(
          context,
          title: l10n.food_newDishTitle,
          initial: '',
        );
        if (name == null) return;
        targetDishId = await ProgressStore.createFoodDish(name);
      }
    }
    await ProgressStore.addItemToFoodDish(
      dishId: targetDishId,
      foodName: widget.product.name,
      grams: _grams,
      proteinG: scaled.p,
      carbsG: scaled.c,
      fatsG: scaled.f,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.food_addedToDish(widget.product.name, _grams.toStringAsFixed(0)),
        ),
      ),
    );
  }

  Future<void> _addToToday() async {
    final l10n = context.l10n;
    final scaled = _scaled;
    if (scaled == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.food_enterGramsMacros)));
      return;
    }
    await ProgressStore.addFoodIntakeFood(
      name: widget.product.name,
      grams: _grams,
      proteinG: scaled.p,
      carbsG: scaled.c,
      fatsG: scaled.f,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.food_addedToTodayFull(
            widget.product.name,
            _grams.toStringAsFixed(0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final product = widget.product;
    final scaled = _scaled;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: AppColors.surfaceDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.stroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      color: GreenScreenStyle.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.food_scannedProduct,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
                if (product.brand != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.brand!,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'Roboto',
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  l10n.food_barcodeValue(product.barcode),
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Roboto',
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.food_per100g,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                // Just the four headline numbers here — fiber, sugar, sat.
                // fat etc. would only repeat the full breakdown shown below.
                _MacroChipsRow(
                  kcal: product.kcalPer100g,
                  proteinG: product.proteinPer100g,
                  carbsG: product.carbsPer100g,
                  fatsG: product.fatsPer100g,
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.food_amount,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _gramsCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Roboto',
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    suffixText: 'g',
                    suffixStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.stroke),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: GreenScreenStyle.accent),
                    ),
                  ),
                ),
                if (scaled != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.food_forGrams(_grams.toStringAsFixed(0)),
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MacroChipsRow(
                    kcal: scaled.kcal,
                    proteinG: scaled.p,
                    carbsG: scaled.c,
                    fatsG: scaled.f,
                  ),
                  const SizedBox(height: 18),
                ],
                // Actions sit right after the amount/macros you just set, not
                // below the full nutrient breakdown — no need to scroll past
                // micronutrients and amino acids just to log the food.
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _addToTodayFlow,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GreenScreenStyle.accent,
                          side: BorderSide(color: GreenScreenStyle.accent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.today_outlined, size: 18),
                        label: Text(
                          l10n.food_eatToday,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _addToDishFlow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GreenScreenStyle.soft,
                          foregroundColor: GreenScreenStyle.foreground,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.restaurant_menu, size: 18),
                        label: Text(
                          l10n.food_addToDishBtn,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ShoppingFoodButton(
                  name: product.name,
                  grams: _grams,
                  onAdded: () => Navigator.of(context).pop(),
                ),
                if (scaled != null) ...[
                  const SizedBox(height: 20),
                  DailyNutrientsPanel(
                    totals: FoodNutrientEstimator.forPortion(
                      name: product.name,
                      grams: _grams,
                      proteinG: scaled.p,
                      carbsG: scaled.c,
                      fatsG: scaled.f,
                    ),
                    infoOnly: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<String?> _promptDishName(
  BuildContext context, {
  required String title,
  required String initial,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: context.l10n.food_dishNameHint,
          hintStyle: TextStyle(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.stroke),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: GreenScreenStyle.accent),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            context.l10n.common_cancel,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        TextButton(
          onPressed: () {
            final v = controller.text.trim();
            if (v.isEmpty) return;
            Navigator.of(ctx).pop(v);
          },
          child: Text(
            context.l10n.common_save,
            style: TextStyle(color: GreenScreenStyle.accent),
          ),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
