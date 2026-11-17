import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/screens/food_screen.dart';
import 'package:kaizen/screens/shopping_list_screen.dart';
import 'package:kaizen/services/anatomy_catalog.dart';
import 'package:kaizen/services/organ_guidance.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/theme/app_theme.dart';
import 'package:kaizen/widgets/organ_guidance_panel.dart';

Widget host(Widget child, {bool dark = false, String locale = 'de'}) =>
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.build(light: !dark),
      home: child,
    );

Future<void> flushUi(WidgetTester tester) async {
  await Future<void>.delayed(const Duration(milliseconds: 80));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('kaizen_shopping_');
    await ProgressStore.init(storageRootPath: storage.path);
    await ProgressStore.setUseGerman(true);
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });

  test(
    'draft, checks, archive names and custom order survive a restart',
    () async {
      await ProgressStore.addShoppingItem('Joghurt', grams: 150);
      final first = ProgressStore.shoppingDraft;
      await ProgressStore.updateShoppingDraft(
        first.copyWith(items: [first.items.single.copyWith(checked: true)]),
      );
      await ProgressStore.saveShoppingDraft();
      await ProgressStore.saveShoppingDraft();
      expect(ProgressStore.shoppingHistory, hasLength(1));
      await ProgressStore.renameShoppingList(first.id, 'Wochenmarkt');
      await ProgressStore.clearShoppingDraft();
      await ProgressStore.addShoppingItem('Chia');
      final second = ProgressStore.shoppingDraft;
      await ProgressStore.saveShoppingDraft();
      await ProgressStore.reorderShoppingLists(0, 1);
      await ProgressStore.closeForTesting();
      await ProgressStore.init(storageRootPath: storage.path);
      expect(ProgressStore.shoppingHistory.map((list) => list.id), [
        first.id,
        second.id,
      ]);
      expect(ProgressStore.shoppingHistory.first.name, 'Wochenmarkt');
      expect(ProgressStore.shoppingHistory.first.items.single.checked, true);
      expect(ProgressStore.shoppingDraft.items.single.text, 'Chia');
      await ProgressStore.openShoppingList(first.id);
      expect(ProgressStore.shoppingDraft.items.single.text, 'Joghurt · 150 g');
      await ProgressStore.deleteShoppingList(first.id);
      expect(ProgressStore.shoppingDraft.isEmpty, true);
      expect(ProgressStore.shoppingHistory.single.id, second.id);
      expect(
        ProgressStore.foodIntake,
        isEmpty,
        reason: 'Shopping does not imply eating',
      );
    },
  );

  test('opening a saved purchase preserves an unfinished draft', () async {
    await ProgressStore.addShoppingItem('Äpfel');
    await ProgressStore.saveShoppingDraft();
    final saved = ProgressStore.shoppingDraft;
    await ProgressStore.clearShoppingDraft();
    await ProgressStore.addShoppingItem('Nicht vergessen');
    final draft = ProgressStore.shoppingDraft;
    await ProgressStore.openShoppingList(saved.id);
    expect(
      ProgressStore.shoppingHistory.map((list) => list.id),
      contains(draft.id),
    );
    await ProgressStore.clearShoppingDraft();
    expect(ProgressStore.shoppingHistory, hasLength(2));
  });

  test(
    'all selectable organs resolve to usable, sourced food suggestions',
    () async {
      final catalog = await AnatomyCatalog.load();
      final organIds = catalog.structures.entries
          .where((entry) => entry.key.startsWith('organ.'))
          .map((entry) => entry.value.organId ?? entry.key);
      expect(organIds.length, greaterThan(20));
      for (final id in organIds) {
        final guide = OrganGuidance.forOrgan(id);
        expect(guide.tipsDe, isNotEmpty, reason: id);
        expect(guide.tipsEn.length, guide.tipsDe.length);
        expect(
          guide.sources.values.every((url) => Uri.parse(url).scheme == 'https'),
          true,
        );
        for (final name in guide.foods) {
          expect(catalogFoodHasMacros(name), true, reason: '$id: $name');
        }
      }
      expect(
        OrganGuidance.forOrgan('lung.l'),
        same(OrganGuidance.forOrgan('lung.r')),
      );
      expect(
        OrganGuidance.forOrgan('large_intestine').foods,
        contains('Chiasamen'),
      );
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'write, save, swipe, clear and undo on a narrow ${dark ? 'dark' : 'light'} screen',
      (tester) async {
        await tester.runAsync(() async {
          tester.view.physicalSize = const Size(360, 780);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await ProgressStore.setUseLightTheme(!dark);
          await tester.pumpWidget(host(const ShoppingListScreen(), dark: dark));
          await flushUi(tester);
          final first = find.byKey(const ValueKey('shopping-item-0'));
          await tester.enterText(first, 'Joghurt');
          await tester.testTextInput.receiveAction(TextInputAction.next);
          await flushUi(tester);
          await tester.enterText(
            find.byKey(const ValueKey('shopping-item-1')),
            'Chia',
          );
          await tester.tap(find.text('Speichern'));
          await flushUi(tester);
          expect(ProgressStore.shoppingHistory, hasLength(1));
          await tester.drag(find.byType(TabBarView), const Offset(-300, 0));
          await flushUi(tester);
          expect(
            find.text(ProgressStore.shoppingHistory.single.name),
            findsOneWidget,
          );
          await tester.drag(find.byType(TabBarView), const Offset(300, 0));
          await flushUi(tester);
          await tester.tap(find.byTooltip('Zettel löschen'));
          await flushUi(tester);
          expect(ProgressStore.shoppingDraft.isEmpty, true);
          // The undo action must belong to the current snackbar.
          await tester.tap(find.text('Rückgängig'));
          await flushUi(tester);
          expect(ProgressStore.shoppingDraft.items.first.text, 'Joghurt');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      },
    );
  }

  testWidgets('gut recommendation can be shopped, eaten and added to a dish', (
    tester,
  ) async {
    await tester.runAsync(() async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final dish in ProgressStore.foodDishes) {
        await ProgressStore.deleteFoodDish(dish['id'] as String);
      }
      await ProgressStore.createFoodDish('Frühstück');
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: OrganGuidancePanel(organId: 'large_intestine'),
            ),
          ),
        ),
      );
      await flushUi(tester);
      await tester.ensureVisible(find.text('Zettel').first);
      await tester.tap(find.text('Zettel').first);
      await flushUi(tester);
      expect(
        ProgressStore.shoppingDraft.items.single.text,
        'Griechischer Joghurt',
      );
      expect(ProgressStore.foodIntake, isEmpty);
      await tester.tap(find.text('Heute').first);
      await flushUi(tester);
      final amount = find.byType(TextField).last;
      await tester.enterText(amount, '200');
      final today = find.widgetWithText(FilledButton, 'Heute essen');
      await tester.ensureVisible(today);
      await tester.tap(today);
      await flushUi(tester);
      expect(ProgressStore.foodIntake.single['grams'], 200);
      expect(ProgressStore.foodIntake.single['proteinG'], 18);
      await tester.tap(find.text('Gericht').first);
      await flushUi(tester);
      final dishButton = find.widgetWithText(FilledButton, 'Zum Gericht');
      await tester.ensureVisible(dishButton);
      await tester.tap(dishButton);
      await flushUi(tester);
      await tester.ensureVisible(find.text('Frühstück'));
      await tester.tap(find.text('Frühstück'));
      await flushUi(tester);
      expect(
        (ProgressStore.foodDishes.firstWhere(
                  (dish) => dish['name'] == 'Frühstück',
                )['items']
                as List)
            .single['foodName'],
        'Griechischer Joghurt',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
