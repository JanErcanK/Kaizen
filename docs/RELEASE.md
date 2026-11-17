# Android and iOS release preparation

Last reviewed: **2026-10-17**. This is a working release plan, not approval to publish or a claim of store readiness. See the [application audit](APP_AUDIT.md) and [latest verification evidence](release/VERIFICATION.md).

Implementation/build facts updated **2026-10-25**: source version `1.1.0+3`, iOS deployment target 14.0, and the Android share/carousel APK builds successfully. Store-policy and publication requirements below must still be rechecked before submission.

## Current identity

| Item | Current repository value |
| --- | --- |
| Display name | Kaizen |
| Flutter package | `kaizen` |
| Version in `pubspec.yaml` | `1.1.0+3` |
| Android package | `de.jankilic.kaizen` |
| Android minimum | API 28 |
| Android target in the current local release build | API 36 |
| iOS bundle identifier | `com.example.kaizen` — template value; must be replaced with the registered App ID |
| iOS deployment target | 14.0 in project and framework metadata; native build still needs verification on Mac |

**Do not reuse version code 2 for an upload without checking Play Console.** The old build-2 document does not prove whether that number was already uploaded. Decide the next version/build against both consoles, then update `pubspec.yaml` and the release notes together.

The current sideload APK also uses code **3**; this does not prove that code 3 is available for a store upload. All APKs, including named distribution copies, belong in `build/app/outputs/flutter-apk/`. Build artifacts and private local configuration are excluded from Git.

Google Play requires new apps and updates to target Android 16 / API 36 from **31 August 2026**. The current local bundle meets that target; verify again against the [official target API policy](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en) when selecting the track.

## Blocking work before submission

| Priority | Item | Required evidence / owner input |
| --- | --- | --- |
| Required | Real AI verification | Funded text and meal-photo requests to both providers; review/edit/confirm on a physical release build |
| Required | Privacy and third-party AI | Public privacy/support URLs, operator contact and explicit provider-specific sharing consent; test denial and revocation paths |
| Required | Generated/social content | Functional content reporting and moderation handling; review social blocking/reporting |
| Required | Cloud account/data deletion | End-to-end deletion of anonymous identity and related cloud records; user-facing process and retention policy |
| Required | Health declarations | Health Connect rationale/privacy access, least-privilege reads, Play health declaration and iOS HealthKit verification |
| Required | Rights and service configuration | Complete asset provenance and required attribution; rotate the historically embedded routing token; verify backend rules and provider usage terms |
| Required | Store access and metadata | Actual store account status, current build numbers, categories/age ratings, support details, screenshots and reviewer access |
| Required for iOS | Signing and native build | Mac/Xcode, Apple team and registered bundle ID, dependency integration, privacy manifests, archive and device tests |
| Before broad rollout | Release regression pass | Second Android model, long body-map session, permissions, update from installed data, social flows and pre-launch reports |

AI billing belonging to the user does not remove privacy, review-access or content-policy requirements. This checklist should be resolved with implementation and evidence, not simply marked complete after a document edit.

## Android build and upload procedure

1. Retain the existing upload key. Restore ignored `android/key.properties` and its keystore if missing; never generate a replacement just to get a build working.
2. Rotate/restrict service credentials and prepare ignored `config/local.defines.json` for the intended environment. Confirm Firestore rules and separate development data.
3. Select an unused build number greater than the highest previous Play upload and update the app version.
4. Run the automated checks and [device matrix](TESTING.md#manual-release-checks).
5. Build from the repository root:

```sh
flutter build appbundle --release --dart-define-from-file=config/local.defines.json
```

Windows convenience command: `build_aab.cmd`. It requires the local signing file. A direct Flutter build without signing configuration may use the project's debug-signing fallback and is unsuitable for uploading.

Output: `build/app/outputs/bundle/release/app-release.aab`. Check its certificate against Play Console's **upload certificate**. Record the artifact SHA-256, version, build number and source revision. Check effective target SDK, native-library 16 KB compatibility and Play bundle validation for the selected release toolchain.

6. Supply [store text](release/STORE_LISTING.md), platform screenshots and a public privacy policy. Complete App access, Data safety, health, audience/content-rating and any permission declarations from actual behavior.
7. Upload to the appropriate internal/closed track, run the pre-launch checks, and test Play-installed updates before production. Existing tester enrollment should be preserved where applicable.

For personal Play accounts created after 13 November 2023, Google currently requires at least 12 opted-in closed testers continuously for 14 days before applying for production access. This condition does not apply indiscriminately to every account. [Official testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).

## iOS preparation on a Mac

No signed IPA can be produced or validated in the current Windows environment. [Flutter's release guide](https://docs.flutter.dev/deployment/ios) requires macOS/Xcode and describes App ID registration, signing and archiving.

1. Confirm Apple Developer enrollment and the existing/new App Store Connect record. Register an App ID owned by the developer; `de.jankilic.kaizen` is a candidate, not a claim of availability or registration.
2. Replace the template bundle ID in all Runner and RunnerTests configurations. Select the real development team; do not invent a team ID.
3. Align the deployment target with the installed plugins and current store requirements. The local `health` podspec requires iOS 14.0 while the project still says 13.0.
4. Install/resolve native dependencies using Flutter's supported Xcode/CocoaPods or Swift Package Manager integration. The current repository has no Podfile and no verified iOS dependency lock/archive; do not assume generated registrants alone provide linkage.
5. Validate HealthKit capability/provisioning, secure storage, camera/library access, English/German permission strings and deep links on a physical iPhone. Review landscape and iPad layouts if the target declares support.
6. Inspect the archive's privacy report, required-reason API declarations and SDK manifests. Complete App Privacy and export-compliance answers from the actual build and behavior; do not copy blanket declarations.
7. Use the current accepted Xcode/SDK from [Apple's submission requirements](https://developer.apple.com/app-store/submitting/), then build:

```sh
flutter pub get
flutter gen-l10n
flutter test
flutter build ipa --release --dart-define-from-file=config/local.defines.json
```

The IPA command assumes signing and native integration are already configured. Validate the archive in Xcode, distribute through TestFlight, repeat the release scenarios, then select the verified build for App Review.

## Reviewer access and assets

Core tracking must be reviewable without buying AI credit. For the advertised AI feature, arrange a controlled, funded review method and document it privately in the store review fields; never embed a shared developer key in a public build or repository. A screenshot fixture is not a working review account.

The README's synthetic Flutter captures illustrate design. Store screenshots must match the actual platform release and required device sizes. Verify icon/feature-graphic ownership and dimensions. Use [store copy](release/STORE_LISTING.md) as a draft, including the separate API-cost disclosure.

## Policy references

- [Apple review guidelines](https://developer.apple.com/app-store/review/guidelines/): sharing consent, privacy, account deletion and review access.
- [Google AI-generated content](https://support.google.com/googleplay/android-developer/answer/13985936?hl=en): applicable content safeguards and reporting.
- [Google health declarations](https://support.google.com/googleplay/android-developer/answer/14738291?hl=en).
- [Google account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en-gb).

Recheck console requirements immediately before submission; dated documentation does not guarantee future acceptance. No upload, account change or public rollout has been performed by this preparation work.
