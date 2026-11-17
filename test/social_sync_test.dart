import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaizen/models/shared_content.dart';
import 'package:kaizen/models/social_models.dart';
import 'package:kaizen/models/route_activity.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/services/social/firebase_social_backend.dart';
import 'package:kaizen/services/social/live_run_publisher.dart';
import 'package:kaizen/services/social/social_service.dart';
import 'package:kaizen/services/social/social_store.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/screens/social/friend_live_run_detail_screen.dart';

const workout = {
  'name': 'My strength session',
  'exercises': [
    {
      'name': 'Squat',
      'mainGroup': 'Legs',
      'description': 'Controlled tempo',
      'tags': ['quads'],
      'setReps': [8, 7, 6],
      'weight': 60,
    },
  ],
};
const dish = {
  'name': 'Lunch',
  'description': 'My recipe',
  'items': [
    {
      'foodName': 'Eggs',
      'grams': 200,
      'proteinG': 25,
      'carbsG': 2,
      'fatsG': 20,
      'sodiumMg': 280,
    },
  ],
};

InboxMessage message(
  ShareContentType type,
  Map<String, dynamic> payload, {
  String id = 'share-1',
}) => InboxMessage(
  id: id,
  fromUid: 'friend',
  fromName: 'Friend',
  type: type,
  payload: payload,
  status: InboxMessageStatus.pending,
  createdAt: DateTime.now(),
);

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kaizen_social_test_');
    await ProgressStore.init(storageRootPath: directory.path);
    await SocialStore.init();
  });
  tearDown(() async {
    await Hive.close();
    await ProgressStore.closeForTesting();
    await directory.delete(recursive: true);
  });

  FirebaseSocialBackend backend(
    FutureOr<http.Response> Function(http.Request) handler, {
    String? uid = 'me',
    String? token = 'fake-token',
  }) => FirebaseSocialBackend.forTesting(
    client: MockClient((request) async => handler(request)),
    uid: uid,
    idToken: token,
  );

  test(
    'partial acknowledgement uses a mask and never replaces the share payload',
    () async {
      http.Request? patch;
      final api = backend((r) {
        if (r.method == 'PATCH') patch = r;
        return http.Response('{}', 200);
      });
      await api.updateInboxStatusRemote(
        messageId: 'm',
        status: InboxMessageStatus.accepted,
      );
      expect(patch!.url.queryParametersAll['updateMask.fieldPaths'], [
        'status',
      ]);
      expect((jsonDecode(patch!.body)['fields'] as Map).keys, ['status']);
    },
  );

  test('rejected writes fail instead of reporting a sent share', () async {
    final api = backend((r) => http.Response('permission denied', 403));
    await expectLater(
      api.sendShareMessage(
        toUid: 'friend',
        type: ShareContentType.foodDish,
        payload: dish,
      ),
      throwsA(isA<SocialBackendException>()),
    );
    await expectLater(
      api.clearActiveRun(),
      throwsA(isA<SocialBackendException>()),
    );
  });

  test(
    'collection pagination loads beyond the first page and errors retain cache',
    () async {
      var calls = 0;
      final api = backend((r) {
        calls++;
        if (calls == 1) {
          return http.Response(
            jsonEncode({
              'documents': [
                {
                  'name': 'users/me/friends/alice',
                  'fields': {
                    'displayName': {'stringValue': 'Alice'},
                    'consentVersion': {'integerValue': '1'},
                  },
                },
              ],
              'nextPageToken': 'next',
            }),
            200,
          );
        }
        expect(r.url.queryParameters['pageToken'], 'next');
        return http.Response(
          jsonEncode({
            'documents': [
              {
                'name': 'users/me/friends/bob',
                'fields': {
                  'displayName': {'stringValue': 'Bob'},
                  'consentVersion': {'integerValue': '1'},
                },
              },
            ],
          }),
          200,
        );
      });
      await api.refreshFriends();
      expect(SocialStore.friends.map((f) => f.uid), ['alice', 'bob']);
      await expectLater(
        backend((_) => http.Response('', 503)).refreshFriends(),
        throwsA(isA<SocialBackendException>()),
      );
      expect(SocialStore.friends.length, 2);
    },
  );

  test(
    'transient session refresh failure preserves identity and never creates a new user',
    () async {
      await SocialStore.setCloudUid('existing-user');
      await SocialStore.setRefreshToken('fake-refresh');
      var calls = 0;
      final api = backend(
        (r) {
          calls++;
          expect(r.url.host, 'securetoken.googleapis.com');
          return http.Response('', 503);
        },
        uid: null,
        token: null,
      );
      expect(await api.ensureSignedIn(), isFalse);
      expect(SocialStore.cloudUid, 'existing-user');
      expect(SocialStore.refreshToken, 'fake-refresh');
      expect(calls, 1);
    },
  );

  test(
    'friend request creates no unilateral friend edges; accept commits both together',
    () async {
      final requests = <http.Request>[];
      final api = backend((r) {
        requests.add(r);
        return http.Response('{}', 200);
      });
      await api.connectFriend(
        friendUid: 'alice',
        displayName: 'Alice',
        friendCode: 'KZN-ABCDEF',
      );
      expect(
        requests.last.url.path,
        endsWith('/users/alice/friendRequests/me'),
      );
      requests.clear();
      await api.acceptFriendRequest(
        FriendRequest(
          uid: 'alice',
          displayName: 'Alice',
          friendCode: 'KZN-ABCDEF',
          createdAt: DateTime.now(),
        ),
      );
      final commit = requests.first;
      expect(commit.url.path, endsWith('/documents:commit'));
      final writes = jsonDecode(commit.body)['writes'] as List;
      expect(writes.length, 3);
      expect(writes[0]['update']['name'], endsWith('/users/me/friends/alice'));
      expect(writes[1]['update']['name'], endsWith('/users/alice/friends/me'));
      expect(writes[2]['delete'], endsWith('/users/me/friendRequests/alice'));
    },
  );

  for (final type in [
    ShareContentType.gymWorkout,
    ShareContentType.calisthenicsWorkout,
    ShareContentType.foodDish,
  ]) {
    test(
      'shared $type imports once across repeated confirmation and restart',
      () async {
        final incoming = message(
          type,
          type == ShareContentType.foodDish ? dish : workout,
        );
        final ids = await Future.wait([
          ProgressStore.importSharedMessage(incoming),
          ProgressStore.importSharedMessage(incoming),
        ]);
        expect(ids[0], ids[1]);
        List<Map<String, dynamic>> entries() => switch (type) {
          ShareContentType.gymWorkout => ProgressStore.gymWorkouts,
          ShareContentType.calisthenicsWorkout =>
            ProgressStore.calisthenicsWorkouts,
          _ =>
            ProgressStore.foodDishes
                .where((entry) => entry['sharedSource'] != null)
                .toList(),
        };
        expect(entries().length, 1);
        if (type == ShareContentType.foodDish) {
          expect(entries().single['items'][0]['sodiumMg'], 280);
          expect(entries().single['description'], 'My recipe');
        } else {
          expect(entries().single['exercises'][0]['setReps'], [8, 7, 6]);
          expect(entries().single['exercises'][0]['weight'], 60);
        }
        await ProgressStore.closeForTesting();
        await ProgressStore.init(storageRootPath: directory.path);
        expect(await ProgressStore.importSharedMessage(incoming), ids[0]);
        expect(entries().length, 1);
      },
    );
  }

  test(
    'failed remote acknowledgement cannot duplicate an already imported dish',
    () async {
      var status = 503;
      final service = SocialService.forTesting(
        backend((_) => http.Response('{}', status)),
      );
      final incoming = message(ShareContentType.foodDish, dish);
      final before = ProgressStore.foodDishes.length;
      await expectLater(
        service.acceptMessage(incoming),
        throwsA(isA<SocialBackendException>()),
      );
      expect(ProgressStore.foodDishes.length, before + 1);
      status = 200;
      await service.acceptMessage(incoming);
      expect(ProgressStore.foodDishes.length, before + 1);
      expect(SocialStore.inbox.single.status, InboxMessageStatus.accepted);
    },
  );

  test('malformed incoming content is rejected before local writes', () async {
    final before = ProgressStore.foodDishes;
    for (final payload in [
      {'name': 'Empty', 'items': []},
      {
        'name': 'Bad',
        'items': [
          {
            'foodName': 'Eggs',
            'grams': -1,
            'proteinG': 1,
            'carbsG': 0,
            'fatsG': 0,
          },
        ],
      },
    ]) {
      await expectLater(
        ProgressStore.importSharedMessage(
          message(ShareContentType.foodDish, payload),
        ),
        throwsA(isA<FormatException>()),
      );
    }
    expect(ProgressStore.foodDishes, before);
    expect(
      () => normalizeSharedContent(ShareContentType.gymWorkout, {
        'name': 'Bad',
        'exercises': [],
      }),
      throwsFormatException,
    );
  });

  test(
    'live writer sends actual fix, stable start time, paused state and bounded full trail',
    () async {
      http.Request? sent;
      final api = backend((r) {
        sent = r;
        return http.Response('{}', 200);
      });
      final start = DateTime.utc(2026, 10, 5, 12);
      await api.publishLiveRun(
        LiveRunUpdate(
          routeId: 'run',
          routeName: 'Lunch run',
          latitude: 52.5,
          longitude: 13.4,
          distanceMeters: 2100,
          startedAt: start,
          positionUpdatedAt: start.add(const Duration(minutes: 10)),
          paused: true,
          recordedPoints: List.generate(1000, (i) => [52.0 + i / 10000, 13.0]),
          plannedPoints: [],
        ),
      );
      final fields = jsonDecode(sent!.body)['fields'];
      expect(fields['latitude']['doubleValue'], 52.5);
      expect(fields['startedAt']['timestampValue'], start.toIso8601String());
      expect(fields['paused']['booleanValue'], isTrue);
      final points = fields['recordedPoints']['arrayValue']['values'] as List;
      expect(points.length, 400);
      expect(points.first['mapValue']['fields']['lat']['doubleValue'], 52.0);
      expect(
        points.last['mapValue']['fields']['lat']['doubleValue'],
        closeTo(52.0999, .00001),
      );
    },
  );

  test(
    'live publisher coalesces pending positions and stop cannot resurrect the run',
    () async {
      final first = Completer<void>();
      final events = <String>[];
      final publisher = LiveRunPublisher<int>(
        send: (v) async {
          events.add('send:$v');
          if (v == 1) await first.future;
        },
        clear: () async {
          events.add('delete');
        },
      );
      publisher.start();
      publisher.update(1);
      publisher.update(2);
      publisher.update(3);
      final stopped = publisher.stop();
      publisher.update(4);
      expect(events, ['send:1']);
      first.complete();
      await stopped;
      expect(events, ['send:1', 'delete']);
    },
  );

  test(
    'live publisher keeps only newest pending snapshot while running',
    () async {
      final first = Completer<void>();
      final newest = Completer<void>();
      final events = <int>[];
      final publisher = LiveRunPublisher<int>(
        send: (v) async {
          events.add(v);
          if (v == 1) await first.future;
          if (v == 3) newest.complete();
        },
        clear: () async {},
      );
      publisher.start();
      publisher.update(1);
      publisher.update(2);
      publisher.update(3);
      first.complete();
      await newest.future;
      await publisher.stop();
      expect(events, [1, 3]);
    },
  );

  test(
    'deleted run clears receiver presence and resets start notification',
    () async {
      final friend = FriendConnection(
        uid: 'alice',
        displayName: 'Alice',
        friendCode: 'KZN-ABCDEF',
        notifyOnRunStart: true,
        connectedAt: DateTime.now(),
      );
      final events = <bool>[];
      SocialServiceRunEvents.instance.onRunChanged =
          ({
            required friendUid,
            required friendName,
            required routeName,
            required active,
          }) => events.add(active);
      addTearDown(() => SocialServiceRunEvents.instance.onRunChanged = null);
      await backend(
        (_) => http.Response('', 404),
      ).refreshFriendLiveRuns([friend]);
      expect(SocialStore.friendLiveRuns, isEmpty);
      expect(events, [false]);
    },
  );

  test(
    'shared route uses Firestore-compatible points and decodes before import',
    () async {
      Map<String, dynamic>? document;
      final api = backend((request) {
        if (request.method == 'PATCH' && request.url.path.contains('/inbox/')) {
          document = jsonDecode(request.body) as Map<String, dynamic>;
        }
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'documents': [
                {'name': 'users/me/inbox/route', ...document!},
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });
      await api.sendShareMessage(
        toUid: 'friend',
        type: ShareContentType.runningRoute,
        payload: {
          'name': 'Park',
          'points': [
            [52.0, 13.0],
            [52.1, 13.1],
          ],
          'waypoints': [
            [52.0, 13.0],
            [52.1, 13.1],
          ],
          'distanceMeters': 1000,
          'activity': const RouteActivity(
            type: RouteActivityType.hiking,
            durationSeconds: 1200,
            descentMeters: 50,
            elevationRecorded: true,
          ).toJson(),
        },
      );
      final first =
          document!['fields']['payload']['mapValue']['fields']['points']['arrayValue']['values'][0];
      expect(first['mapValue']['fields']['lat']['doubleValue'], 52.0);
      await api.refreshInbox();
      expect(SocialStore.inbox.single.payload['points'], [
        [52.0, 13.0],
        [52.1, 13.1],
      ]);
      await ProgressStore.importSharedMessage(SocialStore.inbox.single);
      expect(ProgressStore.runningRoutes.single['name'], 'Park');
      expect(
        (ProgressStore.runningRoutes.single['activity'] as Map)['type'],
        'hiking',
      );
      expect(
        (ProgressStore.runningRoutes.single['activity']
            as Map)['durationSeconds'],
        1200,
      );
    },
  );

  test(
    'community round trip retains activity and all measured metrics',
    () async {
      Map<String, dynamic>? document;
      final api = backend((request) {
        if (request.method == 'PATCH') {
          document = jsonDecode(request.body) as Map<String, dynamic>;
        }
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'documents': [
                {'name': 'communityRuns/ride', ...document!},
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });
      final activity = RouteActivity(
        type: RouteActivityType.cycling,
        durationSeconds: 1800,
        descentMeters: 85,
        maxSpeedKmh: 31.2,
        calories: 400,
        elevationRecorded: true,
        recordedAt: DateTime(2026, 11, 10),
      );
      await api.publishCommunityRun(
        CommunityRun(
          id: 'ride',
          uid: 'me',
          displayName: 'Me',
          routeName: 'Ride',
          distanceMeters: 12000,
          ascentMeters: 90,
          points: [
            [52, 13],
            [52.01, 13.01],
          ],
          createdAt: DateTime.now(),
          activity: activity,
        ),
      );
      final restored = (await api.refreshCommunityRuns()).single;
      expect(restored.activity!.toJson(), activity.toJson());
      expect(restored.distanceMeters, 12000);
      expect(restored.ascentMeters, 90);
      expect(restored.activity!.averageSpeed(restored.distanceMeters), 24);
    },
  );

  testWidgets('detail never falls back to a cached location after a run ends', (
    tester,
  ) async {
    final now = DateTime.now();
    final oldRun = FriendLiveRun(
      uid: 'alice',
      displayName: 'Alice',
      routeId: 'r',
      routeName: 'Park',
      latitude: 52,
      longitude: 13,
      distanceMeters: 100,
      currentPaceSecPerKm: null,
      avgPaceSecPerKm: null,
      recordedPoints: const [],
      plannedPoints: const [],
      startedAt: now,
      updatedAt: now,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FriendLiveRunDetailScreen(run: oldRun),
      ),
    );
    await tester.pump();
    expect(find.textContaining('This run has ended'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
