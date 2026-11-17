import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Dictation stays in the draft until the user explicitly sends it.
class ChatVoiceInput extends StatefulWidget {
  const ChatVoiceInput({
    super.key,
    required this.controller,
    required this.enabled,
    required this.isActive,
    required this.onActiveChanged,
    required this.onError,
    this.recognizer,
  });

  final TextEditingController controller;
  final bool enabled, isActive;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<String> onError;
  final SpeechToText? recognizer;

  @override
  State<ChatVoiceInput> createState() => _ChatVoiceInputState();
}

class _ChatVoiceInputState extends State<ChatVoiceInput>
    with WidgetsBindingObserver {
  late final _speech = widget.recognizer ?? SpeechToText();
  bool _active = false, _starting = false, _stopping = false;
  int _session = 0;
  String _draft = '';

  String t(String de, String en) =>
      Localizations.localeOf(context).languageCode == 'de' ? de : en;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant ChatVoiceInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive && _active) {
      // Keep recognized text when moving to another tab.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.isActive && _active) {
          unawaited(_cancel(restoreDraft: false));
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Permission dialogs can temporarily make the app inactive during startup.
    if (state != AppLifecycleState.resumed && _active && !_starting) {
      unawaited(_cancel(restoreDraft: false));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session++;
    unawaited(_speech.cancel());
    super.dispose();
  }

  void _finish() {
    if (!mounted || !_active) return;
    setState(() {
      _active = false;
      _starting = false;
      _stopping = false;
    });
    widget.onActiveChanged(false);
  }

  Future<void> _start() async {
    if (_active || !widget.enabled || !widget.isActive) return;
    FocusScope.of(context).unfocus();
    final session = ++_session;
    final language = Localizations.localeOf(context).languageCode;
    _draft = widget.controller.text;
    setState(() {
      _active = true;
      _starting = true;
    });
    widget.onActiveChanged(true);
    try {
      // initialize is cached by the plugin; refresh callbacks on every session
      // so reopening the chat cannot leave listeners on a disposed widget.
      _speech.statusListener = (status) {
        if (status == SpeechToText.doneStatus) _finish();
      };
      _speech.errorListener = (error) {
        if (!mounted || !_active) return;
        widget.onError(
          error.errorMsg == 'error_permission' ||
                  error.errorMsg == 'error_insufficient_permissions'
              ? t(
                  'Bitte erlaube Mikrofon und Spracherkennung in den App-Einstellungen.',
                  'Please allow microphone and speech recognition in app settings.',
                )
              : error.errorMsg == 'error_no_match' ||
                    error.errorMsg == 'error_speech_timeout'
              ? t(
                  'Keine Sprache erkannt. Bitte erneut versuchen.',
                  'No speech detected. Please try again.',
                )
              : t(
                  'Spracheingabe unterbrochen. Prüfe die Verbindung und versuche es erneut.',
                  'Voice input interrupted. Check your connection and try again.',
                ),
        );
        _finish();
      };
      final available = await _speech.initialize(
        options: [SpeechToText.androidNoBluetooth],
        onStatus: _speech.statusListener,
        onError: _speech.errorListener,
      );
      if (!mounted || session != _session || !_active) return;
      if (!available) {
        widget.onError(
          t(
            'Spracheingabe nicht verfügbar. Bitte prüfe die Mikrofon- und Spracherkennungsberechtigung sowie den Sprachdienst deines Geräts.',
            'Voice input unavailable. Please check microphone and speech recognition permissions and your device speech service.',
          ),
        );
        _finish();
        return;
      }
      if (!widget.isActive ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.hidden) {
        await _cancel(restoreDraft: false);
        return;
      }
      final locales = await _speech.locales();
      if (!mounted || session != _session || !_active) return;
      final locale = locales
          .where(
            (l) => l.localeId.replaceAll('-', '_').split('_').first == language,
          )
          .firstOrNull;
      if (locale == null) {
        widget.onError(
          t(
            'Deutsch ist für die Spracherkennung nicht installiert. Bitte im Sprachdienst deines Geräts hinzufügen.',
            'English is not installed for speech recognition. Please add it in your device speech service.',
          ),
        );
        _finish();
        return;
      }
      setState(() => _starting = false);
      await _speech.listen(
        onResult: (result) {
          if (!mounted || !widget.isActive || !_active || session != _session) {
            return;
          }
          final words = result.recognizedWords.trim();
          if (words.isEmpty) return;
          final text =
              '$_draft${_draft.isEmpty || _draft.endsWith(' ') || _draft.endsWith('\n') ? '' : ' '}$words';
          final limited = text.characters.take(8000).toString();
          widget.controller.value = TextEditingValue(
            text: limited,
            selection: TextSelection.collapsed(offset: limited.length),
          );
        },
        listenOptions: SpeechListenOptions(
          localeId: locale.localeId,
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          autoPunctuation: true,
          listenFor: const Duration(minutes: 2),
          pauseFor: const Duration(seconds: 5),
        ),
      );
    } catch (_) {
      if (!mounted || session != _session) return;
      widget.onError(
        t(
          'Spracheingabe konnte nicht gestartet werden. Bitte erneut versuchen.',
          'Could not start voice input. Please try again.',
        ),
      );
      _finish();
    }
  }

  Future<void> _stop() async {
    setState(() => _stopping = true);
    try {
      // The done status follows the final transcript, including its timeout.
      await _speech.stop();
    } catch (_) {
      _finish();
    }
  }

  Future<void> _cancel({bool restoreDraft = true}) async {
    _session++;
    if (restoreDraft) widget.controller.text = _draft;
    _finish();
    await _speech.cancel();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_active)
        IconButton(
          key: const Key('chat-voice-cancel'),
          tooltip: t('Aufnahme verwerfen', 'Discard voice input'),
          onPressed: _cancel,
          icon: const Icon(Icons.close),
        ),
      IconButton(
        key: const Key('chat-voice'),
        tooltip: _active
            ? t('Aufnahme beenden', 'Stop voice input')
            : t('Nachricht einsprechen', 'Dictate message'),
        color: _active ? Theme.of(context).colorScheme.error : null,
        onPressed: _active
            ? (_starting || _stopping ? null : _stop)
            : widget.enabled && widget.isActive
            ? _start
            : null,
        icon: _starting || _stopping
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _active ? Icons.stop_circle_outlined : Icons.mic_none_rounded,
              ),
      ),
    ],
  );
}
