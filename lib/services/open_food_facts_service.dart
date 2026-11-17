import 'dart:convert';

import 'package:http/http.dart' as http;

/// Product data resolved from the Open Food Facts database.
class ScannedFoodProduct {
  const ScannedFoodProduct({
    required this.barcode,
    required this.name,
    this.brand,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
  });

  final String barcode;
  final String name;
  final String? brand;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatsPer100g;

  int get kcalPer100g =>
      (proteinPer100g * 4 + carbsPer100g * 4 + fatsPer100g * 9).round();
}

class OpenFoodFactsService {
  OpenFoodFactsService._();

  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  static Future<ScannedFoodProduct?> lookupBarcode(String rawBarcode) async {
    final barcode = rawBarcode.replaceAll(RegExp(r'\D'), '');
    if (barcode.length < 8) return null;

    final uri = Uri.parse('$_baseUrl/$barcode.json');
    final response = await http
        .get(
          uri,
          headers: const {
            'User-Agent': 'KaizenFitFlow/1.0 (nutrition tracking app)',
          },
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    if (decoded['status'] != 1) return null;

    final product = decoded['product'];
    if (product is! Map<String, dynamic>) return null;

    final name = _resolveName(product);
    if (name.isEmpty) return null;

    final nutriments = product['nutriments'];
    if (nutriments is! Map<String, dynamic>) return null;

    final protein = _readNutrient(nutriments, 'proteins_100g');
    final carbs = _readNutrient(nutriments, 'carbohydrates_100g');
    final fats = _readNutrient(nutriments, 'fat_100g');

    if (protein == null && carbs == null && fats == null) return null;

    return ScannedFoodProduct(
      barcode: barcode,
      name: name,
      brand: _resolveBrand(product),
      proteinPer100g: protein ?? 0,
      carbsPer100g: carbs ?? 0,
      fatsPer100g: fats ?? 0,
    );
  }

  static String _resolveName(Map<String, dynamic> product) {
    for (final key in [
      'product_name_de',
      'product_name',
      'generic_name_de',
      'generic_name',
    ]) {
      final value = product[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  static String? _resolveBrand(Map<String, dynamic> product) {
    final brands = product['brands']?.toString().trim();
    if (brands == null || brands.isEmpty) return null;
    return brands.split(',').first.trim();
  }

  static double? _readNutrient(
    Map<String, dynamic> nutriments,
    String key,
  ) {
    final value = nutriments[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }
}
