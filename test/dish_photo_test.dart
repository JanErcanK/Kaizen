import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/screens/food_screen.dart';
import 'package:kaizen/services/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dish_photo_');
    await ProgressStore.init(storageRootPath: directory.path);
  });

  tearDown(() async {
    await ProgressStore.closeForTesting();
    await directory.delete(recursive: true);
  });

  test('dish photos survive reopening and are removed with the dish', () async {
    final id = await ProgressStore.createFoodDish('Soup');
    expect(ProgressStore.foodDishPhoto(id), isNull);
    await ProgressStore.saveFoodDishPhoto(id, Uint8List.fromList([1, 2]));
    await ProgressStore.saveFoodDishPhoto(id, Uint8List.fromList([3, 4]));
    await ProgressStore.closeForTesting();
    await ProgressStore.init(storageRootPath: directory.path);
    expect(ProgressStore.foodDishPhoto(id), [3, 4]);
    await ProgressStore.deleteFoodDish(id);
    expect(ProgressStore.foodDishPhoto(id), isNull);
  });

  testWidgets('dish card opens details with both photo sources', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: FoodScreen(),
      ),
    );
    await tester.tap(find.text('Dishes'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Eat today'), findsWidgets);
    expect(find.text('3 ingredients'), findsNothing);
    await tester.tap(find.byIcon(Icons.restaurant_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose dish photo'));
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });
}
