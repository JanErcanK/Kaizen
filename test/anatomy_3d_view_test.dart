import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/body_map_view_mode.dart';
import 'package:kaizen/models/body_muscle_group.dart';
import 'package:kaizen/services/anatomy_catalog.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/widgets/anatomy_3d_view.dart';
import 'package:kaizen/widgets/anatomy_webview.dart';
import 'package:kaizen/widgets/body_map_tab_intro_dialog.dart';
import 'package:kaizen/widgets/muscle_exercise_popup.dart';
import 'package:kaizen/widgets/organ_detail_card.dart';

class _FakeView implements AnatomyWebView {
  final scripts = <String>[];
  late ValueChanged<Object?> send;
  Map<String, Object?>? initial;
  int starts = 0;
  int disposals = 0;
  int pointers = 0;
  Completer<void>? pending;

  @override
  Future<void> initialize({
    required Map<String, Object?> initialState,
    required Color backgroundColor,
    required ValueChanged<Object?> onMessage,
    required ValueChanged<String> onError,
    required VoidCallback onPageFinished,
  }) async {
    starts++;
    initial = initialState;
    send = onMessage;
    await pending?.future;
    onPageFinished();
  }

  @override
  Widget buildView() => Listener(
    behavior: HitTestBehavior.opaque,
    onPointerDown: (_) => pointers++,
    child: const SizedBox.expand(key: ValueKey('fake-native-view')),
  );
  @override
  Future<void> runJavaScript(String script) async {
    scripts.add(script);
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

const _snapshot = MuscleRecoverySnapshot(
  recovery: {BodyMuscleGroup.abs: MuscleRecoveryHighlight.recent},
  afterburn: {BodyMuscleGroup.chest: MuscleAfterburnState(active: true)},
  trainedThisWeek: {BodyMuscleGroup.legs},
);

Widget _host(
  _FakeView view, {
  bool expanded = false,
  BodyMapViewMode mode = BodyMapViewMode.recovery,
  AnatomyCatalog catalog = const AnatomyCatalog.empty(),
  Anatomy3DController? controller,
  Locale? locale,
  ValueChanged<bool>? onDetailsChanged,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Anatomy3DView(
      mode: mode,
      expanded: expanded,
      snapshot: _snapshot,
      catalog: catalog,
      controller: controller,
      onDetailsChanged: onDetailsChanged,
      webViewFactory: () => view,
    ),
  ),
);

void main() {
  late Directory storage;
  setUpAll(() async {
    storage = await Directory.systemTemp.createTemp('kaizen_atlas_test_');
    await ProgressStore.init(storageRootPath: storage.path);
  });
  tearDownAll(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });

  for (final pick in [
    (
      mode: BodyMapViewMode.recovery,
      tissue: 'muscle',
      id: 'rectus_abdominis.l',
      card: 'anatomy-muscle-card',
    ),
    (
      mode: BodyMapViewMode.skeleton,
      tissue: 'bone',
      id: 'bone.femur.l',
      card: 'anatomy-structure-card',
    ),
    (
      mode: BodyMapViewMode.connective,
      tissue: 'ligament',
      id: 'ligament.acl.l',
      card: 'anatomy-structure-card',
    ),
    (
      mode: BodyMapViewMode.organs,
      tissue: 'organ',
      id: 'organ.lung.l',
      card: 'anatomy-organ-card',
    ),
  ]) {
    testWidgets(
      '${pick.mode.name} card holds, moves, clamps and keeps its controls',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final catalog = (await tester.runAsync(AnatomyCatalog.load))!;
        final view = _FakeView();
        var detailsVisible = false;
        Widget host() => _host(
          view,
          expanded: true,
          mode: pick.mode,
          catalog: catalog,
          onDetailsChanged: (visible) => detailsVisible = visible,
        );
        final selection = {
          'type': 'selected',
          'tissue': pick.tissue,
          'id': pick.id,
          'trainingSegment': 'abs-upper',
          'organId': 'lung.l',
          'upperBody': true,
        };
        await tester.pumpWidget(host());
        await tester.pump();
        view.send({'type': 'loaded', 'mode': pick.mode.anatomyMode});
        view.send(selection);
        await tester.pumpAndSettle();
        expect(detailsVisible, isTrue);
        final card = find.byKey(ValueKey(pick.card));
        final initial = tester.getRect(card);
        Offset handle() => tester.getTopLeft(card) + const Offset(40, 22);
        Future<void> holdAndMove(Offset delta, {Offset? from}) async {
          final before = tester.getRect(card);
          final gesture = await tester.startGesture(from ?? handle());
          await tester.pump(const Duration(milliseconds: 600));
          expect(
            tester.getRect(card),
            before,
            reason: 'Holding must not make the card jump',
          );
          await gesture.moveBy(delta);
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();
        }

        await tester.dragFrom(handle(), const Offset(15, -50));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(card),
          initial,
          reason: 'A quick swipe must not reposition the card',
        );
        await holdAndMove(const Offset(24, -90));
        final moved = tester.getRect(card);
        expect(moved.top, closeTo(initial.top - 90, .01));
        expect(moved.size, initial.size);
        expect(
          view.pointers,
          0,
          reason: 'Moving the card must not rotate the native model',
        );
        await tester.pumpWidget(host());
        await tester.pumpAndSettle();
        expect(
          tester.getRect(card),
          moved,
          reason: 'Data rebuilds preserve the chosen position',
        );

        if (pick.tissue == 'organ' || pick.tissue == 'muscle') {
          final scrolling = tester
              .stateList<ScrollableState>(
                find.descendant(of: card, matching: find.byType(Scrollable)),
              )
              .firstWhere((state) => state.position.axis == Axis.vertical);
          final oldOffset = scrolling.position.pixels;
          await tester.dragFrom(
            tester.getBottomLeft(card) + const Offset(50, -55),
            const Offset(0, -65),
          );
          await tester.pumpAndSettle();
          expect(scrolling.position.pixels, greaterThan(oldOffset));
          expect(
            tester.getRect(card),
            moved,
            reason: 'Content scrolls without moving its card',
          );
          final scrolled = scrolling.position.pixels;
          await holdAndMove(
            const Offset(0, -25),
            from: tester.getTopLeft(card) + const Offset(20, 180),
          );
          expect(tester.getRect(card).top, closeTo(moved.top - 25, .01));
          expect(
            scrolling.position.pixels,
            scrolled,
            reason: 'Holding the content also moves the card without scrolling',
          );
        }

        await holdAndMove(const Offset(-2000, -2000));
        final offscreen = tester.getRect(card);
        expect(offscreen.left, closeTo(-offscreen.width / 2, .01));
        final areaTop = pick.tissue == 'muscle' ? 72.0 : 0.0;
        expect(offscreen.top, closeTo(areaTop - offscreen.height / 2, .01));
        // Any visible content can be held to recover an offscreen card.
        await holdAndMove(
          const Offset(2000, 2000),
          from: Offset(20, areaTop + 20),
        );
        final bottomRight = tester.getRect(card);
        expect(bottomRight.left, closeTo(390 - bottomRight.width / 2, .01));
        expect(bottomRight.top, closeTo(844 - bottomRight.height / 2, .01));
        await holdAndMove(
          const Offset(-200, -400),
          from: bottomRight.topLeft + const Offset(20, 20),
        );
        // Shrinking and restoring keeps the same selected structure.
        await tester.tap(find.byTooltip('Collapse'));
        await tester.pumpAndSettle();
        expect(tester.getRect(card).height, lessThan(initial.height));
        await tester.tap(find.byTooltip('Expand'));
        await tester.pumpAndSettle();
        expect(tester.getRect(card).height, closeTo(initial.height, .01));
        tester.view.physicalSize = const Size(844, 390);
        await tester.pumpAndSettle();
        final resized = tester.getRect(card);
        expect(resized.left, greaterThanOrEqualTo(-resized.width / 2));
        expect(resized.top, greaterThanOrEqualTo(areaTop - resized.height / 2));
        expect(resized.left, lessThanOrEqualTo(844 - resized.width / 2));
        expect(resized.top, lessThanOrEqualTo(390 - resized.height / 2));
        expect(find.byTooltip('Close').hitTestable(), findsOneWidget);
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(detailsVisible, isFalse);
        expect(card, findsNothing);
        tester.view.physicalSize = const Size(390, 844);
        await tester.pump();
        view.send(selection);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(card),
          initial,
          reason: 'Reopening starts at the original dock',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('3D lung and gut picks immediately expose food actions that save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog = (await tester.runAsync(AnatomyCatalog.load))!;
    await tester.runAsync(() async {
      await ProgressStore.setUseGerman(true);
      await ProgressStore.createFoodDish('Organ-Testgericht');
    });
    final view = _FakeView();
    var organDetailsVisible = false;
    await tester.pumpWidget(
      _host(
        view,
        expanded: true,
        mode: BodyMapViewMode.organs,
        catalog: catalog,
        locale: const Locale('de'),
        onDetailsChanged: (visible) => organDetailsVisible = visible,
      ),
    );
    await tester.pump();
    view.send({'type': 'loaded', 'mode': 'organs'});
    await tester.pumpAndSettle();
    for (final entry in {
      'lung.l': 'Brokkoli',
      'large_intestine': 'Griechischer Joghurt',
    }.entries) {
      view.send({
        'type': 'selected',
        'tissue': 'organ',
        'id': 'organ.${entry.key}',
        'organId': entry.key,
        'upperBody': entry.key.startsWith('lung'),
      });
      await tester.pumpAndSettle();
      expect(organDetailsVisible, isTrue);
      expect(find.text('Was du tun kannst').hitTestable(), findsOneWidget);
      final food = find.byKey(ValueKey('organ-food-${entry.value}'));
      final shopping = find.descendant(
        of: food,
        matching: find.widgetWithText(OutlinedButton, 'Zettel'),
      );
      final today = find.descendant(
        of: food,
        matching: find.widgetWithText(OutlinedButton, 'Heute'),
      );
      final dish = find.descendant(
        of: food,
        matching: find.widgetWithText(OutlinedButton, 'Gericht'),
      );
      for (final action in [shopping, today, dish]) {
        expect(
          action.hitTestable(),
          findsOneWidget,
          reason:
              'All food destinations must be visible immediately after the organ pick',
        );
      }
      final previousShopping = ProgressStore.shoppingDraft.items.length;
      await tester.runAsync(() async {
        await tester.tap(shopping);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(ProgressStore.shoppingDraft.items.length, previousShopping + 1);
      expect(ProgressStore.shoppingDraft.items.last.text, entry.value);
      await tester.tap(today);
      await tester.pumpAndSettle();
      final confirmToday = find.widgetWithText(FilledButton, 'Heute essen');
      await tester.ensureVisible(confirmToday);
      final previousIntake = ProgressStore.foodIntake.length;
      await tester.runAsync(() async {
        await tester.tap(confirmToday);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(ProgressStore.foodIntake.length, previousIntake + 1);
      await tester.tap(dish);
      await tester.pumpAndSettle();
      final confirmDish = find.widgetWithText(FilledButton, 'Zum Gericht');
      await tester.ensureVisible(confirmDish);
      await tester.tap(confirmDish);
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('Organ-Testgericht'),
        find.byType(ListView).last,
        const Offset(0, -240),
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('Organ-Testgericht'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      // The picker route completes during the pump, then persistence starts.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      final items =
          ProgressStore.foodDishes.firstWhere(
                (d) => d['name'] == 'Organ-Testgericht',
              )['items']
              as List;
      expect(items.any((item) => item['foodName'] == entry.value), isTrue);
      if (entry.key == 'large_intestine') {
        await tester.ensureVisible(find.text('Chiasamen'));
        expect(find.text('Chiasamen').hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    expect(organDetailsVisible, isFalse);
    expect(find.byKey(const ValueKey('anatomy-organ-card')), findsNothing);
    expect(view.scripts.last, contains('clearSelection'));
    await tester.runAsync(() => ProgressStore.setUseGerman(false));
  });
  testWidgets('organ actions remain reachable with large text in both themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final light in [true, false]) {
      await tester.runAsync(() => ProgressStore.setUseLightTheme(light));
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(light ? 'de' : 'en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: OrganDetailCard(
                organId: 'large_intestine',
                title: 'Darm / Intestines',
                description: 'Anatomy',
                latinName: 'Intestinum',
                height: 400,
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final food = find.byKey(const ValueKey('organ-food-Chiasamen'));
      final action = find.descendant(
        of: food,
        matching: find.widgetWithText(
          OutlinedButton,
          light ? 'Gericht' : 'Dish',
        ),
      );
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(action.hitTestable(), findsOneWidget);
      expect(
        find.byTooltip(light ? 'Schließen' : 'Close').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
    await tester.runAsync(() => ProgressStore.setUseLightTheme(true));
  });
  testWidgets(
    'cards dock opposite the pick and leave native gestures available',
    (tester) async {
      final view = _FakeView();
      await tester.pumpWidget(_host(view, expanded: true));
      await tester.pump();
      view.send({'type': 'loaded', 'mode': 'muscles'});
      view.send({
        'type': 'selected',
        'tissue': 'muscle',
        'id': 'rectus_abdominis.l',
        'trainingSegment': 'abs-upper',
        'upperBody': true,
      });
      await tester.pumpAndSettle();
      var card = tester.getRect(
        find.byKey(const ValueKey('anatomy-muscle-card')),
      );
      expect(card.top, greaterThan(300));
      await tester.dragFrom(const Offset(400, 180), const Offset(70, 0));
      expect(
        view.pointers,
        1,
        reason: 'Dragging outside the card reaches the native model',
      );
      expect(find.byType(MuscleExercisePopup), findsOneWidget);
      view.send({
        'type': 'selected',
        'tissue': 'muscle',
        'id': 'rectus_femoris.l',
        'trainingSegment': 'quads',
        'upperBody': false,
      });
      await tester.pumpAndSettle();
      card = tester.getRect(find.byKey(const ValueKey('anatomy-muscle-card')));
      expect(card.top, lessThan(100));
      await tester.tapAt(const Offset(400, 520));
      expect(view.pointers, 2);
      await tester.pumpWidget(
        _host(view, expanded: true, mode: BodyMapViewMode.skeleton),
      );
      await tester.pump();
      view.send({'type': 'loaded', 'mode': 'skeleton'});
      view.send({
        'type': 'selected',
        'tissue': 'bone',
        'id': 'bone.femur.l',
        'upperBody': false,
      });
      await tester.pumpAndSettle();
      expect(
        tester
            .getRect(find.byKey(const ValueKey('anatomy-structure-card')))
            .top,
        84,
      );
      expect(view.initial?['organHealth'], isNotEmpty);
    },
  );

  testWidgets('toolbar controller turns only the active fullscreen view', (
    tester,
  ) async {
    final view = _FakeView();
    final controller = Anatomy3DController();
    await tester.pumpWidget(_host(view, controller: controller));
    await tester.pump();
    controller.toggleFrontBack();
    expect(view.scripts.where((s) => s.contains('toggleFrontBack')), isEmpty);
    await tester.pumpWidget(
      _host(view, expanded: true, controller: controller),
    );
    await tester.pump();
    view.send({'type': 'loaded', 'mode': 'muscles'});
    await tester.pump();
    expect(find.byIcon(Icons.center_focus_strong_rounded), findsNothing);
    expect(find.byIcon(Icons.person_outline_rounded), findsNothing);
    controller.toggleFrontBack();
    expect(
      view.scripts.where((s) => s.contains('toggleFrontBack')),
      hasLength(1),
    );
    await tester.pumpWidget(const SizedBox());
    controller.toggleFrontBack();
    expect(
      view.scripts.where((s) => s.contains('toggleFrontBack')),
      hasLength(1),
    );
    controller.dispose();
  });
  testWidgets('syncs data, ignores compact picks, and avoids loaded feedback', (
    tester,
  ) async {
    final view = _FakeView();
    await tester.pumpWidget(_host(view));
    await tester.pump();
    expect(view.starts, 1);
    expect(view.initial?['mode'], 'muscles');
    expect(view.initial?['recovery'], {'abs': 'recent'});
    expect(view.initial?['afterburn'], ['chest']);
    expect(view.initial?['trained'], ['legs']);
    final scriptsBeforeLoaded = view.scripts.length;
    view.send(jsonEncode({'type': 'loaded', 'mode': 'muscles'}));
    await tester.pump();
    expect(view.scripts.length, scriptsBeforeLoaded);
    view.send({
      'type': 'selected',
      'tissue': 'muscle',
      'id': 'rectus_abdominis.l',
      'trainingSegment': 'abs-upper',
    });
    await tester.pump();
    expect(find.byType(MuscleExercisePopup), findsNothing);
    await tester.pumpWidget(_host(view, expanded: true));
    await tester.pump();
    expect(view.starts, 1);
    view.send({
      'type': 'selected',
      'tissue': 'muscle',
      'id': 'rectus_abdominis.l',
      'name': 'Upper abdominal muscles',
      'trainingSegment': 'abs-upper',
    });
    await tester.pumpAndSettle();
    expect(find.byType(MuscleExercisePopup), findsOneWidget);
    expect(
      tester
          .widget<MuscleExercisePopup>(find.byType(MuscleExercisePopup))
          .segment
          .slug,
      'abs-upper',
    );
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(view.scripts.last, contains('clearSelection'));
    await tester.pumpWidget(
      _host(view, expanded: true, mode: BodyMapViewMode.skeleton),
    );
    await tester.pump();
    expect(view.starts, 1);
    view.send({'type': 'loaded', 'mode': 'skeleton'});
    view.send({
      'type': 'selected',
      'tissue': 'muscle',
      'id': 'wrong',
      'name': 'Forbidden muscle',
    });
    await tester.pump();
    expect(find.text('Forbidden muscle'), findsNothing);
    view.send({
      'type': 'selected',
      'tissue': 'bone',
      'id': 'bone.femur.l',
      'name': 'Femur',
      'nameLatin': 'Os femoris',
    });
    await tester.pump();
    expect(find.text('Femur'), findsOneWidget);
    expect(find.text('(Os femoris)'), findsOneWidget);
    await tester.pumpWidget(
      _host(view, expanded: true, mode: BodyMapViewMode.connective),
    );
    await tester.pump();
    expect(find.text('Femur'), findsNothing);
    expect(view.scripts.last, contains('"mode":"connective"'));
    view.send({'type': 'loaded', 'mode': 'connective'});
    view.send({
      'type': 'selected',
      'tissue': 'ligament',
      'id': 'ligament.test',
      'name': 'Ligament detail',
    });
    await tester.pump();
    expect(find.text('Ligament detail'), findsOneWidget);
    await tester.pumpWidget(
      _host(view, expanded: true, mode: BodyMapViewMode.organs),
    );
    await tester.pump();
    view.send({'type': 'loaded', 'mode': 'organs'});
    view.send({
      'type': 'selected',
      'tissue': 'organ',
      'id': 'organ.heart',
      'name': 'Heart',
    });
    await tester.pump();
    expect(find.text('Heart'), findsOneWidget);
    view.send({'type': 'cleared'});
    await tester.pump();
    expect(find.text('Heart'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    expect(view.disposals, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muscle card uses bilateral region title below the host header', (
    tester,
  ) async {
    final catalog = AnatomyCatalog.fromJson({
      'schemaVersion': 1,
      'muscles': <String, dynamic>{},
      'structures': <String, dynamic>{},
      'segments': {
        'abs-upper': {
          'canonicalGroup': 'abs',
          'nameDe': 'Obere Bauchregion',
          'nameEn': 'Upper abdominal region',
          'descriptionDe': 'Trainingsregion',
          'descriptionEn': 'Training region',
        },
      },
    });
    final view = _FakeView();
    await tester.pumpWidget(_host(view, expanded: true, catalog: catalog));
    await tester.pump();
    view.send({'type': 'loaded', 'mode': 'muscles'});
    view.send({
      'type': 'selected',
      'tissue': 'muscle',
      'id': 'rectus_abdominis.r',
      'trainingSegment': 'abs-upper',
      'name': 'Long right-sided atlas name',
    });
    await tester.pumpAndSettle();
    expect(find.text('Upper abdominal region'), findsOneWidget);
    expect(find.text('Long right-sided atlas name'), findsNothing);
    expect(
      tester.getTopLeft(find.byType(MuscleExercisePopup)).dy,
      greaterThanOrEqualTo(72),
    );
  });

  testWidgets(
    'anatomy information shows tips instead of the relocated license',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => BodyMapTabIntroDialog.show(
                  context,
                  BodyMapViewMode.connective,
                ),
                child: const Text('Info'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Info'));
      await tester.pumpAndSettle();
      expect(find.text('10 practical tips for everyday life'), findsOneWidget);
      expect(find.byKey(const ValueKey('anatomy-tips-list')), findsOneWidget);
      expect(find.textContaining('Z-Anatomy / BodyParts3D'), findsNothing);
      expect(find.text('Sources & license'), findsNothing);
      expect(find.text('Close'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('retiring initialization cannot update a removed view', (
    tester,
  ) async {
    final view = _FakeView()..pending = Completer<void>();
    await tester.pumpWidget(_host(view));
    await tester.pumpWidget(const SizedBox());
    expect(view.disposals, 1);
    view.pending!.complete();
    view.send({'type': 'loaded', 'mode': 'muscles'});
    await tester.pump();
    expect(view.scripts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'default adapter uses a safe non-native fallback in widget tests',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Anatomy3DView(
              mode: BodyMapViewMode.recovery,
              expanded: false,
              snapshot: _snapshot,
              catalog: AnatomyCatalog.empty(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('3D view is unavailable on this device'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
