import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/sport_catalog.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/ai_chat.dart';
import 'package:kaizen/screens/chat_screen.dart';
import 'package:kaizen/screens/workout_hub_screen.dart';
import 'package:kaizen/services/ai_chat_store.dart';
import 'package:kaizen/services/calorie_burn_service.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/theme/app_theme.dart';

Widget host(Widget screen, {String language = 'en'}) => MaterialApp(
  theme: AppTheme.build(light: true),
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: screen,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('feedback_test_');
    await ProgressStore.init(storageRootPath: storage.path);
    await ProgressStore.saveChatSettings({'coachIntroSeen': true});
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });

  for (final count in [0, 30]) {
    testWidgets('history scroll dismisses with $count conversations', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(
        () => AiChatStore.save([
          for (var i = 0; i < count; i++)
            ChatConversation(
              id: '$i',
              provider: AiProvider.openai,
              model: 'test',
              title: 'Conversation $i',
              messages: [],
            ),
        ]),
      );
      await tester.pumpWidget(
        host(Scaffold(body: ChatScreen(keyReader: (_) async => null))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Chat history'));
      await tester.pumpAndSettle();
      final history = find.byKey(const ValueKey('chat-history-scroll'));
      if (count > 0) {
        await tester.drag(history, const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(history, findsOneWidget);
        // Scroll back to the start before collapsing the sheet.
        for (var i = 0; i < 12 && history.evaluate().isNotEmpty; i++) {
          await tester.drag(history, const Offset(0, 350));
          await tester.pumpAndSettle();
        }
      } else {
        await tester.drag(history, const Offset(0, 500));
        await tester.pumpAndSettle();
      }
      expect(history, findsNothing);
      expect(AiChatStore.load(), hasLength(count));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  test(
    '40 sports share estimates across both languages and search aliases',
    () {
      expect(sportCatalog, hasLength(40));
      expect(sportCatalog.map((s) => s.de).toSet(), hasLength(40));
      expect(sportCatalog.map((s) => s.en).toSet(), hasLength(40));
      for (final sport in sportCatalog) {
        final de = CalorieBurnService.sportSession(
          sportName: sport.de,
          durationSeconds: 1800,
        );
        final en = CalorieBurnService.sportSession(
          sportName: sport.en,
          durationSeconds: 1800,
        );
        expect(de.totalKcal, en.totalKcal);
        expect(de.breakdown.single.met, sport.met);
        expect(de.totalKcal, greaterThan(0));
      }
      expect(SportActivity.find('Soccer')?.de, 'Fußball');
      expect(SportActivity.find('Paddel')?.de, 'Paddeln / Kajak');
      expect(SportActivity.find('Padel')?.de, 'Padel');
    },
  );

  for (final language in ['de', 'en']) {
    testWidgets('sport search finds rowing and padel in $language', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const SportActivityScreen(), language: language),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChoiceChip), findsNWidgets(40));
      for (final query in ['row', 'padel', 'kajak']) {
        await tester.enterText(find.byType(TextField).first, query);
        await tester.pumpAndSettle();
        expect(find.byType(ChoiceChip), findsOneWidget);
        await tester.tap(find.byType(ChoiceChip));
        await tester.pumpAndSettle();
        final selected = tester
            .widget<TextField>(find.byType(TextField).first)
            .controller!
            .text;
        expect(SportActivity.find(selected), isNotNull);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
