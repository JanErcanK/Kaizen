# Changelog

Changes below describe the repository's development version. They are not a declaration that a store release has been published.

## Unreleased

### Added

- Android share-to-Chat import for videos, screenshots and public Instagram posts. Complete carousels of up to 20 slides retain their order and slide numbers; temporary downloads are removed after local image/video processing.
- Reviewable workout proposals from shared media, with exercise evidence and uncertainty; saving requires confirmation and never logs the demonstrated routine as completed.
- Optional fitness context and eight-week training analysis, bounded local lookups, reviewed coach notes and updates to existing workouts, dishes and shopping lists.
- Import tests for cold/warm navigation, public-media resolution, nine-slide image preparation, provider payloads and confirmation; separate live Instagram diagnostics do not use AI credentials.

- Profile health connection for Apple Health / Health Connect: sleep, steps, active calories, workout minutes, resting heart rate, HRV and weight, with 7/28-day charts, daily selection, source selection and week comparisons. Partial permissions, missing data, stale snapshots and local import deletion have explicit states.
- Chat barcode entry below the meal-photo button and in existing conversations, sharing Food's scanner, portion/macros and shopping/today/dish actions without an AI key.
- Shopping lists: automatically retained draft, checkboxes, saved purchases, rename/delete/reorder, and a paper shortcut in the right quarter of the Home food card.
- Organ-specific everyday guidance and food actions for today's intake, a saved/new dish, or the shopping list; food and barcode detail sheets also support shopping.
- Recipient-confirmed friend requests, per-run live-sharing choice, pause/GPS freshness indicators and social transport/import tests.
- Official Firestore-emulator tests and a separate CI rules job; migration and deployment limitations are documented.

- Chat tab with OpenAI/Claude API-key configuration, local history, image attachment and editable meal estimates requiring confirmation.
- Home eating-window display and independent visibility settings for water and fasting.
- Regression coverage for provider requests, meal confirmation, body-map interaction and preferences.
- Portfolio README, synthetic app previews, setup/architecture/testing documentation and release checklists.
- Local service configuration template; code reuse requires the author's prior written permission.

### Changed

- Combine all Profile trends in “Your health”: add burned calories, water, afterburn, food intake and macros, and offer local steps, workout counts and manual weight alongside imported sources without summing them. Remove the duplicate analytics card; Add weight and Edit profile follow the health card directly.
- Fullscreen anatomy cards in all four views can be moved by holding and dragging. Cards stay inside the usable screen area, retain their position while open, and keep normal scrolling, tabs and actions. The toolbar stays clear of open cards.
- Share the narrower workout-style back control across routes. Tendon and ligament training now uses a subtle blue outer outline while preserving pink tendon and white ligament surfaces.
- Enlarge the Home shopping-note illustration with a light green border; remove the timer's setup introduction while retaining the controls' vertical position.
- Navigation order is Chat, Home, Profile, with Home selected initially.
- Profile returns to the top when opened.
- Fresh installations default to English and light mode; existing choices are preserved.
- Settings grouping and headings are clearer; Home uses “Burned” and “Intake” (“Verbrannt” / “Eingenommen”).
- Existing workouts rename the abs preset to “Abs Calisthenics” and omit the runner-optimized preset from the list without deleting historical records.
- Service settings no longer contain an embedded routing token or a default production Firebase project.

### Fixed

- Keep the anatomy controls within reach on short dashboards and load the run-history test fonts from the active Flutter SDK.
- Save the Home-open counter and initial analytics date together so database shutdown cannot interrupt a second read/write. Three lifecycle regressions reproduce the GitHub Actions failure and verify saved data after reopening.
- Deliver cold-start Android share intents after the Flutter channel is available; synchronize the visible Chat page and refresh pending shares on resume.
- Handle links in Android ClipData without mistaking text previews for video attachments. Show import progress immediately and preserve a clear fallback when media cannot be retrieved.
- Import the full Instagram carousel rather than treating its URL as an unavailable video or keeping only the selected `img_index` slide.

- Keep the weight-entry field alive throughout dialog dismissal so saving a new weight safely updates the unified health chart.
- Restore visible tissue involvement contours using a separate afterburn-style pass: blue tendon/ligament outlines retain pink/white surfaces, while warm cartilage contours remain visible around joints even where bone would cover them. Selection and expired training clear/restore contours correctly.
- Picking an organ now opens a wide card with practical guidance and food actions first, a persistent close button and visible scrolling. Lung and gut picks expose shopping/today/dish actions immediately; anatomy details are expandable below. The fullscreen sidebar hides while the card is open so it cannot cover the content.
- Import phone-only steps directly from the platform aggregate, including Health Connect's built-in phone counter, and allow iPhone step refresh when read-access status is unknown. Profile setup and missing-data guidance now explain phone, app and optional watch sources.
- Restore the shared back arrow on the 9-minute, stretching/warm-up, wake-up and morning workout details.
- Keep inactive Home/Chat/Profile tabs out of focus restoration; dismissing Home's anatomy tips no longer reopens the hidden Chat keyboard.
- Barcode lookup can be cancelled safely or retried after a connection error; late results cannot navigate after cancellation.
- Shopping from a food/product sheet closes the sheet so its confirmation and Open action are accessible; compact organ buttons show an inline check after adding.
- Match the catalog's plural apple/banana names to existing nutrition values, and guard food saves against repeated taps while a write is pending.
- Preserve Firestore fields during partial updates; report failed writes and retain identity/cache across temporary outages.
- Prevent duplicate shared workout/dish imports after retries or restart; retain workout configuration and additional nutrients.
- Serialize live updates before stop/delete, publish actual GPS fixes with heartbeats, and expire ended/stale views.
- Restrict location and sharing to accepted friends in the local rules; legacy connections require reconfirmation. Rules are not yet deployed.

- Bound expensive body-map rasterization during enlargement and zoom; improve overlay/back/disposal behavior.
- Use a scoped renderer workaround for the observed Motorola `leap` GPU-driver crash.

### Verification limits

- On 2026-10-25, the full Flutter suite passed 187 tests after the Home persistence fix. The supplied Instagram carousel was fetched and decoded live into nine images; AI replies remain mocked in tests. See [current evidence](docs/release/VERIFICATION.md).

- Real AI provider requests still require funded end-to-end verification.
- iOS build/device verification and store compliance work remain open.

## 1.1.0 — historical release preparation

The repository contains [earlier Android build-2 notes](docs/PLAY_STORE_RELEASE_1.1.0.md) for social/challenge/running features. Those notes are retained for context; they do not establish that a release was published or that build number 2 is available for reuse.
