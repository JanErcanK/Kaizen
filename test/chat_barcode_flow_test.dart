import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/ai_chat.dart';
import 'package:kaizen/screens/chat_screen.dart';
import 'package:kaizen/screens/food_barcode_scan_screen.dart';
import 'package:kaizen/screens/shopping_list_screen.dart';
import 'package:kaizen/services/ai_chat_store.dart';
import 'package:kaizen/services/open_food_facts_service.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/theme/app_theme.dart';
import 'package:kaizen/widgets/app_back_button.dart';

const product = ScannedFoodProduct(
  barcode: '4000000000001',
  name: 'Test Naturjoghurt',
  proteinPer100g: 4,
  carbsPer100g: 5,
  fatsPer100g: 3,
);

Widget host(Widget child, {String locale = 'de'}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.build(light: true),
  home: Scaffold(body: child),
);

Future<void> flushUi(WidgetTester tester) async {
  await Future<void>.delayed(const Duration(milliseconds: 80));
  await tester.pumpAndSettle();
}

Future<void> submitBarcode(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('chat-scan-barcode')));
  await tester.tap(find.byKey(const Key('chat-scan-barcode')));
  await tester.pumpAndSettle();
  expect(find.byType(FoodBarcodeScanScreen), findsOneWidget);
  await tester.enterText(find.byType(TextField), product.barcode);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('kaizen_barcode_');
    await ProgressStore.init(storageRootPath: storage.path);
    await ProgressStore.saveChatSettings({'coachIntroSeen': true});
    await ProgressStore.setUseGerman(true);
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });

  testWidgets('chat scan needs no AI key and supports all three destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      var lookups = 0;
      for (final dish in ProgressStore.foodDishes) {
        await ProgressStore.deleteFoodDish(dish['id'] as String);
      }
      final dishId = await ProgressStore.createFoodDish('Frühstück');
      await tester.pumpWidget(
        host(
          ChatScreen(
            keyReader: (_) async =>
                throw StateError('Barcode must not access AI'),
            barcodeLookup: (barcode) async {
              expect(barcode, product.barcode);
              lookups++;
              return product;
            },
          ),
        ),
      );
      await flushUi(tester);
      expect(
        tester.getTopLeft(find.byKey(const Key('chat-scan-barcode'))).dy,
        greaterThan(tester.getTopLeft(find.text('Mahlzeit fotografieren')).dy),
      );
      await submitBarcode(tester);
      await flushUi(tester);
      expect(find.text(product.name), findsOneWidget);
      expect(find.text('Pro 100 g'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '250');
      await tester.pump();
      final shopping = find.text('Auf den Einkaufszettel');
      await tester.ensureVisible(shopping);
      await tester.tap(shopping);
      await flushUi(tester);
      expect(
        ProgressStore.shoppingDraft.items.single.text,
        '${product.name} · 250 g',
      );
      expect(ProgressStore.foodIntake, isEmpty);
      // Opening the list from the result must preserve the chosen amount.
      await tester.tap(find.text('Öffnen'));
      await flushUi(tester);
      expect(find.byType(ShoppingListScreen), findsOneWidget);
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();
      await submitBarcode(tester);
      await flushUi(tester);
      await tester.enterText(find.byType(TextField).last, '250');
      await tester.pump();
      final today = find.text('Heute essen');
      await tester.ensureVisible(today);
      await tester.tap(today);
      await flushUi(tester);
      expect(ProgressStore.foodIntake.single['grams'], 250);
      expect(ProgressStore.foodIntake.single['proteinG'], 10);
      expect(ProgressStore.foodIntake.single['carbsG'], 12.5);
      expect(ProgressStore.foodIntake.single['fatsG'], 7.5);
      await submitBarcode(tester);
      await flushUi(tester);
      await tester.enterText(find.byType(TextField).last, '75');
      await tester.pump();
      await tester.ensureVisible(find.text('Zum Gericht'));
      await tester.tap(find.text('Zum Gericht'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Frühstück'));
      await flushUi(tester);
      final dish = ProgressStore.foodDishes.firstWhere(
        (d) => d['id'] == dishId,
      );
      expect((dish['items'] as List).single['grams'], 75);
      expect((dish['items'] as List).single['proteinG'], 3);
      expect(ProgressStore.foodIntake, hasLength(1));
      expect(lookups, 3);
      expect(ProgressStore.savedChats, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets('cancelled lookup cannot navigate when its late result arrives', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final pending = Completer<ScannedFoodProduct?>();
      await tester.pumpWidget(
        host(ChatScreen(barcodeLookup: (_) => pending.future)),
      );
      await tester.pumpAndSettle();
      await submitBarcode(tester);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      pending.complete(product);
      await flushUi(tester);
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text(product.name), findsNothing);
      expect(ProgressStore.foodIntake, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets('network error can retry and missing product stays unlogged', (
    tester,
  ) async {
    await tester.runAsync(() async {
      var calls = 0;
      await tester.pumpWidget(
        host(
          ChatScreen(
            barcodeLookup: (_) async {
              if (calls++ == 0) throw const SocketException('offline');
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await submitBarcode(tester);
      await flushUi(tester);
      await tester.tap(find.text('Erneut versuchen'));
      await flushUi(tester);
      expect(calls, 2);
      expect(find.textContaining('Verbindung fehlgeschlagen'), findsNothing);
      expect(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(AlertDialog)),
          ).food_barcodeNotFound,
        ),
        findsOneWidget,
      );
      expect(ProgressStore.foodIntake, isEmpty);
      expect(ProgressStore.shoppingDraft.isEmpty, true);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets(
    'manual barcode entry fits a small screen with the keyboard open',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(host(const FoodBarcodeScanScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Produkt suchen'));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('existing conversations retain access to barcode scanning', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await AiChatStore.save([
        ChatConversation(
          id: 'existing',
          provider: AiProvider.openai,
          model: AiProvider.openai.defaultModel,
          title: 'Training',
          messages: [
            ChatMessage(
              id: 'one',
              role: 'user',
              text: 'Training heute',
              createdAt: DateTime(2026, 10, 24),
            ),
          ],
        ),
      ]);
      await tester.pumpWidget(host(const ChatScreen(), locale: 'en'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Scan the barcode'));
      await tester.pumpAndSettle();
      expect(find.byType(FoodBarcodeScanScreen), findsOneWidget);
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();
      expect(find.text('Training heute'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
