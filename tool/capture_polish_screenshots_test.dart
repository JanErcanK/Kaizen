// Visual checks with isolated synthetic data. No production account is used.
// Run with FLUTTER_ROOT pointing to the Flutter SDK.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/main.dart';
import 'package:kaizen/screens/chat_screen.dart';
import 'package:kaizen/screens/food_screen.dart';
import 'package:kaizen/screens/shopping_list_screen.dart';
import 'package:kaizen/screens/workout_timer_screen.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/services/open_food_facts_service.dart';
import 'package:kaizen/theme/app_theme.dart';
import 'package:kaizen/widgets/organ_guidance_panel.dart';
import 'package:kaizen/widgets/organ_detail_card.dart';
import 'package:kaizen/widgets/movable_anatomy_card.dart';
import 'package:kaizen/services/anatomy_catalog.dart';

void main() {
  testWidgets('capture and exercise the polish screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final sdk = Platform.environment['FLUTTER_ROOT']!;
      for (final font in {
        'Roboto': 'roboto-regular.ttf',
        'MaterialIcons': 'MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(font.key)..addFont(
              File(
                '$sdk/bin/cache/artifacts/material_fonts/${font.value}',
              ).readAsBytes().then(ByteData.sublistView),
            ))
            .load();
      }
      final storage = await Directory.systemTemp.createTemp(
        'kaizen_polish_preview_',
      );
      await ProgressStore.init(storageRootPath: storage.path);
      await ProgressStore.setUseGerman(true);
      await ProgressStore.setHasCompletedOnboarding(true);
      await ProgressStore.setHasCompletedAppTour(true);
      await ProgressStore.setHasCompletedHomeIntro(true);
      await ProgressStore.setProfileName('Alex');
      for (final item in [
        'Joghurt natur',
        'Chiasamen',
        'Haferflocken',
        'Äpfel',
        'Brokkoli',
      ]) {
        await ProgressStore.addShoppingItem(item);
      }
      await ProgressStore.saveShoppingDraft();
      await ProgressStore.renameShoppingList(
        ProgressStore.shoppingDraft.id,
        'Wochenmarkt',
      );
      final boundary = GlobalKey();
      Future<void> capture(String name) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/polish-preview/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        expect(tester.takeException(), isNull);
      }

      Widget host(Widget child, {bool dark = false}) => RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.build(light: !dark),
          home: child,
        ),
      );
      await tester.pumpWidget(
        RepaintBoundary(key: boundary, child: const KaizenApp()),
      );
      await capture('home');
      await tester.tap(find.byKey(const ValueKey('home-shopping-list')));
      await tester.pumpAndSettle();
      expect(find.byType(ShoppingListScreen), findsOneWidget);
      expect(find.byType(FoodScreen), findsNothing);
      await capture('shopping-light');
      await tester.tap(find.text('Meine Einkäufe'));
      await tester.pumpAndSettle();
      await capture('shopping-history');
      await tester.pumpWidget(const SizedBox.shrink());
      await ProgressStore.setUseLightTheme(false);
      await tester.pumpWidget(host(const ShoppingListScreen(), dark: true));
      await capture('shopping-dark');
      await tester.pumpWidget(const SizedBox.shrink());
      await ProgressStore.setUseLightTheme(true);
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Darm',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    OrganGuidancePanel(organId: 'large_intestine'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await capture('organ-actions');
      await tester.pumpWidget(const SizedBox.shrink());
      final organCatalog = await AnatomyCatalog.load();
      for (final organId in ['lung.l', 'large_intestine']) {
        final info = organCatalog.describe(
          id: 'organ.$organId',
          tissue: 'organ',
          organId: organId,
        );
        await tester.pumpWidget(
          host(
            Scaffold(
              body: Stack(
                children: [
                  const Positioned(
                    top: 24,
                    left: 20,
                    child: Text('Organansicht · Vorschau'),
                  ),
                  Positioned.fill(
                    child: MovableAnatomyCard(
                      initialAlignment: Alignment.bottomLeft,
                      insets: const EdgeInsets.fromLTRB(12, 72, 12, 16),
                      child: SizedBox(
                        width: 366,
                        child: OrganDetailCard(
                          key: ValueKey(organId),
                          organId: organId,
                          title: info.title(true),
                          description: info.description(true),
                          latinName: info.latinName,
                          height: 844 * .67,
                          onClose: () {},
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await capture('organ-card-$organId');
        final card = find.byKey(const ValueKey('anatomy-organ-card'));
        final initial = tester.getRect(card);
        final hold = await tester.startGesture(
          initial.topLeft + const Offset(60, 25),
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await hold.moveBy(const Offset(0, -120));
        await hold.up();
        await capture('organ-card-$organId-moved');
        expect(tester.getRect(card).top, closeTo(initial.top - 120, .01));
        await tester.pumpWidget(const SizedBox.shrink());
      }
      // Product lookup is a fixture; this capture does not call the network.
      await tester.pumpWidget(
        host(
          Scaffold(
            body: ChatScreen(
              barcodeLookup: (_) async => const ScannedFoodProduct(
                barcode: '4000000000001',
                name: 'Joghurt natur',
                brand: 'Beispielprodukt',
                proteinPer100g: 4,
                carbsPer100g: 5,
                fatsPer100g: 3,
              ),
            ),
          ),
        ),
      );
      await capture('chat-barcode');
      await tester.tap(find.byKey(const Key('chat-scan-barcode')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '4000000000001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await capture('barcode-product');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(host(const WorkoutTimerScreen()));
      await capture('timer-setup');
      await tester.pumpWidget(const SizedBox.shrink());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // This developer renderer deliberately uses the same isolated test store.
      // ignore: invalid_use_of_visible_for_testing_member
      await ProgressStore.closeForTesting();
      await storage.delete(recursive: true);
    });
  });
}
