import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/social_models.dart';
import '../../models/route_activity.dart';
import '../../models/shared_content.dart';
import '../progress_store.dart';
import 'social_cloud_config.dart';
import 'social_store.dart';
import 'live_run_publisher.dart';

class SocialBackendException implements Exception {
  const SocialBackendException(this.operation, this.statusCode);
  final String operation;
  final int statusCode;
  @override
  String toString() => 'Social request failed: $operation ($statusCode)';
}

/// Cross-platform Firestore sync via REST (no native Firebase SDK).
class FirebaseSocialBackend {
  FirebaseSocialBackend._()
    : _client = http.Client(),
      _projectId = SocialCloudConfig.projectId,
      _apiKey = SocialCloudConfig.apiKey;

  FirebaseSocialBackend.forTesting({
    required http.Client client,
    String projectId = 'demo-kaizen',
    String apiKey = 'test',
    String? uid,
    String? idToken,
  }) : _client = client,
       _projectId = projectId,
       _apiKey = apiKey,
       _uid = uid,
       _idToken = idToken,
       _profileRegistered = uid != null && idToken != null;

  final http.Client _client;
  final String _projectId, _apiKey;
  Future<bool>? _refreshInFlight;
  bool get isConfigured => _projectId.isNotEmpty && _apiKey.isNotEmpty;

  static final FirebaseSocialBackend instance = FirebaseSocialBackend._();

  String? _idToken;
  String? _uid;
  bool _profileRegistered = false;

  String? get uid => _uid;
  bool get isReady => _uid != null && _idToken != null;

