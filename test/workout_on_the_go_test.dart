import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/screens/workout_hub_screen.dart';
import 'package:kaizen/screens/gym_screen.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/theme/app_theme.dart';
import 'package:kaizen/widgets/anatomy_3d_view.dart';
import 'package:kaizen/widgets/anatomy_webview.dart';

class _FakeView implements AnatomyWebView {
  late ValueChanged<Object?> send;
  @override
  Future<void> initialize({
    required Map<String, Object?> initialState,
    required Color backgroundColor,
    required ValueChanged<Object?> onMessage,
    required ValueChanged<String> onError,
    required VoidCallback onPageFinished,
  }) async {
    send = onMessage;
    onPageFinished();
    send({'type': 'loaded', 'mode': 'muscles'});
  }

  @override
  Widget buildView() => const SizedBox.expand();
  @override
  Future<void> runJavaScript(String script) async {}
  @override
  Future<void> dispose() async {}
  void select(String slug) => send({
    'type': 'selected',
    'tissue': 'muscle',
    'id': 'muscle.$slug',
    'trainingSegment': slug,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('on_the_go');
    await ProgressStore.init(storageRootPath: storage.path);
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });

  for (final width in [390.0, 320.0]) {
    testWidgets('generate, customize and start at width $width', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await ProgressStore.setAppLocaleCode(width == 390 ? 'en' : 'de');
        await tester.binding.setSurfaceSize(Size(width, 780));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final view = _FakeView();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.build(light: true),
            locale: Locale(width == 390 ? 'en' : 'de'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(width == 390 ? 1 : 1.3)),
              child: child!,
            ),
            home: WorkoutOnTheGoScreen(webViewFactory: () => view),
          ),
        );
        await tester.pumpAndSettle();
        final figure = find.byType(Anatomy3DView);
        final generate = find.byKey(const ValueKey('on-the-go-generate'));
        expect(tester.widget<FilledButton>(generate).onPressed, isNull);
        final figureRect = tester.getRect(figure);
        final flipRect = tester.getRect(
          find.byKey(const ValueKey('on-the-go-flip')),
        );
        expect(flipRect.center.dx, greaterThan(figureRect.center.dx));
        expect(
          flipRect.center.dy,
          greaterThan(figureRect.top + figureRect.height * .7),
        );
        Future<void> select(String slug, bool front) async {
          view.select(slug);
          await tester.pumpAndSettle();
        }

        await select('chest', true);
        await tester.tap(find.byKey(const ValueKey('on-the-go-flip')));
        await tester.pumpAndSettle();
        await select('calves', false);
        expect(find.byType(InputChip), findsNWidgets(2));
        await tester.tap(generate);
        await tester.pumpAndSettle();
        expect(find.text('Workout (7)'), findsOneWidget);
        final plan = find.byKey(const ValueKey('on-the-go-plan'));
        final suggestions = find.byKey(const ValueKey('on-the-go-suggestions'));
        expect(
          tester.getRect(plan).right,
          lessThan(tester.getRect(suggestions).left),
        );
        expect(ProgressStore.gymWorkouts, isEmpty);
        expect(tester.takeException(), isNull);

        await tester.enterText(find.byType(TextField), 'xyz-no-matches');
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.add_circle_outline), findsNothing);
        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();
        final firstSuggestion = find
            .descendant(of: suggestions, matching: find.byType(Text))
            .first;
        final suggestionName = tester.widget<Text>(firstSuggestion).data!;
        await tester.tap(
          find
              .descendant(
                of: suggestions,
                matching: find.byIcon(Icons.add_circle_outline),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Workout (8)'), findsOneWidget);
        expect(
          find.descendant(of: suggestions, matching: find.text(suggestionName)),
          findsNothing,
        );

        await tester.tap(
          find
              .descendant(
                of: plan,
                matching: find.byIcon(Icons.remove_circle_outline),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Workout (7)'), findsOneWidget);
        await tester.tap(
          find.descendant(of: plan, matching: find.text('3 × 10')).first,
        );
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        await tester.enterText(find.byType(TextFormField).first, '4');
        await tester.pumpAndSettle();
        await tester.tap(find.text(width == 390 ? 'Save' : 'Speichern').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const ValueKey('on-the-go-start')));
        for (
          var i = 0;
          i < 100 && find.byType(GymWorkoutDetailScreen).evaluate().isEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pumpAndSettle();
        }
        expect(find.byType(GymWorkoutDetailScreen), findsOneWidget);
        expect(ProgressStore.gymWorkouts, hasLength(1));
        final exercises = ProgressStore.gymWorkouts.single['exercises'] as List;
        expect(exercises, hasLength(7));
        expect(
          exercises
              .skip(1)
              .every((exercise) => exercise['setReps'].length == 3),
          isTrue,
        );
        expect(exercises.first['setReps'], hasLength(4));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    });
  }
  testWidgets(
    'direct search adds exercises without generating or picking muscles',
    (tester) async {
      final view = _FakeView();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WorkoutOnTheGoScreen(webViewFactory: () => view),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('on-the-go-direct-search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'push');
      await tester.pumpAndSettle();
      final add = find.byIcon(Icons.add_circle_outline);
      expect(add, findsWidgets);
      await tester.tap(add.first);
      await tester.pumpAndSettle();
      expect(find.text('Workout (1)'), findsOneWidget);
      expect(ProgressStore.gymWorkouts, isEmpty);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('on-the-go-start')))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      view.select('chest');
      await tester.pumpAndSettle();
      expect(find.byType(InputChip), findsOneWidget);
      view.select('chest');
      await tester.pumpAndSettle();
      expect(find.byType(InputChip), findsNothing);
      await tester.tap(find.byKey(const ValueKey('on-the-go-add')));
      await tester.pumpAndSettle();
      expect(find.text('Workout (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
