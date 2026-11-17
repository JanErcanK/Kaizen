/// Public Firebase client configuration (not a server credential).
///
/// Setup guide: `docs/FIREBASE_SOCIAL_SETUP.md`
/// 1) Create Firebase project
/// 2) Enable Anonymous Auth + Firestore
/// 3) Set FIREBASE_* in config/local.defines.json (ignored by Git)
/// 4) Publish `firestore.rules`
/// 5) Run/build with --dart-define-from-file=config/local.defines.json
class SocialCloudConfig {
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String apiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID');

  static bool get isConfigured =>
      projectId != 'REPLACE_ME' &&
      apiKey != 'REPLACE_ME' &&
      projectId.trim().isNotEmpty &&
      apiKey.trim().isNotEmpty;
}
