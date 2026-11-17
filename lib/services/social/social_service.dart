import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../models/social_models.dart';
import '../progress_store.dart';
import '../training_notification_service.dart';
import 'firebase_social_backend.dart';
import 'social_store.dart';
import 'live_run_publisher.dart';

/// Facade for friends, sharing, inbox, and live-run notifications.
class SocialService {
  SocialService._() : _backend = FirebaseSocialBackend.instance;
  SocialService.forTesting(FirebaseSocialBackend backend)
    : _backend = backend,
      _cloudEnabled = true;
  final FirebaseSocialBackend _backend;

  static final SocialService instance = SocialService._();

  static const String inviteLinkPrefix = 'kaizen://friend/';
  static const int monthlyPushUpGoal = 1000;

  bool _cloudEnabled = false;
  bool _initialized = false;
  Timer? _pollTimer;
  int _liveViewCount = 0;
  DateTime? _lastGeneralPoll;
  Future<bool>? _connectionInFlight;
  final Set<String> _acceptingMessages = {};
  bool _pollInProgress = false;
  bool _challengeSyncPending = false;
  StreamSubscription<Uri>? _linkSub;
  AppLinks? _appLinks;
  final Set<String> _notifiedRuns = {};
  List<CommunityRun> _communityRuns = const [];
  DateTime? _lastCommunityRunRefresh;
  bool communityLoading = false;
  bool communityLoadFailed = false;
  bool communityAccessDenied = false;

  bool get cloudEnabled => _cloudEnabled;
  bool get isInitialized => _initialized;
  String? get currentUid => _backend.uid;

  String get friendCode => SocialStore.friendCode;
  String get inviteLink => '$inviteLinkPrefix$friendCode';
  List<FriendConnection> get friends => SocialStore.friends;
  List<FriendRequest> get friendRequests => SocialStore.friendRequests;
  List<InboxMessage> get inbox => SocialStore.inbox;
  int get pendingInboxCount =>
      SocialStore.pendingInboxCount + friendRequests.length;
  List<FriendLiveRun> get friendsLiveRuns => SocialStore.friendLiveRuns;
  List<CommunityRun> get communityRuns => _communityRuns;
  String get challengeMonthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  int get monthlyPushUpCount =>
      SocialStore.monthlyChallengeCount(challengeMonthKey);
  List<MonthlyChallengeProgress> get friendMonthlyChallengeProgress =>
      SocialStore.friendMonthlyChallengeProgress(challengeMonthKey);

  ValueNotifier<int> get listenable => SocialStore.listenable();

  Future<void> init() async {
    if (_initialized) return;
    await SocialStore.init();

    SocialServiceRunEvents.instance.onRunChanged = _onFriendRunChanged;
    _initialized = true;
    // Startup must not wait for the network. Offline startup retries later.
    if (_backend.isConfigured) {
      _startPolling();
      unawaited(_pollTick());
    }
    await _initDeepLinks();
    listenable.value++;
  }

  Future<bool> _ensureCloud() {
    if (_cloudEnabled) return Future.value(true);
    if (!_backend.isConfigured) return Future.value(false);
    return _connectionInFlight ??= _connect().whenComplete(
      () => _connectionInFlight = null,
    );
  }

  Future<bool> _connect() async {
    try {
      _cloudEnabled = await _backend.ensureSignedIn();
    } catch (_) {
      _cloudEnabled = false;
    }
    listenable.value++;
    return _cloudEnabled;
  }

  Future<void> _requireCloud() async {
    if (!await _ensureCloud()) {
      throw const SocialBackendException('cloud_unavailable', 503);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      Duration(seconds: _liveViewCount > 0 ? 5 : 20),
      (_) => _pollTick(),
    );
  }

  void setFastLivePolling(bool enabled) {
    _liveViewCount = (_liveViewCount + (enabled ? 1 : -1)).clamp(0, 100);
    if (_backend.isConfigured) _startPolling();
  }

