import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/main.dart';
import 'package:kaizen/screens/onboarding/onboarding_flow.dart';
import 'package:kaizen/services/progress_store.dart';

void main() {
  late Directory storageRoot;

  setUpAll(() async {
    storageRoot = await Directory.systemTemp.createTemp('kaizen_widget_test_');
    await ProgressStore.init(storageRootPath: storageRoot.path);
  });

  tearDownAll(() async {
    await ProgressStore.closeForTesting();
    await storageRoot.delete(recursive: true);
  });

  testWidgets('shows onboarding for a new installation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KaizenApp());
    await tester.pump();

    expect(find.byType(OnboardingFlow), findsOneWidget);
  });
}
