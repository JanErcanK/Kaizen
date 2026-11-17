# Application audit

**Reviewed:** 17 October 2026

**Historical snapshot:** the findings below describe the 17 October tree. Later health, anatomy and share/carousel changes, corrected iOS deployment metadata and current validation are documented in [latest verification](release/VERIFICATION.md), [testing](TESTING.md) and [the changelog](../CHANGELOG.md). Statements below about an uncommitted tree or earlier test counts are dated audit evidence, not the current Git status.

**Repository:** FitFlow · **Application:** Kaizen

**Status:** Android bundle builds locally; release readiness is **not confirmed**.

This is a code and configuration audit of the current working tree. It covers application structure, local persistence, health and AI integrations, maps, Firebase social features, platform metadata, automated checks, and release documentation. It is not a penetration test, legal review, production Firebase inspection, or store approval.

## Executive summary

The project has a clear Flutter structure and unusually good developer documentation for its size. Local tests and the Firestore Rules emulator pass, and a signed Android App Bundle was produced for the current code. The local Android target is API 36, which matches Google Play's target requirement for new apps and updates from 31 August 2026.

The app is **not ready for a public store release yet**. The working tree is uncommitted, Play Console version availability is unknown, and current production Firestore rules cannot be confirmed from this repository. Privacy and social safety work remains, and location sharing has not passed a two-device release-build check. An iOS upload is not ready because the bundle ID is still a template and the deployment target conflicts with an installed plugin requirement.

## Project map

| Area | Main responsibility |
| --- | --- |
| `lib/screens/`, `lib/navigation/` | Home, profile, chat, workouts, nutrition, running, friends and app navigation |
| `lib/services/`, `lib/models/` | Progress persistence, health imports, AI requests, routing, notifications and domain data |
| `lib/services/social/`, `lib/screens/social/` | Anonymous Firebase REST auth, friend requests, live presence, challenges, inbox and sharing |
| `firestore.rules` | Access control for profiles, friendships, inbox, challenge records and live presence |
| `test/`, `tool/` | Flutter regression tests, screenshot capture and local Firestore Rules emulator checks |
| `docs/` | Setup, architecture, data handling, feature behavior, tests, release steps and decisions |

The working tree contains a substantial documentation set. This audit is the current status entry point; the [documentation index](README.md) links the focused guides.

## Verification evidence

| Check | Result | What it establishes |
| --- | --- | --- |
| `flutter test --reporter expanded` | **40 passed** | Current widget, service, persistence and social regression tests pass; provider calls are mocked |
| `node tool/run_firestore_rules.mjs` | **19 passed** | Local rules allow intended operations and deny tested unauthorized operations in an isolated emulator |
| `flutter analyze lib test tool --no-fatal-infos --no-fatal-warnings` | **0 errors, 57 warnings, 35 informational findings** | No analyzer errors; existing warning and lint debt remains |
| Android release build | **AAB built and signed** | Current source can produce an Android bundle using local configuration and signing files |
| AAB signer comparison | **Matches local upload certificate** | The artifact uses the repository's expected local certificate; Play Console identity is unverified |
| `git diff --check` | **Passed** | No whitespace errors; Git reports Windows line-ending normalization notices |

See the dated [verification record](release/VERIFICATION.md) for the current artifact hash, target SDK and limitations. These checks do not replace device, production-backend or store validation.

## Firestore and social features

### Configuration

- The ignored `config/local.defines.json` is present. Its `FIREBASE_PROJECT_ID`, `FIREBASE_WEB_API_KEY` and `FIREBASE_APP_ID` fields are populated, and the Dart configuration reads the matching names.
- The Firebase web API key and app ID are client configuration values, not Firebase Admin credentials. No service-account key was found in the local build configuration.
- `firebase.json` points to `firestore.rules`. The repository has no `.firebaserc`, no `firestore.indexes.json`, and the Firebase CLI is unavailable in this environment.
- The actual configured project's console state and deployed rules are therefore unknown. There is no evidence in this audit that rules were deployed or that they match the local file. Do not treat the 19 emulator passes as production verification.

### Access and behavior reviewed

- Friend codes create requests; knowing a code alone does not grant access. The recipient must accept. Acceptance writes reciprocal friendship records atomically and includes `consentVersion: 1`.
- Live location and challenge reads require a reciprocal accepted friendship. Location reads are limited to an exact active-run document and fresh presence; unrelated collection listing is denied.
- A run is shared only after the explicit share-and-start action. The publisher coalesces queued updates and orders stop after in-flight writes so delayed updates do not recreate a stopped run.
- Workout, dish and route shares are separate inbox copies. The client validates incoming content and records imports to prevent duplicate local entries.
- The app polls rather than using server push: live views refresh about every five seconds and normal social refresh is slower. Background location behavior still needs real-device testing.

