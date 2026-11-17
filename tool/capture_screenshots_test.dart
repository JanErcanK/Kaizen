// Documentation renderer. Uses isolated synthetic data; never runs main(),
// initializes cloud services, or sends AI requests.
// FLUTTER_ROOT must point to the Flutter SDK (for the bundled Roboto font).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/main.dart';
import 'package:kaizen/models/ai_chat.dart';
import 'package:kaizen/navigation/app_tab_navigation.dart';
import 'package:kaizen/services/ai_chat_store.dart';
import 'package:kaizen/services/progress_store.dart';

void main() {
  testWidgets('render portfolio screenshots with synthetic data', (
    tester,
  ) async {
    final sdk = Platform.environment['FLUTTER_ROOT'];
    if (sdk == null) throw StateError('Set FLUTTER_ROOT to your Flutter SDK.');
    late Directory storage;
    tester.view.physicalSize = const Size(420, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      storage = await Directory.systemTemp.createTemp('kaizen_docs_');
      final font = File(
        '$sdk/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
      );
      final loader = FontLoader('Roboto')
        ..addFont(
          font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File(
            '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await icons.load();
      await ProgressStore.init(storageRootPath: storage.path);
      await ProgressStore.setHasCompletedOnboarding(true);
      await ProgressStore.setHasCompletedAppTour(true);
      await ProgressStore.setHasCompletedHomeIntro(true);
      await ProgressStore.setProfileName('Alex');
      await ProgressStore.setProfileAge(28);
      await ProgressStore.setProfileHeightCm(175);
      await ProgressStore.setProfileGender('male');
      await ProgressStore.setWeightForToday(72);
      await ProgressStore.setTodaySteps(6400);
      await ProgressStore.setWaterTrackingEnabled(true);
      await ProgressStore.setTodayWaterMl(1250);
      await ProgressStore.saveEatingWindow(
        startMinutes: 720,
        endMinutes: 1200,
        remindersEnabled: false,
      );
      await ProgressStore.addFoodIntakeFood(
        name: 'Example breakfast',
        grams: 350,
        proteinG: 28,
        carbsG: 65,
        fatsG: 16,
      );
      await AiChatStore.save([
        ChatConversation(
          id: 'demo_chat',
          provider: AiProvider.openai,
          model: AiProvider.openai.defaultModel,
          title: 'Lunch estimate',
          messages: [
            ChatMessage(
              id: 'demo_user',
              role: 'user',
              createdAt: DateTime.now(),
              text:
                  'I had 200 g of eggs and 100 g of spinach. Can you estimate the macros?',
            ),
            ChatMessage(
              id: 'demo_reply',
              role: 'assistant',
              createdAt: DateTime.now(),
              text:
                  'Here is an estimate. Check the portions and any added oil before logging.',
              meal: const MealDraft(
                name: 'Eggs and spinach',
                assumptions: 'Estimated values. No added oil included.',
                foods: [
                  MealFood(
                    name: 'Eggs',
                    grams: 200,
                    proteinG: 25,
                    carbsG: 2,
                    fatsG: 20,
                  ),
                  MealFood(
                    name: 'Spinach',
                    grams: 100,
                    proteinG: 3,
                    carbsG: 2,
                    fatsG: 0.4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ]);
    });
    await tester.runAsync(() async {
      final boundary = GlobalKey();
      AppTabNavigation.selectedTab.value = 0;
      await tester.pumpWidget(
        RepaintBoundary(key: boundary, child: const KaizenApp()),
      );
      await tester.pumpAndSettle();

      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        try {
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          final file = File('docs/images/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes.buffer.asUint8List());
        } finally {
          image.dispose();
        }
        expect(tester.takeException(), isNull);
      }

      await capture('home');
      AppTabNavigation.selectedTab.value = 2;
      await tester.pumpAndSettle();
      await capture('chat');
      AppTabNavigation.selectedTab.value = 1;
      await tester.pumpAndSettle();
      await capture('profile');
      await tester.pumpWidget(const SizedBox());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await ProgressStore.closeForTesting();
      await storage.delete(recursive: true);
    });
  });
}
