import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/ai_chat.dart';
import 'package:kaizen/navigation/app_tab_navigation.dart';
import 'package:kaizen/screens/root_shell.dart';
import 'package:kaizen/screens/chat_screen.dart';
import 'package:kaizen/services/ai_chat_service.dart';
import 'package:kaizen/services/ai_chat_store.dart';
import 'package:kaizen/services/chat_image_service.dart';
import 'package:kaizen/services/progress_store.dart';

const eggs = MealFood(
  name: 'Eggs',
  grams: 200,
  proteinG: 25,
  carbsG: 2,
  fatsG: 20,
);
const meal = MealDraft(
  name: 'Eggs and spinach',
  assumptions: 'Estimated portions; no added oil.',
  foods: [
    eggs,
    MealFood(name: 'Spinach', grams: 100, proteinG: 3, carbsG: 2, fatsG: .4),
  ],
);
Map<String, dynamic> answer({bool withFood = true}) => {
  'reply': 'Here is your meal estimate.',
  'mealName': withFood ? meal.name : '',
  'assumptions': withFood ? meal.assumptions : '',
  'foods': withFood ? meal.foods.map((f) => f.toJson()).toList() : [],
};
http.Response response(AiProvider provider, {bool withFood = true}) =>
    http.Response(
      jsonEncode(
        provider == AiProvider.openai
            ? {
                'status': 'completed',
                'output': [
                  {
                    'type': 'message',
                    'content': [
                      {
                        'type': 'output_text',
                        'text': jsonEncode(answer(withFood: withFood)),
                      },
                    ],
                  },
                ],
              }
            : {
                'stop_reason': 'end_turn',
                'content': [
                  {
                    'type': 'text',
                    'text': jsonEncode(answer(withFood: withFood)),
                  },
                ],
              },
      ),
      200,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kaizen_ai_test_');
    await ProgressStore.init(storageRootPath: directory.path);
    await ProgressStore.saveChatSettings({'coachIntroSeen': true});
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await directory.delete(recursive: true);
  });

  testWidgets(
    'API setup keeps the key out of history and never sends a paid request on save',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ChatScreen(
                serviceFactory: () {
                  calls++;
                  return AiChatService(
                    client: MockClient(
                      (_) async => response(AiProvider.openai),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('chat-api-key-prompt')), findsOneWidget);
        await tester.tap(find.byKey(const Key('chat-api-key-prompt')));
        await tester.pumpAndSettle();
        expect(find.textContaining('About €5 in API credit'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('chat-api-key')),
          'test-credential',
        );
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(await AiChatStore.apiKey(AiProvider.openai), 'test-credential');
        expect(find.byKey(const Key('chat-api-key-prompt')), findsNothing);
        expect(await AiChatStore.apiKey(AiProvider.claude), isNull);
        expect(
          jsonEncode(ProgressStore.chatSettings),
          isNot(contains('test-credential')),
        );
        expect(ProgressStore.savedChats, isEmpty);
        expect(calls, 0);
        await tester.tap(find.byTooltip('AI settings'));
        await tester.pumpAndSettle();
        expect(find.text('Key saved. Leave blank to keep it.'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('chat-api-key')))
              .controller!
              .text,
          isEmpty,
        );
        await tester.ensureVisible(find.text('Remove API key'));
        await tester.tap(find.text('Remove API key'));
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        expect(await AiChatStore.apiKey(AiProvider.openai), isNull);
        Navigator.of(
          tester.element(find.byKey(const Key('chat-api-key'))),
        ).pop();
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('chat-api-key-prompt')), findsOneWidget);
        expect(calls, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    },
  );

  test(
    'photo preprocessing bounds dimensions, strips to PNG and rejects corrupt files',
    () async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 2000, 3000),
        Paint()..color = Colors.orange,
      );
      final picture = recorder.endRecording();
      final original = await picture.toImage(2000, 3000);
      final encoded = await original.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${directory.path}/large.png');
      await file.writeAsBytes(encoded!.buffer.asUint8List());
      original.dispose();
      picture.dispose();
      final prepared = await ChatImageService.prepare(XFile(file.path));
      final codec = await ui.instantiateImageCodec(prepared);
      final image = (await codec.getNextFrame()).image;
      expect(image.width, lessThanOrEqualTo(1280));
      expect(image.height, 1280);
      expect(prepared.length, lessThan(4 * 1024 * 1024));
      image.dispose();
      codec.dispose();
      final broken = File('${directory.path}/broken.png');
      await broken.writeAsString('not an image');
      await expectLater(
        ChatImageService.prepare(XFile(broken.path)),
        throwsA(anything),
      );
    },
  );

  testWidgets('navigation is Chat, Home, Profile and starts on Home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AppTabNavigation.selectedTab.value = AppTabNavigation.home;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RootShell(),
        ),
      );
      await tester.pumpAndSettle();
      final chat = find.text('Chat');
      expect(
        tester.getCenter(chat).dx,
        lessThan(tester.getCenter(find.text('Home')).dx),
      );
      expect(
        tester.getCenter(find.text('Home')).dx,
        lessThan(tester.getCenter(find.text('Profile')).dx),
      );
      expect(find.text('Burned'), findsOneWidget);
      await tester.tap(chat);
      await tester.pumpAndSettle();
      expect(find.text('How can I help today?'), findsOneWidget);
      await tester.tap(find.text('Profile'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(AppTabNavigation.selectedTab.value, AppTabNavigation.home);
      expect(find.text('Burned'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });

  test(
    'rejects malformed, negative and impossible portions without logging',
    () {
      for (final change in [
        {'grams': 0},
        {'grams': -10},
        {'grams': 5},
        {'proteinG': -1},
        {'fatsG': 'ten'},
        {'name': ''},
        {'grams': 10001},
      ]) {
        final json = answer();
        json['foods'] = [
          {...eggs.toJson(), ...change},
        ];
        expect(
          () => AiChatReply.parse(jsonEncode(json)),
          throwsA(isA<AiChatException>()),
        );
      }
      expect(
        AiChatReply.parse(jsonEncode(answer(withFood: false))).meal,
        isNull,
      );
      expect(ProgressStore.foodIntake, isEmpty);
    },
  );

  test(
    'confirmation logs all portions once, retains day, totals and durable receipt',
    () async {
      final day = DateTime(2026, 9, 30, 19);
      expect(ProgressStore.foodIntake, isEmpty);
      await Future.wait([
        ProgressStore.confirmChatMeal(sourceId: 'one', meal: meal, at: day),
        ProgressStore.confirmChatMeal(sourceId: 'one', meal: meal, at: day),
      ]);
      expect(ProgressStore.foodIntakeForDay(day), hasLength(2));
      expect(ProgressStore.foodNutrientsForDay(day).proteinG, 28);
      expect(ProgressStore.foodNutrientsForDay(day).kcal, meal.totals.kcal);
      await ProgressStore.closeForTesting();
      await ProgressStore.init(storageRootPath: directory.path);
      await ProgressStore.saveChatSettings({'coachIntroSeen': true});
      await ProgressStore.confirmChatMeal(
        sourceId: 'one',
        meal: meal,
        at: DateTime.now(),
      );
      expect(ProgressStore.foodIntakeForDay(day), hasLength(2));
      expect(ProgressStore.foodIntakeForDay(DateTime.now()), isEmpty);
      expect(ProgressStore.hasChatMeal('one'), isTrue);
      final scaled = eggs.scaledTo(100);
      expect(scaled.proteinG, 12.5);
      expect(scaled.nutrients.kcal, eggs.nutrients.scaled(.5).kcal);
    },
  );

  test(
    'history and resized image survive restart without credentials in records',
    () async {
      final image = await AiChatStore.saveImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZ1cAAAAASUVORK5CYII=',
        ),
        'image/png',
      );
      final message = ChatMessage(
        id: 'm',
        role: 'user',
        text: 'Food photo',
        createdAt: DateTime.now(),
        imageName: image,
        imageMime: 'image/png',
      );
      await AiChatStore.save([
        ChatConversation(
          id: 'c',
          provider: AiProvider.claude,
          model: AiProvider.claude.defaultModel,
          title: 'Dinner',
          messages: [message],
        ),
      ]);
      await ProgressStore.closeForTesting();
      await ProgressStore.init(storageRootPath: directory.path);
      await ProgressStore.saveChatSettings({'coachIntroSeen': true});
      final loaded = AiChatStore.load().single;
      expect(loaded.provider, AiProvider.claude);
      expect(loaded.messages.single.imageName, image);
      expect(await AiChatStore.imageFile(image).exists(), isTrue);
      expect(jsonEncode(ProgressStore.savedChats), isNot(contains('apiKey')));
      await AiChatStore.deleteImages(loaded);
      expect(await AiChatStore.imageFile(image).exists(), isFalse);
      expect(
        () => AiChatStore.imageFile('../other.png'),
        throwsFormatException,
      );
    },
  );

  for (final provider in AiProvider.values) {
    test(
      '${provider.label} sends correct text/image payload and parses a proposal without writing food',
      () async {
        final photo = await AiChatStore.saveImage(
          base64Decode('AQID'),
          'image/png',
        );
        var calls = 0;
        final client = MockClient((request) async {
          calls++;
          expect(request.followRedirects, isFalse);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final openai = provider == AiProvider.openai;
          expect(
            request.url.host,
            openai ? 'api.openai.com' : 'api.anthropic.com',
          );
          expect(body['model'], provider.defaultModel);
          final history = body[openai ? 'input' : 'messages'] as List;
          expect(history, hasLength(3));
          final content = history.first['content'] as List;
          if (openai) {
            expect(body['store'], isFalse);
            expect(body['text']['format']['strict'], isTrue);
            expect(content.last['image_url'], 'data:image/png;base64,AQID');
            expect(history[1]['content'], 'What portion?');
          } else {
            expect(request.headers['anthropic-version'], '2023-06-01');
            expect(body['output_config']['format']['type'], 'json_schema');
            expect(content.first['source']['media_type'], 'image/png');
            expect(content.first['source']['data'], 'AQID');
          }
          expect(request.body, isNot(contains('test-credential')));
          return response(provider);
        });
        final service = AiChatService(client: client);
        final reply = await service.send(
          provider: provider,
          model: provider.defaultModel,
          apiKey: 'test-credential',
          language: 'English',
          messages: [
            ChatMessage(
              id: 'a',
              role: 'user',
              text: 'Photo',
              createdAt: DateTime.now(),
              imageName: photo,
              imageMime: 'image/png',
            ),
            ChatMessage(
              id: 'b',
              role: 'assistant',
              text: 'What portion?',
              createdAt: DateTime.now(),
            ),
            ChatMessage(
              id: 'c',
              role: 'user',
              text: '200 g',
              createdAt: DateTime.now(),
            ),
          ],
        );
        expect(calls, 1);
        expect(reply.meal!.foods, hasLength(2));
        expect(ProgressStore.foodIntake, isEmpty);
        service.close();
      },
    );
  }

  test('API errors do not leak keys or retry billable requests', () async {
    var calls = 0;
    final service = AiChatService(
      client: MockClient((request) async {
        calls++;
        return http.Response('{"error":"test-credential"}', 401);
      }),
    );
    await expectLater(
      service.send(
        provider: AiProvider.openai,
        model: 'any',
        apiKey: 'test-credential',
        language: 'English',
        messages: [
          ChatMessage(
            id: 'm',
            role: 'user',
            text: 'Hello',
            createdAt: DateTime.now(),
          ),
        ],
      ),
      throwsA(
        isA<AiChatException>()
            .having((e) => e.code, 'code', 'auth')
            .having(
              (e) => e.toString(),
              'error',
              isNot(contains('test-credential')),
            ),
      ),
    );
    expect(calls, 1);
    service.close();
  });

  testWidgets(
    'chat sends, reviews, edits and confirms a meal; history restores it',
    (tester) async {
      tester.view.physicalSize = const Size(390, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget app() => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChatScreen(
            keyReader: (_) async => 'test-credential',
            serviceFactory: () => AiChatService(
              client: MockClient((_) async => response(AiProvider.openai)),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('chat-input')),
          '200g eggs and 100g spinach',
        );
        await tester.tap(find.byKey(const Key('chat-send')));
        for (var i = 0; i < 80; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
          if (find.text('Review & log').evaluate().isNotEmpty &&
              find.text('Preparing response …').evaluate().isEmpty) {
            break;
          }
        }
        await tester.pumpAndSettle();
        expect(find.text('Review & log'), findsOneWidget);
        expect(ProgressStore.foodIntake, isEmpty);
        await tester.ensureVisible(find.text('Review & log'));
        await tester.tap(find.text('Review & log'));
        await tester.pumpAndSettle();
        expect(find.text('Eggs · 200 g'), findsOneWidget);
        await tester.tap(find.text('Eggs · 200 g'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Amount (g)'),
          '100',
        );
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        expect(find.text('Eggs · 100 g'), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('confirm-chat-meal')));
        await tester.tap(find.byKey(const Key('confirm-chat-meal')));
        for (var i = 0; i < 30; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(ProgressStore.foodIntake, hasLength(2));
        expect(
          ProgressStore.foodNutrientsForDay(DateTime.now()).proteinG,
          15.5,
        );
        expect(find.text('Logged'), findsOneWidget);
        await tester.tap(find.byTooltip('New chat'));
        await tester.pumpAndSettle();
        expect(find.text('How can I help today?'), findsOneWidget);
        await tester.tap(find.byTooltip('Chat history'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('200g eggs and 100g spinach'));
        await tester.pumpAndSettle();
        expect(find.text('Logged'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    },
  );
}
