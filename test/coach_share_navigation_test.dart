import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/navigation/app_tab_navigation.dart';
import 'package:kaizen/screens/chat_screen.dart';
import 'package:kaizen/screens/root_shell.dart';
import 'package:kaizen/services/ai_chat_store.dart';
import 'package:kaizen/services/coach_share_service.dart';
import 'package:kaizen/services/progress_store.dart';

void main() {
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('kaizen_share_navigation_');
    await ProgressStore.init(storageRootPath: storage.path);
    await ProgressStore.saveChatSettings({'coachIntroSeen': true});
    AppTabNavigation.selectedTab.value = AppTabNavigation.home;
    CoachShareService.pending.value = [];
  });
  tearDown(() async {
    CoachShareService.pending.value = [];
    AppTabNavigation.selectedTab.value = AppTabNavigation.home;
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });
  const share = CoachSharedInput(
    id: 'navigation-share',
    text: 'https://www.instagram.com/reel/test/',
    error: 'SHARE_UNREADABLE',
  );

  for (final cold in [true, false]) {
    testWidgets(
      '${cold ? "cold" : "warm"} share displays Chat and imports once',
      (tester) async {
        await tester.runAsync(() async {
          final navigator = GlobalKey<NavigatorState>();
          if (cold) CoachShareService.pending.value = [share];
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: navigator,
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const RootShell(),
            ),
          );
          if (!cold) {
            await tester.pumpAndSettle();
            navigator.currentState!.push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Another screen')),
              ),
            );
            await tester.pumpAndSettle();
            CoachShareService.pending.value = [share];
          }
          for (var i = 0; i < 40; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            await tester.pump();
          }
          await tester.pumpAndSettle();
          expect(AppTabNavigation.selectedTab.value, AppTabNavigation.chat);
          expect(
            tester
                .widget<PageView>(find.byType(PageView).first)
                .controller!
                .page,
            0,
          );
          expect(find.byType(ChatScreen).hitTestable(), findsOneWidget);
          expect(find.text('Another screen'), findsNothing);
          expect(AiChatStore.load(), hasLength(1));
          expect(CoachShareService.pending.value, isEmpty);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        });
      },
    );
  }
}