### Remaining backend and social risks

| Priority | Finding | Required release evidence or work |
| --- | --- | --- |
| High | Production Firestore project and deployed rules are unverified | Identify the intended project, inspect deployed rules, deploy the reviewed rules through the authorized Firebase account, then run a two-client smoke test |
| High | Social refresh token is persisted in local Hive storage rather than platform secure storage | Move credentials to secure storage and verify migration, refresh, reinstall and sign-out behavior |
| High | No complete cloud-account and associated-data deletion flow | Implement deletion and document retention; verify removal of user, friend-code, request, inbox, challenge and presence records |
| High | Social reporting/blocking and server-side request rate controls are absent | Define abuse handling and enforce limits before public social rollout |
| Medium | Rules limit top-level share fields and collection sizes, while nested content validation is mainly client-side | Strengthen server-side nested schema and abuse limits; treat client validation as defense in depth |
| Medium | Device timestamps influence live-run freshness; failed stop deletion can leave a stale owner-readable presence record | Test clock skew/network failure; define cleanup and retention rather than relying only on the two-minute read window |
| Medium | Outbound shares have no durable idempotency key | A timeout after server commit can make a retry create a second inbox item; consider a stable request ID |

The local rules tests cover relationship consent, atomic acceptance, spoofing, stale locations and revocation. They cannot prove behavior of deployed rules or Android/iOS background services. See [social behavior and rollout notes](SOCIAL_FEATURES.md) and the [structured rules assessment](security/firestore-audit.json).

## Privacy, integrations and data boundaries

- Fitness history and chat records are stored locally. Attached meal images remain in app storage. The audit found no general automatic cloud backup of the full profile.
- Health data is read from Health Connect or Apple Health. Android declares `READ_STEPS` and `READ_SLEEP`; the Play health declaration and purpose disclosures must match the actual release behavior.
- Chat text and meal photos can be sent to the user-selected AI provider. The code and developer disclosure are not a substitute for a clear, provider-specific consent and revocation flow.
- AI credentials use platform secure storage; social refresh credentials do not. Local Hive content is not application-level encrypted.
- The configured OpenRouteService key is compiled into the client app for route requests. Treat it as extractable: restrict it to the needed API, rotate any key exposed by earlier builds/history, and set provider quotas. `--dart-define` keeps values out of source control when configured correctly; it does not make a value secret inside an installed binary.
- There is no public privacy/support URL or complete account-deletion process recorded in this repository. Store privacy, data-safety and health declarations need the real operator and production configuration.

More detail is in [data and privacy](DATA_AND_PRIVACY.md), [AI chat](AI_CHAT.md) and [third-party notices](THIRD_PARTY_NOTICES.md).

## Release readiness

### Android

The current local bundle is `build/app/outputs/bundle/release/app-release.aab`, application ID `de.jankilic.kaizen`, version `1.1.0+2`, minimum SDK 28 and target SDK 36. It was signed with a certificate matching `android/upload_certificate.pem`. A separate sideload APK was built at `build/app/outputs/flutter-apk/app-release.apk` with build number 3 so it can upgrade a previously installed build 2. Neither artifact has been installed on a phone or validated by Play, and the local signer has not been compared with the active Play Console certificate. Check Play Console before selecting an upload code; code 2 and code 3 availability are unknown.

Before submission, finish the high-priority items above, confirm rights and attribution for every shipped asset, complete AI and health declarations, check route-key restrictions, run the release scenarios on a physical device, and test the actual Firebase project with two upgraded clients. Google Play's [target API policy](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en) currently requires API 36 for new apps and updates.

### iOS

The configured bundle identifier is still `com.example.kaizen`. The project deployment target is 13.0 while the installed `health` plugin requires 14.0. This Windows checkout has no verified signed archive, App Store Connect identity, Xcode device run or HealthKit declaration. iOS distribution requires those items to be resolved on a Mac.

### Repository state and upload

The working tree contains many modified and untracked application, test and documentation files. It is not a clean, reviewed release commit. The local AAB is a review artifact only; no GitHub push, Firebase rules deployment or store upload was performed. Choose the destination, verify its current version/build number and access, review the audit findings, then commit and upload the approved artifact.

## Store policy references

- [Google Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
- [Google Play health apps declaration](https://support.google.com/googleplay/android-developer/answer/14738291?hl=en)
- [Google Play account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en-gb)
- [Google Play AI-generated content policy](https://support.google.com/googleplay/android-developer/answer/13985936?hl=en)
