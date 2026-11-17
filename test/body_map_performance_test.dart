import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/body_map_view_mode.dart';
import 'package:kaizen/models/body_muscle_group.dart';
import 'package:kaizen/navigation/app_tab_navigation.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/widgets/cached_body_paint.dart';
import 'package:kaizen/widgets/anatomy_3d_view.dart';
import 'package:kaizen/widgets/body_overlay_painter.dart';
import 'package:kaizen/widgets/muscle_exercise_popup.dart';
import 'package:kaizen/widgets/recovery_body_map.dart';

class _CountingPainter extends CustomPainter {
  _CountingPainter(this.onPaint, {this.color = Colors.green});
  final VoidCallback onPaint;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    onPaint();
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CountingPainter oldDelegate) =>
      oldDelegate.color != color;
}

void main() {
  testWidgets('zoom reuses a bounded image and changes invalidate it', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1440, 3000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final transform = TransformationController();
    addTearDown(transform.dispose);
    var paints = 0;

    Widget host(Color color) => MaterialApp(
      home: InteractiveViewer(
        transformationController: transform,
        maxScale: 4.5,
        child: CachedBodyPaint(
          painter: _CountingPainter(() => paints++, color: color),
        ),
      ),
    );
    await tester.pumpWidget(host(Colors.green));
    final initial = tester.widget<RawImage>(find.byType(RawImage)).image!;
    expect(initial.width, lessThanOrEqualTo(2048));
    expect(initial.height, lessThanOrEqualTo(2048));
    expect(initial.width * initial.height, lessThanOrEqualTo(2004096));
    for (var i = 0; i < 30; i++) {
      transform.value = Matrix4.diagonal3Values(1 + i / 10, 1 + i / 10, 1);
      await tester.pump();
    }
    expect(paints, 1);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, same(initial));
    await tester.pumpWidget(host(Colors.green));
    expect(paints, 1);
    await tester.pumpWidget(host(Colors.red));
    expect(paints, 2);
    expect(initial.debugDisposed, isTrue);
    final replacement = tester.widget<RawImage>(find.byType(RawImage)).image!;
    await tester.pumpWidget(const SizedBox());
    expect(replacement.debugDisposed, isTrue);
    expect(tester.takeException(), isNull);
  });

  test('equivalent recovery snapshots reuse the rendered figure', () {
    BodyMuscleMapPainter painter(MuscleRecoveryHighlight state) =>
        BodyMuscleMapPainter(
          front: true,
          mode: BodyMapViewMode.recovery,
          snapshot: MuscleRecoverySnapshot(
            recovery: {BodyMuscleGroup.chest: state},
            afterburn: const {},
            trainedThisWeek: const {},
          ),
        );
    final previous = painter(MuscleRecoveryHighlight.none);
    expect(
      painter(MuscleRecoveryHighlight.none).shouldRepaint(previous),
      isFalse,
    );
    expect(
      painter(MuscleRecoveryHighlight.recent).shouldRepaint(previous),
      isTrue,
    );
  });

  group('Android-sized body map', () {
    late Directory storage;
    setUpAll(() async {
      storage = await Directory.systemTemp.createTemp('kaizen_body_map_test_');
      await ProgressStore.init(storageRootPath: storage.path);
    });
    tearDownAll(() async {
      await ProgressStore.closeForTesting();
      await storage.delete(recursive: true);
    });

    testWidgets('repeated expand, zoom, tabs and system back keep the app open', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.padding = const FakeViewPadding(top: 96, bottom: 72);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(height: 340, child: RecoveryBodyCard()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var cycle = 0; cycle < 3; cycle++) {
        await tester.tap(find.byType(CachedBodyPaint).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 16));
        final image = tester
            .widget<RawImage>(find.byType(RawImage).first)
            .image;
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(
          tester.widget<RawImage>(find.byType(RawImage).first).image,
          same(image),
        );
        await tester.pumpAndSettle();
        final expandedRect = tester.getRect(find.byType(Anatomy3DView).first);
        expect(find.byType(Anatomy3DView), findsOneWidget);
        expect(expandedRect.top, greaterThanOrEqualTo(32));
        expect(expandedRect.bottom, lessThanOrEqualTo(820));
        final flip = find.byTooltip('Switch front and back');
        final info = find.byTooltip('Anatomy tips');
        expect(flip, findsOneWidget);
        expect(info, findsOneWidget);
        // The sidebar keeps its layout slot while the detail card is open.
        // Its hidden controls must not intercept taps on the card.
        tester
            .widget<Anatomy3DView>(find.byType(Anatomy3DView))
            .onDetailsChanged!(true);
        await tester.pumpAndSettle();
        expect(flip.hitTestable(), findsNothing);
        expect(info.hitTestable(), findsNothing);
        tester
            .widget<Anatomy3DView>(find.byType(Anatomy3DView))
            .onDetailsChanged!(false);
        await tester.pumpAndSettle();
        expect(flip, findsOneWidget);
        expect(info, findsOneWidget);
        expect(tester.getCenter(flip).dy, lessThan(tester.getCenter(info).dy));
        expect(
          tester.getCenter(find.byTooltip('Muscles')).dy,
          lessThan(tester.getCenter(flip).dy),
        );
        expect(find.byIcon(Icons.center_focus_strong_rounded), findsNothing);
        final viewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer).first,
        );
        viewer.transformationController!.value = Matrix4.diagonal3Values(
          4.5,
          4.5,
          1,
        );
        await tester.pump();
        expect(
          tester.widget<RawImage>(find.byType(RawImage).first).image,
          same(image),
        );
        viewer.transformationController!.value = Matrix4.identity();
        await tester.pump();
        final bodyFinder = find.byType(CachedBodyPaint).first;
        final paths = transformedMusclePaths(
          tester.getSize(bodyFinder),
          front: true,
        );
        final chest = paths['chest']!.first.getBounds().center;
        await tester.tapAt(tester.getTopLeft(bodyFinder) + chest);
        await tester.pumpAndSettle();
        expect(find.byType(MuscleExercisePopup), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(MuscleExercisePopup), findsNothing);
        await tester.tap(find.bySemanticsLabel('Organs'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.bySemanticsLabel('Muscles'));
        await tester.pumpAndSettle();
        // Exercise dialogs live above the figure in its nested navigator.
        final bodyContext = tester.element(find.byType(CachedBodyPaint).first);
        showDialog<void>(
          context: bodyContext,
          useRootNavigator: false,
          builder: (_) => const AlertDialog(title: Text('Exercise options')),
        );
        await tester.pumpAndSettle();
        expect(await navigator.currentState!.maybePop(), isTrue);
        await tester.pumpAndSettle();
        expect(find.text('Exercise options'), findsNothing);
        expect(AppTabNavigation.tabSwipeEnabled.value, isFalse);
        // This targets the root route, like Android's system back dispatcher.
        expect(await navigator.currentState!.maybePop(), isTrue);
        // Repeated back while reversing must not restart/strand the transition.
        expect(await navigator.currentState!.maybePop(), isTrue);
        await tester.pumpAndSettle();
        expect(find.byType(RecoveryBodyCard), findsOneWidget);
        expect(AppTabNavigation.tabSwipeEnabled.value, isTrue);
        expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      // System back can arrive before the opening animation has finished.
      await tester.tap(find.byType(CachedBodyPaint).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
      expect(await navigator.currentState!.maybePop(), isTrue);
      await tester.pumpAndSettle();
      expect(AppTabNavigation.tabSwipeEnabled.value, isTrue);
      // Removing the screen mid-transition must cancel tickers and free images.
      await tester.tap(find.byType(CachedBodyPaint).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(AppTabNavigation.tabSwipeEnabled.value, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
