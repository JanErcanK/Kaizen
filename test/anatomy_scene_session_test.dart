import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/navigation/app_tab_navigation.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/widgets/anatomy_scene_session.dart';
import 'package:kaizen/widgets/anatomy_webview.dart';
import 'package:kaizen/widgets/recovery_body_map.dart';

class _Scene extends AnatomyWebView {
  int starts = 0, disposals = 0, captures = 0, mounts = 0, maxMounts = 0;
  late ValueChanged<Object?> send;
  final scripts = <String>[];
  Completer<void>? pendingInitialization;
  Completer<void>? pendingDispatch;
  String? frame;
  bool respondToCapture = true;

  @override
  Future<void> initialize({
    required Map<String, Object?> initialState,
    required Color backgroundColor,
    required ValueChanged<Object?> onMessage,
    required ValueChanged<String> onError,
    required VoidCallback onPageFinished,
  }) async {
    starts++;
    send = onMessage;
    await pendingInitialization?.future;
    onPageFinished();
    send({'type': 'loaded', 'mode': initialState['mode']});
  }

  @override
  Widget buildView() => _Surface(this);

  @override
  Future<void> runJavaScript(String script) async {
    scripts.add(script);
    if (script.contains('captureFrame(')) {
      captures++;
      final request = RegExp(
        r'captureFrame\("([^"()]+)"\)',
      ).firstMatch(script)![1];
      if (respondToCapture) {
        send({
          'type': 'transitionFrame',
          'requestId': request,
          'dataUrl': frame,
        });
      }
      await pendingDispatch?.future;
    }
  }

  @override
  Future<void> dispose() async => disposals++;
}

class _Surface extends StatefulWidget {
  const _Surface(this.scene);
  final _Scene scene;
  @override
  State<_Surface> createState() => _SurfaceState();
}

class _SurfaceState extends State<_Surface> {
  @override
  void initState() {
    super.initState();
    widget.scene.mounts++;
    if (widget.scene.mounts > widget.scene.maxMounts) {
      widget.scene.maxMounts = widget.scene.mounts;
    }
  }

  @override
  void dispose() {
    widget.scene.mounts--;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.white);
}

Future<AnatomyWebView?> _attach(
  AnatomySceneSession session,
  Object owner,
  List<Object?> messages,
) => session.attach(
  owner: owner,
  initialState: const {'mode': 'muscles'},
  backgroundColor: Colors.white,
  onMessage: messages.add,
  onError: (_) {},
  onPageFinished: () {},
);

