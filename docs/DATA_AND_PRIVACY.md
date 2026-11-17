# Data and privacy: technical inventory

This is a developer-facing description of current data flows, **not the published privacy policy**. A release policy still needs the operator's identity, contact channel, hosting URL, retention/deletion process and applicable disclosures. Do not submit this document as if those decisions were already resolved.

## Data flows

| Data | Stored/processed where | When it leaves the device |
| --- | --- | --- |
| Profile, workout history, weight and food entries | Local Hive database | Selected content can be shared through social features; not general automatic cloud backup |
| Sleep, steps, active calories, workout minutes, resting heart rate, HRV and weight | Read-only Health Connect / Apple Health import; latest 28 days reduced to daily, per-source values in local Hive | With explicit fitness-context opt-in, source-specific sleep/heart-rate/HRV summaries enter AI requests and detailed health readings can be requested by the coach; no automatic social sharing |
| Coach notes and training analysis | Confirmed notes in local Hive; eight-week aggregates computed from local logs at request time | With fitness-context opt-in, profile, confirmed notes and eight-week summaries go to the selected AI provider; bounded detailed lookups may follow. Analysis does not automatically save new memories |
| Chat text and meal estimates | Local Hive history | Recent context goes directly to the selected AI provider on send/retry |
| Attached meal photos | Normalized files in the app's local storage | The latest context photo may be sent/re-sent to the selected provider |
| Android shared videos and Instagram carousels | Private share inbox; temporary downloads; locally decoded images/video samples saved with chat | Public Instagram/CDN requests fetch the shared post. Actual prepared media and recent chat context go to the configured AI provider automatically for an imported share; no Instagram login or AI key is sent to Instagram |
| OpenAI/Claude API keys | Platform secure storage | Authorization to the chosen provider endpoint |
| Social identity and refresh state | Local social Hive box; Firebase Anonymous Auth | Authentication and refresh requests to Firebase |
| Friend codes, shared content, challenge counts and live-run presence | Firebase/Firestore and local social cache | When configured social features are used; authentication initializes at startup |
| Map viewport and route coordinates | OpenStreetMap tiles / OpenRouteService | Loading maps or requesting routes; live locations may also be shared with friends |
| Barcode | Open Food Facts | Product lookup |
| Error details | App-local error log | No automatic log-upload system identified; manual sharing must be redacted |

All network providers also receive ordinary connection metadata such as the source IP address. Confirm exact provider settings and production configurations before completing store declarations.

## Storage and deletion boundaries

Live location is sent only after choosing to share that run. The revised rules require accepted reciprocal friendships and deny stale location reads. Normal stop deletes presence; failed deletion can leave an owner-readable cloud document. An expired map marker is not a server deletion/retention guarantee. See [social behavior and rollout status](SOCIAL_FEATURES.md).

- Hive history and image files are **not application-level encrypted**. App sandboxing is not equivalent to database encryption.
- Profile → Your health → Connection & privacy can stop the new health import and clear its local snapshot. This does not delete the platform's originals or revoke OS permissions. Read grants are managed in Apple Health / Health Connect; older Kaizen step caches and manual logs are separate. There is no new background-reading or historical-data permission, no health write permission, and no route import.
- Health Connect has a dedicated native permission-rationale activity. The workout bridge reads only ExerciseSessionRecord so denying distance, steps or total-calorie access does not prevent importing workout minutes. The existing third-party reader would otherwise request those auxiliary records.
- The connection accepts phone, app and optional watch sources; it does not require a wearable. Steps use the unfiltered native aggregate, so phone/watch priorities remain with the platform. No raw-source precondition or hardcoded Android phone package name is used. Ambiguous zero/no-data results remain gaps. iPhone can supply its own steps; Android's built-in Health Connect counter requires Android 14+ and SDK extension 20+, otherwise a compatible app must provide steps. Kaizen does not add its own background phone-sensor recorder. See [Apple sources](https://support.apple.com/en-hk/108779) and [Android phone steps](https://developer.android.com/health-and-fitness/health-connect/read-data).
- API keys use `flutter_secure_storage`; iOS is configured for first unlock on this device. Social refresh state currently uses Hive, not the AI key store.
- Android disables application backup and excludes app data from backup/transfer rules. This is not a cross-platform backup guarantee.
- Deleting a conversation removes its local attached images. It does not delete confirmed meals or provider-side records.
- Shared originals are removed after successful import/processing, including temporary Instagram downloads. Prepared slide images/video samples remain with the local conversation until deletion. Workout proposals do not change saved workouts until confirmed; deleting the chat does not delete a previously confirmed workout.
- Removing a stored API key does not revoke it at the provider. Provider revocation is a separate account action.
- Removing a friend or inbox item is not deletion of the Firebase account. A full cloud account/data-deletion workflow has not been implemented or verified.
- iOS Keychain behavior must be checked on real-device uninstall/reinstall; do not promise that uninstall removes every credential.

## Before store release

1. Publish a complete privacy policy and accessible support/deletion contact. Link it from the app and listings.
2. Add and verify explicit, provider-specific consent before sending data to third-party AI. Current settings explain transmission and costs, but that alone has not been accepted as a release-ready consent flow.
3. Implement and test AI-content reporting and the handling process required for the applicable store policy. Also review social-content reporting/blocking.
4. Implement end-to-end deletion for the automatically created cloud identity and associated records, including a documented retention policy.
5. Check Health Connect permission rationale, actual requested read types and an accessible privacy explanation. Review HealthKit use and privacy declarations on a real iPhone.
6. Audit the final native build's SDKs, permissions and privacy manifests; then complete Google Data safety and Apple App Privacy from that inventory, not from guesses.

Sources: [Apple App Review privacy requirements](https://developer.apple.com/app-store/review/guidelines/#privacy), [Google Play AI content policy](https://support.google.com/googleplay/android-developer/answer/13985936?hl=en), [Google health-app declarations](https://support.google.com/googleplay/android-developer/answer/14738291?hl=en).
