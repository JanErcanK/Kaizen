import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../models/social_models.dart';

/// Local Hive cache for friends, inbox, and social identity.
class SocialStore {
  static const String _boxName = 'kaizen_social';
  static const String keyFriendCode = 'friend_code';
  static const String keyCloudUid = 'cloud_uid';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyFriends = 'friends';
  static const String keyFriendRequests = 'friend_requests';
  static const String keyInbox = 'inbox';
  static const String keyFriendLiveRuns = 'friend_live_runs';
  static const String keyMonthlyChallengeCounts = 'monthly_challenge_counts';
  static const String keyFriendMonthlyChallengeProgress =
      'friend_monthly_challenge_progress';

  static Box<dynamic>? _box;
  static final ValueNotifier<int> _changeTick = ValueNotifier<int>(0);

  static ValueNotifier<int> listenable() => _changeTick;

  static void _notify() => _changeTick.value++;

  static Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<dynamic>(_boxName);
    if (friendCode.isEmpty) {
      await _safeBox.put(keyFriendCode, _generateFriendCode());
    }
    _notify();
  }

  static Box<dynamic> get _safeBox {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('SocialStore.init() must be called first');
    }
    return box;
  }

  static String _generateFriendCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final random = Random.secure();
    final buffer = StringBuffer('KZN-');
    for (var i = 0; i < 6; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  static String regenerateFriendCode() => _generateFriendCode();

  static Future<void> setFriendCode(String code) async {
    await _safeBox.put(keyFriendCode, code.trim().toUpperCase());
    _notify();
  }

  static String get friendCode =>
      _box?.get(keyFriendCode, defaultValue: '')?.toString() ?? '';

  static String? get cloudUid =>
      _box?.get(keyCloudUid)?.toString().trim().isEmpty == true
      ? null
      : _box?.get(keyCloudUid)?.toString();

  static Future<void> setCloudUid(String uid) async {
    await _safeBox.put(keyCloudUid, uid);
    _notify();
  }

  static String? get refreshToken {
    final value = _box?.get(keyRefreshToken)?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Future<void> setRefreshToken(String? token) async {
    if (token == null || token.trim().isEmpty) {
      await _safeBox.delete(keyRefreshToken);
    } else {
      await _safeBox.put(keyRefreshToken, token.trim());
    }
    _notify();
  }

  static Future<void> clearCloudSession() async {
    await _safeBox.delete(keyCloudUid);
    await _safeBox.delete(keyRefreshToken);
    _notify();
  }

  static List<FriendConnection> get friends {
    final raw = _box?.get(keyFriends, defaultValue: const []);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => FriendConnection.fromJson(Map<String, dynamic>.from(e)))
        .where((f) => f.uid.isNotEmpty)
        .toList();
  }

  static Future<void> setFriends(List<FriendConnection> next) async {
    await _safeBox.put(keyFriends, next.map((f) => f.toJson()).toList());
    _notify();
  }

  static List<FriendRequest> get friendRequests {
    final raw = _box?.get(keyFriendRequests, defaultValue: const []);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (value) => FriendRequest.fromJson(Map<String, dynamic>.from(value)),
        )
        .where((r) => r.uid.isNotEmpty)
        .toList();
  }

  static Future<void> setFriendRequests(List<FriendRequest> next) async {
    await _safeBox.put(keyFriendRequests, next.map((r) => r.toJson()).toList());
    _notify();
  }

  static List<InboxMessage> get inbox {
    final raw = _box?.get(keyInbox, defaultValue: const []);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => InboxMessage.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.id.isNotEmpty)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static int get pendingInboxCount =>
      inbox.where((m) => m.status == InboxMessageStatus.pending).length;

  static Future<void> setInbox(List<InboxMessage> next) async {
    await _safeBox.put(keyInbox, next.map((m) => m.toJson()).toList());
    _notify();
  }

  static Future<void> upsertInboxMessage(InboxMessage message) async {
    final next = inbox.toList();
    final index = next.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      next[index] = message;
    } else {
      next.add(message);
    }
    await setInbox(next);
  }

  static Future<void> removeInboxMessage(String id) async {
    await setInbox(inbox.where((m) => m.id != id).toList());
  }

  static Future<void> updateFriendNotify(String uid, bool enabled) async {
    final next = friends
        .map((f) => f.uid == uid ? f.copyWith(notifyOnRunStart: enabled) : f)
        .toList();
    await setFriends(next);
  }

  static Future<void> removeFriend(String uid) async {
    await setFriends(friends.where((f) => f.uid != uid).toList());
  }

  static Future<void> addOrUpdateFriend(FriendConnection friend) async {
    final next = friends.where((f) => f.uid != friend.uid).toList();
    next.add(friend);
    await setFriends(next);
  }

  static List<FriendLiveRun> get friendLiveRuns {
    final raw = _box?.get(keyFriendLiveRuns, defaultValue: const []);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => FriendLiveRun.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.uid.isNotEmpty && !r.isStale)
        .toList();
  }

  static Future<void> setFriendLiveRuns(List<FriendLiveRun> next) async {
    await _safeBox.put(keyFriendLiveRuns, next.map((r) => r.toJson()).toList());
    _notify();
  }

  static int monthlyChallengeCount(String monthKey) {
    final raw = _box?.get(keyMonthlyChallengeCounts, defaultValue: const {});
    if (raw is! Map) return 0;
    final value = raw[monthKey];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Future<void> setMonthlyChallengeCount(
    String monthKey,
    int count,
  ) async {
    final raw = _safeBox.get(keyMonthlyChallengeCounts, defaultValue: const {});
    final next = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    next[monthKey] = count.clamp(0, 10000000);
    await _safeBox.put(keyMonthlyChallengeCounts, next);
    _notify();
  }

  static List<MonthlyChallengeProgress> friendMonthlyChallengeProgress(
    String monthKey,
  ) {
    final raw = _box?.get(
      keyFriendMonthlyChallengeProgress,
      defaultValue: const [],
    );
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (entry) => MonthlyChallengeProgress.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .where((entry) => entry.uid.isNotEmpty && entry.monthKey == monthKey)
        .toList();
  }

  static Future<void> setFriendMonthlyChallengeProgress(
    List<MonthlyChallengeProgress> next,
  ) async {
    await _safeBox.put(
      keyFriendMonthlyChallengeProgress,
      next.map((entry) => entry.toJson()).toList(),
    );
    _notify();
  }
}
