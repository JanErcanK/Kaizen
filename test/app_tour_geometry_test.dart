import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/widgets/app_tour.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/screens/root_shell.dart';
import 'package:kaizen/screens/profile_screen.dart';
import 'package:kaizen/navigation/app_tab_navigation.dart';
import 'package:kaizen/theme/app_theme.dart';

void main() {
  void expectCardsVisible(WidgetTester tester) {
    final overlay = tester.getRect(find.byType(AppTourOverlay));
    final tooltip = tester.getRect(find.byKey(const ValueKey('tour-tooltip')));
    final controls = tester.getRect(
      find.byKey(const ValueKey('tour-controls')),
    );
    expect(tooltip.left, greaterThanOrEqualTo(overlay.left + 16));
    expect(tooltip.right, lessThanOrEqualTo(overlay.right - 16));
    expect(tooltip.top, greaterThanOrEqualTo(overlay.top + 16));
    expect(tooltip.bottom, lessThanOrEqualTo(controls.top - 18));
    expect(controls.bottom, lessThanOrEqualTo(overlay.bottom - 16));
  }

  late Directory storage;
  setUpAll(() async {
    storage = await Directory.systemTemp.createTemp('kaizen_tour_test_');
    await ProgressStore.init(storageRootPath: storage.path);
  });
  tearDownAll(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });
  testWidgets(
    'tour animates between tabs and visits all twelve targets in screen order',
    (tester) async {
      await tester.runAsync(() async {
        tester.view.physicalSize = const Size(379, 845);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        AppTabNavigation.selectedTab.value = AppTabNavigation.profile;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.build(light: true),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const RootShell(),
          ),
        );
        await tester.pumpAndSettle();
        tester.widget<ProfileScreen>(find.byType(ProfileScreen)).onStartTour!();
        for (var i = 0; i < 50; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        final controller = tester
            .widget<AppTourOverlay>(find.byType(AppTourOverlay))
            .controller;
        expect(controller.stepCount, 12);
        expect(controller.currentStep.targetKeyId, 'mannequin');
        const profileOrder = [
          'leveling',
          'metabolic',
          'calendar',
          'gallery',
          'health',
          'weight',
        ];
        Widget? profileBeforeStep;
        double previousProfileOffset = 0;
        for (var step = 0; step < 12; step++) {
          expect(controller.isPreparing, false);
          final key = controller.keyForStep(controller.currentStep)!;
          if (step == 4) {
            expect(controller.currentStep.targetKeyId, 'shopping');
            final shopping = tester.getRect(find.byKey(key));
            final note = tester.getRect(
              find.byKey(const ValueKey('home-shopping-list')),
            );
            expect(
              shopping,
              note,
              reason: 'Only the shopping note is highlighted',
            );
          }
          if (step >= 6) {
            expect(controller.currentStep.targetKeyId, profileOrder[step - 6]);
            final profile = tester.widget<ProfileScreen>(
              find.byType(ProfileScreen),
            );
            if (profileBeforeStep != null) {
              expect(
                identical(profile, profileBeforeStep),
                isTrue,
                reason: 'Step changes must not rebuild the Profile page',
              );
            }
            profileBeforeStep = profile;
            final scroll = Scrollable.of(key.currentContext!).position;
            if (step == 6) {
              expect(scroll.pixels, 0, reason: 'Profile starts at the top');
            }
            expect(scroll.pixels, greaterThanOrEqualTo(previousProfileOffset));
            previousProfileOffset = scroll.pixels;
            if (controller.currentStep.targetKeyId == 'health') {
              expect(
                tester.getRect(find.byKey(key)),
                tester.getRect(find.byKey(const ValueKey('profile-health'))),
                reason: 'The entire health card is introduced once',
              );
            }
          }
          final expected = tester
              .getRect(find.byKey(key))
              .inflate(controller.currentStep.spotlightPadding);
          expect(
            tester.getRect(find.byKey(const ValueKey('tour-spotlight'))),
            expected,
            reason: 'Step $step',
          );
          expectCardsVisible(tester);
          expect(
            tester
                .widget<PageView>(find.byType(PageView).first)
                .controller!
                .position
                .isScrollingNotifier
                .value,
            false,
          );
          if (step < 11) {
            final next = controller.next();
            for (var i = 0; i < 50; i++) {
              await tester.pump(const Duration(milliseconds: 20));
            }
            await next;
          }
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        AppTabNavigation.selectedTab.value = AppTabNavigation.home;
      });
    },
  );
  testWidgets(
    'tour animates vertical scrolling and measures in overlay coordinates',
    (tester) async {
      final workout = GlobalKey();
      final running = GlobalKey();
      final controller = AppTourController(
        keys: {'mannequin': workout, 'workout': running},
      );
      final scroll = ScrollController();
      late BuildContext localized;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
              child: Builder(
                builder: (context) {
                  localized = context;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      SingleChildScrollView(
                        controller: scroll,
                        child: Column(
                          children: [
                            const SizedBox(height: 600),
                            SizedBox(key: workout, width: 200, height: 90),
                            const SizedBox(height: 150),
                            SizedBox(key: running, width: 200, height: 90),
                            const SizedBox(height: 600),
                          ],
                        ),
                      ),
                      Positioned.fill(
                        child: AppTourOverlay(controller: controller),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      final started = controller.start(AppLocalizations.of(localized));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump(const Duration(milliseconds: 80));
      expect(controller.isPreparing, isTrue);
      expect(scroll.position.isScrollingNotifier.value, isTrue);
      final duringScroll = scroll.offset;
      expect(duringScroll, greaterThan(0));
      expect(duringScroll, lessThan(600));
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      await started;
      expect(controller.isPreparing, false);
      var target = tester.getRect(find.byKey(workout)).inflate(4);
      expect(
        tester.getRect(find.byKey(const ValueKey('tour-spotlight'))),
        target,
      );
      expect(scroll.position.isScrollingNotifier.value, false);
      expectCardsVisible(tester);
      final next = controller.next();
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      await next;
      target = tester.getRect(find.byKey(running)).inflate(8);
      expect(
        tester.getRect(find.byKey(const ValueKey('tour-spotlight'))),
        target,
      );
      expect(scroll.position.isScrollingNotifier.value, false);
      expectCardsVisible(tester);
      expect(tester.takeException(), isNull);
      controller.finish();
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      scroll.dispose();
    },
  );

  for (final scenario in [
    (size: const Size(368, 819), textScale: 1.0, padding: EdgeInsets.zero),
    (size: const Size(280, 600), textScale: 1.0, padding: EdgeInsets.zero),
    (
      size: const Size(368, 819),
      textScale: 1.5,
      padding: const EdgeInsets.fromLTRB(8, 30, 8, 24),
    ),
    (size: const Size(600, 320), textScale: 1.0, padding: EdgeInsets.zero),
  ]) {
    testWidgets('large spotlight keeps tooltip visible at ${scenario.size}, '
        'text scale ${scenario.textScale}', (tester) async {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final targetKey = GlobalKey();
      final controller = AppTourController(keys: {'mannequin': targetKey});
      late BuildContext localized;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              localized = context;
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: scenario.padding,
                  textScaler: TextScaler.linear(scenario.textScale),
                ),
                child: Material(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        top: 40,
                        bottom: 90,
                        left: 8,
                        right: 8,
                        child: SizedBox(key: targetKey),
                      ),
                      AppTourOverlay(controller: controller),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      final started = controller.start(AppLocalizations.of(localized));
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      await started;
      expectCardsVisible(tester);
      final tooltip = tester.getRect(
        find.byKey(const ValueKey('tour-tooltip')),
      );
      expect(tooltip.top, greaterThanOrEqualTo(scenario.padding.top + 16));
      expect(tooltip.left, greaterThanOrEqualTo(scenario.padding.left + 16));
      expect(
        tooltip.right,
        lessThanOrEqualTo(scenario.size.width - scenario.padding.right - 16),
      );
      expect(tooltip.overlaps(tester.getRect(find.byKey(targetKey))), isTrue);
      expect(tester.takeException(), isNull);
      controller.finish();
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  }
}
