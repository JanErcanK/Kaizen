import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/models/social_models.dart';

void main() {
  test('monthly challenge progress round-trips through local cache JSON', () {
    final updatedAt = DateTime.utc(2026, 8, 6, 10, 30);
    final progress = MonthlyChallengeProgress(
      uid: 'friend-1',
      displayName: 'Alex',
      monthKey: '2026-08',
      count: 1234,
      updatedAt: updatedAt,
    );

    final restored = MonthlyChallengeProgress.fromJson(progress.toJson());

    expect(restored.uid, 'friend-1');
    expect(restored.displayName, 'Alex');
    expect(restored.monthKey, '2026-08');
    expect(restored.count, 1234);
    expect(restored.updatedAt, updatedAt);
  });
}
