import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';

enum WorkoutVoiceGender { female, male, system }

/// Picks a natural-sounding TTS voice for workout/run prompts.
class WorkoutTtsService {
  WorkoutTtsService._();

  static WorkoutVoiceGender parseGender(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'male' => WorkoutVoiceGender.male,
      'system' => WorkoutVoiceGender.system,
      _ => WorkoutVoiceGender.female,
    };
  }

  static String genderStorageKey(WorkoutVoiceGender gender) {
    return switch (gender) {
      WorkoutVoiceGender.male => 'male',
      WorkoutVoiceGender.system => 'system',
      WorkoutVoiceGender.female => 'female',
    };
  }

  static String languageTag(String appLocaleCode) =>
      appLocaleCode == 'de' ? 'de-DE' : 'en-US';

  static Future<void> configure(
    FlutterTts tts, {
    required String appLocaleCode,
    WorkoutVoiceGender voiceGender = WorkoutVoiceGender.female,
    double speechRate = 0.52,
  }) async {
    // flutter_tts native init can abort the Windows debug runner; plugin is
    // not registered on Windows (see windows/runner/kaizen_plugins.cpp).
    if (Platform.isWindows) return;

    final lang = languageTag(appLocaleCode);
    try {
      await tts.setLanguage(lang);
    } catch (_) {
      // Keep platform default if the tag is unavailable.
    }

    try {
      final voice = await _pickVoice(
        tts,
        appLocaleCode,
        gender: voiceGender,
      );
      if (voice != null) {
        await tts.setVoice(voice);
      }
    } catch (_) {
      // Voice selection must never break workouts.
    }

    try {
      await tts.setSpeechRate(speechRate);
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);
    } catch (_) {}
  }

  static Future<void> previewVoice({
    required String appLocaleCode,
    required WorkoutVoiceGender voiceGender,
    required String sampleText,
    double speechRate = 0.52,
  }) async {
    if (Platform.isWindows) return;
    final tts = FlutterTts();
    await configure(
      tts,
      appLocaleCode: appLocaleCode,
      voiceGender: voiceGender,
      speechRate: speechRate,
    );
    await tts.speak(sampleText);
  }

  static Future<Map<String, String>?> _pickVoice(
    FlutterTts tts,
    String appLocaleCode, {
    required WorkoutVoiceGender gender,
  }) async {
    // Leave voice selection to Android/iOS when the user chooses the
    // system voice. Calling setVoice with a preferred voice here would
    // silently override that setting.
    if (gender == WorkoutVoiceGender.system) return null;

    final raw = await tts.getVoices;
    if (raw is! List) return null;

    final voices = <Map<String, String>>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final name = entry['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      voices.add({
        'name': name,
        'locale': entry['locale']?.toString() ?? '',
      });
    }
    if (voices.isEmpty) return null;

    final preferences =
        appLocaleCode == 'de' ? _germanPreferences : _englishPreferences;
    var matches = voices
        .where(appLocaleCode == 'de' ? _isGermanVoice : _isEnglishVoice)
        .toList();

    if (gender == WorkoutVoiceGender.female) {
      final female = matches.where(_isLikelyFemaleVoice).toList();
      if (female.isNotEmpty) matches = female;
    } else if (gender == WorkoutVoiceGender.male) {
      final male = matches.where(_isLikelyMaleVoice).toList();
      if (male.isNotEmpty) matches = male;
    }

    for (final pref in preferences) {
      for (final voice in matches) {
        final locale = voice['locale']?.toLowerCase() ?? '';
        final name = voice['name']?.toLowerCase() ?? '';
        if (!locale.startsWith(pref.localePrefix.toLowerCase())) continue;
        if (gender == WorkoutVoiceGender.female &&
            !_isLikelyFemaleVoice(voice) &&
            _isLikelyMaleVoice(voice)) {
          continue;
        }
        if (gender == WorkoutVoiceGender.male &&
            !_isLikelyMaleVoice(voice) &&
            _isLikelyFemaleVoice(voice)) {
          continue;
        }
        if (pref.nameContains.isEmpty ||
            pref.nameContains.any(name.contains)) {
          return voice;
        }
      }
    }

    return matches.isNotEmpty ? matches.first : null;
  }

  static bool _isLikelyFemaleVoice(Map<String, String> voice) {
    final name = voice['name']?.toLowerCase() ?? '';
    if (_maleNameHints.any(name.contains)) return false;
    return _femaleNameHints.any(name.contains);
  }

  static bool _isLikelyMaleVoice(Map<String, String> voice) {
    final name = voice['name']?.toLowerCase() ?? '';
    if (_femaleNameHints.any(name.contains)) return false;
    return _maleNameHints.any(name.contains);
  }

  static const _femaleNameHints = [
    'zira',
    'jenny',
    'aria',
    'samantha',
    'sonia',
    'susan',
    'hazel',
    'catherine',
    'linda',
    'michelle',
    'victoria',
    'katja',
    'hedda',
    'amala',
    'anna',
    'helga',
    'marlene',
    'female',
    'woman',
  ];

  static const _maleNameHints = [
    'david',
    'mark',
    'guy',
    'ryan',
    'george',
    'james',
    'paul',
    'stefan',
    'conrad',
    'kal',
    'hans',
    'male',
    'man',
  ];

  static bool _isEnglishVoice(Map<String, String> voice) {
    final locale = voice['locale']?.toLowerCase() ?? '';
    final name = voice['name']?.toLowerCase() ?? '';
    if (!locale.startsWith('en')) return false;
    if (name.contains('german') || name.contains('deutsch')) return false;
    return true;
  }

  static bool _isGermanVoice(Map<String, String> voice) {
    return (voice['locale']?.toLowerCase() ?? '').startsWith('de');
  }

  static const _englishPreferences = [
    _VoicePreference(localePrefix: 'en-US', nameContains: ['zira']),
    _VoicePreference(localePrefix: 'en-US', nameContains: ['jenny']),
    _VoicePreference(localePrefix: 'en-US', nameContains: ['aria']),
    _VoicePreference(localePrefix: 'en-US', nameContains: ['samantha']),
    _VoicePreference(localePrefix: 'en-GB', nameContains: ['sonia']),
    _VoicePreference(localePrefix: 'en-US', nameContains: ['david']),
    _VoicePreference(localePrefix: 'en-US', nameContains: ['mark']),
    _VoicePreference(localePrefix: 'en-US', nameContains: ['guy']),
    _VoicePreference(localePrefix: 'en-GB', nameContains: ['ryan']),
    _VoicePreference(localePrefix: 'en-us', nameContains: []),
    _VoicePreference(localePrefix: 'en-', nameContains: []),
  ];

  static const _germanPreferences = [
    _VoicePreference(localePrefix: 'de-DE', nameContains: ['katja']),
    _VoicePreference(localePrefix: 'de-DE', nameContains: ['hedda']),
    _VoicePreference(localePrefix: 'de-DE', nameContains: ['amala']),
    _VoicePreference(localePrefix: 'de-DE', nameContains: ['stefan']),
    _VoicePreference(localePrefix: 'de-', nameContains: []),
  ];
}

class _VoicePreference {
  const _VoicePreference({
    required this.localePrefix,
    required this.nameContains,
  });

  final String localePrefix;
  final List<String> nameContains;
}