  Future<void> _pollTick() async {
    if (_pollInProgress) return;
    _pollInProgress = true;
    try {
      if (!await _ensureCloud()) return;
      if (_challengeSyncPending) {
        await _backend.publishMonthlyChallengeCount(
          monthKey: challengeMonthKey,
          count: monthlyPushUpCount,
        );
        _challengeSyncPending = false;
      }
      final generalDue =
          _lastGeneralPoll == null ||
          DateTime.now().difference(_lastGeneralPoll!) >=
              const Duration(seconds: 20);
      if (generalDue) {
        await _backend.refreshFriends();
        await _backend.refreshInbox();
        await _backend.refreshFriendRequests();
        _lastGeneralPoll = DateTime.now();
      }
      await _backend.refreshFriendLiveRuns(SocialStore.friends);
      if (generalDue) {
        await _backend.refreshMonthlyChallengeProgress(
          monthKey: challengeMonthKey,
          friends: SocialStore.friends,
        );
      }
      listenable.value++;
    } catch (error) {
      debugPrint('Social sync temporarily unavailable: $error');
    } finally {
      _pollInProgress = false;
      // Expire cached positions even when the network poll failed.
      listenable.value++;
    }
  }

  Future<void> refreshLiveRunsNow() async {
    if (!await _ensureCloud()) return;
    try {
      await _backend.refreshFriendLiveRuns(SocialStore.friends);
      listenable.value++;
    } catch (error) {
      debugPrint('Could not refresh live runs: $error');
    }
  }

  Future<void> refreshCommunityRunsNow({bool force = false}) async {
    if (!force &&
        _lastCommunityRunRefresh != null &&
        DateTime.now().difference(_lastCommunityRunRefresh!) <
            const Duration(minutes: 2)) {
      return;
    }
    if (communityLoading) return;
    communityLoading = true;
    communityLoadFailed = false;
    communityAccessDenied = false;
    listenable.value++;
    try {
      await _requireCloud();
      _communityRuns = await _backend.refreshCommunityRuns();
      _lastCommunityRunRefresh = DateTime.now();
    } catch (error) {
      communityLoadFailed = true;
      communityAccessDenied =
          error is SocialBackendException && error.statusCode == 403;
      debugPrint('Could not refresh community runs: $error');
    } finally {
      communityLoading = false;
      listenable.value++;
    }
  }

  Future<void> publishCommunityRun(CommunityRun run) async {
    await _requireCloud();
    await _backend.publishCommunityRun(run);
    _communityRuns = [
      run,
      ..._communityRuns.where((item) => item.id != run.id),
    ];
    _lastCommunityRunRefresh = DateTime.now();
    listenable.value++;
  }

  Future<void> deleteCommunityRun(String runId) async {
    await _requireCloud();
    await _backend.deleteCommunityRun(runId);
    _communityRuns = _communityRuns
        .where((run) => run.id != runId || run.uid != _backend.uid)
        .toList(growable: false);
    listenable.value++;
  }

  Future<void> refreshFriendsHubNow() async {
    if (!await _ensureCloud()) return;
    try {
      await _backend.refreshFriends();
      await _backend.refreshFriendRequests();
      await _backend.refreshInbox();
      await _backend.refreshMonthlyChallengeProgress(
        monthKey: challengeMonthKey,
        friends: SocialStore.friends,
      );
      await _backend.refreshFriendLiveRuns(SocialStore.friends);
      listenable.value++;
    } catch (error) {
      debugPrint('Could not refresh friends hub: $error');
    }
  }

  Future<void> updateMonthlyPushUpCount(int count) async {
    final normalized = count.clamp(0, 10000000).toInt();
    await SocialStore.setMonthlyChallengeCount(challengeMonthKey, normalized);
    _challengeSyncPending = true;
    if (_cloudEnabled) {
      try {
        await _backend.publishMonthlyChallengeCount(
          monthKey: challengeMonthKey,
          count: normalized,
        );
        _challengeSyncPending = false;
      } catch (error) {
        debugPrint('Challenge saved locally; cloud retry pending: $error');
      }
    }
    listenable.value++;
  }

