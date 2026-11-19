# Testing and verification

## Automated checks

```sh
flutter pub get
flutter gen-l10n
flutter test
flutter analyze lib test tool
```

Tests use isolated temporary storage and mocked provider responses; they do not need paid AI usage. Run the whole suite after changes to navigation, persistence or shared widgets. Do not run tests with real health data or provider secrets.

| Test file | Main regression coverage |
| --- | --- |
| `test/ai_chat_test.dart` | Provider payloads, photo limits, malformed output, local history, credential separation and repeated/editable meal confirmation |
| `test/coach_import_test.dart` | Automatic media submission, full nine-slide decoding/payload, slide evidence, review-before-save, duplicate-safe actions and opt-in fitness context |
| `test/coach_share_navigation_test.dart` | Cold/warm shared content opens the visible Chat page and dismisses nested routes |
| `test/instagram_video_service_test.dart` | Public metadata/embed parsing, complete carousel order, mixed media, redirect/size/host limits, missing-slide fallback and temporary-file cleanup |
| `test/coach_training_analysis_test.dart` | Eight-week training aggregates and comparisons with explicit missing-data behavior |
| `test/chat_barcode_flow_test.dart` | Shared scanner from Chat without an AI key, portion scaling and all three destinations, visible shopping confirmation, cancellation with a late response, network retry, missing products, keyboard layout and existing conversations |
| `test/social_sync_test.dart` | Consent flow, HTTP errors, partial writes, duplicate-safe imports, live update/stop ordering, route encoding and ended-run UI |
| `test/body_map_performance_test.dart` | Bounded raster cache, invalidation, expansion, gestures, back behavior and disposal |
| `test/home_settings_test.dart` | First-install defaults, language migration, water/fasting toggles, Profile position and workout names |
| `test/progress_store_lifecycle_test.dart` | Immediate shutdown during Home initialization, persisted counters/dates after reopening, legacy analytics backfill and overlapping opens |
| `test/home_recovery_test.dart` | Home recovery calculations and display state |
| `test/shopping_and_organ_flow_test.dart` | Draft/archive persistence across restart, checks, rename/order/deletion, unfinished-draft preservation, swipe/edit/undo in both themes, catalog coverage and organ → shopping/intake/dish actions |
| `test/monthly_challenge_progress_test.dart` | Challenge data/progress behavior |
| `test/launcher_icon_service_test.dart` | Progress-icon behavior |
| `test/widget_test.dart` | New-install onboarding |

