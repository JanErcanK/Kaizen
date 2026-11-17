import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/ai_chat.dart';
import 'package:kaizen/screens/chat_screen.dart';
import 'package:kaizen/services/ai_chat_service.dart';
import 'package:kaizen/services/ai_chat_store.dart';
import 'package:kaizen/services/coach_context_service.dart';
import 'package:kaizen/services/coach_share_service.dart';
import 'package:kaizen/services/instagram_video_service.dart';
import 'package:kaizen/services/progress_store.dart';
import 'fixtures/instagram_post_fixture.dart';

Map<String, dynamic> workout({
  String type = 'save_workout',
  String target = '',
}) => {
  'type': type,
  'workoutName': 'Video routine',
  'workoutCategory': 'calisthenics',
  'durationMinutes': 12,
  'targetId': target,
  'exercises': [
    {
      'name': 'Squat',
      'sets': 3,
      'reps': 10,
      'mainGroup': 'Beine',
      'secondaryMuscles': ['Bauch'],
      'evidence': '00:03 visible squat; 3 × 10 is a suggestion.',
    },
  ],
};
http.Response reply(
  AiProvider provider,
  Map<String, dynamic>? action,
) => http.Response(
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
                    'text': jsonEncode({
                      'reply':
                          'I identified squats. Save or change this proposal?',
                      'action': action ?? {'type': 'none'},
                    }),
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
                'text': jsonEncode({
                  'reply': 'Done',
                  'action': action ?? {'type': 'none'},
                }),
              },
            ],
          },
  ),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Widget app(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('kaizen_coach_');
    await ProgressStore.init(storageRootPath: temp.path);
    CoachShareService.pending.value = [];
  });
  tearDown(() async {
    CoachShareService.pending.value = [];
    await ProgressStore.closeForTesting();
    await temp.delete(recursive: true);
  });

  test(
    'fitness access is opt-in, refreshes profile, and excludes unrelated secrets',
    () async {
      await ProgressStore.setProfileName('Ava');
      expect(CoachContextService.snapshot(), isNot(contains('Ava')));
      await ProgressStore.saveChatSettings({
        'shareFitnessContext': true,
        'privateToken': 'never-export-this',
      });
      expect(CoachContextService.snapshot(), contains('Ava'));
      expect(
        CoachContextService.snapshot(),
        isNot(contains('never-export-this')),
      );
      await ProgressStore.setProfileName('Mila');
      expect(CoachContextService.snapshot(), contains('Mila'));
      await CoachContextService.saveMemories(['I train at home']);
      expect(CoachContextService.snapshot(), contains('I train at home'));
      await CoachContextService.saveMemories([]);
      expect(
        CoachContextService.snapshot(),
        isNot(contains('I train at home')),
      );
    },
  );

  test(
    'shopping saves once, keeps the previous draft and supports updates',
    () async {
      await ProgressStore.addShoppingItem('Apples');
      await ProgressStore.saveAiShoppingList(
        sourceId: 'shopping1',
        name: 'Weekly groceries',
        items: ['200 g rice', 'Eggs'],
      );
      await ProgressStore.saveAiShoppingList(
        sourceId: 'shopping1',
        name: 'Weekly groceries',
        items: ['200 g rice', 'Eggs'],
      );
      expect(ProgressStore.shoppingDraft.items, hasLength(2));
      expect(ProgressStore.shoppingHistory, hasLength(2));
      final id = ProgressStore.shoppingDraft.id;
      await ProgressStore.saveAiShoppingList(
        sourceId: 'shopping2',
        name: 'Revised groceries',
        items: ['300 g rice'],
        targetId: id,
      );
      expect(ProgressStore.shoppingHistory, hasLength(2));
      expect(ProgressStore.shoppingDraft.name, 'Revised groceries');
      await expectLater(
        ProgressStore.saveAiShoppingList(
          sourceId: 'bad',
          name: 'Missing',
          items: ['Rice'],
          targetId: 'missing',
        ),
        throwsStateError,
      );
    },
  );

  test(
    'workout updates preserve identity and source, reject deleted targets',
    () async {
      final action = AiChatAction.fromJson(workout());
      final created = await ProgressStore.saveAiWorkout(
        sourceId: 'w1',
        name: action.workoutName,
        category: action.workoutCategory,
        exercises: action.exercises.map((e) => e.toWorkoutMap()).toList(),
        sourceUrl: 'https://www.instagram.com/reel/example/',
      );
      await ProgressStore.setCalisthenicsWorkoutExercises(
        workoutId: created.id,
        exercises: [
          {
            ...action.exercises.single.toWorkoutMap(),
            'weight': 24.0,
            'setReps': [10, 8, 6],
          },
        ],
      );
      final updated = await ProgressStore.saveAiWorkout(
        sourceId: 'w2',
        name: 'Revised',
        category: action.workoutCategory,
        exercises: action.exercises.map((e) => e.toWorkoutMap()).toList(),
        targetId: created.id,
      );
      expect(updated.id, created.id);
      final kept =
          (ProgressStore.calisthenicsWorkouts.single['exercises'] as List)
                  .single
              as Map;
      expect(kept['weight'], 24.0);
      expect(kept['setReps'], [10, 8, 6]);
      expect(ProgressStore.calisthenicsWorkouts, hasLength(1));
      expect(
        ProgressStore.calisthenicsWorkouts.single['sourceUrl'],
        contains('instagram.com'),
      );
      await expectLater(
        ProgressStore.saveAiWorkout(
          sourceId: 'bad',
          name: 'Missing',
          category: 'gym',
          exercises: action.exercises.map((e) => e.toWorkoutMap()).toList(),
          targetId: 'missing',
        ),
        throwsStateError,
      );
    },
  );

  test(
    'video proposal and samples survive reload and are deleted with chat',
    () async {
      final name = await AiChatStore.saveImage(
        Uint8List.fromList([1, 2, 3]),
        'image/jpeg',
      );
      final chat = ChatConversation(
        id: 'c',
        provider: AiProvider.openai,
        model: 'gpt-5.4-mini',
        title: 'Video',
        messages: [
          ChatMessage(
            id: 'u',
            role: 'user',
            text: 'Analyze',
            createdAt: DateTime.now(),
            frames: [ChatFrame(imageName: name, seconds: 3.2)],
            videoSource: 'Shared video',
          ),
          ChatMessage(
            id: 'a',
            role: 'assistant',
            text: 'Proposal',
            createdAt: DateTime.now(),
            proposal: AiChatAction.fromJson(workout()),
          ),
        ],
      );
      await AiChatStore.save([chat]);
      final loaded = AiChatStore.load().single;
      expect(loaded.messages.first.frames.single.seconds, 3.2);
      expect(
        loaded.messages.last.proposal!.exercises.single.evidence,
        contains('suggestion'),
      );
      expect(ProgressStore.calisthenicsWorkouts, isEmpty);
      await AiChatStore.deleteImages(loaded);
      expect(await AiChatStore.imageFile(name).exists(), isFalse);
    },
  );

  for (final provider in AiProvider.values) {
    test(
      '${provider.name} receives ordered frame labels and image payloads',
      () async {
        final name = await AiChatStore.saveImage(
          Uint8List.fromList([1, 2, 3]),
          'image/jpeg',
        );
        final service = AiChatService(
          client: MockClient((request) async {
            final body = jsonDecode(request.body);
            final content =
                (body[provider == AiProvider.openai ? 'input' : 'messages']
                            as List)
                        .first['content']
                    as List;
            expect(
              content.where(
                (c) =>
                    c['type'] ==
                    (provider == AiProvider.openai ? 'input_image' : 'image'),
              ),
              hasLength(2),
            );
            expect(
              request.body.indexOf('1.00 s'),
              lessThan(request.body.indexOf('3.00 s')),
            );
            expect(request.body, contains('NO AUDIO'));
            return reply(provider, workout());
          }),
        );
        addTearDown(service.close);
        await service.send(
          provider: provider,
          model: provider.defaultModel,
          apiKey: 'test-key',
          language: 'English',
          messages: [
            ChatMessage(
              id: 'u',
              role: 'user',
              text: 'Analyze',
              createdAt: DateTime.now(),
              frames: [
                ChatFrame(imageName: name, seconds: 1),
                ChatFrame(imageName: name, seconds: 3),
              ],
              videoSource: 'Shared video',
            ),
          ],
        );
        expect(ProgressStore.calisthenicsWorkouts, isEmpty);
      },
    );
  }

  test(
    'local data lookups paginate, supply results and have a hard round limit',
    () async {
      await ProgressStore.saveChatSettings({'shareFitnessContext': true});
      for (var i = 0; i < 25; i++) {
        await ProgressStore.createGymWorkout('Routine $i');
      }
      final page = jsonDecode(CoachContextService.query('workouts', 0));
      expect(page['records'], hasLength(20));
      expect(page['nextOffset'], 20);
      expect(
        jsonDecode(CoachContextService.query('workouts', 20))['records'],
        hasLength(5),
      );
      var calls = 0;
      final service = AiChatService(
        client: MockClient((request) async {
          calls++;
          if (calls > 1) expect(request.body, contains('Routine 0'));
          return reply(AiProvider.openai, {
            'type': 'read_fitness_data',
            'dataSection': 'workouts',
            'dataOffset': 0,
          });
        }),
      );
      addTearDown(service.close);
      final answer = await service.send(
        provider: AiProvider.openai,
        model: 'gpt-5.4-mini',
        apiKey: 'test',
        language: 'English',
        messages: [
          ChatMessage(
            id: 'u',
            role: 'user',
            text: 'My workouts?',
            createdAt: DateTime.now(),
          ),
        ],
      );
      expect(calls, 4);
      expect(answer.action, isNull);
    },
  );

  testWidgets(
    'intro waits until visible, shows gold video step and persists completion',
    (tester) async {
      tester.view.physicalSize = const Size(390, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await tester.pumpWidget(app(const ChatScreen(isActive: false)));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('coach-intro-next')), findsNothing);
        await tester.pumpWidget(app(const ChatScreen(isActive: true)));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('take a photo of your meal.'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('coach-intro-next')));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('coach-intro-next')));
        await tester.pumpAndSettle();
        expect(find.text('NEW · VIDEO WORKOUTS'), findsOneWidget);
        await tester.tap(find.byKey(const Key('coach-intro-next')));
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(CoachContextService.enabled, isTrue);
        expect(ProgressStore.chatSettings['coachIntroSeen'], isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    },
  );

  testWidgets(
    'social link creates one fresh chat with honest fallback and no provider call',
    (tester) async {
      var calls = 0;
      await tester.runAsync(() async {
        await ProgressStore.saveChatSettings({'coachIntroSeen': true});
        await tester.pumpWidget(
          app(
            ChatScreen(
              sharedInputPreparer: (_) async =>
                  throw const SharedVideoUnavailable(),
              serviceFactory: () {
                calls++;
                return AiChatService();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        CoachShareService.pending.value = [
          const CoachSharedInput(
            id: 'share-one',
            text: 'https://www.instagram.com/reel/abc/',
          ),
        ];
        for (var i = 0; i < 30; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(AiChatStore.load(), hasLength(1));
        expect(
          AiChatStore.load().single.messages.last.text,
          contains('could not be loaded publicly'),
        );
        expect(calls, 0);
        expect(CoachShareService.pending.value, isEmpty);
        CoachShareService.pending.value = [
          const CoachSharedInput(
            id: 'share-one',
            text: 'https://www.instagram.com/reel/abc/',
          ),
        ];
        for (var i = 0; i < 15; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        expect(AiChatStore.load(), hasLength(1));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    },
  );

  testWidgets(
    'video workout requires save and duplicate taps do not duplicate it',
    (tester) async {
      await tester.runAsync(() async {
        await ProgressStore.saveChatSettings({'coachIntroSeen': true});
        final user = ChatMessage(
          id: 'video_user',
          role: 'user',
          text: 'Video import',
          videoSource: 'Shared video',
          createdAt: DateTime.now(),
        );
        await AiChatStore.save([
          ChatConversation(
            id: 'chat',
            provider: AiProvider.openai,
            model: 'gpt-5.4-mini',
            title: 'Video',
            messages: [user],
          ),
        ]);
        await tester.pumpWidget(
          app(
            ChatScreen(
              keyReader: (_) async => 'test',
              serviceFactory: () => AiChatService(
                client: MockClient(
                  (_) async =>
                      reply(AiProvider.openai, workout(type: 'log_workout')),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('chat-input')),
          'Propose a workout',
        );
        await tester.tap(find.byKey(const Key('chat-send')));
        for (var i = 0; i < 40; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(ProgressStore.calisthenicsWorkouts, isEmpty);
        expect(ProgressStore.workoutEvents, isEmpty);
        await tester.ensureVisible(find.text('Save proposal'));
        await tester.tap(find.text('Save proposal'));
        for (var i = 0; i < 25; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(ProgressStore.calisthenicsWorkouts, hasLength(1));
        expect(ProgressStore.workoutEvents, isEmpty);
        expect(AiChatStore.load().single.messages.last.actionSaved, isTrue);
        expect(find.text('Saved'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    },
  );

  for (final withFile in [false, true]) {
    testWidgets(
      'shared ${withFile ? "file" : "Instagram link"} analyzes automatically and waits for approval',
      (tester) async {
        await tester.runAsync(() async {
          final preparation = Completer<List<ChatFrame>>();
          var calls = 0;
          CoachShareService.pending.value = [
            CoachSharedInput(
              id: 'auto-video',
              text: 'https://www.instagram.com/reel/abc/',
              files: withFile
                  ? [
                      {'path': '/shared/video', 'mime': 'video/mp4'},
                    ]
                  : [],
            ),
          ];
          await tester.pumpWidget(
            app(
              ChatScreen(
                keyReader: (_) async => 'test',
                sharedInputPreparer: (_) => preparation.future,
                serviceFactory: () => AiChatService(
                  client: MockClient((request) async {
                    calls++;
                    expect(request.body, contains('data:image/png;base64,'));
                    return reply(
                      AiProvider.openai,
                      workout(type: 'log_workout'),
                    );
                  }),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(find.byKey(const Key('coach-intro-next')), findsNothing);
          expect(
            find.text('Loading and preparing shared content …'),
            findsOneWidget,
          );
          expect(
            find.textContaining('https://www.instagram.com/reel/abc/'),
            findsWidgets,
          );
          final name = await AiChatStore.saveImage(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aM1sAAAAASUVORK5CYII=',
            ),
            'image/png',
          );
          preparation.complete([ChatFrame(imageName: name, seconds: 1)]);
          for (var i = 0; i < 40; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            await tester.pump();
          }
          await tester.pumpAndSettle();
          expect(calls, 1);
          expect(CoachShareService.pending.value, isEmpty);
          expect(ProgressStore.calisthenicsWorkouts, isEmpty);
          expect(ProgressStore.workoutEvents, isEmpty);
          expect(
            AiChatStore.load().single.messages.last.proposal?.type,
            AiChatActionType.saveWorkout,
          );
          await tester.ensureVisible(find.text('Save proposal'));
          await tester.tap(find.text('Save proposal'));
          await tester.tap(find.text('Save proposal'));
          for (var i = 0; i < 25; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            await tester.pump();
          }
          expect(ProgressStore.calisthenicsWorkouts, hasLength(1));
          expect(ProgressStore.workoutEvents, isEmpty);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        });
      },
    );
  }

  testWidgets(
    'carousel downloads, decodes, submits nine ordered images and saves only on approval',
    (tester) async {
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawColor(Colors.green, BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(20, 20);
        final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
        final png = encoded!.buffer.asUint8List();
        image.dispose();
        picture.dispose();
        var calls = 0;
        final imports = await temp.createTemp('imports_');
        CoachShareService.pending.value = [
          const CoachSharedInput(id: 'carousel', text: instagramPostUrl),
        ];
        // Decode native image buffers outside the widget scheduler's fake zone.
        final prepared = await CoachShareService.prepare(
          CoachShareService.pending.value.single,
          temporaryDirectory: imports,
          instagram: InstagramVideoService(
            client: MockClient((request) async {
              if (request.url.path.endsWith('/embed/')) {
                return http.Response(instagramEmbed(), 200);
              }
              if (request.url.host == 'www.instagram.com') {
                return http.Response(instagramPostPage(), 200);
              }
              return http.Response.bytes(
                png,
                200,
                headers: {'content-type': 'image/png'},
              );
            }),
          ),
        );
        await tester.pumpWidget(
          app(
            ChatScreen(
              keyReader: (_) async => 'test',
              sharedInputPreparer: (_) async => prepared,
              serviceFactory: () => AiChatService(
                client: MockClient((request) async {
                  calls++;
                  final input = jsonDecode(request.body)['input'] as List;
                  final content = input.first['content'] as List;
                  expect(
                    content.where((c) => c['type'] == 'input_image'),
                    hasLength(9),
                  );
                  for (var i = 1; i <= 9; i++) {
                    expect(request.body, contains('Slide $i'));
                  }
                  expect(
                    request.body.indexOf('Slide 6'),
                    lessThan(request.body.indexOf('Slide 9')),
                  );
                  expect(
                    request.body,
                    contains('still image (no video timestamp)'),
                  );
                  return reply(AiProvider.openai, workout());
                }),
              ),
            ),
          ),
        );
        for (var i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
          if (AiChatStore.load().firstOrNull?.messages.last.proposal != null &&
              find.byType(CircularProgressIndicator).evaluate().isEmpty) {
            break;
          }
        }
        expect(
          calls,
          1,
          reason:
              'Pending: ${CoachShareService.pending.value.length}; chats: ${AiChatStore.load().length}',
        );
        expect(
          AiChatStore.load().single.messages.last.proposal,
          isNotNull,
          reason: AiChatStore.load().single.messages
              .map((m) => '${m.role}: ${m.text}; failed=${m.failed}')
              .join('\n'),
        );
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(find.text('9 images · in post order'), findsOneWidget);
        final chat = AiChatStore.load().single;
        expect(
          chat.messages.first.frames.map((f) => f.slideNumber),
          List.generate(9, (i) => i + 1),
        );
        expect(
          chat.messages.first.frames.every((f) => f.seconds == -1),
          isTrue,
        );
        expect(await imports.list().toList(), isEmpty);
        expect(ProgressStore.calisthenicsWorkouts, isEmpty);
        expect(ProgressStore.workoutEvents, isEmpty);
        await tester.ensureVisible(find.text('Save proposal'));
        await tester.tap(find.text('Save proposal'));
        for (var i = 0; i < 25; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        expect(ProgressStore.calisthenicsWorkouts, hasLength(1));
        expect(ProgressStore.workoutEvents, isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    },
  );
}
