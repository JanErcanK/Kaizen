/// Preset meal templates seeded into the user's dish library on first launch.
class StandardFoodDish {
  const StandardFoodDish({
    required this.id,
    required this.nameDe,
    required this.descriptionDe,
    required this.items,
  });

  final String id;
  final String nameDe;
  final String descriptionDe;
  final List<StandardFoodDishItem> items;
}

class StandardFoodDishItem {
  const StandardFoodDishItem({
    required this.foodName,
    required this.grams,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });

  final String foodName;
  final double grams;
  final double proteinG;
  final double carbsG;
  final double fatsG;

  Map<String, dynamic> toJson() => {
        'foodName': foodName,
        'grams': grams,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatsG': fatsG,
      };
}

const List<StandardFoodDish> standardFoodDishes = [
  StandardFoodDish(
    id: 'preset_haehnchen_reis_brokkoli',
    nameDe: 'Hähnchen mit Reis & Brokkoli',
    descriptionDe:
        'Klassisches Fitness-Gericht: Hähnchenbrust, gekochter Reis und Brokkoli.',
    items: [
      StandardFoodDishItem(
        foodName: 'Hähnchenbrust',
        grams: 150,
        proteinG: 34.5,
        carbsG: 0,
        fatsG: 2.25,
      ),
      StandardFoodDishItem(
        foodName: 'Reis (gekocht)',
        grams: 200,
        proteinG: 5.6,
        carbsG: 56,
        fatsG: 0.6,
      ),
      StandardFoodDishItem(
        foodName: 'Brokkoli',
        grams: 150,
        proteinG: 4.2,
        carbsG: 10.5,
        fatsG: 0.6,
      ),
    ],
  ),
  StandardFoodDish(
    id: 'preset_lachs_süßkartoffel_spinat',
    nameDe: 'Lachs mit Süßkartoffel & Spinat',
    descriptionDe:
        'Omega-3, komplexe Carbs und Eisen: Lachs, Süßkartoffel und Spinat.',
    items: [
      StandardFoodDishItem(
        foodName: 'Lachs',
        grams: 150,
        proteinG: 30.6,
        carbsG: 0,
        fatsG: 19.5,
      ),
      StandardFoodDishItem(
        foodName: 'Süßkartoffeln (orange)',
        grams: 200,
        proteinG: 3.2,
        carbsG: 40,
        fatsG: 0.2,
      ),
      StandardFoodDishItem(
        foodName: 'Spinat',
        grams: 100,
        proteinG: 2.9,
        carbsG: 3.6,
        fatsG: 0.4,
      ),
    ],
  ),
  StandardFoodDish(
    id: 'preset_spaghetti_bolognese',
    nameDe: 'Spaghetti Bolognese',
    descriptionDe:
        'Spaghetti mit magerem Rinderhack, Tomatenpassata und Zwiebeln.',
    items: [
      StandardFoodDishItem(
        foodName: 'Spaghetti',
        grams: 80,
        proteinG: 10.4,
        carbsG: 56.8,
        fatsG: 1.2,
      ),
      StandardFoodDishItem(
        foodName: 'Rinderhack (mager)',
        grams: 150,
        proteinG: 30,
        carbsG: 0,
        fatsG: 15,
      ),
      StandardFoodDishItem(
        foodName: 'Tomatenpassata',
        grams: 120,
        proteinG: 1.44,
        carbsG: 7.2,
        fatsG: 0.12,
      ),
      StandardFoodDishItem(
        foodName: 'Zwiebeln (gelb)',
        grams: 50,
        proteinG: 0.55,
        carbsG: 4.5,
        fatsG: 0.05,
      ),
      StandardFoodDishItem(
        foodName: 'Olivenöl',
        grams: 10,
        proteinG: 0,
        carbsG: 0,
        fatsG: 10,
      ),
    ],
  ),
  StandardFoodDish(
    id: 'preset_protein_pizza_skyr',
    nameDe: 'Protein-Pizza (Skyr-Teig)',
    descriptionDe:
        'Selbstgemachte Pizza mit Skyr-, Hafer- und Eier-Teig, Mozzarella und Passata.',
    items: [
      StandardFoodDishItem(
        foodName: 'Skyr',
        grams: 100,
        proteinG: 11,
        carbsG: 4,
        fatsG: 0.2,
      ),
      StandardFoodDishItem(
        foodName: 'Eier',
        grams: 60,
        proteinG: 7.5,
        carbsG: 0.66,
        fatsG: 6.6,
      ),
      StandardFoodDishItem(
        foodName: 'Haferflocken',
        grams: 40,
        proteinG: 5.2,
        carbsG: 24,
        fatsG: 2.8,
      ),
      StandardFoodDishItem(
        foodName: 'Mozzarella',
        grams: 70,
        proteinG: 12.6,
        carbsG: 1.4,
        fatsG: 14,
      ),
      StandardFoodDishItem(
        foodName: 'Tomatenpassata',
        grams: 80,
        proteinG: 0.96,
        carbsG: 4.8,
        fatsG: 0.08,
      ),
      StandardFoodDishItem(
        foodName: 'Olivenöl',
        grams: 5,
        proteinG: 0,
        carbsG: 0,
        fatsG: 5,
      ),
    ],
  ),
  StandardFoodDish(
    id: 'preset_linsensuppe',
    nameDe: 'Linsensuppe',
    descriptionDe:
        'Herzhafte Suppe mit roten Linsen, Karotten, Sellerie und Zwiebeln.',
    items: [
      StandardFoodDishItem(
        foodName: 'Rote Linsen',
        grams: 250,
        proteinG: 22.5,
        carbsG: 50,
        fatsG: 1,
      ),
      StandardFoodDishItem(
        foodName: 'Karotten',
        grams: 80,
        proteinG: 0.72,
        carbsG: 8,
        fatsG: 0.16,
      ),
      StandardFoodDishItem(
        foodName: 'Sellerie (Staude)',
        grams: 60,
        proteinG: 0.42,
        carbsG: 1.8,
        fatsG: 0.12,
      ),
      StandardFoodDishItem(
        foodName: 'Zwiebeln (gelb)',
        grams: 60,
        proteinG: 0.66,
        carbsG: 5.4,
        fatsG: 0.06,
      ),
      StandardFoodDishItem(
        foodName: 'Olivenöl',
        grams: 8,
        proteinG: 0,
        carbsG: 0,
        fatsG: 8,
      ),
    ],
  ),
  StandardFoodDish(
    id: 'preset_menemen',
    nameDe: 'Menemen',
    descriptionDe:
        'Türkisches Frühstück: Eier mit Paprika, Tomaten, Zwiebeln, Knoblauch, Butter und Sucuk.',
    items: [
      StandardFoodDishItem(
        foodName: 'Eier',
        grams: 180,
        proteinG: 22.5,
        carbsG: 1.98,
        fatsG: 19.8,
      ),
      StandardFoodDishItem(
        foodName: 'Paprika',
        grams: 120,
        proteinG: 1.2,
        carbsG: 7.2,
        fatsG: 0.36,
      ),
      StandardFoodDishItem(
        foodName: 'Tomaten',
        grams: 150,
        proteinG: 1.35,
        carbsG: 5.85,
        fatsG: 0.3,
      ),
      StandardFoodDishItem(
        foodName: 'Zwiebeln (gelb)',
        grams: 70,
        proteinG: 0.77,
        carbsG: 6.3,
        fatsG: 0.07,
      ),
      StandardFoodDishItem(
        foodName: 'Knoblauch',
        grams: 10,
        proteinG: 0.64,
        carbsG: 3.3,
        fatsG: 0.05,
      ),
      StandardFoodDishItem(
        foodName: 'Butter',
        grams: 12,
        proteinG: 0.1,
        carbsG: 0.01,
        fatsG: 9.7,
      ),
      StandardFoodDishItem(
        foodName: 'Sucuk',
        grams: 50,
        proteinG: 10,
        carbsG: 1,
        fatsG: 14,
      ),
    ],
  ),
];
