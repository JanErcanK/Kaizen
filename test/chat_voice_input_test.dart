import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/widgets/chat_voice_input.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class FakeSpeech extends SpeechToText {
  FakeSpeech() : super.withMethodChannel();
  SpeechStatusListener? status;
  SpeechErrorListener? error;
  SpeechResultListener? result;
  SpeechListenOptions? options;
  bool available = true;
  int cancellations = 0;
  Completer<bool>? permission;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    status = onStatus;
    error = onError;
    return permission == null ? available : permission!.future;
  }

  @override
  Future<List<LocaleName>> locales() async => [LocaleName('en_US', 'English')];

  @override
  Future<void> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    cancelOnError = false,
    partialResults = true,
    onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    result = onResult;
    options = listenOptions;
    status?.call(SpeechToText.listeningStatus);
  }

  void words(String text) => result?.call(
    SpeechRecognitionResult([SpeechRecognitionWords(text, null, 1)], 0),
  );

  @override
  Future<void> stop() async {
    words('final words');
    status?.call(SpeechToText.doneStatus);
  }

  @override
  Future<void> cancel() async {
    cancellations++;
  }
}

void main() {
  late FakeSpeech speech;
  late TextEditingController input;
  late List<bool> activity;
  late List<String> errors;

  setUp(() {
    speech = FakeSpeech();
    input = TextEditingController(text: 'Existing draft');
    activity = [];
    errors = [];
  });
  tearDown(() => input.dispose());

  Widget host({bool active = true}) => MaterialApp(
    home: Scaffold(
      body: ChatVoiceInput(
        controller: input,
        enabled: true,
        isActive: active,
        recognizer: speech,
        onActiveChanged: activity.add,
        onError: errors.add,
      ),
    ),
  );

  Future<void> start(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.byKey(const Key('chat-voice')));
    await tester.pump();
  }

  testWidgets(
    'partial results replace each other and final words stay in draft',
    (tester) async {
      await start(tester);
      expect(speech.options?.localeId, 'en_US');
      speech.words('one');
      speech.words('one two');
      expect(input.text, 'Existing draft one two');
      await tester.tap(find.byKey(const Key('chat-voice')));
      await tester.pump();
      expect(input.text, 'Existing draft final words');
      expect(activity, [true, false]);
      expect(errors, isEmpty);
    },
  );

  testWidgets('discard restores draft and ignores late recognition', (
    tester,
  ) async {
    await start(tester);
    speech.words('discard this');
    await tester.tap(find.byKey(const Key('chat-voice-cancel')));
    await tester.pump();
    speech.words('late result');
    expect(input.text, 'Existing draft');
    expect(speech.cancellations, 1);
    expect(activity, [true, false]);
  });

  testWidgets('denied permission restores idle controls', (tester) async {
    speech.available = false;
    await start(tester);
    expect(errors.single, contains('permissions'));
    expect(activity, [true, false]);
    expect(input.text, 'Existing draft');
  });

  testWidgets('recognition error retains text and allows retry', (
    tester,
  ) async {
    await start(tester);
    speech.words('keep this');
    speech.error!(SpeechRecognitionError('error_network', true));
    await tester.pump();
    expect(input.text, 'Existing draft keep this');
    expect(errors.single, contains('connection'));
    expect(activity, [true, false]);
  });

  testWidgets('tab change stops microphone without losing recognized text', (
    tester,
  ) async {
    await start(tester);
    speech.words('keep this');
    await tester.pumpWidget(host(active: false));
    await tester.pump();
    speech.words('late result');
    expect(input.text, 'Existing draft keep this');
    expect(speech.cancellations, 1);
    expect(activity, [true, false]);
  });

  testWidgets('cancel during permission dialog cannot start recording later', (
    tester,
  ) async {
    speech.permission = Completer<bool>();
    await start(tester);
    await tester.tap(find.byKey(const Key('chat-voice-cancel')));
    speech.permission!.complete(true);
    await tester.pump();
    expect(speech.options, isNull);
    expect(activity, [true, false]);
  });
}
