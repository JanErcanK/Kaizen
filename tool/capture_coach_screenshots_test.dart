// Synthetic UI fixture; never loads the user's profile or API credentials.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/ai_chat.dart';
import 'package:kaizen/screens/chat_screen.dart';
import 'package:kaizen/services/ai_chat_store.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/theme/app_theme.dart';

void main() {
  testWidgets('capture coach introduction and video proposal', (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final sdk = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter';
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
        'kaizen_coach_preview_',
      );
      await ProgressStore.init(storageRootPath: storage.path);
      await ProgressStore.setProfileName('Alex');
      await ProgressStore.setUseGerman(true);
      final boundary = GlobalKey();
      Widget host() => RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.build(light: true),
          home: const Scaffold(body: ChatScreen()),
        ),
      );
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final picture = await render.toImage(pixelRatio: 2);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/coach-preview/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(host());
      await capture('intro-food');
      await tester.tap(find.byKey(const Key('coach-intro-next')));
      await capture('intro-context');
      await tester.tap(find.byKey(const Key('coach-intro-next')));
      await capture('intro-gold');
      await tester.tap(find.byKey(const Key('coach-intro-next')));
      for (var i = 0; i < 15; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await AiChatStore.save([
        ChatConversation(
          id: 'preview',
          provider: AiProvider.openai,
          model: 'gpt-5.4-mini',
          title: 'Workout aus Video',
          messages: [
            ChatMessage(
              id: 'user',
              role: 'user',
              text: 'Erstelle ein Workout aus diesem Video.',
              videoSource: 'Geteiltes Video',
              createdAt: DateTime.now(),
            ),
            ChatMessage(
              id: 'proposal',
              role: 'assistant',
              text:
                  'Ich erkenne Kniebeugen und Liegestütze. Die Satz- und Wiederholungszahlen sind mein Vorschlag. Möchtest du das Workout speichern oder etwas ändern?',
              createdAt: DateTime.now(),
              proposal: const AiChatAction(
                type: AiChatActionType.saveWorkout,
                workoutName: 'Dein Ganzkörper-Workout',
                durationMinutes: 15,
                exercises: [
                  AiWorkoutExercise(
                    name: 'Kniebeugen',
                    sets: 3,
                    reps: 12,
                    mainGroup: 'Beine',
                    secondaryMuscles: ['Bauch'],
                    evidence: '00:03 · Übung erkannt; Umfang vorgeschlagen.',
                  ),
                  AiWorkoutExercise(
                    name: 'Liegestütze',
                    sets: 3,
                    reps: 8,
                    mainGroup: 'Brust',
                    secondaryMuscles: ['Trizeps'],
                    evidence: '00:12 · Handposition bitte prüfen.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ]);
      await tester.pumpWidget(host());
      await capture('workout-proposal');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await ProgressStore.closeForTesting();
      await storage.delete(recursive: true);
    });
  });
}
