# Friends, live runs and shared content

Reviewed on **2026-10-17**. This describes the working tree. The local Firebase rules passed the emulator checks, but deployment state cannot be confirmed from this repository; no deployment was performed during this audit. The two-device flow has **not** been verified on physical phones.

## Connect with a friend

Open Home → Friends → Connect, exchange the `KZN-…` code, and send a request. The recipient accepts it in Connect. The app commits both friendship records and removes the request atomically. Knowing a code alone grants no location or challenge access.

Old records did not prove recipient consent. The new rules require `consentVersion: 1` on both records. Old connections are excluded from the refreshed friend list; exchange codes and accept a new request once after upgrading. Existing workout history and imported dishes are retained.

## Watch a run

The runner starts a run and chooses **Share & start**. Accepted friends open Home → Lauf, turn on the Friends map layer, and tap a runner for route, distance, pace and pause/GPS status. Private recording does not publish location. The live trail is dashed and sampled points carry timestamps so older sections fade and thin.

## Community runs

The Community map layer shows completed routes shared by signed-in Kaizen users. Sharing is off by default; the runner must check the separate sharing option in the finish summary. Long-press Community to filter by distance and elevation gain. A user can remove their own shared route from its map marker. A shared route is visible to other signed-in Community members.

The app publishes the actual GPS fix, never the planned origin. Heartbeats are approximately five seconds apart, including while standing or paused. Open live views poll approximately every five seconds; normal end-to-end delay can approach ten seconds plus network latency. Elsewhere the social poll is approximately twenty seconds. This is polling, not a guaranteed instantaneous stream.

Only one location write is in flight; queued snapshots are replaced by the latest one. Stopping prevents new updates, waits for the in-flight write, then deletes presence, preventing delayed writes from recreating a finished run. Connection failures produce a visible status. Cached presence expires after two minutes without updates; rules also reject stale friend reads using the published timestamp. Device clock skew can affect this window. GPS sample age is checked separately from heartbeat age.

Recorded trails are sampled across the entire route to at most 400 points; planned paths are limited to 1,000 points. Invalid coordinates are filtered before rendering.

Android tracking uses a foreground location service with a persistent notification and wake lock. iOS declares background location and uses fitness location settings. Screen lock, battery saver and real-device behavior still need verification. Force-stop is not a supported tracking mode. Run-start notifications depend on app polling; there is no server push service for a closed viewer app.

## Share your own workout or dish

- Gym/Calisthenics → workout menu → Share → choose a friend.
- Nutrition → open the saved dish → Share → choose a friend.
- The friend accepts the item in Inbox to create a local copy.

Workouts preserve exercises, repetitions/sets and weight. Dishes preserve ingredients, portions, macros and available additional nutrient fields. Imports validate shapes, finite numbers and limits, create a new local ID, and retain a sender/message receipt. Repeated confirmation, restart or a failed remote acknowledgement do not create another copy.

These are independent copies; later sender edits do not update them. Sending succeeds in the UI only after Firestore accepts the write. A timeout can still be ambiguous if the server committed before its reply was lost: retrying the entire send can create a second distinct inbox message. Durable outbound delivery IDs remain future work.

## Implementation

| Component | Responsibility |
| --- | --- |
| `FirebaseSocialBackend` | Auth refresh, HTTP timeouts/errors, pagination, masked PATCH, atomic friendship commits |
| `SocialService` / `SocialStore` | Offline startup retry, polling, local social cache and inbox |
| `LiveRunPublisher` | Coalescing location updates and ordering stop/delete |
| `normalizeSharedContent` | Incoming/outgoing shape, size and numeric validation |
| `ProgressStore.importSharedMessage` | Serialized imports and durable duplicate receipts |
| `firestore.rules` | Recipient consent, mutual friendship, ownership, field restrictions and stale-location denial |

Firestore PATCH without `updateMask` replaces omitted fields. All partial patches now supply a mask: status updates preserve inbox payloads and notification settings preserve friend metadata. Shared routes use coordinate maps on the wire because Firestore disallows directly nested arrays; the client decodes them to pairs.

## Security and remaining work

Original local rules allowed unrelated signed-in users to read locations, unilateral creation of reciprocal friendships and arbitrary inbox senders. The new rules fix these findings and passed official-emulator tests. This is not evidence that production has these rules. See the [structured assessment](security/firestore-audit.json).

Before public rollout: add request-spam/rate controls, reporting/blocking, cloud account deletion, secure refresh-token storage and deployed-rule verification. Anonymous identity survives ordinary launches, but there is no recovery/sign-in flow guaranteeing the same social account after reinstall or on another device. Rules bound major lists and fields; the receiving app additionally validates nested shared data.

## Verification

```sh
flutter test test/social_sync_test.dart
node tool/run_firestore_rules.mjs
```

The second command needs Node 22+ and Java 21+ (`JAVA_HOME` or PATH). It downloads official emulator 1.22.0 into ignored `build/social-emulator`, verifies a pinned SHA-256, starts **localhost:8185 / demo-kaizen**, runs 19 scenarios and stops. No login, Firebase credentials or paid services are used. Port 8185 must be free. Only the disposable demo database is cleared.

Flutter tests cover masked writes, rejected requests, pagination/cache retention, refresh failure, friend requests, Gym/Calisthenics/dish imports, acknowledgement retries, malformed payloads, location fields, bounded trails, stop races, route encoding and ended-run UI. Emulator checks cover allowed/denied operations, spoofed identities, pending requests, legacy edges, atomic acceptance, stale positions and friendship removal.

Follow the coordinated upgrade in [Firebase setup](FIREBASE_SOCIAL_SETUP.md). Then test two upgraded clients against a development project: request/accept, live start, movement, pause, ten-minute screen lock, network loss/recovery, stop, removal, and workout/dish sharing with repeated confirmation. Record devices, OS versions and build hashes. Automated tests do not replace this pass.
