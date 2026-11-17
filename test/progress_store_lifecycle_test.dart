import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kaizen/services/progress_store.dart';

void main() {
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('kaizen_store_lifecycle_');
    await ProgressStore.init(storageRootPath: storage.path);
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });

  for (final previousOpens in [0, 5]) {
    test(
      'Home initialization survives immediate close ($previousOpens prior opens)',
      () async {
        await Hive.box<dynamic>(
          'fitflow_progress',
        ).put(ProgressStore.keyHomeOpens, previousOpens);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final start = previousOpens == 0
            ? today
            : today.subtract(
                Duration(days: ProgressStore.profileAnalyticsDays - 1),
              );
        final expectedStart = DateTime(start.year, start.month, start.day);

        // RootShell starts this write without awaiting it. Close immediately,
        // reproducing test teardown without depending on disk speed or sleeps.
        final opening = ProgressStore.markHomeOpened();
        await Future.wait([opening, ProgressStore.closeForTesting()]);

        await ProgressStore.init(storageRootPath: storage.path);
        expect(ProgressStore.homeOpens, previousOpens + 1);
        expect(ProgressStore.profileAnalyticsTrackingStart, expectedStart);
      },
    );
  }

  test(
    'overlapping Home opens preserve the existing analytics start',
    () async {
      await Hive.box<dynamic>('fitflow_progress').putAll({
        ProgressStore.keyHomeOpens: 5,
        ProgressStore.keyProfileAnalyticsStart: '2026-09-01',
      });
      final first = ProgressStore.markHomeOpened();
      final second = ProgressStore.markHomeOpened();
      await Future.wait([first, second, ProgressStore.closeForTesting()]);

      await ProgressStore.init(storageRootPath: storage.path);
      expect(ProgressStore.homeOpens, 7);
      expect(ProgressStore.profileAnalyticsTrackingStart, DateTime(2026, 9, 1));
    },
  );
}
