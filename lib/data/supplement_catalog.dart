/// Popular dietary supplements with a typical single-serving amount in mg.
class SupplementCatalogEntry {
  const SupplementCatalogEntry({
    required this.nameEn,
    required this.nameDe,
    required this.typicalMg,
    this.category = 'general',
  });

  final String nameEn;
  final String nameDe;
  final double typicalMg;
  final String category;

  String localizedName(bool german) => german ? nameDe : nameEn;
}

/// ~100 common vitamins, minerals, and other supplements.
const List<SupplementCatalogEntry> supplementCatalog = [
  // Vitamins
  SupplementCatalogEntry(nameEn: 'Vitamin A', nameDe: 'Vitamin A', typicalMg: 0.8, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin B1 (Thiamine)', nameDe: 'Vitamin B1 (Thiamin)', typicalMg: 1, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin B2 (Riboflavin)', nameDe: 'Vitamin B2 (Riboflavin)', typicalMg: 1, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin B3 (Niacin)', nameDe: 'Vitamin B3 (Niacin)', typicalMg: 16, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin B5 (Pantothenic acid)', nameDe: 'Vitamin B5 (Pantothensäure)', typicalMg: 5, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin B6', nameDe: 'Vitamin B6', typicalMg: 1, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin B7 (Biotin)', nameDe: 'Vitamin B7 (Biotin)', typicalMg: 0, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Biotin', nameDe: 'Biotin', typicalMg: 5, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin B9 (Folic acid)', nameDe: 'Vitamin B9 (Folsäure)', typicalMg: 0, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Folic acid', nameDe: 'Folsäure', typicalMg: 0, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin B12', nameDe: 'Vitamin B12', typicalMg: 0, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin C', nameDe: 'Vitamin C', typicalMg: 1000, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin D', nameDe: 'Vitamin D', typicalMg: 0, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin D3', nameDe: 'Vitamin D3', typicalMg: 0, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin E', nameDe: 'Vitamin E', typicalMg: 15, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin K', nameDe: 'Vitamin K', typicalMg: 0, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin K2', nameDe: 'Vitamin K2', typicalMg: 0, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Vitamin K2 (MK-7)', nameDe: 'Vitamin K2 (MK-7)', typicalMg: 0, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'Multivitamin', nameDe: 'Multivitamin', typicalMg: 1, category: 'vitamin'),
  SupplementCatalogEntry(nameEn: 'B-Complex', nameDe: 'B-Komplex', typicalMg: 1, category: 'vitamin'),

  // Minerals
  SupplementCatalogEntry(nameEn: 'Magnesium', nameDe: 'Magnesium', typicalMg: 300, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Magnesium citrate', nameDe: 'Magnesiumcitrat', typicalMg: 300, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Magnesium glycinate', nameDe: 'Magnesiumglycinat', typicalMg: 200, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Zinc', nameDe: 'Zink', typicalMg: 15, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Zinc bisglycinate', nameDe: 'Zinkbisglycinat', typicalMg: 15, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Iron', nameDe: 'Eisen', typicalMg: 14, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Calcium', nameDe: 'Calcium', typicalMg: 500, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Potassium', nameDe: 'Kalium', typicalMg: 300, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Selenium', nameDe: 'Selen', typicalMg: 0, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Iodine', nameDe: 'Jod', typicalMg: 0, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Chromium', nameDe: 'Chrom', typicalMg: 0, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Copper', nameDe: 'Kupfer', typicalMg: 1, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Manganese', nameDe: 'Mangan', typicalMg: 2, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Molybdenum', nameDe: 'Molybdän', typicalMg: 0, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Boron', nameDe: 'Bor', typicalMg: 3, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Silicon', nameDe: 'Silicium', typicalMg: 10, category: 'mineral'),
  SupplementCatalogEntry(nameEn: 'Chromium picolinate', nameDe: 'Chrompicolinat', typicalMg: 0, category: 'mineral'),

  // Omega / fats
  SupplementCatalogEntry(nameEn: 'Omega-3', nameDe: 'Omega-3', typicalMg: 1000, category: 'fatty_acid'),
  SupplementCatalogEntry(nameEn: 'Fish oil', nameDe: 'Fischöl', typicalMg: 1000, category: 'fatty_acid'),
  SupplementCatalogEntry(nameEn: 'EPA', nameDe: 'EPA', typicalMg: 500, category: 'fatty_acid'),
  SupplementCatalogEntry(nameEn: 'DHA', nameDe: 'DHA', typicalMg: 250, category: 'fatty_acid'),
  SupplementCatalogEntry(nameEn: 'Cod liver oil', nameDe: 'Lebertran', typicalMg: 1000, category: 'fatty_acid'),
  SupplementCatalogEntry(nameEn: 'Krill oil', nameDe: 'Krillöl', typicalMg: 500, category: 'fatty_acid'),
  SupplementCatalogEntry(nameEn: 'Algae oil', nameDe: 'Algenöl', typicalMg: 500, category: 'fatty_acid'),
  SupplementCatalogEntry(nameEn: 'Flaxseed oil', nameDe: 'Leinöl', typicalMg: 1000, category: 'fatty_acid'),
  SupplementCatalogEntry(nameEn: 'CLA', nameDe: 'CLA', typicalMg: 1000, category: 'fatty_acid'),
  SupplementCatalogEntry(nameEn: 'MCT oil', nameDe: 'MCT-Öl', typicalMg: 5000, category: 'fatty_acid'),

  // Amino acids / sports
  SupplementCatalogEntry(nameEn: 'Creatine monohydrate', nameDe: 'Creatin-Monohydrat', typicalMg: 3000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'Creatine', nameDe: 'Creatin', typicalMg: 3000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'Whey protein', nameDe: 'Whey-Protein', typicalMg: 25000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'Casein protein', nameDe: 'Casein-Protein', typicalMg: 25000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'Plant protein', nameDe: 'Pflanzenprotein', typicalMg: 25000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'BCAA', nameDe: 'BCAA', typicalMg: 5000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'L-Glutamine', nameDe: 'L-Glutamin', typicalMg: 5000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'L-Carnitine', nameDe: 'L-Carnitin', typicalMg: 1000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'L-Arginine', nameDe: 'L-Arginin', typicalMg: 3000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'L-Citrulline', nameDe: 'L-Citrullin', typicalMg: 3000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'Beta-alanine', nameDe: 'Beta-Alanin', typicalMg: 3000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'HMB', nameDe: 'HMB', typicalMg: 3000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'EAAs', nameDe: 'EAAs', typicalMg: 10000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'Collagen peptides', nameDe: 'Kollagenpeptide', typicalMg: 10000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'Collagen', nameDe: 'Kollagen', typicalMg: 10000, category: 'sports'),
  SupplementCatalogEntry(nameEn: 'Electrolyte mix', nameDe: 'Elektrolyt-Mix', typicalMg: 1000, category: 'sports'),

  // Herbs / adaptogens / other
  SupplementCatalogEntry(nameEn: 'Ashwagandha', nameDe: 'Ashwagandha', typicalMg: 300, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Rhodiola rosea', nameDe: 'Rhodiola Rosea', typicalMg: 200, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Ginseng', nameDe: 'Ginseng', typicalMg: 200, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Maca', nameDe: 'Maca', typicalMg: 1500, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Turmeric / Curcumin', nameDe: 'Kurkuma / Curcumin', typicalMg: 500, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Ginger extract', nameDe: 'Ingwerextrakt', typicalMg: 250, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Garlic extract', nameDe: 'Knoblauchextrakt', typicalMg: 600, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Green tea extract', nameDe: 'Grüntee-Extrakt', typicalMg: 500, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Ginkgo biloba', nameDe: 'Ginkgo Biloba', typicalMg: 120, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Milk thistle', nameDe: 'Mariendistel', typicalMg: 150, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Elderberry', nameDe: 'Holunder', typicalMg: 500, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Echinacea', nameDe: 'Echinacea', typicalMg: 400, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Valerian', nameDe: 'Baldrian', typicalMg: 300, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Chamomile extract', nameDe: 'Kamillenextrakt', typicalMg: 300, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Spirulina', nameDe: 'Spirulina', typicalMg: 2000, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Chlorella', nameDe: 'Chlorella', typicalMg: 2000, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Moringa', nameDe: 'Moringa', typicalMg: 500, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Lion\'s mane', nameDe: 'Lion\'s Mane', typicalMg: 500, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Reishi', nameDe: 'Reishi', typicalMg: 500, category: 'herb'),
  SupplementCatalogEntry(nameEn: 'Cordyceps', nameDe: 'Cordyceps', typicalMg: 500, category: 'herb'),

  // Specialty / popular
  SupplementCatalogEntry(nameEn: 'CoQ10', nameDe: 'CoQ10', typicalMg: 100, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Ubiquinol', nameDe: 'Ubiquinol', typicalMg: 100, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Alpha-lipoic acid', nameDe: 'Alpha-Liponsäure', typicalMg: 300, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'NAC', nameDe: 'NAC', typicalMg: 600, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Glutathione', nameDe: 'Glutathion', typicalMg: 250, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Astaxanthin', nameDe: 'Astaxanthin', typicalMg: 4, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Lutein', nameDe: 'Lutein', typicalMg: 10, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Zeaxanthin', nameDe: 'Zeaxanthin', typicalMg: 2, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Resveratrol', nameDe: 'Resveratrol', typicalMg: 150, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Quercetin', nameDe: 'Quercetin', typicalMg: 500, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Melatonin', nameDe: 'Melatonin', typicalMg: 1, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Probiotics', nameDe: 'Probiotika', typicalMg: 1, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Prebiotics', nameDe: 'Präbiotika', typicalMg: 5000, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Psyllium husk', nameDe: 'Flohsamenschalen', typicalMg: 5000, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Fiber supplement', nameDe: 'Ballaststoff-Supplement', typicalMg: 5000, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Glucosamine', nameDe: 'Glucosamin', typicalMg: 1500, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Chondroitin', nameDe: 'Chondroitin', typicalMg: 800, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'MSM', nameDe: 'MSM', typicalMg: 1000, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Hyaluronic acid', nameDe: 'Hyaluronsäure', typicalMg: 100, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Beta-glucan', nameDe: 'Beta-Glucan', typicalMg: 250, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Inositol', nameDe: 'Inositol', typicalMg: 2000, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Choline', nameDe: 'Cholin', typicalMg: 250, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'TMG (Betaine)', nameDe: 'TMG (Betain)', typicalMg: 500, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'PQQ', nameDe: 'PQQ', typicalMg: 10, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'NMN', nameDe: 'NMN', typicalMg: 250, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'NAD+', nameDe: 'NAD+', typicalMg: 100, category: 'specialty'),
  SupplementCatalogEntry(nameEn: '5-HTP', nameDe: '5-HTP', typicalMg: 100, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'L-Theanine', nameDe: 'L-Theanin', typicalMg: 200, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Caffeine', nameDe: 'Koffein', typicalMg: 100, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Taurine', nameDe: 'Taurin', typicalMg: 1000, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Apple cider vinegar capsules', nameDe: 'Apfelessig-Kapseln', typicalMg: 500, category: 'specialty'),
  SupplementCatalogEntry(nameEn: 'Berberine', nameDe: 'Berberin', typicalMg: 500, category: 'specialty'),
];

List<SupplementCatalogEntry> searchSupplementCatalog(
  String query, {
  required bool german,
  int limit = 20,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final starts = <SupplementCatalogEntry>[];
  final contains = <SupplementCatalogEntry>[];
  for (final e in supplementCatalog) {
    final en = e.nameEn.toLowerCase();
    final de = e.nameDe.toLowerCase();
    if (en.startsWith(q) || de.startsWith(q)) {
      starts.add(e);
    } else if (en.contains(q) || de.contains(q)) {
      contains.add(e);
    }
  }
  return [...starts, ...contains].take(limit).toList(growable: false);
}
