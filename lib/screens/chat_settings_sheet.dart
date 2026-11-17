import 'package:flutter/material.dart';

import '../models/ai_chat.dart';
import '../services/ai_chat_store.dart';
import '../services/coach_context_service.dart';
import '../services/progress_store.dart';

class ChatSettingsSheet extends StatefulWidget {
  const ChatSettingsSheet({super.key, required this.provider});
  final AiProvider provider;
  @override
  State<ChatSettingsSheet> createState() => _ChatSettingsSheetState();
}

class _ChatSettingsSheetState extends State<ChatSettingsSheet> {
  late AiProvider _provider;
  final _key = TextEditingController();
  final _model = TextEditingController();
  bool _stored = false, _loading = true, _saving = false;
  String? _error;
  String t(String de, String en) =>
      Localizations.localeOf(context).languageCode == 'de' ? de : en;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider;
    _load();
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _key.clear();
    _model.text =
        ProgressStore.chatSettings['model_${_provider.name}'] as String? ??
        _provider.defaultModel;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final key = await AiChatStore.apiKey(_provider);
      if (mounted) {
        setState(() {
          _stored = key != null && key.isNotEmpty;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = t(
            'Der sichere Schlüsselspeicher ist nicht verfügbar.',
            'Secure key storage is unavailable.',
          );
        });
      }
    }
  }

  Future<void> _save() async {
    final key = _key.text.trim();
    if ((!_stored && key.isEmpty) ||
        _model.text.trim().isEmpty ||
        key.contains(RegExp(r'\s'))) {
      setState(
        () => _error = t(
          'Bitte Modell und einen gültigen API-Schlüssel eingeben.',
          'Enter a model and a valid API key.',
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (key.isNotEmpty) await AiChatStore.saveKey(_provider, key);
      await ProgressStore.saveChatSettings({
        ...ProgressStore.chatSettings,
        'provider': _provider.name,
        'model_${_provider.name}': _model.text.trim(),
        'configured_${_provider.name}': true,
      });
      if (mounted) Navigator.pop(context, _provider);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = t(
            'Schlüssel konnte nicht sicher gespeichert werden.',
            'Could not save the key securely.',
          );
        });
      }
    }
  }

  Future<void> _remove() async {
    setState(() => _saving = true);
    try {
      await AiChatStore.deleteKey(_provider);
      await ProgressStore.saveChatSettings({
        ...ProgressStore.chatSettings,
        'configured_${_provider.name}': false,
      });
      if (mounted) {
        setState(() => _saving = false);
        await _load();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = t(
            'Schlüssel konnte nicht entfernt werden.',
            'Could not remove the key.',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      12,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('KI verbinden', 'Connect AI'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'Dein eigener API-Schlüssel. Die Nutzung wird von deinem Anbieter separat berechnet; dein Chat-Abo enthält diese Kosten nicht.',
              'Use your own API key. Your provider bills API usage separately; your chat subscription does not cover it.',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'Etwa 5 € API-Guthaben können bei täglicher Nutzung einen Monat reichen. Das ist eine grobe Schätzung: Modell, Nachrichtenlänge sowie Foto- und Videoanalysen beeinflussen die tatsächlichen Kosten.',
              'About €5 in API credit may last around a month with daily use. This is a rough estimate: the model, message length, and photo or video analysis affect actual costs.',
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<AiProvider>(
            initialValue: _provider,
            decoration: InputDecoration(
              labelText: t('Anbieter', 'Provider'),
              border: const OutlineInputBorder(),
            ),
            items: AiProvider.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                .toList(),
            onChanged: _saving || _loading
                ? null
                : (p) {
                    if (p != null) {
                      _provider = p;
                      _load();
                    }
                  },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _model,
            enabled: !_saving && !_loading,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: t('Modell', 'Model'),
              border: const OutlineInputBorder(),
              helperText: t(
                'Standard: ${_provider.defaultModel}',
                'Default: ${_provider.defaultModel}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('chat-api-key'),
            controller: _key,
            enabled: !_saving && !_loading,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'API key',
              border: const OutlineInputBorder(),
              helperMaxLines: 3,
              helperText: _stored
                  ? t(
                      'Schlüssel gespeichert. Leer lassen, um ihn zu behalten.',
                      'Key saved. Leave blank to keep it.',
                    )
                  : (_provider == AiProvider.openai
                        ? 'platform.openai.com → API keys'
                        : 'platform.claude.com → Settings → API keys'),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              t(
                'Fitnessdaten mit dem Coach teilen',
                'Share fitness data with the coach',
              ),
            ),
            subtitle: Text(
              t(
                'Profil, 8-Wochen-Trainingsauswertung, Ernährung und Gesundheitswerte werden für persönliche Vorschläge an den gewählten KI-Anbieter gesendet.',
                'Profile, an 8-week training analysis, nutrition and health data are sent to your selected AI provider for personalized suggestions.',
              ),
            ),
            value: CoachContextService.enabled,
            onChanged: _saving
                ? null
                : (value) async {
                    await ProgressStore.saveChatSettings({
                      ...ProgressStore.chatSettings,
                      'shareFitnessContext': value,
                    });
                    if (mounted) setState(() {});
                  },
          ),
          if (CoachContextService.memories.isNotEmpty) ...[
            Text(
              t('Gespeicherte Coach-Notizen', 'Saved coach notes'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final note in CoachContextService.memories)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(note),
                trailing: IconButton(
                  tooltip: t('Notiz löschen', 'Delete note'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await CoachContextService.saveMemories(
                      CoachContextService.memories
                          .where((n) => n != note)
                          .toList(),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text(
            t(
              'Beim Senden gehen Nachrichten, das letzte Foto und die letzten Videobilder an den gewählten Anbieter. Mit aktivierter Personalisierung kommen Fitnessdaten und bestätigte Coach-Notizen hinzu. Eine Frage kann bis zu drei Datenabfragen mit weiteren KI-Aufrufen auslösen. Chats und Bilder bleiben lokal gespeichert; der Schlüssel liegt im geschützten Gerätespeicher.',
              'Requests send messages, the latest photo and video images to your chosen provider. Personalization adds fitness data and confirmed coach notes. A question may trigger up to three data lookups with additional AI calls. Chats and images are stored locally; your key stays in secure device storage.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving || _loading ? null : _save,
            child: Text(
              _saving ? t('Speichern …', 'Saving …') : t('Speichern', 'Save'),
            ),
          ),
          if (_stored)
            TextButton(
              onPressed: _saving || _loading ? null : _remove,
              child: Text(t('API-Schlüssel entfernen', 'Remove API key')),
            ),
        ],
      ),
    ),
  );
}