void main() {
  test(
    'one loaded scene survives handoffs and rejects concurrent surfaces',
    () async {
      final scene = _Scene();
      final session = AnatomySceneSession(factory: () => scene);
      final first = Object(), second = Object();
      final oldMessages = <Object?>[], newMessages = <Object?>[];
      expect(await _attach(session, first, oldMessages), same(scene));
      expect(session.loadedMode, 'muscles');
      await expectLater(
        _attach(session, second, newMessages),
        throwsStateError,
      );
      session.detach(first);
      expect(await _attach(session, second, newMessages), same(scene));
      scene.send({'type': 'selected', 'id': 'muscle'});
      expect(oldMessages, hasLength(1));
      expect(newMessages, hasLength(1));
      expect(scene.starts, 1);
      expect(scene.disposals, 0);
      session.detach(first); // A late former owner cannot detach the new owner.
      scene.send({'type': 'cleared'});
      expect(newMessages, hasLength(2));
      await session.dispose();
      expect(scene.disposals, 1);
      await session.dispose();
      expect(scene.disposals, 1);
    },
  );

  test(
    'initialization can complete after a sequential owner handoff',
    () async {
      final scene = _Scene()..pendingInitialization = Completer<void>();
      final session = AnatomySceneSession(factory: () => scene);
      final first = Object(), second = Object();
      final initial = _attach(session, first, []);
      session.detach(first);
      final next = _attach(session, second, []);
      scene.pendingInitialization!.complete();
      expect(await initial, isNull);
      expect(await next, same(scene));
      expect(scene.starts, 1);
      await session.dispose();
    },
  );

  test(
    'capture failure and disposal cannot leave a pending transition',
    () async {
      final scene = _Scene();
      final session = AnatomySceneSession(factory: () => scene);
      await _attach(session, Object(), []);
      expect(await session.captureFrame(), isNull);
      await session.resume();
      expect(session.transitioning, isFalse);
      expect(scene.scripts.last, contains('paused:false'));
      scene.respondToCapture = false;
      final capture = session.captureFrame();
      await session.dispose();
      expect(await capture, isNull);
    },
  );

  test(
    'capture deadline also bounds an unresponsive native JS dispatch',
    () async {
      final scene = _Scene()
        ..respondToCapture = false
        ..pendingDispatch = Completer<void>();
      final session = AnatomySceneSession(factory: () => scene);
      await _attach(session, Object(), []);
      final clock = Stopwatch()..start();
      expect(await session.captureFrame(), isNull);
      expect(clock.elapsedMilliseconds, lessThan(1200));
      await session.resume();
      expect(session.transitioning, isFalse);
      scene.pendingDispatch!.complete();
      await session.dispose();
    },
  );

  testWidgets('home/fullscreen flies a cached frame and initializes only once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AppTabNavigation.selectedTab.value = AppTabNavigation.home;
    final storage = (await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'kaizen_scene_flight_',
      );
      await ProgressStore.init(storageRootPath: directory.path);
      return directory;
    }))!;
    final scene = _Scene();
    final session = AnatomySceneSession(factory: () => scene);
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 100, 200),
        Paint()..color = Colors.green,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(100, 200);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      scene.frame =
          'data:image/png;base64,${base64Encode(bytes!.buffer.asUint8List())}';
      image.dispose();
      picture.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 340,
            child: RecoveryBodyCard(anatomySession: session),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var cycle = 0; cycle < 3; cycle++) {
      await tester.tap(find.byKey(const ValueKey('anatomy-expand')));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      final flightFinder = find.byKey(
        const ValueKey('anatomy-transition-frame'),
      );
      expect(flightFinder, findsOneWidget);
      final image = tester.widget<RawImage>(flightFinder).image!;
      final firstRect = tester.getRect(flightFinder);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.widget<RawImage>(flightFinder).image, same(image));
      expect(
        tester.getRect(flightFinder).height,
        greaterThan(firstRect.height),
      );
      await tester.pumpAndSettle();
      expect(flightFinder, findsNothing);
      expect(image.debugDisposed, isTrue);
      final collapse = find.byTooltip('Close fullscreen');
      final flip = find.byTooltip('Switch front and back');
      final collapseRect = tester.getRect(collapse);
      final flipRect = tester.getRect(flip);
      expect(collapseRect.center.dx, flipRect.center.dx);
      // The existing sidebar places the four anatomy modes between these
      // controls. Close sits directly above the first mode, not above flip.
      final firstMode = tester.getRect(find.byTooltip('Muscles'));
      expect(firstMode.top - collapseRect.bottom, inInclusiveRange(0, 8));
      expect(flipRect.top, greaterThan(firstMode.bottom));
      expect(collapse.hitTestable(), findsOneWidget);
      expect(flip.hitTestable(), findsOneWidget);
      expect(scene.starts, 1);
      expect(scene.maxMounts, 1);
      expect(scene.disposals, 0);
      await tester.tap(collapse);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('anatomy-expand')), findsOneWidget);
      expect(scene.starts, 1);
      expect(scene.maxMounts, 1);
      expect(tester.takeException(), isNull);
    }
    expect(scene.captures, 6);
    scene.respondToCapture = false;
    await tester.tap(find.byKey(const ValueKey('anatomy-expand')));
    AppTabNavigation.selectedTab.value = AppTabNavigation.profile;
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close fullscreen'), findsNothing);
    expect(AppTabNavigation.tabSwipeEnabled.value, isTrue);
    expect(session.transitioning, isFalse);
    AppTabNavigation.selectedTab.value = AppTabNavigation.home;
    scene.respondToCapture = true;
    await tester.tap(find.byKey(const ValueKey('anatomy-expand')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(AppTabNavigation.tabSwipeEnabled.value, isTrue);
    expect(find.byKey(const ValueKey('anatomy-expand')), findsOneWidget);
    expect(scene.maxMounts, 1);
    expect(scene.starts, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    expect(scene.mounts, 0);
    await session.dispose();
    expect(scene.disposals, 1);
    await tester.runAsync(() async {
      await ProgressStore.closeForTesting();
      await storage.delete(recursive: true);
    });
  });
}
