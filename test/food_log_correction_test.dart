import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/ai_chat.dart';
import 'package:kaizen/screens/profile_screen.dart';
import 'package:kaizen/screens/chat_screen.dart';
import 'package:kaizen/services/ai_chat_store.dart';
import 'package:kaizen/services/progress_store.dart';

const original = MealDraft(
  name: 'Chicken',
  assumptions: '',
  foods: [
    MealFood(
      name: 'Grilled chicken',
      grams: 150,
      proteinG: 30,
      carbsG: 0,
      fatsG: 5,
    ),
  ],
);
const corrected = MealDraft(
  name: 'Chicken',
  assumptions: 'Fried',
  foods: [
    MealFood(
      name: 'Fried chicken',
      grams: 150,
      proteinG: 30,
      carbsG: 5,
      fatsG: 15,
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('food_correction_');
    await ProgressStore.init(storageRootPath: directory.path);
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await directory.delete(recursive: true);
  });

  test('delete and replace actions round-trip and reject missing targets', () {
    for (final type in [
      AiChatActionType.deleteFoodEntries,
      AiChatActionType.replaceFoodEntries,
    ]) {
      final action = AiChatAction(
        type: type,
        entryIds: ['ai_original_0'],
        meal: type == AiChatActionType.replaceFoodEntries ? corrected : null,
      );
      final parsed = AiChatAction.fromJson(action.toJson());
      expect(parsed.type, type);
      expect(parsed.entryIds, ['ai_original_0']);
      expect(parsed.needsReview, isTrue);
      expect(
        () => AiChatAction.fromJson({...action.toJson(), 'entryIds': []}),
        throwsFormatException,
      );
    }
  });

  test(
    'correction replaces only targets on the original day and survives retry',
    () async {
      final day = DateTime(2026, 10, 24, 20, 49);
      await ProgressStore.confirmChatMeal(
        sourceId: 'original',
        meal: original,
        at: day,
      );
      await ProgressStore.confirmChatMeal(
        sourceId: 'unrelated',
        meal: original,
        at: day.add(const Duration(days: 1)),
      );
      await ProgressStore.changeChatFoodEntries(
        sourceId: 'fix',
        entryIds: ['ai_original_0'],
        replacement: corrected,
      );
      expect(ProgressStore.foodIntake, hasLength(2));
      expect(
        ProgressStore.foodIntakeForDay(day).single['name'],
        'Fried chicken',
      );
      expect(
        ProgressStore.foodIntakeForDay(day).single['recordedAt'],
        day.toIso8601String(),
      );
      expect(ProgressStore.foodTotalsForDay(day).kcal, corrected.totals.kcal);
      await ProgressStore.closeForTesting();
      await ProgressStore.init(storageRootPath: directory.path);
      await ProgressStore.changeChatFoodEntries(
        sourceId: 'fix',
        entryIds: ['ai_original_0'],
        replacement: corrected,
      );
      expect(ProgressStore.foodIntake, hasLength(2));
    },
  );

  test(
    'delete duplicate, reject stale batch, and keep original logging receipts',
    () async {
      final day = DateTime(2026, 10, 25);
      await ProgressStore.confirmChatMeal(
        sourceId: 'original',
        meal: original,
        at: day,
      );
      await ProgressStore.confirmChatMeal(
        sourceId: 'duplicate',
        meal: corrected,
        at: day,
      );
      await expectLater(
        ProgressStore.changeChatFoodEntries(
          sourceId: 'stale',
          entryIds: ['ai_original_0', 'missing'],
        ),
        throwsStateError,
      );
      expect(ProgressStore.foodIntake, hasLength(2));
      await ProgressStore.changeChatFoodEntries(
        sourceId: 'delete',
        entryIds: ['ai_original_0'],
      );
      await ProgressStore.confirmChatMeal(
        sourceId: 'original',
        meal: original,
        at: day,
      );
      expect(ProgressStore.foodIntake.single['name'], 'Fried chicken');
      expect(ProgressStore.foodTotalsForDay(day).kcal, corrected.totals.kcal);
      await ProgressStore.changeChatFoodEntries(
        sourceId: 'delete',
        entryIds: ['ai_original_0'],
      );
      expect(ProgressStore.foodIntake, hasLength(1));
    },
  );

  test('replacement cannot collapse entries from different days', () async {
    final day = DateTime(2026, 10, 24);
    await ProgressStore.confirmChatMeal(
      sourceId: 'one',
      meal: original,
      at: day,
    );
    await ProgressStore.confirmChatMeal(
      sourceId: 'two',
      meal: original,
      at: day.add(const Duration(days: 1)),
    );
    await expectLater(
      ProgressStore.changeChatFoodEntries(
        sourceId: 'bad',
        entryIds: ['ai_one_0', 'ai_two_0'],
        replacement: corrected,
      ),
      throwsArgumentError,
    );
    expect(ProgressStore.foodIntake, hasLength(2));
  });

  for (final replace in [false, true]) {
    testWidgets(
      'chat applies ${replace ? 'correction' : 'deletion'} only after review',
      (tester) async {
        await tester.runAsync(() async {
          await ProgressStore.saveChatSettings({'coachIntroSeen': true});
          await ProgressStore.confirmChatMeal(
            sourceId: 'original',
            meal: original,
            at: DateTime.now(),
          );
          await AiChatStore.save([
            ChatConversation(
              id: 'chat',
              provider: AiProvider.openai,
              model: AiProvider.openai.defaultModel,
              title: 'Fix food',
              messages: [
                ChatMessage(
                  id: 'change',
                  role: 'assistant',
                  text: 'Review these entries.',
                  createdAt: DateTime.now(),
                  proposal: AiChatAction(
                    type: replace
                        ? AiChatActionType.replaceFoodEntries
                        : AiChatActionType.deleteFoodEntries,
                    entryIds: ['ai_original_0'],
                    meal: replace ? corrected : null,
                  ),
                ),
              ],
            ),
          ]);
          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ChatScreen(keyReader: (_) async => 'test')),
            ),
          );
          await tester.pumpAndSettle();
          expect(ProgressStore.foodIntake.single['name'], 'Grilled chicken');
          final button = find.byKey(const ValueKey('save-proposal-change'));
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pumpAndSettle();
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();
          if (replace) {
            expect(ProgressStore.foodIntake.single['name'], 'Fried chicken');
          } else {
            expect(ProgressStore.foodIntake, isEmpty);
          }
          expect(ProgressStore.hasAiChatAction('change'), isTrue);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      },
    );
  }

  testWidgets('calendar day delete can be cancelled and updates the open day', (
    tester,
  ) async {
    await tester.runAsync(() async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await ProgressStore.confirmChatMeal(
        sourceId: 'today',
        meal: original,
        at: DateTime.now(),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final day = find.text(DateTime.now().day.toString()).last;
      await tester.ensureVisible(day);
      await tester.tap(day);
      await tester.pumpAndSettle();
      final remove = find.byKey(const ValueKey('delete-food-ai_today_0'));
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(ProgressStore.foodIntake, hasLength(1));
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(remove, findsNothing);
      expect(ProgressStore.foodIntake, isEmpty);
      expect(ProgressStore.foodTotalsForDay(DateTime.now()).kcal, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