Each push and pull request runs the full Flutter test suite, checks for analyzer errors and tests the Firestore rules against a local emulator. The workflow reports analyzer warnings and informational lints separately. [Public CI results](https://github.com/JanErcanK/Kaizen/actions/workflows/verify.yml)

## Compact dashboard and run-history tests — 2026-11-19

The [first public run](https://github.com/JanErcanK/Kaizen/actions/runs/44067304901) exposed two issues. The Home anatomy sidebar overflowed when a share arrived while the app was open. The sidebar now scrolls when vertical space is short. A widget test scrolls the compact dashboard and checks that its last control is reachable. The run-history tests now load Roboto from the active Flutter SDK, so the tests also run on machines with a different SDK installation path.

## Home persistence and GitHub CI — 2026-10-25

The development run at `37c7eb6` failed in the Home keyboard/swipe test. `markHomeOpened()` resumed after the test had closed Hive, then attempted to read the analytics date, raising `Box has already been closed`. Dependency setup, localization generation, analysis and the Firestore-rules job passed.

The counter and initial analytics date are now submitted in one `putAll` before yielding. Three lifecycle tests reproduced the original error without sleeps. After the fix they verified persistence across an immediate close/reopen, legacy backfill and overlapping opens. At the time, all **187 tests** passed locally and analysis reported **0 errors, 59 warnings and 36 informational findings**.

## Share to Chat and Instagram carousels — 2026-10-25

The full Flutter suite passes **184 tests**. The complete analyzer reports **0 errors, 59 warnings and 36 informational findings**; the changed import/chat files and diagnostics pass targeted analysis without issues. `node test/anatomy_viewer_test.cjs` passes with the bundled models.

The supplied public Instagram post was fetched and decoded through the real importer into **nine images in order**, totalling 6,665,979 bytes of PNG analysis images. The provider request and confirmation behavior are tested with mocked AI responses. A direct-video link that does not expose public media produces an attachment request instead of fabricated analysis.

Optional live diagnostics are outside `test/` so ordinary CI never depends on Instagram availability or incurs AI charges:

```sh
dart run tool/check_public_video.dart "https://www.instagram.com/p/De3BL_pCByI/?img_index=6"
flutter test --no-pub tool/check_instagram_import_test.dart
```

The first checks public media download; the second also exercises local image decoding, all nine slide numbers, provider-size limits and source cleanup. Neither reads AI credentials or calls an AI provider. Availability of public posts can change, so a later network failure is not equivalent to a regression in the mocked suite.

Manual Android follow-up: share with the app closed and open, including from a nested screen; test a direct video, this carousel, a restricted link, missing credentials and a network failure. The actual configured provider should produce a reviewable proposal; change it in chat, then confirm once and verify one saved workout with no completed-session entry. Latest APK path and hash are in [verification evidence](release/VERIFICATION.md).

## Unified Profile health card — 2026-10-24

The full Flutter suite passes **138 tests**. Four new regressions cover local values and missing days, separate import/local sources, workout counts versus imported minutes, all 14 categories without a health connection at 320px and 1.5× text in both languages/themes, the removal of the duplicate chart, the bottom-of-profile ordering, and saving weight into the same chart. The new model, adapter and health widget pass analysis; the broader targeted run reports no errors and 12 existing warnings/informational findings in Profile and tour tests.

The isolated visual fixture now also renders local nutrition and the complete Profile footer in `build/health-preview/local-protein.png` and `profile-health-bottom.png`. Both were inspected: the unified card ends above the weight/+ row and Edit profile. No fixture data enters the user's storage. Native health permissions and the seven imported data types are unchanged.

The Windows release build succeeded and the fresh application was opened. The full category selector, local workout chart and footer ordering were visually verified in the running app.

The Android release build also succeeded. `build/app/outputs/flutter-apk/Kaizen-Health-Update-2026-10-24.apk` matches the build output and verifies with APK signature scheme v2. SHA-256: `a251043dbee6b743b1552a331271e64f21937a559b5a8676f9a3213690aca0a8`. This update was not installed on a physical phone during this check.

## Movable fullscreen anatomy cards — 2026-10-24

The full suite passes **134 tests**. Four bridge regressions exercise muscle, skeleton, connective and organ cards on a 390×844 screen: a hold does not jump, a quick swipe does not reposition, a held drag moves without reaching the native model, content still scrolls, holding the content also moves the card, rebuilds retain position, oversized drags clamp at the edges, resizing to 844×390 keeps Close reachable, and reopening resets to the original dock. Existing food-save and exercise-picker flows remain green. Targeted analysis is clean. The synthetic capture utility additionally renders and checks a 120px upward organ-card drag in `build/polish-preview/organ-card-*-moved.png`.

Windows and Android release builds succeeded. The fresh Windows app was opened and the muscle card/sidebar layout checked; hold gestures were exercised in Flutter tests, not on a physical phone. The distributed APK copies match the build and its v2 signature verifies. APK SHA-256 for this build: `7b71bbd034fe52db4f4ba23dc31733a8cb223ecc3f50da15b59efc7725cb0760`.

## Organ actions and visible tissue contours — 2026-10-24

The subsequent full suite passes **130 tests**. The new 3D bridge regression picks the lung and large intestine using the real catalog, checks that all three food destinations are hit-testable immediately, and verifies shopping, intake and dish persistence in isolated storage. A 320px / 1.5× text check keeps the card scrollable and its close control reachable in both languages/themes. The capture utility renders the actual lung and gut cards in `build/polish-preview/organ-card-*.png`.

The real-GLB NullEngine contract passes with an independent tissue outline, unchanged surface colors/emission, selection restoration and expiry cleanup. A real WebGL browser check with synthetic leg training confirmed blue contours on pink tendons/white ligaments and warm cartilage markers. Cartilage was previously hidden by bone even when its highlight state was active; bones are now excluded only from the contour mask, remaining in the normal scene. The shared 768px outer-outline pass uses the afterburn blur width and does not run for inactive tissues. Phone GPU appearance still requires device verification.

The final toolbar fix passed the 12 targeted anatomy/body-map tests: picking an organ hides the overlapping fullscreen sidebar, and dismissal restores it. Targeted analysis reports no issues. The rebuilt Windows app was opened and both lung and gut cards were inspected, including all three food destinations and sidebar restoration. Windows and Android release builds succeeded; the renderer and v4 contour configuration match the source byte-for-byte in both bundles. APK v2 signature verification and both distribution-copy hashes pass. APK SHA-256 for that earlier build: `059a0414dbcb730ca4be19a006521bbe9c7ea1075603c888bf7959b7e2e71524`.

## Profile health integration — 2026-10-24

The full Flutter suite passes **128 tests**. `test/health_dashboard_test.dart` covers overnight sleep stages sharing a native session UUID, exclusion of awake time, session-only estimates, duplicate/provider separation, daily weight selection, median vitals, separate HRV methods, partial grants, iOS's unknown read-access state, persistent snapshots, stale errors, provider deletions and disconnect during a pending read. A method-channel regression verifies that phone-only step aggregates are imported without requiring raw samples, that platform totals are retained once, and that no empty midnight query or fabricated zero day is created. Widget checks cover a phone-only connection, sensor-specific missing-data guidance, category and period selection, denied data, 320px layouts and 1.5× text in both languages/themes. The workout-navigation regression confirms that the shared back arrows return to the list without saving a workout. The introduction tour follows the new Profile order.

`FLUTTER_ROOT=C:/src/flutter flutter test tool/capture_health_screenshots_test.dart` renders **synthetic** sleep/HRV/28-day, dark, connection, phone-only steps and missing-HRV previews into `build/health-preview/`; these fixtures never enter user storage. The new health model, service, widget, tests and capture tool pass targeted analysis. Existing unrelated analyzer findings remain elsewhere.

Read-only Android permissions and the iOS HealthKit usage description are configured. Android has a paginated workout-only bridge because the installed health package's ordinary workout query also reads distance, total calories and steps. The native privacy/rationale entry describes the real data flow and local deletion. No Health Connect history or background permissions are requested; the rolling window is 28 days.

Windows and Android release builds succeeded after the final Dart/Android changes. The fresh Windows app was opened at the Profile health section; its mobile-only state was visually checked. The copied APK's hash matches the build output and its v2 signature verifies. The iOS deployment target and framework minimum are aligned to 14.0, required by the already-installed `health` 13.3.1 podspec. Native dependency resolution, compilation and device checks on a Mac remain unverified here.

**Real device verification is still required:** grant only selected categories on Android and iPhone; test phone-only steps on an iPhone, Android 14+ with SDK extension 20+ (Health Connect's built-in recorder), and an older Android phone using a compatible step source; then add a watch and compare totals without duplication. Check source labels, steps against the platform aggregate, sleep around midnight and daylight-saving changes, partial denial/revocation, missing Health Connect and foreground refresh. iOS cannot disclose whether read access was denied, so empty iOS reads are labelled as no available data, not a confirmed denial. This Windows environment does not establish an iOS build or end-to-end phone/watch synchronization.

## Chat barcode and rebuilt previews — 2026-10-24

The full Flutter suite passed **115 tests**, and the Babylon/real-model contract test passed. The five added barcode widget tests inject product responses; they do not establish live camera capture. The screenshot utility now also renders `chat-barcode.png` and `barcode-product.png` from an explicit product fixture. Home, shopping, history, organ and barcode screenshots were inspected at 390 × 844 logical pixels.

Two further Home regressions reproduce the unwanted keyboard after closing the anatomy tips, through both tab taps and swipes. They now pass and verify that returning to Chat retains the unsent draft without reopening the keyboard until the user taps the input. The larger green-bordered note and unchanged timer-control height were visually compared; `timer-setup.png` captures the timer. Real WebGL inspection with synthetic training in both themes confirmed pink/white connective surfaces, with only an outer blue training outline. The renderer contract checks that involvement changes neither connective albedo nor surface emission, and that selection and clearing restore the correct materials.

Windows release and Android release APK builds succeeded. The rebuilt Windows application was opened and its Home paper shortcut, Chat barcode button and scanner route were visually inspected. A new physical-phone camera test remains outstanding. Targeted analysis of Chat, the shared lookup, shopping button and new tests/capture utility is clean; `food_screen.dart` retains its existing unused `dragHandle` warning.

## Shopping and organ polish — 2026-10-23

The full Flutter suite passed **108 tests**. `node test/anatomy_viewer_test.cjs` passed with the real bundled models and a NullEngine, including blue/yellow tissue colors, reduced emission, selection priority and restoration. The actual WebGL viewer was also inspected in the local browser with synthetic leg-training data; a background-aware halo avoids dark rings in the light theme. Neither check establishes phone GPU behavior. A live lookup through `OpenFoodFactsService` returned the sample product for barcode `3017620422003`; camera capture still requires a phone check. Analysis reported **0 errors** with **97 warnings/informational findings** remaining across the repository.

`FLUTTER_ROOT=C:/src/flutter flutter test tool/capture_polish_screenshots_test.dart` renders isolated synthetic Home, shopping (light/dark), saved-purchase and organ-action previews into `build/polish-preview/`. It also verifies that the Home paper shortcut opens shopping without opening Food. On PowerShell, set `$env:FLUTTER_ROOT` before running the command. These captures do not establish iOS or real-device readiness.

## Earlier recorded evidence — 2026-10-17

The current working-tree run passed **40 Flutter tests**, **19 local Firestore Rules checks**, and the analyzer reported **0 errors, 57 warnings and 35 informational findings**. A signed Android AAB was built, but not installed or validated by Play. Full scope and hashes are recorded in [release verification](release/VERIFICATION.md). The emulator uses only a localhost demo project; no production Firestore state was checked.

## Historical device evidence — 2026-10-05

The separate `firestore-rules` CI job runs `node tool/run_firestore_rules.mjs`. It uses only the official local emulator with a demo project and no credentials. See [social verification](SOCIAL_FEATURES.md#verification) for requirements and the two-device checklist.

Environment: Windows, Flutter 3.44.8 / Dart 3.12.2. The following notes describe the 2026-10-05 snapshot, not the current release artifact.

- Android release APK built and installed on the connected Motorola razr 60 ultra during the preceding device session. The user confirmed the body-map stability improvement.
- The USB device is not connected during the documentation/release-preparation pass; the currently installed files cannot be re-read.
- Whole-project analysis completed with no errors and 111 existing warnings/informational findings before the documentation/configuration edits. This is a dated baseline, not a claim of clean lint output.
- AI provider tests use mocks. No funded production API request or photo analysis has been confirmed.
- No iOS archive, TestFlight distribution or iPhone test has been performed.

The current [application audit](APP_AUDIT.md) summarizes release blockers and the limits of these checks.

## Manual release checks

| Scenario | Expected result |
| --- | --- |
| Fresh install and subsequent restart | English/light default; saved preferences survive |
| Home → Profile after scrolling | Profile opens at the top |
| Water and fasting settings | Correct cards hide/show and eating window reflects saved values |
| Body-map expand/zoom/back repeatedly | No native crash, persistent rendering artifact or growing allocation trend |
| Fold/rotate/background/resume | Navigation and overlays remain usable |
| Chat without a key or with exhausted credit | Clear recoverable message; no meal written |
| Real text request to each provider | Normal reply and expected billing behavior |
| Camera/gallery meal photo and follow-up | Estimate with assumptions; correct contextual image behavior |
| Edit portion/date, confirm twice, restart | Correct totals/date and no duplicate entries |
| Delete chat or key | Correct local removal; confirmed meal remains; key not exposed in history |
| Deny camera/health/location permissions | Feature explains the limitation; core app remains usable |
| Two-device social session | Rules permit intended sharing, prevent unrelated access, and deletion is verified |

Real-device tests must use the intended signed release build. Record model, OS, build number and findings. Widget tests cannot verify GPU-driver behavior, camera permissions, native secure storage or actual provider compatibility.

## Documentation screenshots

`tool/capture_screenshots_test.dart` renders the actual widgets at 420 × 920 logical pixels with synthetic profile and chat data. It uses a fresh temporary Hive directory and does not execute application startup or initialize network services. The AI message is an explicit fixture. Date/time-dependent UI reflects capture time.

PowerShell:

```powershell
$env:FLUTTER_ROOT = 'C:\path\to\flutter'
flutter test tool/capture_screenshots_test.dart
```

macOS/Linux:

```sh
FLUTTER_ROOT=/path/to/flutter flutter test tool/capture_screenshots_test.dart
```

Output is `docs/images/home.png`, `chat.png` and `profile.png`, at twice the logical resolution. The capture loads Roboto and Material Icons from the Flutter SDK to avoid test placeholder glyphs. Inspect every image after regeneration. This utility is separate from the regular test suite and does not constitute a pixel-golden regression test.

These images are suitable for the README. Generate platform-specific screenshots from real release builds for store submission; do not present a mocked chat response as a measured live-model result.
