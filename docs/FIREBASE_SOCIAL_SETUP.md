# Firebase Social Setup (Friends)

Kaizen uses **Firebase REST** (Anonymous Auth + Firestore), not the FlutterFire SDK.
Configure your own development project through the ignored `config/local.defines.json` file.
`lib/services/social/social_cloud_config.dart` reads compile-time values; a clean checkout has no default cloud project.

## 1. Create the project

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Add project (e.g. `kaizen-social`)
3. Skip Google Analytics if you want (optional)

## 2. Enable Anonymous Auth

1. **Build → Authentication → Sign-in method**
2. Enable **Anonymous**

## 3. Create Firestore

1. **Build → Firestore Database → Create database**
2. Start in **production mode** (deploy and verify rules before client use)
3. Pick a region close to you

## 4. Configure the client

1. Project settings (gear) → **General**
2. Under **Your apps**, add a **Web** app if none exists (name e.g. `kaizen-web`)
3. Copy:
   - **Project ID** → `FIREBASE_PROJECT_ID`
   - **Web API Key** → `FIREBASE_WEB_API_KEY`
   - Optional **App ID** → `FIREBASE_APP_ID`

Copy `config/example.defines.json` to `config/local.defines.json` and fill the matching fields. These are public client identifiers, not server/admin credentials. Never add a service-account private key to the app.

```sh
flutter run --dart-define-from-file=config/local.defines.json
```

Android Gradle builds automatically include the local Firebase and routing identifiers from this file. Explicit Firebase build parameters select a separate Firebase configuration.

Perform a full restart after changing configuration; hot reload does not update compile-time constants.

## 5. Deploy security rules

**Coordinated upgrade required:** the current rules introduce confirmed friend requests and reject legacy edges for sensitive access. On 2026-11-14 the Community collection rules and their validators were added to the active project's existing production rules. An anonymous Firebase user could list Community runs (HTTP 200), and an unauthenticated request was denied (HTTP 403). The separate friend-request rules in this file still require a coordinated deployment. Upgrade both clients and deploy together, first in a development project. Existing connections need a new request and acceptance; do not stamp old records with `consentVersion` without consent. Old clients cannot create the new request flow.

First run `node tool/run_firestore_rules.mjs` (Node 22+, Java 21+). See [social behavior, limitations and tests](SOCIAL_FEATURES.md).

Copy `firestore.rules` from this repo into **Firestore → Rules → Publish**,
or install Firebase CLI and run:

```bash
firebase login
firebase init firestore   # select this project, use existing firestore.rules
firebase deploy --only firestore:rules
```

The rules include the monthly friends challenge at
`users/{uid}/challenges/{YYYY-MM}` and opt-in completed routes at
`communityRuns/{runId}`. Community routes are readable by signed-in app users
and writable/removable only by the runner who shared them. The map lists runs after a runner explicitly shares one. No collection or document has
to be created manually.

Completed activities now retain their actual GPS track and a local full-route
PNG, together with duration, pace, speed, ascent/descent and estimated calories.
The optional `activity` map is included in friend inbox route payloads and
`communityRuns`. Deploy the current rules before using the new community share;
older rules reject that additional field. Existing posts without it still load.
Sharing lets the sender choose jogging, walking, cycling, hiking or other.
Local history stays private until an explicit share action. Imports create a
reusable route and never award the recipient workout credit. Missing GPS altitude
is shown as unavailable. Older history entries cannot recover unrecorded tracks.

## 6. Smoke test

1. Run Kaizen on two devices / emulators / Windows + phone using your test project
2. Open Friends from Home
3. Exchange `KZN-……` codes
4. The recipient accepts in Friends → Connect; both then appear in each other's list
5. Home → Friends → Monthly Challenge: change the push-up count on one device
6. Pull to refresh on the other device; the new count should appear in the leaderboard
7. Start a run and choose live sharing. Check movement, pause, ten-minute screen lock, reconnect and stop on the other device's map.
8. Share a custom Gym workout, Calisthenics workout and dish. Accept in Inbox; inspect repetitions, weight, ingredients and nutrients. Confirm repeatedly and restart to check duplicates.
9. Remove the friendship and verify that location access and new shares are denied.

## Already done in code

- Friends UI, invite codes, share + inbox
- Monthly challenge leaderboard with per-user Firestore sync
- Firestore REST backend
- Anonymous sign-in **with refresh-token persistence** (stable identity across launches)
- Android deep link `kaizen://friend/{CODE}`

## Release caveats

The full local rules passed the documented emulator checks. The Community deployment is recorded above. Verify the deployed rules and repeat the two-client smoke test. Social refresh state currently uses local Hive storage. Full account/data deletion and social-content reporting remain open; see [data and privacy](DATA_AND_PRIVACY.md).