  Future<void> _initDeepLinks() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _appLinks = AppLinks();
    final initial = await _appLinks!.getInitialLink();
    if (initial != null) {
      await handleInviteUri(initial);
    }
    _linkSub = _appLinks!.uriLinkStream.listen(handleInviteUri);
  }

  Future<void> _onFriendRunChanged({
    required String friendUid,
    required String friendName,
    required String routeName,
    required bool active,
  }) async {
    if (!active) {
      _notifiedRuns.remove(friendUid);
      return;
    }
    if (_notifiedRuns.contains(friendUid)) return;
    _notifiedRuns.add(friendUid);
    await _showFriendRunNotification(friendName, routeName);
  }

  Future<void> _showFriendRunNotification(
    String friendName,
    String routeName,
  ) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final plugin = TrainingNotificationService.pluginForFasting;
    const androidDetails = AndroidNotificationDetails(
      'friend_live_runs',
      'Friend live runs',
      channelDescription: 'Alerts when a friend starts a run',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '$friendName started a run',
      routeName,
      details,
    );
  }

  Future<void> handleInviteUri(Uri uri) async {
    if (uri.scheme != 'kaizen' || uri.host != 'friend') return;
    final code = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.first
        : uri.path.replaceFirst('/', '');
    if (code.trim().isEmpty) return;
    await addFriendByCode(code);
  }

  Future<String?> addFriendByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (!RegExp(r'^KZN-[A-Z0-9]{6,24}$').hasMatch(normalized)) return 'invalid';
    if (normalized == friendCode) return 'self';

    if (!await _ensureCloud()) {
      return 'cloud_disabled';
    }

    final user = await _backend.lookupUserByFriendCode(normalized);
    if (user == null) return 'not_found';

    final friendUid = user['uid']?.toString() ?? '';
    if (friends.any((f) => f.uid == friendUid)) return 'already';

    await _backend.connectFriend(
      friendUid: friendUid,
      displayName: user['displayName']?.toString() ?? 'Friend',
      friendCode: user['friendCode']?.toString() ?? normalized,
    );
    listenable.value++;
    return null;
  }

  Future<void> removeFriend(String uid) async {
    await _requireCloud();
    await _backend.removeFriendRemote(uid);
    await SocialStore.removeFriend(uid);
    await _backend.refreshFriendLiveRuns(friends);
    listenable.value++;
  }

  Future<void> setNotifyOnRunStart(String uid, bool enabled) async {
    await _requireCloud();
    await _backend.setFriendNotifyRemote(uid, enabled);
    await SocialStore.updateFriendNotify(uid, enabled);
    listenable.value++;
  }

  Future<void> shareWithFriend({
    required String friendUid,
    required ShareContentType type,
    required Map<String, dynamic> payload,
  }) async {
    await _requireCloud();
    await _backend.sendShareMessage(
      toUid: friendUid,
      type: type,
      payload: payload,
    );
  }

  Future<void> sendThumbsUp(String friendUid) async {
    await _requireCloud();
    await _backend.sendShareMessage(
      toUid: friendUid,
      type: ShareContentType.thumbsUp,
      payload: const {'name': '👍'},
    );
  }

  Future<void> acceptMessage(InboxMessage message) async {
    if (!_acceptingMessages.add(message.id)) return;
    try {
      if (message.type != ShareContentType.thumbsUp) {
        await ProgressStore.importSharedMessage(message);
      }
      await _setMessageStatus(message, InboxMessageStatus.accepted);
    } finally {
      _acceptingMessages.remove(message.id);
    }
  }

  Future<void> acceptFriendRequest(FriendRequest request) async {
    await _requireCloud();
    await _backend.acceptFriendRequest(request);
  }

  Future<void> rejectFriendRequest(String uid) async {
    await _requireCloud();
    await _backend.rejectFriendRequest(uid);
  }

  Future<void> rejectMessage(InboxMessage message) async {
    await _setMessageStatus(message, InboxMessageStatus.rejected);
  }

  Future<void> deleteInboxMessage(InboxMessage message) async {
    await _requireCloud();
    await _backend.deleteInboxMessageRemote(message.id);
    await SocialStore.removeInboxMessage(message.id);
    listenable.value++;
  }

  Future<void> _setMessageStatus(
    InboxMessage message,
    InboxMessageStatus status,
  ) async {
    await _requireCloud();
    await _backend.updateInboxStatusRemote(
      messageId: message.id,
      status: status,
    );
    final updated = message.copyWith(status: status);
    await SocialStore.upsertInboxMessage(updated);
    listenable.value++;
  }

  Future<void> publishLiveRun(LiveRunUpdate run) async {
    await _requireCloud();
    await _backend.publishLiveRun(run);
  }

  Future<void> clearActiveRun() async {
    await _requireCloud();
    await _backend.clearActiveRun();
  }

  Future<void> dispose() async {
    _pollTimer?.cancel();
    await _linkSub?.cancel();
    SocialServiceRunEvents.instance.onRunChanged = null;
  }
}
