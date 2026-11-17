import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/food_search.dart';
import 'package:kaizen/data/standard_food_catalog.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/l10n/catalog_localizations.dart';
import 'package:kaizen/screens/food_screen.dart';
import 'package:kaizen/services/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('food_catalog_');
    await ProgressStore.init(storageRootPath: directory.path);
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await directory.delete(recursive: true);
  });

  test(
    '300 new groceries have distinct identities and usable sourced macros',
    () {
      expect(standardFoodEntries, hasLength(300));
      final names = catalogFoodNames;
      expect(names.toSet(), hasLength(names.length));
      expect(
        names.map((n) => normalizeFoodSearch(canonicalFoodName(n))).toSet(),
        hasLength(names.length),
      );
      expect(names, isNot(contains('Eier')));
      expect(
        names.where((n) => canonicalFoodName(n) == 'Hühnereier'),
        hasLength(1),
      );
      expect(names, containsAll(['Hühnereier', 'Gänseeier', 'Wachteleier']));
      for (final food in standardFoodEntries) {
        expect(
          names.where((n) => n == food.nameDe),
          hasLength(1),
          reason: food.nameDe,
        );
        expect(catalogFoodHasMacros(food.nameDe), isTrue, reason: food.nameDe);
        expect(food.source, isNotEmpty);
        for (final value in [food.proteinG, food.carbsG, food.fatsG]) {
          expect(
            value.isFinite && value >= 0 && value <= 100,
            isTrue,
            reason: food.nameDe,
          );
        }
        expect(
          food.proteinG + food.carbsG + food.fatsG,
          lessThanOrEqualTo(101),
          reason: food.nameDe,
        );
      }
      expect(standardFoodsByName['Zucker (weiß)']!.carbsG, 100);
      expect(standardFoodsByName['Vollmilchschokolade']!.proteinG, 7.3);
      expect(standardFoodsByName['Kakao-Nibs']!.fatsG, 53);
      expect(catalogFoodHasMacros('Eier'), isTrue);
      expect(catalogFoodHasMacros('Körniger Frischkäse'), isTrue);
      expect(catalogFoodHasMacros('Hähnchenschenkel'), isTrue);
    },
  );

  for (final locale in ['de', 'en']) {
    test(
      'all foods are bilingual and display in $locale without duplicates',
      () async {
        await ProgressStore.setAppLocaleCode(locale);
        for (final name in catalogFoodNames) {
          final english = CatalogLocalizations.foodEnglishAlias(name);
          expect(english, isNotNull, reason: 'Missing translation: $name');
          expect(CatalogLocalizations.matchesFoodQuery(name, name), isTrue);
          expect(CatalogLocalizations.matchesFoodQuery(name, english!), isTrue);
        }
        final labels = catalogFoodNames
            .map(CatalogLocalizations.foodName)
            .toList();
        final seen = <String>{};
        for (final label in labels) {
          expect(
            seen.add(normalizeFoodSearch(label)),
            isTrue,
            reason: 'Duplicate $locale label: $label',
          );
        }
        for (final food in standardFoodEntries) {
          expect(
            CatalogLocalizations.foodName(food.nameDe),
            locale == 'de' ? food.nameDe : food.nameEn,
          );
          expect(
            CatalogLocalizations.foodSubtitle(food.nameDe),
            locale == 'de' ? food.subtitleDe : food.subtitleEn,
          );
        }
        expect(
          CatalogLocalizations.foodName('Eier'),
          locale == 'de' ? 'Hühnerei' : 'Chicken egg',
        );
      },
    );

    testWidgets('food search accepts both languages and displays $locale', (
      tester,
    ) async {
      await tester.runAsync(() => ProgressStore.setAppLocaleCode(locale));
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(locale),
          home: const FoodScreen(),
        ),
      );
      await tester.pumpAndSettle();
      final search = find.byType(TextField).first;
      for (final query in ['kakao nibs', 'cocoa nibs', 'CACAO NIBS']) {
        await tester.enterText(search, query);
        await tester.pumpAndSettle();
        expect(
          find.text(locale == 'de' ? 'Kakao-Nibs' : 'Cacao nibs'),
          findsOneWidget,
        );
      }
      for (final query in ['vollmilchschokolade', 'milk chocolate']) {
        await tester.enterText(search, query);
        await tester.pumpAndSettle();
        expect(
          find.text(locale == 'de' ? 'Vollmilchschokolade' : 'Milk chocolate'),
          findsOneWidget,
        );
      }
      for (final query in ['huehnerei', 'chicken egg']) {
        await tester.enterText(search, query);
        await tester.pumpAndSettle();
        expect(
          find.text(locale == 'de' ? 'Hühnerei' : 'Chicken egg'),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('ingredient picker uses the same bilingual search in $locale', (
      tester,
    ) async {
      await tester.runAsync(() => ProgressStore.setAppLocaleCode(locale));
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(locale),
          home: const FoodScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(locale == 'de' ? 'Gerichte' : 'Dishes'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.restaurant_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is FloatingActionButton &&
              widget.heroTag == 'dishIngredientCatalogue',
        ),
      );
      await tester.pumpAndSettle();
      for (final query in ['kakao nibs', 'cocoa nibs']) {
        await tester.enterText(find.byType(TextField).last, query);
        await tester.pumpAndSettle();
        expect(
          find.text(locale == 'de' ? 'Kakao-Nibs' : 'Cacao nibs'),
          findsOneWidget,
        );
      }
      await tester.tap(find.text(locale == 'de' ? 'Kakao-Nibs' : 'Cacao nibs'));
      await tester.pumpAndSettle();
      // Selecting a sourced food opens the portion controls, not manual macros.
      expect(
        find.text(locale == 'de' ? 'Kakao-Nibs' : 'Cacao nibs'),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'synonyms, umlauts, accents and word order work independently of locale',
    () {
      for (final pair in <(String, String)>[
        ('Hühnereier', 'Ei'),
        ('Hühnereier', 'eggs'),
        ('Hühnereier', 'HUEHNEREI'),
        ('Hühnereier', 'huhnerei'),
        ('Hüttenkäse', 'koerniger frischkaese'),
        ('Hüttenkäse', 'cottage cheese'),
        ('Äpfel', 'apfel'),
        ('Blaubeeren', 'heidelbeeren'),
        ('Karotten', 'mohre'),
        ('Zartbitterschokolade', 'chocolate dark'),
        ('Kakao-Nibs', 'Kakao Nibs'),
        ('Kakao-Nibs', 'cocoa-nibs'),
        ('Paprikapulver', 'gewuerz'),
        ('Paprikapulver', 'spice'),
        ('Zimt (gemahlen)', 'cinnamon'),
        ('Gruyère', 'gruyere'),
      ]) {
        expect(
          CatalogLocalizations.matchesFoodQuery(pair.$1, pair.$2),
          isTrue,
          reason: '${pair.$1} must match ${pair.$2}',
        );
      }
      expect(CatalogLocalizations.matchesFoodQuery('Reis', 'ei'), isFalse);
      expect(
        CatalogLocalizations.matchesFoodQuery('Kakao-Nibs', 'zzzz'),
        isFalse,
      );
      expect(CatalogLocalizations.matchesFoodQuery('Kakao-Nibs', '  '), isTrue);
      expect(
        CatalogLocalizations.matchesFoodQuery('Hühnereier', 'egg chocolate'),
        isFalse,
      );
    },
  );
}
