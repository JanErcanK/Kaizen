# Documentation

Start with the [project overview](../README.md). This documentation separates learning, practical tasks, reference information and design explanations, following the lightweight principles of [Diátaxis](https://diataxis.fr/). The [GitHub README guidance](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes) informs the repository landing page.

| I want to… | Read |
| --- | --- |
| Understand the project in a few minutes | [README](../README.md) and its screenshots |
| Review current validation and release readiness | [Latest verification](release/VERIFICATION.md), [release checklist](RELEASE.md) and [historical audit](APP_AUDIT.md) |
| Run it for the first time | [Getting started](GETTING_STARTED.md) |
| Understand the code and its trade-offs | [Architecture](ARCHITECTURE.md) |
| Review the idea for a more personal first launch | [Onboarding idea](ONBOARDING_IDEE.md) |
| Follow a meal from chat to the food log | [AI chat](AI_CHAT.md) |
| Import an Instagram post or video and review a workout proposal | [Share to Coach](AI_CHAT.md#android-share-to-coach-and-video-proposals) |
| Understand the Android body-map fix | [Rendering decision](decisions/001-body-map-rendering.md) |
| Reproduce tests or screenshots | [Testing](TESTING.md) |
| Configure the social backend | [Firebase setup](FIREBASE_SOCIAL_SETUP.md) |
| Understand live tracking and sharing | [Social features and verification](SOCIAL_FEATURES.md) |
| Review data handling | [Data and privacy](DATA_AND_PRIVACY.md) |
| Prepare an Android or iOS release | [Release checklist](RELEASE.md) and [store copy](release/STORE_LISTING.md) |
| Check usage rights | [Project rights](../LICENSE.md) and [third-party notices](THIRD_PARTY_NOTICES.md) |
| Report a bug or propose work | [Contribution guidance](../CONTRIBUTING.md) |

## Keeping documentation useful

Update the document closest to a behavior change in the same pull request. Keep installation commands executable, use relative repository links, and distinguish implemented features from planned work. Record evidence with a date and environment; a passing unit test is not a successful device or store review.

The README is the introduction, not a copy of every implementation detail. Important decisions belong in short records under `decisions/`; changing setup, privacy or release behavior requires updating the corresponding guide. Generated localization files should be regenerated from their ARB sources.
