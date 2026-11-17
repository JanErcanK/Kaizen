# Kaizen 1.1.0 (Build 2)

> Historical preparation notes. For the current working tree use [Release preparation](RELEASE.md). Confirm the highest uploaded version code in Play Console before building another upload; do not assume code 2 can be reused. Publication of this historical build has not been verified here.

## Play-Store release notes (German)

Freunde sind jetzt direkt vom Homescreen erreichbar. Neu sind die monatliche Liegestütz-Challenge, synchronisierte Ranglisten, Live-Laufkarten, Daumen-hoch-Nachrichten und geteilte Inhalte. Zusätzlich gibt es fortschrittsabhängige App-Icons, Verbesserungen an der Körperansicht sowie zahlreiche Stabilitäts- und Designkorrekturen.

## Play Store release notes (English)

Friends are now available directly from the home screen. This update adds a monthly push-up challenge, synced leaderboards, live running maps, thumbs-up messages, and shared content. It also introduces progress-based app icons, body-view improvements, and numerous stability and design fixes.

## Upload checklist

- Use the existing closed-testing track so testers remain opted in.
- Upload `build/app/outputs/bundle/release/app-release.aab`.
- Confirm version name `1.1.0` and version code `2`.
- Confirm package name `de.jankilic.kaizen`.
- Verify that Google Play reports the same upload certificate as build 1.
- Add the localized release notes above.
- Save the release, review warnings, and roll it out to the closed-testing track.
- Keep at least 12 testers opted in continuously until the 14-day requirement is complete.

## Play Console declarations to review

The new social and live-tracking functionality can change the app's declarations. Review these sections before rollout:

- Data safety: user IDs, display names, fitness activity, precise location/live location, shared user content, and notifications.
- App access: explain whether anonymous Firebase sign-in gives reviewers access without credentials.
- Health apps declaration and Health Connect permissions.
- Location permission declaration and the in-app disclosure for live tracking.
- Privacy policy: include friend syncing, challenges, inbox/shared content, and live-running location.

## Signing requirement

Build 2 must use the same upload key as build 1. Restore:

- `android/key.properties`
- the keystore referenced by its `storeFile` entry

Do not generate a replacement key unless an upload-key reset has first been approved in Play Console.