  Future<bool> ensureSignedIn() async {
    if (!isConfigured) return false;
    if (isReady) {
      if (!_profileRegistered) await _registerUserProfile(_uid!);
      return true;
    }

    final existingRefresh = SocialStore.refreshToken;
    if (existingRefresh != null) {
      final refreshed = await _refreshSession(existingRefresh);
      if (refreshed) {
        await _registerUserProfile(_uid!);
        return true;
      }
      // A transient refresh failure must never silently replace the user's
      // identity and orphan their friends. Keep the saved session for retry.
      return false;
    }

    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey',
    );
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'returnSecureToken': true}),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode >= 400) return false;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _idToken = data['idToken']?.toString();
    _uid = data['localId']?.toString();
    final refreshToken = data['refreshToken']?.toString();
    if (_uid == null || _idToken == null || refreshToken == null) return false;
    await SocialStore.setCloudUid(_uid!);
    await SocialStore.setRefreshToken(refreshToken);
    await _registerUserProfile(_uid!);
    return true;
  }

  Future<bool> _refreshSession(String refreshToken) async {
    final uri = Uri.parse(
      'https://securetoken.googleapis.com/v1/token?key=$_apiKey',
    );
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'grant_type': 'refresh_token', 'refresh_token': refreshToken},
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode >= 400) return false;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _idToken = data['id_token']?.toString();
    _uid = data['user_id']?.toString();
    final nextRefresh = data['refresh_token']?.toString();
    if (_uid == null || _idToken == null) return false;
    await SocialStore.setCloudUid(_uid!);
    if (nextRefresh != null && nextRefresh.isNotEmpty) {
      await SocialStore.setRefreshToken(nextRefresh);
    }
    return true;
  }

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $_idToken',
    'Content-Type': 'application/json',
  };

  String _docPath(String path) =>
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$path';

  Future<void> _registerUserProfile(String userId) async {
    final name = ProgressStore.profileName;
    var code = SocialStore.friendCode;
    for (var attempt = 0; attempt < 5; attempt++) {
      final existing = await _getDocument('friendCodes/$code');
      final owner = existing == null ? null : _stringField(existing, 'uid');
      if (owner == null || owner == userId) break;
      code = SocialStore.regenerateFriendCode();
      await SocialStore.setFriendCode(code);
    }
    await _patchDocument('users/$userId', {
      'fields': {
        'displayName': {'stringValue': name},
        'friendCode': {'stringValue': code},
      },
    });
    await _patchDocument('friendCodes/$code', {
      'fields': {
        'uid': {'stringValue': userId},
      },
    });
    _profileRegistered = true;
  }

  Future<void> syncDisplayName() async {
    if (!isReady) return;
    await _patchDocument('users/$_uid', {
      'fields': {
        'displayName': {'stringValue': ProgressStore.profileName},
      },
    });
  }

  Future<Map<String, dynamic>?> lookupUserByFriendCode(String code) async {
    if (!isReady) return null;
    final normalized = code.trim().toUpperCase();
    final snap = await _getDocument('friendCodes/$normalized');
    if (snap == null) return null;
    final friendUid = _stringField(snap, 'uid');
    if (friendUid == null || friendUid.isEmpty || friendUid == _uid) {
      return null;
    }
    final userSnap = await _getDocument('users/$friendUid');
    if (userSnap == null) return null;
    return {
      'uid': friendUid,
      'displayName': _stringField(userSnap, 'displayName') ?? 'Friend',
      'friendCode': _stringField(userSnap, 'friendCode') ?? normalized,
    };
  }

  Future<void> connectFriend({
    required String friendUid,
    required String displayName,
    required String friendCode,
  }) async {
    _requireReady();
    await syncDisplayName();
    final now = DateTime.now().toUtc().toIso8601String();
    // Knowing a code permits a request, never unilateral location access.
    await _patchDocument('users/$friendUid/friendRequests/$_uid', {
      'fields': {
        'fromUid': {'stringValue': _uid},
        'displayName': {'stringValue': ProgressStore.profileName},
        'friendCode': {'stringValue': SocialStore.friendCode},
        'createdAt': {'timestampValue': now},
      },
    });
  }

  Future<void> refreshFriendRequests() async {
    _requireReady();
    final docs = await _listCollection('users/$_uid/friendRequests');
    await SocialStore.setFriendRequests(
      docs.map((doc) {
        final fields = Map<String, dynamic>.from(doc['fields'] as Map? ?? {});
        return FriendRequest(
          uid: doc['id'] as String,
          displayName: _readString(fields, 'displayName') ?? 'Friend',
          friendCode: _readString(fields, 'friendCode') ?? '',
          createdAt: _readTimestamp(fields, 'createdAt') ?? DateTime(1970),
        );
      }).toList(),
    );
  }

  Future<void> acceptFriendRequest(FriendRequest request) async {
    _requireReady();
    final now = DateTime.now().toUtc().toIso8601String();
    Map<String, dynamic> connection(String name, String code) => {
      'displayName': {'stringValue': name},
      'friendCode': {'stringValue': code},
      'notifyOnRunStart': {'booleanValue': true},
      'connectedAt': {'timestampValue': now},
      'consentVersion': {'integerValue': '1'},
      'acceptedBy': {'stringValue': _uid},
    };
    String document(String path) =>
        'projects/$_projectId/databases/(default)/documents/$path';
    final body = {
      'writes': [
        {
          'update': {
            'name': document('users/$_uid/friends/${request.uid}'),
            'fields': connection(request.displayName, request.friendCode),
          },
        },
        {
          'update': {
            'name': document('users/${request.uid}/friends/$_uid'),
            'fields': connection(
              ProgressStore.profileName,
              SocialStore.friendCode,
            ),
          },
        },
        {'delete': document('users/$_uid/friendRequests/${request.uid}')},
      ],
    };
    await _request(
      'POST',
      Uri.parse('${_docPath('')}:commit'.replaceFirst('/:commit', ':commit')),
      body: jsonEncode(body),
    );
    await refreshFriends();
    await refreshFriendRequests();
  }

  Future<void> rejectFriendRequest(String uid) async {
    _requireReady();
    await _deleteDocument('users/$_uid/friendRequests/$uid');
    await refreshFriendRequests();
  }

  Future<void> removeFriendRemote(String friendUid) async {
    _requireReady();
    final base = 'projects/$_projectId/databases/(default)/documents';
    await _request(
      'POST',
      Uri.parse('${_docPath('')}:commit'.replaceFirst('/:commit', ':commit')),
      body: jsonEncode({
        'writes': [
          {'delete': '$base/users/$_uid/friends/$friendUid'},
          {'delete': '$base/users/$friendUid/friends/$_uid'},
        ],
      }),
    );
    await refreshFriends();
  }

  Future<void> setFriendNotifyRemote(String friendUid, bool enabled) async {
    if (!isReady) return;
    await _patchDocument('users/$_uid/friends/$friendUid', {
      'fields': {
        'notifyOnRunStart': {'booleanValue': enabled},
      },
    });
    await refreshFriends();
  }

  Future<void> sendShareMessage({
    required String toUid,
    required ShareContentType type,
    required Map<String, dynamic> payload,
  }) async {
    _requireReady();
    final content = normalizeSharedContent(type, payload);
    if (type == ShareContentType.runningRoute) {
      // Firestore does not support arrays directly containing arrays.
      for (final key in ['points', 'waypoints']) {
        content[key] = (content[key] as List)
            .map((p) => {'lat': p[0], 'lon': p[1]})
            .toList();
      }
    }
    await syncDisplayName();
    final id = 'msg_${DateTime.now().microsecondsSinceEpoch}';
    await _patchDocument('users/$toUid/inbox/$id', {
      'fields': {
        'id': {'stringValue': id},
        'fromUid': {'stringValue': _uid},
        'fromName': {'stringValue': ProgressStore.profileName},
        'type': {'stringValue': shareContentTypeToString(type)},
        'payload': {'mapValue': _toFirestoreMap(content)},
        'status': {'stringValue': 'pending'},
        'createdAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
      },
    });
  }

  Future<void> updateInboxStatusRemote({
    required String messageId,
    required InboxMessageStatus status,
  }) async {
    if (!isReady) return;
    await _patchDocument('users/$_uid/inbox/$messageId', {
      'fields': {
        'status': {'stringValue': inboxMessageStatusToString(status)},
      },
    });
    await refreshInbox();
  }

  Future<void> deleteInboxMessageRemote(String messageId) async {
    if (!isReady) return;
    await _deleteDocument('users/$_uid/inbox/$messageId');
    await refreshInbox();
  }

  Future<void> refreshFriends() async {
    if (!isReady) return;
    final list = await _listCollection('users/$_uid/friends');
    // Legacy edges were created without recipient consent. Reconnect through
    // a request instead of treating those records as accepted friendships.
    final friends = list
        .where((doc) {
          final fields = doc['fields'] as Map<String, dynamic>? ?? {};
          return _readDouble(fields, 'consentVersion') == 1;
        })
        .map((doc) {
          final id = doc['id']?.toString() ?? '';
          final fields = doc['fields'] as Map<String, dynamic>? ?? {};
          return FriendConnection(
            uid: id,
            displayName: _readString(fields, 'displayName') ?? 'Friend',
            friendCode: _readString(fields, 'friendCode') ?? '',
            notifyOnRunStart: _readBool(fields, 'notifyOnRunStart') ?? true,
            connectedAt:
                _readTimestamp(fields, 'connectedAt') ?? DateTime.now(),
          );
        })
        .toList();
    await SocialStore.setFriends(friends);
  }

  Future<void> refreshInbox() async {
    if (!isReady) return;
    final list = await _listCollection('users/$_uid/inbox');
    final messages = list.map((doc) {
      final fields = doc['fields'] as Map<String, dynamic>? ?? {};
      return InboxMessage.fromJson({
        'id': _readString(fields, 'id') ?? doc['id'],
        'fromUid': _readString(fields, 'fromUid') ?? '',
        'fromName': _readString(fields, 'fromName') ?? 'Friend',
        'type': _readString(fields, 'type'),
        'payload': _decodeSharedPayload(fields),
        'status': _readString(fields, 'status'),
        'createdAt': _readTimestamp(fields, 'createdAt')?.toIso8601String(),
      });
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await SocialStore.setInbox(messages);
  }

  Future<void> publishMonthlyChallengeCount({
    required String monthKey,
    required int count,
  }) async {
    if (!isReady) return;
    await _patchDocument('users/$_uid/challenges/$monthKey', {
      'fields': {
        'challengeId': {'stringValue': 'pushups_1000'},
        'monthKey': {'stringValue': monthKey},
        'displayName': {'stringValue': ProgressStore.profileName},
        'count': {'integerValue': '${count.clamp(0, 10000000)}'},
        'goal': {'integerValue': '1000'},
        'updatedAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
      },
    });
  }

  Future<void> refreshMonthlyChallengeProgress({
    required String monthKey,
    required List<FriendConnection> friends,
  }) async {
    if (!isReady) return;
    final progress = <MonthlyChallengeProgress>[];
    for (final friend in friends) {
      final doc = await _getDocument(
        'users/${friend.uid}/challenges/$monthKey',
      );
      final fields = doc?['fields'] as Map<String, dynamic>?;
      progress.add(
        MonthlyChallengeProgress(
          uid: friend.uid,
          displayName: fields == null
              ? friend.displayName
              : _readString(fields, 'displayName') ?? friend.displayName,
          monthKey: monthKey,
          count: fields == null
              ? 0
              : (_readDouble(fields, 'count') ?? 0)
                    .round()
                    .clamp(0, 10000000)
                    .toInt(),
          updatedAt: fields == null
              ? DateTime.fromMillisecondsSinceEpoch(0)
              : _readTimestamp(fields, 'updatedAt') ??
                    DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    }
    await SocialStore.setFriendMonthlyChallengeProgress(progress);
  }

  Future<void> refreshFriendRuns(List<FriendConnection> friends) async {
    await refreshFriendLiveRuns(friends);
  }

  Future<void> refreshFriendLiveRuns(List<FriendConnection> friends) async {
    if (!isReady) return;
    final live = <FriendLiveRun>[];
    for (final friend in friends) {
      Map<String, dynamic>? doc;
      try {
        doc = await _getDocument('users/${friend.uid}/presence/activeRun');
      } on SocialBackendException catch (error) {
        // A removed friendship must disappear without breaking other runners.
        if (error.statusCode != 403) rethrow;
      }
      if (doc == null) {
        SocialServiceRunEvents.instance.emit(
          friendUid: friend.uid,
          friendName: friend.displayName,
          routeName: '',
          active: false,
        );
        continue;
      }
      final fields = doc['fields'] as Map<String, dynamic>? ?? {};
      final updatedAt =
          _readTimestamp(fields, 'updatedAt') ??
          _readTimestamp(fields, 'startedAt') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      if (DateTime.now().difference(updatedAt) > const Duration(minutes: 2)) {
        SocialServiceRunEvents.instance.emit(
          friendUid: friend.uid,
          friendName: friend.displayName,
          routeName: '',
          active: false,
        );
        continue;
      }
      final lat = _readDouble(fields, 'latitude');
      final lon = _readDouble(fields, 'longitude');
      if (lat == null ||
          lon == null ||
          !lat.isFinite ||
          !lon.isFinite ||
          lat.abs() > 90 ||
          lon.abs() > 180) {
        continue;
      }

      final run = FriendLiveRun(
        uid: friend.uid,
        displayName: _readString(fields, 'displayName') ?? friend.displayName,
        routeId: _readString(fields, 'routeId') ?? '',
        routeName: _readString(fields, 'routeName') ?? 'Run',
        latitude: lat,
        longitude: lon,
        distanceMeters: _readDouble(fields, 'distanceMeters') ?? 0,
        currentPaceSecPerKm: _readDouble(fields, 'currentPaceSecPerKm'),
        avgPaceSecPerKm: _readDouble(fields, 'avgPaceSecPerKm'),
        recordedPoints: _decodePointField(fields['recordedPoints']),
        recordedPointTimestamps: _decodeIntegerField(
          fields['recordedPointTimestamps'],
        ),
        plannedPoints: _decodePointField(fields['plannedPoints']),
        startedAt: _readTimestamp(fields, 'startedAt') ?? DateTime.now(),
        updatedAt: updatedAt,
        paused: _readBool(fields, 'paused') ?? false,
        positionUpdatedAt: _readTimestamp(fields, 'positionUpdatedAt'),
      );
      live.add(run);

      if (friend.notifyOnRunStart) {
        SocialServiceRunEvents.instance.emit(
          friendUid: friend.uid,
          friendName: run.displayName,
          routeName: run.routeName,
          active: true,
        );
      }
    }
    await SocialStore.setFriendLiveRuns(live);
  }

  Future<List<CommunityRun>> refreshCommunityRuns() async {
    _requireReady();
    final runs = <CommunityRun>[];
    final docs = await _listCollection(
      'communityRuns',
      limit: 30,
      orderBy: 'createdAt desc',
    );
    for (final doc in docs) {
      final fields = doc['fields'] as Map<String, dynamic>? ?? {};
      final uid = _readString(fields, 'ownerUid');
      final distance = _readDouble(fields, 'distanceMeters');
      final createdAt = _readTimestamp(fields, 'createdAt');
      final points = _decodePointField(fields['points']);
      if (uid == null ||
          uid.isEmpty ||
          distance == null ||
          createdAt == null ||
          points.length < 2) {
        continue;
      }
      runs.add(
        CommunityRun(
          id: doc['id']?.toString() ?? '',
          uid: uid,
          displayName: _readString(fields, 'displayName') ?? 'Runner',
          routeName: _readString(fields, 'routeName') ?? 'Run',
          distanceMeters: distance,
          ascentMeters: _readDouble(fields, 'ascentMeters') ?? 0,
          activity: fields['activity'] == null
              ? null
              : RouteActivity.fromJson(_fromFirestoreMap(fields['activity'])),
          points: points,
          createdAt: createdAt,
        ),
      );
    }
    runs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return runs;
  }

  Future<void> publishCommunityRun(CommunityRun run) async {
    _requireReady();
    if (run.uid != _uid || run.id.isEmpty || run.points.length < 2) {
      throw const FormatException('Invalid community run');
    }
    final indices = boundedRunPointIndices(run.points, 1000);
    await _patchDocument('communityRuns/${run.id}', {
      'fields': {
        'ownerUid': {'stringValue': _uid},
        'displayName': {'stringValue': ProgressStore.profileName},
        'routeName': {'stringValue': run.routeName},
        'distanceMeters': {'doubleValue': run.distanceMeters},
        'ascentMeters': {'doubleValue': run.ascentMeters},
        if (run.activity != null)
          'activity': {'mapValue': _toFirestoreMap(run.activity!.toJson())},
        'points': {
          'arrayValue': {
            'values': indices
                .map((index) => _pointValue(run.points[index]))
                .toList(),
          },
        },
        'createdAt': {
          'timestampValue': run.createdAt.toUtc().toIso8601String(),
        },
      },
    });
  }

  Future<void> deleteCommunityRun(String runId) async {
    _requireReady();
    await _deleteDocument('communityRuns/$runId');
  }

  Future<void> publishLiveRun(LiveRunUpdate run) async {
    _requireReady();
    if (!run.latitude.isFinite ||
        !run.longitude.isFinite ||
        run.latitude.abs() > 90 ||
        run.longitude.abs() > 180) {
      throw const FormatException('Invalid live position');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    await _patchDocument('users/$_uid/presence/activeRun', {
      'fields': {
        'routeId': {'stringValue': run.routeId},
        'routeName': {'stringValue': run.routeName},
        'displayName': {'stringValue': ProgressStore.profileName},
        'latitude': {'doubleValue': run.latitude},
        'longitude': {'doubleValue': run.longitude},
        'distanceMeters': {'doubleValue': run.distanceMeters},
        'currentPaceSecPerKm': run.currentPaceSecPerKm == null
            ? {'nullValue': null}
            : {'doubleValue': run.currentPaceSecPerKm},
        'avgPaceSecPerKm': run.avgPaceSecPerKm == null
            ? {'nullValue': null}
            : {'doubleValue': run.avgPaceSecPerKm},
        'recordedPoints': {
          'arrayValue': {
            'values': boundedRunPointIndices(
              run.recordedPoints,
              400,
            ).map((index) => _pointValue(run.recordedPoints[index])).toList(),
          },
        },
        'recordedPointTimestamps': {
          'arrayValue': {
            'values': boundedRunPointIndices(run.recordedPoints, 400)
                .map(
                  (index) => index < run.recordedPointTimestamps.length
                      ? {
                          'integerValue':
                              '${run.recordedPointTimestamps[index]}',
                        }
                      : {
                          'integerValue':
                              '${run.positionUpdatedAt.millisecondsSinceEpoch}',
                        },
                )
                .toList(),
          },
        },
        'plannedPoints': {
          'arrayValue': {
            'values': boundedRunPoints(
              run.plannedPoints,
              1000,
            ).map(_pointValue).toList(),
          },
        },
        'startedAt': {
          'timestampValue': run.startedAt.toUtc().toIso8601String(),
        },
        'updatedAt': {'timestampValue': now},
        'positionUpdatedAt': {
          'timestampValue': run.positionUpdatedAt.toUtc().toIso8601String(),
        },
        'paused': {'booleanValue': run.paused},
      },
    });
  }

  Future<void> clearActiveRun() async {
    if (!isReady) return;
    await _deleteDocument('users/$_uid/presence/activeRun');
  }

  Future<bool> _tryRefreshAfterUnauthorized(int statusCode) async {
    if (statusCode != 401) return false;
    final refresh = SocialStore.refreshToken;
    if (refresh == null) return false;
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;
    final next = _refreshSession(refresh);
    _refreshInFlight = next;
    try {
      return await next;
    } finally {
      _refreshInFlight = null;
    }
  }

  void _requireReady() {
    if (!isReady) throw const SocialBackendException('not_signed_in', 401);
  }

  Future<http.Response> _request(
    String method,
    Uri uri, {
    String? body,
    bool allowMissing = false,
  }) async {
    _requireReady();
    Future<http.Response> send() async {
      final request = http.Request(method, uri)
        ..followRedirects = false
        ..headers.addAll(_authHeaders);
      if (body != null) request.body = body;
      return _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 12));
    }

    var response = await send();
    if (await _tryRefreshAfterUnauthorized(response.statusCode)) {
      response = await send();
    }
    if (allowMissing && response.statusCode == 404) return response;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Do not log the URL/token or remote body.
      throw SocialBackendException(method, response.statusCode);
    }
    return response;
  }

  Future<Map<String, dynamic>?> _getDocument(String path) async {
    final uri = Uri.parse(_docPath(path));
    final response = await _request('GET', uri, allowMissing: true);
    if (response.statusCode == 404) return null;
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _listCollection(
    String path, {
    int? limit,
    String? orderBy,
  }) async {
    final result = <Map<String, dynamic>>[];
    String? pageToken;
    do {
      final uri = Uri.parse(_docPath(path)).replace(
        queryParameters: {
          'pageSize': '${limit == null ? 100 : limit.clamp(1, 100)}',
          if (orderBy != null) 'orderBy': orderBy,
          if (pageToken != null) 'pageToken': pageToken,
        },
      );
      final response = await _request('GET', uri);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      for (final doc
          in (data['documents'] as List? ?? const []).whereType<Map>()) {
        result.add({
          'id': doc['name'].toString().split('/').last,
          'fields': doc['fields'],
        });
      }
      pageToken = data['nextPageToken'] as String?;
    } while (limit == null && pageToken != null && pageToken.isNotEmpty);
    return result;
  }

  Future<void> _patchDocument(String path, Map<String, dynamic> body) async {
    // Without updateMask Firestore PATCH replaces all omitted fields, which
    // used to erase inbox payloads, friend names and the run's startedAt.
    final fields = Map<String, dynamic>.from(body['fields'] as Map);
    final uri = Uri.parse(
      _docPath(path),
    ).replace(queryParameters: {'updateMask.fieldPaths': fields.keys.toList()});
    await _request('PATCH', uri, body: jsonEncode(body));
  }

  Future<void> _deleteDocument(String path) async {
    await _request('DELETE', Uri.parse(_docPath(path)), allowMissing: true);
  }

  String? _stringField(Map<String, dynamic> doc, String key) {
    final fields = doc['fields'] as Map<String, dynamic>?;
    if (fields == null) return null;
    return _readString(fields, key);
  }

  String? _readString(Map<String, dynamic> fields, String key) {
    final value = fields[key];
    if (value is Map && value['stringValue'] != null) {
      return value['stringValue'].toString();
    }
    return null;
  }

  double? _readDouble(Map<String, dynamic> fields, String key) {
    final value = fields[key];
    if (value is Map && value['doubleValue'] != null) {
      return (value['doubleValue'] as num?)?.toDouble();
    }
    if (value is Map && value['integerValue'] != null) {
      return double.tryParse(value['integerValue'].toString());
    }
    return null;
  }

  List<List<double>> _decodePointField(dynamic raw) {
    if (raw is! Map) return const [];
    final values = raw['arrayValue']?['values'];
    if (values is! List) return const [];
    final out = <List<double>>[];
    for (final entry in values) {
      final decoded = _fromFirestoreValue(entry);
      if (decoded is Map) {
        final lat = decoded['lat'];
        final lon = decoded['lon'];
        if (lat is num &&
            lon is num &&
            lat.isFinite &&
            lon.isFinite &&
            lat.abs() <= 90 &&
            lon.abs() <= 180) {
          out.add([lat.toDouble(), lon.toDouble()]);
        }
      }
    }
    return out;
  }

  List<int> _decodeIntegerField(dynamic raw) {
    if (raw is! Map) return const [];
    final values = raw['arrayValue']?['values'];
    if (values is! List) return const [];
    return values
        .map(_fromFirestoreValue)
        .whereType<num>()
        .map((value) => value.toInt())
        .toList(growable: false);
  }

  Map<String, dynamic> _pointValue(List<double> point) {
    return {
      'mapValue': {
        'fields': {
          'lat': {'doubleValue': point[0]},
          'lon': {'doubleValue': point[1]},
        },
      },
    };
  }

  bool? _readBool(Map<String, dynamic> fields, String key) {
    final value = fields[key];
    if (value is Map && value['booleanValue'] != null) {
      return value['booleanValue'] == true;
    }
    return null;
  }

  DateTime? _readTimestamp(Map<String, dynamic> fields, String key) {
    final value = fields[key];
    if (value is Map && value['timestampValue'] != null) {
      return DateTime.tryParse(value['timestampValue'].toString());
    }
    return null;
  }

  Map<String, dynamic> _toFirestoreMap(Map<String, dynamic> input) {
    final fields = <String, dynamic>{};
    input.forEach((key, value) {
      fields[key] = _toFirestoreValue(value);
    });
    return {'fields': fields};
  }

  dynamic _toFirestoreValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': '$value'};
    if (value is double) return {'doubleValue': value};
    if (value is String) return {'stringValue': value};
    if (value is List) {
      return {
        'arrayValue': {'values': value.map(_toFirestoreValue).toList()},
      };
    }
    if (value is Map) {
      return {'mapValue': _toFirestoreMap(Map<String, dynamic>.from(value))};
    }
    return {'stringValue': value.toString()};
  }

  Map<String, dynamic> _fromFirestoreMap(dynamic raw) {
    if (raw is! Map) return const {};
    final mapValue = raw['mapValue'];
    if (mapValue is! Map) return const {};
    final fields = mapValue['fields'];
    if (fields is! Map) return const {};
    final out = <String, dynamic>{};
    fields.forEach((key, value) {
      out[key.toString()] = _fromFirestoreValue(value);
    });
    return out;
  }

  Map<String, dynamic> _decodeSharedPayload(Map<String, dynamic> fields) {
    final payload = _fromFirestoreMap(fields['payload']);
    if (_readString(fields, 'type') == 'runningRoute') {
      for (final key in ['points', 'waypoints']) {
        final points = payload[key];
        if (points is List) {
          payload[key] = points
              .map((p) => p is Map ? [p['lat'], p['lon']] : p)
              .toList();
        }
      }
    }
    return payload;
  }

  dynamic _fromFirestoreValue(dynamic value) {
    if (value is! Map) return null;
    if (value.containsKey('stringValue')) {
      return value['stringValue'];
    }
    if (value.containsKey('integerValue')) {
      return int.tryParse(value['integerValue'].toString());
    }
    if (value.containsKey('doubleValue')) {
      return (value['doubleValue'] as num?)?.toDouble();
    }
    if (value.containsKey('booleanValue')) {
      return value['booleanValue'] == true;
    }
    if (value.containsKey('timestampValue')) {
      return value['timestampValue'];
    }
    if (value.containsKey('arrayValue')) {
      final values = value['arrayValue']?['values'];
      if (values is! List) return const [];
      return values.map(_fromFirestoreValue).toList();
    }
    if (value.containsKey('mapValue')) {
      return _fromFirestoreMap({'mapValue': value['mapValue']});
    }
    return null;
  }
}

/// Lightweight event bus for friend run notifications from REST polling.
class SocialServiceRunEvents {
  SocialServiceRunEvents._();
  static final SocialServiceRunEvents instance = SocialServiceRunEvents._();

  void Function({
    required String friendUid,
    required String friendName,
    required String routeName,
    required bool active,
  })?
  onRunChanged;

  void emit({
    required String friendUid,
    required String friendName,
    required String routeName,
    required bool active,
  }) {
    onRunChanged?.call(
      friendUid: friendUid,
      friendName: friendName,
      routeName: routeName,
      active: active,
    );
  }
}
