# Latest verification — 2026-10-25

This record accompanies the current source/documentation snapshot. Checks are local unless identified as GitHub Actions evidence; they do not establish store approval, an iOS build, production Firebase verification or a completed live AI analysis.

## Current checks

| Check | Result | Scope / limitation |
| --- | --- | --- |
| `flutter test --no-pub --reporter expanded` | **187 passed** | Entire `test/` suite, including three Home persistence lifecycle regressions; AI responses are mocked |
| `flutter analyze --no-pub lib test tool --no-fatal-infos --no-fatal-warnings` | **0 errors, 59 warnings, 36 info** | Error-level gate passes; existing analyzer debt remains |
| Targeted analysis of share/chat changes and diagnostics | **No issues** | Ten changed source/test/diagnostic files |
| `node test/anatomy_viewer_test.cjs` | **PASS** | Real bundled GLBs with Babylon NullEngine; not a physical-phone GPU test |
| Live Instagram import diagnostic | **9 images decoded, 6,665,979 PNG bytes** | Exact supplied public carousel, all slides in order; no AI API call |
| Android release APK | **Built successfully before the CI fix** | `1.1.0+3` at `37c7eb6`; no new physical-device installation |
| Firestore emulator | **GitHub Actions job passed at `37c7eb6`** | [Run 40206742480](https://github.com/JanErcanK/FitFlow/actions/runs/40206742480); deployed rules remain unverified |
| Remote CI | [Results by pushed revision](https://github.com/JanErcanK/FitFlow/actions/workflows/verify.yml) | The first run at `37c7eb6` failed in a Home test after database teardown; setup, analysis and rules passed. Local success alone does not establish a green remote run. |

The CI follow-up saves the Home-open counter and analytics start date in one operation. Three deterministic lifecycle tests failed with the original `Box has already been closed` error before this change and passed afterward; the full local suite passes 187 tests. See the [failure diagnosis and regression details](../TESTING.md#home-persistence-and-github-ci--2026-10-25). The APK below predates this small persistence change and was not rebuilt for the CI follow-up.

The carousel diagnostic uses `https://www.instagram.com/p/De3BL_pCByI/?img_index=6`. This is a nine-image post; the viewing index does not discard other slides. Regression tests cover ordered image payloads, slide-number persistence, cold/warm navigation, inaccessible-media fallback and saving only after confirmation. The older Reel example below did not expose downloadable video; public import remains best effort.

## Current Android artifact

- Source version: `1.1.0+3`; application ID: `de.jankilic.kaizen`.
- Build command: `flutter build apk --release --no-pub --dart-define-from-file=config/local.defines.json`.
- Named APK: `build/app/outputs/flutter-apk/Kaizen-1.1.0-instagram-import.apk`.
- Size: **196,630,793 bytes**.
- SHA-256: `D11966179C16376CA06C9CA2F065F815133727530B2ADD8B23806EC16CC98476`.
- The named APK is a copy of the successful release output. APK/AAB binaries, local service definitions and signing secrets are excluded from Git; source, required assets, tests and documentation are versioned.

The latest APK still needs an Android share-sheet/device test and real configured-provider analysis. Build number 3 is a sideload version, not proof that this number is available for a Play upload. No store upload, backend deployment or iOS archive was performed. [Release follow-up](../RELEASE.md).

---

# Historical verification — 2026-10-17

This is local evidence for the current working tree, not a published release or a clean commit. The build, source and test files remain uncommitted. No GitHub push, store upload, Firebase deployment, production Firestore read, or iOS archive was performed.

## Current checks

| Check | Result | Scope / limitation |
| --- | --- | --- |
| `flutter test --reporter expanded` | **40 passed** | Provider calls are mocked; no real-device/native behavior is covered |
| `node tool/run_firestore_rules.mjs` | **19 passed** | Official emulator, localhost `demo-kaizen`; does not inspect production rules |
| `flutter analyze lib test tool --no-fatal-infos --no-fatal-warnings` | **0 errors, 57 warnings, 35 info** | Command succeeds, but existing analyzer debt remains |
| Android release AAB | **Built successfully** | No Play Console validation or device install |
| Android sideload APK | **Built successfully, build number 3** | Signature verified; not installed on a phone |
| `git diff --check` | **Passed** | Git reports line-ending normalization notices in existing Windows working files |

Toolchain: Windows, Flutter 3.44.8 / Dart 3.12.2, Node 24.19.0, Android Studio bundled Java 25.0.2. The Firestore runner used only the localhost demo project.

## Current Android bundle

- Output: `build/app/outputs/bundle/release/app-release.aab` (146.6 MB).
- Application ID: `de.jankilic.kaizen`; source version: `1.1.0+2`.
- Merged manifest: minimum SDK **28**, target SDK **36**.
- AAB SHA-256: `82B94A7A6A50503E7975BD84210509093EC7F0AA77A7D200549836000F5B8A00`.
- The signer fingerprint matches `android/upload_certificate.pem` (SHA-256 `3A:4E:FD:E8:06:6C:DF:93:0A:7F:E8:72:3E:2A:2D:EB:C6:87:28:A4:57:2F:05:E6:A1:56:5D:56:03:15:8E:27`). This confirms the local signing identity only; it has not been compared with Play Console's current upload certificate.
- Sideload test APK: `build/app/outputs/flutter-apk/app-release.apk`, version name `1.1.0`, version code **3**, 172.8 MB. `apksigner` verification passes and its certificate matches the same local upload certificate. SHA-256: `D645269E43BFF8C4C92228807AAB5DC87A9444123880F10E49BAC8927BC5440B`.
- Version code **2** may already have been used. Check Play Console and select an unused number before another upload.

The test APK uses build number 3 so it can upgrade a previously installed build 2. This does not establish that code 3 is available in Play Console; check the console before producing or uploading the submission bundle.

The bundle has not been installed on a phone, validated by Play, exercised on a 16 KB page-size device, or checked against the currently configured store record. The earlier APK and device checks below are historical.

## Current backend evidence

`config/local.defines.json` is present and Git-ignored; its Firebase project, web API key and app ID fields are populated. The source reads the matching `FIREBASE_*` names. Their values are deliberately not recorded here. The repository has no `.firebaserc`, Firebase CLI is unavailable, and there is no authenticated deployment evidence. Therefore the active Firebase project and production Firestore rules remain **unverified**. Local emulator success does not establish production deployment.

See the [application audit](../APP_AUDIT.md) for privacy, location-sharing, account deletion and social rollout findings.

---

# Historical verification record — 2026-10-05

This records local working-tree evidence, not a published release or a clean committed revision. The repository contains uncommitted application and documentation changes. No GitHub push, store upload, Firebase rules deployment or iOS archive was performed.

## Automated results

| Check | Result | Scope / limitation |
| --- | --- | --- |
| `flutter test --reporter expanded` | **40 passed** | Includes 16 social regression checks; provider requests use mocks |
| `node tool/run_firestore_rules.mjs` | **19 passed** | Official emulator 1.22.0, localhost demo project; does not test deployed production rules |
| `flutter analyze lib test tool --no-fatal-infos --no-fatal-warnings` | **0 errors**, 56 warnings, 34 informational findings | Error-level gate passed; this is not lint-clean |
| `flutter test tool/capture_screenshots_test.dart` | **1 passed** during documentation capture | Actual widgets, synthetic profile/chat data; three PNGs visually inspected |
| Android release AAB | **Built successfully** | Current local service definitions; version availability/store validation still open |
| Android release APK | **Built successfully** | Not installed during this pass; no connected USB device |
| iOS archive/device check | **Not performed** | Requires Mac/Xcode, real signing identity and native setup |
| GitHub Actions | **Configured, not run remotely** | Flutter checks plus a credential-free emulator job |

Toolchain: Windows, Flutter 3.44.8 / Dart 3.12.2. The emulator was tested with the Android Studio Java 25 runtime; its documented runner requires Java 21+ and Node 22+.

## Android artifacts

- Application ID: `de.jankilic.kaizen`.
- Version: `1.1.0`, version code **2**. Check Play Console before choosing an unused upload number; do not assume code 2 can be uploaded again.
- APK manifest inspected with Android SDK `aapt`: minimum SDK **28**, target/compile SDK **36**.
- AAB: `build/app/outputs/bundle/release/app-release.aab` (approximately 146.5 MB).
- APK: `build/app/outputs/flutter-apk/app-release.apk` (approximately 172.6 MB).
- The AAB signing certificate matches the repository's `android/upload_certificate.pem`. Its relationship to the current Play Console upload certificate has not been independently rechecked.
- `apksigner verify` passes for the APK (v2 signature); the certificate matches the same upload certificate. `jarsigner -verify` passes for the AAB, with expected warnings about its self-signed certificate/no timestamp.
- APK ZIP alignment passes `zipalign -c -P 16 4`. All 12 packaged 64-bit native libraries (`arm64-v8a` and `x86_64`) have ELF load-segment alignment of at least 16,384 bytes. This static inspection does not replace a 16 KB-page device/emulator run or Play bundle validation.

Certificate SHA-256:

```text
3A:4E:FD:E8:06:6C:DF:93:0A:7F:E8:72:3E:2A:2D:EB:C6:87:28:A4:57:2F:05:E6:A1:56:5D:56:03:15:8E:27
```

AAB SHA-256:

```text
E4B008A87AF7C86C2802BB921BA71A7E23FB3B6AC98CABFA3068F629DF65026A
```

APK SHA-256:

```text
633702E53874F3EBDC92936AC7EAADCF1303B18AC330B497613A0ABC5239088C
```

These hashes identify local diagnostic artifacts, not an approved store submission. Play bundle validation, 16 KB runtime verification, actual console declarations and update testing remain part of the release checklist.

## Social findings and rollout

The local changes address partial PATCH data loss, silent write failures, unstable offline startup, unconfirmed friendship/location access, repeated imports, GPS/heartbeat handling, stop/write races and stale live views. See [social design and tests](../SOCIAL_FEATURES.md) and the [rules assessment](../security/firestore-audit.json).

The new client and rules must be rolled out together. Old connections need a fresh request and acceptance. No live Firebase records or rules were changed in this audit. Test with two upgraded clients before production: confirmed friendship, start/share, movement, pause, screen lock, network recovery, stop/removal and shared-content import. A successful emulator run cannot prove Android/iOS background behavior.

## Device and release limits

The preceding Motorola razr 60 ultra session installed an earlier APK, and the user reported the body-map improvement. No USB device was connected when checked in this pass. The newly generated APK and social fixes have therefore **not** been installed or verified on that phone.

Real OpenAI/Claude text/photo tests remain unverified because funded API usage was unavailable. iOS still needs its registered bundle identifier, team/signing, compatible deployment target, dependency integration and physical-device testing. Published privacy/support/deletion details, content reporting, asset provenance and historical routing-token rotation remain open. [Full release checklist](../RELEASE.md).
