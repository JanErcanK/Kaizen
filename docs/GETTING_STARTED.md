# Getting started

## Prerequisites

- Flutter **3.44.8**, including Dart **3.12.2**, is the toolchain used for current verification. The package SDK constraint is `^3.10.3`; this does not establish compatibility with every older Flutter release.
- Android SDK and a connected emulator/device. The Android minimum SDK is **28**. Java **17** is configured for compilation.
- For the Windows preview: Visual Studio C++ desktop tooling and the WebView2 runtime.
- For iOS: a Mac with Xcode and the Flutter iOS prerequisites. iOS has not yet been built or tested for this release. Follow [Flutter's iOS release guide](https://docs.flutter.dev/deployment/ios).

Run `flutter doctor -v` and resolve missing components for your platform. Commit `pubspec.lock` for reproducible dependency resolution; do not upgrade dependencies as part of a routine build.

## First run

```sh
git clone https://github.com/JanErcanK/Kaizen.git
cd Kaizen
flutter pub get
flutter gen-l10n
flutter devices
```

Run `flutter run -d DEVICE_ID`, replacing `DEVICE_ID` with the ID of your emulator or phone. To verify the checkout locally, run `flutter test`. A fresh installation shows onboarding and defaults to English/light mode. Existing saved language and theme choices persist. Core local tracking does not require Firebase or an AI provider account.

For a first walkthrough, complete onboarding, open a workout, inspect the body map, log a food item and revisit Profile. Chat opens without a key; sending requests requires a configured provider account with available API usage.

## Optional online configuration

Copy `config/example.defines.json` to `config/local.defines.json` and fill only the services you need. The local file is ignored by Git.

| Setting | Used for |
| --- | --- |
| `FIREBASE_PROJECT_ID` | Your social backend project |
| `FIREBASE_WEB_API_KEY` | Firebase public client configuration for anonymous authentication |
| `FIREBASE_APP_ID` | Firebase app identification |
| `ORS_API_KEY` | OpenRouteService walking-route requests |

```sh
flutter run -d <device-id> --dart-define-from-file=config/local.defines.json
```

Firebase client identifiers are not admin credentials. Firestore rules, authentication methods and service restrictions enforce access. Use your own development project; follow [Firebase setup](FIREBASE_SOCIAL_SETUP.md). No service-account file belongs in this repository or in an app binary.

Compile-time values can be extracted from distributed binaries. A `dart-define` file prevents accidental source commits; it does not make a bundled routing key secret. Limit usage, rotate previously exposed keys, and decide on an appropriate production routing arrangement before distribution.

OpenAI and Claude keys are **not** build settings. Enter a personal key through Chat → settings. The app saves it with `flutter_secure_storage`. Never commit one, paste it in an issue, or add it to screenshot fixtures. API usage is billed separately from consumer chat subscriptions; check the provider's account and billing settings.

## Local Android build

```sh
flutter build apk --release --dart-define-from-file=config/local.defines.json
```

Omit the define-file option for a build without configured online services. Output: `build/app/outputs/flutter-apk/app-release.apk`.

The Windows convenience scripts `build_apk_release.cmd`, `build_android.cmd`, `build_aab.cmd` and `run_windows.cmd` include the local define file if present. `build_aab.cmd` requires existing upload signing configuration. Set `FLUTTER_HOME` or put Flutter on `PATH`; prefer explicit Flutter commands when diagnosing environment problems.

Android sideload builds can fall back to debug signing without `android/key.properties`. **That fallback is not valid for a Play upload.** Keep the existing upload keystore and passwords outside version control. See [Release preparation](RELEASE.md).

## Useful commands

```sh
flutter test
flutter analyze lib test tool
flutter gen-l10n
```

The analyzer currently reports existing warnings and informational lints; see [Testing](TESTING.md). Edit `lib/l10n/app_en.arb` and `app_de.arb`, then regenerate localization output. Some screens still use inline English/German strings; consolidation is future cleanup.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Device does not appear | USB data connection, USB debugging and phone authorization; run `adb devices -l` |
| AI quota error | API credits and model access; a consumer subscription does not establish API credit |
| Friend features unavailable | Firebase define values, Anonymous Auth and deployed Firestore rules |
| Route calculation unavailable | `ORS_API_KEY`, quota and connectivity |
| Windows plugin issue | Custom registrant in `windows/runner/kaizen_plugins.cpp`; mobile integrations are not all supported on desktop |
| Body-map issue only on phone | Record device, OS, renderer, gestures and sanitized native logs; desktop success does not prove mobile stability |

`lib/main.dart` writes Flutter errors to the app support directory (`Kaizen/logs/error_log.txt` under local app data on Windows). Redact logs before sharing. Native crashes require device logs and may never reach the Dart handler.
