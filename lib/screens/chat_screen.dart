import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/ai_chat.dart';
import '../navigation/app_tab_navigation.dart';
import '../services/ai_chat_service.dart';
import '../services/ai_chat_store.dart';
import '../services/calorie_burn_service.dart';
import '../services/chat_image_service.dart';
import '../services/coach_context_service.dart';
import '../services/coach_share_service.dart';
import '../services/instagram_video_service.dart';
import '../services/workout_video_store.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import '../widgets/chat_voice_input.dart';
import 'chat_meal_review_sheet.dart';
import 'chat_settings_sheet.dart';
import 'coach_intro_sheet.dart';
import 'food_barcode_lookup.dart';
import 'food_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.serviceFactory,
    this.keyReader,
    this.barcodeLookup,
    this.sharedInputPreparer,
    this.isActive = true,
  });
  final AiChatService Function()? serviceFactory;
  final Future<String?> Function(AiProvider)? keyReader;
  final FoodBarcodeLookup? barcodeLookup;
  final Future<List<ChatFrame>> Function(CoachSharedInput)? sharedInputPreparer;
  final bool isActive;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  late List<ChatConversation> _chats;
  ChatConversation? _active;
  late AiProvider _provider;
  final Map<AiProvider, bool> _hasApiKey = {};
  Uint8List? _photo;
  AiChatService? _request;
  bool _busy = false, _picking = false;
  bool _scanning = false, _recording = false;
  int _generation = 0;
  String? _error;
  bool _introRunning = false, _importing = false, _savingProposal = false;
  List<ChatFrame> _videoFrames = [];
  bool get _videoConversation =>
      _active?.messages.any((m) => m.videoSource != null) == true ||
      _videoFrames.isNotEmpty;

  @override
  bool get wantKeepAlive => true;
  String t(String de, String en) =>
      Localizations.localeOf(context).languageCode == 'de' ? de : en;
  String get _model =>
      _active?.model ??
      ProgressStore.chatSettings['model_${_provider.name}'] as String? ??
      _provider.defaultModel;

  @override
  void initState() {
    super.initState();
    _chats = AiChatStore.load();
    _provider = AiProvider.parse(
      ProgressStore.chatSettings['provider'] as String?,
    );
    if (_chats.isNotEmpty) {
      _active = _chats.first;
      _provider = _active!.provider;
    }
    unawaited(_refreshApiKeys());
    if (Platform.isAndroid) unawaited(_recoverImage());
    CoachShareService.pending.addListener(_onVisible);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onVisible());
  }

  @override
  void dispose() {
    _generation++;
    CoachShareService.pending.removeListener(_onVisible);
    _request?.close();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      unawaited(_refreshApiKeys());
      WidgetsBinding.instance.addPostFrameCallback((_) => _onVisible());
    }
  }

  Future<void> _refreshApiKeys() async {
    for (final provider in AiProvider.values) {
      bool stored;
      try {
        final key = await (widget.keyReader ?? AiChatStore.apiKey)(provider);
        stored = key != null && key.trim().isNotEmpty;
      } catch (_) {
        stored = false;
      }
      if (!mounted) return;
      setState(() => _hasApiKey[provider] = stored);
    }
  }

  Future<void> _onVisible() async {
    if (!mounted ||
        !widget.isActive ||
        _recording ||
        _introRunning ||
        _importing ||
        _busy ||
        _picking ||
        _savingProposal) {
      return;
    }
    if (CoachShareService.pending.value.isEmpty &&
        ProgressStore.chatSettings['coachIntroSeen'] != true) {
      _introRunning = true;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
          child: const CoachIntroSheet(),
        ),
      );
      _introRunning = false;
      if (!mounted || !widget.isActive) return;
    }
    if (CoachShareService.pending.value.isEmpty) return;
    _importing = true;
    final shared = CoachShareService.pending.value.first;
    try {
      final existing = _chats
          .where((c) => c.messages.any((m) => m.sharedImportId == shared.id))
          .firstOrNull;
      if (existing != null) {
        setState(() {
          _active = existing;
          _provider = existing.provider;
        });
        await CoachShareService.acknowledge(shared.id);
        return;
      }
      _newChat();
      final hasVideo = shared.files.any(
        (f) => (f['mime'] as String? ?? '').startsWith('video/'),
      );
      final url = CoachShareService.socialUrl(shared.text);
      final videoSource =
          url ?? (hasVideo ? t('Geteiltes Video', 'Shared video') : null);
      final prompt = videoSource != null
          ? _videoPrompt
          : t(
              'Hilf mir mit diesem geteilten Inhalt.',
              'Help me with this shared content.',
            );
      final outgoing = ChatMessage(
        id: newChatId(),
        role: 'user',
        text: [prompt, shared.text].where((s) => s.isNotEmpty).join('\n\n'),
        createdAt: DateTime.now(),
        frames: [],
        videoSource: videoSource,
        sharedImportId: shared.id,
        failed: false,
      );
      _active = ChatConversation(
        id: newChatId(),
        provider: _provider,
        model: _model,
        title: url != null
            ? t('Workout aus Beitrag', 'Workout from post')
            : videoSource != null
            ? t('Workout aus Video', 'Workout from video')
            : t('Geteilter Inhalt', 'Shared content'),
        messages: [outgoing],
      );
      _chats.insert(0, _active!);
      setState(() => _picking = true);
      _scrollDown();
      String? importError;
      try {
        outgoing.frames.addAll(
          await (widget.sharedInputPreparer ?? CoachShareService.prepare)(
            shared,
          ),
        );
      } catch (e) {
        importError = _videoError(e);
      }
      if (!mounted) return;
      final needsFile = url != null && outgoing.frames.isEmpty;
      outgoing.failed = importError == null && !needsFile;
      if (needsFile && importError == null) {
        _active!.messages.add(
          ChatMessage(
            id: newChatId(),
            role: 'assistant',
            text: t(
              'Der Link ist angekommen, aber das Video ist darüber nicht öffentlich abrufbar. Füge die Videodatei oder Screenshots hinzu; dann analysiere ich die Übungen und schlage dir ein Workout vor.',
              'The link arrived, but its video is not publicly accessible. Attach the video file or screenshots and I will analyze the exercises and propose a workout.',
            ),
            createdAt: DateTime.now(),
          ),
        );
      }
      if (importError != null) {
        _active!.messages.add(
          ChatMessage(
            id: newChatId(),
            role: 'assistant',
            text: importError,
            createdAt: DateTime.now(),
          ),
        );
      }
      await AiChatStore.save(_chats);
      await CoachShareService.acknowledge(shared.id);
      if (!mounted) return;
      setState(() => _picking = false);
      _scrollDown();
      if (importError == null && !needsFile) await _send(retry: true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = t(
            'Import konnte nicht gespeichert werden. Bitte erneut öffnen.',
            'Could not save the import. Please reopen the chat.',
          ),
        );
      }
    } finally {
      _importing = false;
      if (mounted) setState(() => _picking = false);
      if (mounted &&
          CoachShareService.pending.value.any((s) => s.id != shared.id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _onVisible());
      }
    }
  }

  String get _videoPrompt => t(
    'Analysiere die bereitgestellten Bilder bzw. Videobilder dieses Beitrags und schlage mir daraus ein Workout vor. Berücksichtige bei einer Bildfolge alle Folien in ihrer Reihenfolge. Erkläre erkannte Übungen, Unsicherheiten und vorgeschlagene Sätze/Wiederholungen. Erstelle einen überprüfbaren Workout-Vorschlag. Speichere ihn erst nach meiner Zustimmung.',
    'Analyze the supplied images or video frames from this post and propose a workout from them. For a carousel, consider all slides in order. Explain the exercises identified, uncertainties and suggested sets/reps. Provide a reviewable workout proposal. Save it only after my approval.',
  );

  String _videoError(Object error) => error is SharedVideoUnavailable
      ? t(
          'Der Link ist angekommen, aber die Bilder oder das Video konnten nicht öffentlich geladen werden. Du kannst ein Workout ohne Video speichern. Beschreibe die Übungen oder füge Screenshots hinzu, damit ich es vorschlagen kann.',
          'The link arrived, but its images or video could not be loaded publicly. You can save a workout without video. Describe the exercises or add screenshots so I can propose it.',
        )
      : error is PlatformException && error.code == 'VIDEO_TOO_LONG'
      ? t(
          'Das Video ist länger als 3 Minuten. Bitte kürze es auf die relevanten Übungen und füge es erneut hinzu.',
          'The video is longer than 3 minutes. Trim it to the relevant exercises and attach it again.',
        )
      : t(
          'Der Anhang konnte nicht gelesen werden. Bitte füge eine Videodatei (bis 3 Minuten / 128 MB) oder Screenshots hinzu.',
          'Could not read the attachment. Add a video file (up to 3 minutes / 128 MB) or screenshots.',
        );

  Future<void> _pickVideo() async {
    if (_busy || _recording || _picking || _savingProposal) return;
    setState(() => _picking = true);
    try {
      final file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file == null) return;
      final frames = await CoachShareService.videoFrames(file.path);
      if (!mounted) return;
      setState(() {
        _videoFrames = frames;
        _photo = null;
        _error = null;
        _picking = false;
      });
      if (_input.text.trim().isEmpty) _input.text = _videoPrompt;
      await _send();
    } catch (error) {
      if (mounted) setState(() => _error = _videoError(error));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _recoverImage() async {
    try {
      final response = await _picker.retrieveLostData();
      if (!mounted || response.isEmpty) return;
      if (response.files?.isNotEmpty == true) {
        await _prepare(response.files!.first);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = t(
            'Das Foto konnte nicht wiederhergestellt werden. Bitte erneut auswählen.',
            'Could not recover the photo. Please select it again.',
          ),
        );
      }
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _settings() async {
    FocusScope.of(context).unfocus();
    final oldProvider = _provider;
    final oldModel = _model;
    final chosen = await showModalBottomSheet<AiProvider>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ChatSettingsSheet(provider: _provider),
    );
    if (!mounted) return;
    setState(() {
      if (chosen != null) {
        _provider = chosen;
        final model =
            ProgressStore.chatSettings['model_${chosen.name}'] as String? ??
            chosen.defaultModel;
        // A new provider/model begins a new conversation; never silently forward
        // an existing chat to another company.
        if (chosen != oldProvider || model != oldModel) _active = null;
      }
      _error = null;
    });
    await _refreshApiKeys();
  }

  Future<void> _prepare(XFile file) async {
    setState(() => _picking = true);
    try {
      final bytes = await ChatImageService.prepare(file);
      if (mounted) {
        setState(() {
          _photo = bytes;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = t(
            'Dieses Bild konnte nicht geöffnet werden. Bitte ein anderes Foto wählen (max. 25 MB).',
            'Could not open this image. Choose another photo (max. 25 MB).',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _scanBarcode() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    try {
      await showFoodBarcodeLookup(context, lookup: widget.barcodeLookup);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _pickPhoto() async {
    FocusScope.of(context).unfocus();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t('Foto auswählen', 'Choose photo')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (Platform.isAndroid || Platform.isIOS)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(t('Foto aufnehmen', 'Take photo')),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => _picking = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (mounted && file != null) await _prepare(file);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = t(
            'Kein Zugriff auf das Foto. Bitte Kamera-/Fotoberechtigung prüfen.',
            'Could not access the photo. Check camera/photo permissions.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _send({bool retry = false}) async {
    if (_busy || _recording || _picking || _savingProposal) return;
    final typed = _input.text.trim();
    if (!retry && typed.isEmpty && _photo == null && _videoFrames.isEmpty) {
      return;
    }
    if (typed.length > 8000) {
      setState(
        () => _error = t(
          'Bitte auf 8.000 Zeichen kürzen.',
          'Please shorten to 8,000 characters.',
        ),
      );
      return;
    }
    final token = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    ChatMessage? outgoing;
    try {
      final key = await (widget.keyReader ?? AiChatStore.apiKey)(_provider);
      if (!mounted || token != _generation) return;
      if (key == null || key.trim().isEmpty) {
        setState(() => _busy = false);
        await _settings();
        return; // Saving credentials never submits a paid request automatically.
      }
      if (retry) {
        outgoing = _active!.messages.last;
      } else {
        final imageName = _photo == null
            ? null
            : await AiChatStore.saveImage(_photo!, 'image/png');
        if (!mounted || token != _generation) return;
        final text = typed.isEmpty && _videoConversation
            ? _videoPrompt
            : typed.isEmpty
            ? t(
                'Analysiere diese Mahlzeit und schätze die Mengen und Makros.',
                'Analyze this meal and estimate the portions and macros.',
              )
            : typed;
        outgoing = ChatMessage(
          id: newChatId(),
          role: 'user',
          text: text,
          createdAt: DateTime.now(),
          imageName: imageName,
          imageMime: imageName == null ? null : 'image/png',
          frames: _videoFrames,
          videoSource: _videoFrames.isNotEmpty
              ? t('Angehängtes Video', 'Attached video')
              : CoachShareService.socialUrl(typed),
        );
        _active ??= ChatConversation(
          id: newChatId(),
          provider: _provider,
          model: _model,
          title: text.length > 60 ? '${text.substring(0, 60)}…' : text,
          messages: [],
        );
        _active!.messages.add(outgoing);
        _chats.removeWhere((chat) => chat.id == _active!.id);
        _chats.insert(0, _active!);
        _input.clear();
        setState(() {
          _photo = null;
          _videoFrames = [];
        });
      }
      // Pending requests persist as retryable, including process death/network loss.
      outgoing.failed = true;
      await AiChatStore.save(_chats);
      if (!mounted || token != _generation) return;
      setState(() {});
      _scrollDown();
      _request = widget.serviceFactory?.call() ?? AiChatService();
      final reply = await _request!.send(
        provider: _provider,
        model: _active!.model,
        apiKey: key,
        messages: _active!.messages,
        language: Localizations.localeOf(context).languageCode == 'de'
            ? 'German'
            : 'English',
      );
      if (!mounted || token != _generation) return;
      var proposedAction = reply.action;
      if (_videoConversation &&
          proposedAction?.type == AiChatActionType.logWorkout) {
        proposedAction = AiChatAction.fromJson({
          ...proposedAction!.toJson(),
          'type': 'save_workout',
        });
      }
      final needsReview =
          proposedAction != null &&
          (_videoConversation || proposedAction.needsReview);
      final actionResult = needsReview
          ? null
          : await _executeAction(proposedAction, sourceId: outgoing.id);
      if (needsReview) {
        for (final message in _active!.messages) {
          if (message.proposal != null && !message.actionSaved) {
            message.proposalSuperseded = true;
          }
        }
      }
      if (!mounted || token != _generation) return;
      outgoing.failed = false;
      final responseText = actionResult == null
          ? reply.text
          : '${reply.text}\n\n$actionResult';
      _active!.messages.add(
        ChatMessage(
          id: newChatId(),
          role: 'assistant',
          text: responseText,
          createdAt: DateTime.now(),
          meal: reply.meal,
          proposal: needsReview ? proposedAction : null,
        ),
      );
      await AiChatStore.save(_chats);
      if (mounted) {
        setState(() {});
        _scrollDown();
        if (!needsReview &&
            proposedAction?.type == AiChatActionType.logWorkout) {
          AppTabNavigation.returnHome(context);
        }
      }
    } on AiChatException catch (e) {
      if (mounted && token == _generation) {
        setState(() => _error = _errorText(e.code));
      }
    } catch (_) {
      if (mounted && token == _generation) {
        setState(
          () => _error = t(
            'Chat oder Schlüssel konnte nicht geladen/gespeichert werden. Bitte erneut versuchen.',
            'Could not load/save the chat or key. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted && token == _generation) {
        _request?.close();
        _request = null;
        setState(() => _busy = false);
        if (!_importing) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _onVisible());
        }
      }
    }
  }

  String _errorText(String code) => switch (code) {
    'auth' || 'key' => t(
      'API-Schlüssel ungültig oder ohne Berechtigung. Bitte unter KI-Einstellungen prüfen.',
      'API key invalid or not permitted. Check AI settings.',
    ),
    'quota' => t(
      'API-Guthaben oder Nutzungslimit erreicht. Bitte beim Anbieter prüfen und später erneut versuchen.',
      'API credit or rate limit reached. Check your provider account and try again later.',
    ),
    'model' => t(
      'Anfrage oder Modell wird von diesem API-Konto nicht unterstützt. Bitte Modell und Bild prüfen.',
      'This API account does not support the request or model. Check the model and image.',
    ),
    'network' => t(
      'Keine Verbindung zum Anbieter. Deine Nachricht bleibt gespeichert.',
      'Could not connect to the provider. Your message is saved.',
    ),
    'timeout' => t(
      'Der Anbieter antwortet zu langsam. Ein erneuter Versuch kann weitere API-Kosten verursachen.',
      'The provider timed out. Retrying may incur another API charge.',
    ),
    'incomplete' || 'invalid' => t(
      'Die Antwort war unvollständig oder enthielt ungültige Rezept- oder Workoutdaten. Es wurde nichts gespeichert.',
      'The response was incomplete or contained invalid recipe or workout data. Nothing was saved.',
    ),
    'refusal' => t(
      'Der Anbieter konnte diese Anfrage nicht beantworten. Bitte anders formulieren.',
      'The provider could not answer this request. Please rephrase.',
    ),
    'image' || 'missing_image' => t(
      'Das gespeicherte Bild fehlt oder ist zu groß. Bitte erneut auswählen.',
      'The saved image is missing or too large. Please select it again.',
    ),
    _ => t(
      'Der KI-Anbieter ist gerade nicht verfügbar. Bitte später erneut versuchen.',
      'The AI provider is unavailable. Please try again later.',
    ),
  };

  Future<String?> _executeAction(
    AiChatAction? action, {
    required String sourceId,
  }) async {
    if (action == null) return null;
    final german = Localizations.localeOf(context).languageCode == 'de';
    switch (action.type) {
      case AiChatActionType.deleteFoodEntries:
      case AiChatActionType.replaceFoodEntries:
        await ProgressStore.changeChatFoodEntries(
          sourceId: sourceId,
          entryIds: action.entryIds,
          replacement: action.meal,
        );
        return action.type == AiChatActionType.deleteFoodEntries
            ? t(
                '✅ ${action.entryIds.length} Ernährungseinträge gelöscht.',
                '✅ Deleted ${action.entryIds.length} food log entries.',
              )
            : t(
                '✅ Ernährungseinträge korrigiert. Datum und Uhrzeit bleiben erhalten.',
                '✅ Food log entries corrected, keeping their original date and time.',
              );
      case AiChatActionType.saveDish:
      case AiChatActionType.logMeal:
        final meal = action.meal!;
        await ProgressStore.saveAiFoodDish(
          sourceId: sourceId,
          meal: meal,
          targetId: action.targetId,
        );
        if (action.type == AiChatActionType.logMeal) {
          await ProgressStore.confirmChatMeal(
            sourceId: sourceId,
            meal: meal,
            at: DateTime.now(),
          );
        }
        final totals = meal.totals;
        final kcal = totals.kcal;
        if (german) {
          return action.type == AiChatActionType.logMeal
              ? '✅ ${meal.name} wurde unter Gerichte mit Rezept, Makros und geschätzten Mikronährstoffen gespeichert und heute eingetragen ($kcal kcal).'
              : '✅ ${meal.name} wurde unter Gerichte mit Rezept, Makros und geschätzten Mikronährstoffen gespeichert ($kcal kcal).';
        }
        return action.type == AiChatActionType.logMeal
            ? '✅ ${meal.name} was saved under Meals with its recipe, macros, and estimated micronutrients, and added to today’s food log ($kcal kcal).'
            : '✅ ${meal.name} was saved under Meals with its recipe, macros, and estimated micronutrients ($kcal kcal).';
      case AiChatActionType.saveWorkout:
        final result = await ProgressStore.saveAiWorkout(
          sourceId: sourceId,
          name: action.workoutName,
          category: action.workoutCategory,
          exercises: await WorkoutVideoStore.attachClips(
            action.exercises,
            _active?.messages.expand((m) => m.frames).toList() ?? [],
          ),
          targetId: action.targetId,
          sourceUrl: _active?.messages
              .map((m) => m.videoSource)
              .whereType<String>()
              .firstOrNull,
        );
        final duration = CalorieBurnService.formatDuration(
          result.durationSeconds,
        );
        return german
            ? '✅ ${action.workoutName} wurde unter Meine Workouts gespeichert. Geschätzt: ${result.calories} kcal · $duration.'
            : '✅ ${action.workoutName} was saved under My Workouts. Estimate: ${result.calories} kcal · $duration.';
      case AiChatActionType.saveShoppingList:
        await ProgressStore.saveAiShoppingList(
          sourceId: sourceId,
          name: action.shoppingName,
          items: action.shoppingItems,
          targetId: action.targetId,
        );
        return t('✅ Einkaufszettel gespeichert.', '✅ Shopping list saved.');
      case AiChatActionType.remember:
        final notes = CoachContextService.memories;
        if (!notes.contains(action.memory)) {
          if (notes.length >= 30) throw StateError('Memory full');
          await CoachContextService.saveMemories([...notes, action.memory]);
        }
        return t(
          '✅ Coach-Notiz gespeichert. Du kannst sie in den KI-Einstellungen löschen.',
          '✅ Coach note saved. You can remove it in AI settings.',
        );
      case AiChatActionType.readFitnessData:
        return null;
      case AiChatActionType.logWorkout:
        final exercises = action.exercises.map((e) {
          return {...e.toWorkoutMap(), 'tags': e.secondaryMuscles};
        }).toList();
        final calories = await ProgressStore.logAiWorkout(
          sourceId: sourceId,
          name: action.workoutName,
          category: action.workoutCategory,
          durationMinutes: action.durationMinutes,
          exercises: exercises,
        );
        String muscleName(String group) {
          if (german) return group;
          return switch (group) {
            'Brust' => 'chest',
            'Rücken' => 'back',
            'Schultern' => 'shoulders',
            'Bizeps' => 'biceps',
            'Trizeps' => 'triceps',
            'Bauch' => 'core',
            'Beine' => 'legs',
            'Unterarme' => 'forearms',
            'Nacken' => 'neck',
            _ => group,
          };
        }

        final muscles = action.exercises
            .expand((e) => [e.mainGroup, ...e.secondaryMuscles])
            .toSet()
            .map(muscleName)
            .join(', ');
        return german
            ? '✅ ${action.workoutName} wurde als absolvierte Einheit im Kalender und Verlauf gespeichert. Geschätzt: $calories kcal · beanspruchte Muskeln: $muscles.'
            : '✅ ${action.workoutName} was recorded as a completed session in your calendar and history. Estimate: $calories kcal · muscles used: $muscles.';
    }
  }

  void _cancel() {
    _generation++;
    _request?.close();
    _request = null;
    setState(() {
      _busy = false;
      _error = t(
        'Anfrage gestoppt. Bereits verarbeitete Daten können berechnet werden.',
        'Request stopped. Data already processed may still be billed.',
      );
    });
  }

  void _newChat() {
    FocusScope.of(context).unfocus();
    setState(() {
      _active = null;
      _photo = null;
      _videoFrames = [];
      _error = null;
      _input.clear();
      _provider = AiProvider.parse(
        ProgressStore.chatSettings['provider'] as String?,
      );
    });
  }

  Future<void> _history() async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        key: const ValueKey('chat-history-sheet'),
        expand: false,
        initialChildSize: .65,
        minChildSize: .25,
        maxChildSize: .9,
        shouldCloseOnMinExtent: true,
        builder: (ctx, scrollController) => StatefulBuilder(
          builder: (ctx, updateSheet) => CustomScrollView(
            key: const ValueKey('chat-history-scroll'),
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: Text(
                        t('Deine Chats', 'Your chats'),
                        style: Theme.of(ctx).textTheme.headlineSmall,
                      ),
                    ),
                    if (_chats.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          t(
                            'Noch keine Chats. Unterhaltungen werden auf diesem Gerät gespeichert.',
                            'No chats yet. Conversations are saved on this device.',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SliverList.builder(
                itemCount: _chats.length,
                itemBuilder: (ctx, i) {
                  final chat = _chats[i];
                  final date = chat.messages.lastOrNull?.createdAt;
                  return ListTile(
                    title: Text(
                      chat.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${chat.provider.label} · ${date == null ? "" : DateFormat.yMMMd(Localizations.localeOf(ctx).languageCode).format(date)}',
                    ),
                    leading: const Icon(Icons.chat_bubble_outline_rounded),
                    onTap: () {
                      setState(() {
                        _active = chat;
                        _provider = chat.provider;
                        _photo = null;
                        _error = null;
                        _input.clear();
                      });
                      Navigator.pop(ctx);
                      _scrollDown();
                    },
                    trailing: IconButton(
                      tooltip: t('Chat löschen', 'Delete chat'),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final remove = await showDialog<bool>(
                          context: ctx,
                          builder: (dialog) => AlertDialog(
                            title: Text(t('Chat löschen?', 'Delete chat?')),
                            content: Text(
                              t(
                                'Chat und Fotos werden gelöscht. Eingetragene Mahlzeiten bleiben erhalten.',
                                'This deletes the chat and photos. Logged meals are kept.',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialog, false),
                                child: Text(t('Abbrechen', 'Cancel')),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(dialog, true),
                                child: Text(t('Löschen', 'Delete')),
                              ),
                            ],
                          ),
                        );
                        if (remove != true || !mounted || !ctx.mounted) {
                          return;
                        }
                        try {
                          final next = _chats
                              .where((c) => c.id != chat.id)
                              .toList();
                          await AiChatStore.save(next);
                          if (!mounted || !ctx.mounted) return;
                          setState(() {
                            _chats = next;
                            if (_active?.id == chat.id) _active = null;
                          });
                          updateSheet(() {});
                          await AiChatStore.deleteImages(chat);
                        } catch (_) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  t(
                                    'Chat/Fotos konnten nicht vollständig gelöscht werden.',
                                    'Could not fully delete the chat/photos.',
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProposal(ChatMessage message) async {
    if (_busy ||
        _recording ||
        _picking ||
        _savingProposal ||
        message.actionSaved ||
        message.proposalSuperseded ||
        message.proposal == null) {
      return;
    }
    setState(() => _savingProposal = true);
    try {
      final result = await _executeAction(
        message.proposal,
        sourceId: message.id,
      );
      message.actionSaved = true;
      if (result != null) message.text += '\n\n$result';
      await AiChatStore.save(_chats);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = t(
            'Vorschlag konnte nicht gespeichert werden. Der Zieleintrag wurde eventuell gelöscht. Bitte prüfen und erneut versuchen.',
            'Could not save the proposal. Its target may have been deleted. Please check and try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingProposal = false);
    }
  }

  Widget _proposalCard(ChatMessage message) {
    final action = message.proposal!;
    final saved =
        message.actionSaved || ProgressStore.hasAiChatAction(message.id);
    final title = switch (action.type) {
      AiChatActionType.deleteFoodEntries => t(
        'Ernährungseinträge löschen',
        'Delete food log entries',
      ),
      AiChatActionType.replaceFoodEntries => t(
        'Ernährungseinträge korrigieren',
        'Correct food log entries',
      ),
      AiChatActionType.saveWorkout ||
      AiChatActionType.logWorkout => action.workoutName,
      AiChatActionType.saveShoppingList => action.shoppingName,
      AiChatActionType.remember => t(
        'Für deinen Coach merken',
        'Remember for your coach',
      ),
      _ => action.meal?.name ?? t('Vorschlag', 'Proposal'),
    };
    final locked =
        saved ||
        message.proposalSuperseded ||
        _busy ||
        _recording ||
        _picking ||
        _savingProposal;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5D9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6C773)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF6D4907),
            ),
          ),
          if (action.targetId.isNotEmpty)
            Text(
              t(
                'Änderung an einem bestehenden Eintrag',
                'Changes an existing entry',
              ),
              style: const TextStyle(fontSize: 12),
            ),
          for (final id in action.entryIds)
            Builder(
              builder: (context) {
                final entry = ProgressStore.foodIntake
                    .where((e) => e['id'] == id)
                    .firstOrNull;
                return Text(
                  entry == null
                      ? t(
                          'Eintrag nicht mehr vorhanden',
                          'Entry no longer exists',
                        )
                      : '${entry['name']} · ${entry['grams'] ?? ''} g · ${entry['recordedAt']}',
                );
              },
            ),
          for (final exercise in action.exercises)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${exercise.name} · ${exercise.sets} × ${exercise.reps} · ${exercise.restSeconds} s ${t("Satzpause", "rest")}${exercise.evidence.isEmpty ? "" : "\n${exercise.evidence}"}',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          for (final item in action.shoppingItems)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text('• $item'),
            ),
          if (action.memory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(action.memory),
            ),
          if (action.meal != null) ...[
            Text(
              '${action.meal!.totals.kcal} kcal · ${t("Schätzung", "Estimate")}',
            ),
            for (final food in action.meal!.foods)
              Text('${food.grams.toStringAsFixed(0)} g ${food.name}'),
            if (action.meal!.recipe.isNotEmpty) Text(action.meal!.recipe),
            if (action.meal!.assumptions.isNotEmpty)
              Text(action.meal!.assumptions),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: ValueKey('save-proposal-${message.id}'),
                onPressed: locked ? null : () => _saveProposal(message),
                icon: Icon(
                  saved
                      ? Icons.check
                      : action.type == AiChatActionType.deleteFoodEntries
                      ? Icons.delete_outline
                      : Icons.save_outlined,
                ),
                label: Text(
                  saved
                      ? t('Gespeichert', 'Saved')
                      : message.proposalSuperseded
                      ? t(
                          'Durch neuen Vorschlag ersetzt',
                          'Replaced by newer proposal',
                        )
                      : action.type == AiChatActionType.deleteFoodEntries
                      ? t('Einträge löschen', 'Delete entries')
                      : action.type == AiChatActionType.replaceFoodEntries
                      ? t('Korrektur anwenden', 'Apply correction')
                      : t('Vorschlag speichern', 'Save proposal'),
                ),
              ),
              if (!saved && !message.proposalSuperseded)
                TextButton(
                  onPressed: locked
                      ? null
                      : () {
                          _input.text = t(
                            'Ändere den Vorschlag: ',
                            'Change the proposal: ',
                          );
                          _input.selection = TextSelection.collapsed(
                            offset: _input.text.length,
                          );
                          _scrollDown();
                        },
                  child: Text(t('Ändern', 'Change')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _review(ChatMessage message) async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: ChatMealReviewSheet(
          message: message,
          onSaved: () => AiChatStore.save(_chats),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _message(ChatMessage message) {
    final user = message.role == 'user';
    final logged =
        message.loggedAt != null || ProgressStore.hasChatMeal(message.id);
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: user
              ? AppColors.primary.withValues(alpha: .12)
              : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(user ? 20 : 8),
            topRight: Radius.circular(user ? 8 : 20),
            bottomLeft: const Radius.circular(20),
            bottomRight: const Radius.circular(20),
          ),
          border: Border.all(
            color: user
                ? AppColors.primary.withValues(alpha: 0.16)
                : AppColors.stroke.withValues(alpha: 0.75),
          ),
          boxShadow: user
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!user) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Kaizen Coach',
                    style: TextStyle(
                      color: AppColors.accentText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (message.imageName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    AiChatStore.imageFile(message.imageName!),
                    height: 180,
                    width: 240,
                    fit: BoxFit.cover,
                    cacheWidth: 480,
                    errorBuilder: (_, _, _) =>
                        Text(t('Foto nicht verfügbar', 'Photo unavailable')),
                  ),
                ),
              ),
            SelectableText(
              message.text,
              style: TextStyle(color: AppColors.textPrimary, height: 1.45),
            ),
            if (message.frames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  message.frames.every((frame) => frame.seconds < 0)
                      ? t(
                          '${message.frames.length} Bilder · in Beitragsreihenfolge',
                          '${message.frames.length} images · in post order',
                        )
                      : t(
                          '${message.frames.length} Bildausschnitte · ohne Ton',
                          '${message.frames.length} visual samples · no audio',
                        ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (user &&
                message.videoSource != null &&
                message.frames.isEmpty &&
                Platform.isAndroid)
              TextButton.icon(
                onPressed: _busy || _recording || _picking ? null : _pickVideo,
                icon: const Icon(Icons.video_library_outlined),
                label: Text(t('Video hinzufügen', 'Attach video')),
              ),
            if (message.proposal != null) _proposalCard(message),
            if (message.meal != null) ...[
              const SizedBox(height: 14),
              Text(
                message.meal!.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${message.meal!.totals.kcal} kcal · ${t("KI-Schätzung", "AI estimate")}',
              ),
              Text(
                'P ${message.meal!.totals.proteinG.toStringAsFixed(1)} g · '
                'C ${message.meal!.totals.carbsG.toStringAsFixed(1)} g · F ${message.meal!.totals.fatsG.toStringAsFixed(1)} g',
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: logged || _busy || _recording
                    ? null
                    : () => _review(message),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: AppColors.textPrimary,
                ),
                icon: Icon(
                  logged
                      ? Icons.check_circle_outline
                      : Icons.restaurant_outlined,
                ),
                label: Text(
                  logged
                      ? t('Eingetragen', 'Logged')
                      : t('Prüfen & eintragen', 'Review & log'),
                ),
              ),
            ],
            if (message.failed &&
                !_busy &&
                identical(message, _active?.messages.lastOrNull))
              TextButton.icon(
                onPressed: () => _send(retry: true),
                icon: const Icon(Icons.refresh),
                label: Text(
                  t('Erneut senden · API-Kosten', 'Retry · API usage'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final messages = _active?.messages ?? <ChatMessage>[];
    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t('Chat', 'Chat'),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${_provider.label} · $_model',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasApiKey[_provider] == false)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.tonalIcon(
                          key: const Key('chat-api-key-prompt'),
                          onPressed:
                              _busy || _recording || _picking || _importing
                              ? null
                              : _settings,
                          icon: const Icon(Icons.key_outlined),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              t(
                                'Um den Coach AI zu nutzen, gib hier deinen Claude-/GPT-API-Schlüssel ein.',
                                'To use the Coach AI, you need to enter your Claude/GPT API key here.',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t(
                            'Etwa 5 € können bei täglicher Nutzung einen Monat reichen. Kosten variieren je nach Modell und Nutzung.',
                            'About €5 may last a month with daily use. Costs vary by model and usage.',
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: messages.isEmpty
                      ? LayoutBuilder(
                          builder: (ctx, constraints) => SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 28,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 78,
                                      height: 78,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.11,
                                        ),
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                      child: Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 36,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      t(
                                        'DEIN FITNESS-COACH',
                                        'YOUR FITNESS COACH',
                                      ),
                                      style: TextStyle(
                                        color: AppColors.accentText,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    Text(
                                      t(
                                        'Wie kann ich dir heute helfen?',
                                        'How can I help today?',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 23,
                                        height: 1.15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.45,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      t(
                                        'Frag zu Training und Ernährung oder lass ein Foto deiner Mahlzeit einschätzen.',
                                        'Ask about training and nutrition, or get an estimate from a meal photo.',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    OutlinedButton.icon(
                                      onPressed: _picking || _recording || _busy
                                          ? null
                                          : _pickPhoto,
                                      icon: const Icon(
                                        Icons.add_a_photo_outlined,
                                      ),
                                      label: Text(
                                        t(
                                          'Mahlzeit fotografieren',
                                          'Add a meal photo',
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.textPrimary,
                                        side: BorderSide(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.06),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 13,
                                        ),
                                        shape: const StadiumBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      key: const Key('chat-scan-barcode'),
                                      onPressed:
                                          _scanning || _recording || _picking
                                          ? null
                                          : _scanBarcode,
                                      icon: const Icon(
                                        Icons.qr_code_scanner_rounded,
                                      ),
                                      label: Text(
                                        t(
                                          'Barcode scannen',
                                          'Scan the barcode',
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.textPrimary,
                                        side: BorderSide(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.06),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 13,
                                        ),
                                        shape: const StadiumBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      t(
                                        'Du kannst hier auch ganz normal chatten.',
                                        'You can also chat about anything here.',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: messages.length,
                          itemBuilder: (_, i) => _message(messages[i]),
                        ),
                ),
                if (_busy || _importing)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _busy && _videoConversation
                                ? t(
                                    'Bilder / Video werden analysiert …',
                                    'Analyzing images / video …',
                                  )
                                : _busy
                                ? t(
                                    'Antwort wird erstellt …',
                                    'Preparing response …',
                                  )
                                : t(
                                    'Geteilter Beitrag wird geladen und vorbereitet …',
                                    'Loading and preparing shared content …',
                                  ),
                          ),
                        ),
                        if (_busy)
                          TextButton(
                            onPressed: _cancel,
                            child: Text(t('Stoppen', 'Stop')),
                          ),
                      ],
                    ),
                  ),
                if (_recording)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: Text(
                      t(
                        'Spracheingabe aktiv · Stoppen, dann Text prüfen und senden',
                        'Listening · Stop, then review and send your text',
                      ),
                      style: TextStyle(
                        color: AppColors.accentText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_videoFrames.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: Text(
                      t(
                        'Video bereit · ${_videoFrames.length} Bildausschnitte',
                        'Video ready · ${_videoFrames.length} visual samples',
                      ),
                    ),
                  ),
                if (_photo != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _photo!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            cacheWidth: 128,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t(
                              'Foto bereit zur Analyse',
                              'Photo ready to analyze',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: t('Foto entfernen', 'Remove photo'),
                          onPressed: _busy
                              ? null
                              : () => setState(() => _photo = null),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (messages.isNotEmpty) ...[
                        _ChatHeaderAction(
                          tooltip: t('Barcode scannen', 'Scan the barcode'),
                          icon: Icons.qr_code_scanner_rounded,
                          onPressed: _scanning || _recording || _picking
                              ? null
                              : _scanBarcode,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (Platform.isAndroid) ...[
                        _ChatHeaderAction(
                          tooltip: t('Video analysieren', 'Analyze video'),
                          icon: Icons.video_library_outlined,
                          onPressed: _busy || _recording || _picking
                              ? null
                              : _pickVideo,
                        ),
                        const SizedBox(width: 4),
                      ],
                      _ChatHeaderAction(
                        tooltip: t('Chatverlauf', 'Chat history'),
                        icon: Icons.history_rounded,
                        onPressed:
                            _busy || _recording || _picking || _savingProposal
                            ? null
                            : _history,
                      ),
                      const SizedBox(width: 4),
                      _ChatHeaderAction(
                        tooltip: t('Neuer Chat', 'New chat'),
                        icon: Icons.add_comment_outlined,
                        onPressed:
                            _busy || _recording || _picking || _savingProposal
                            ? null
                            : _newChat,
                      ),
                      const SizedBox(width: 4),
                      _ChatHeaderAction(
                        tooltip: t('KI-Einstellungen', 'AI settings'),
                        icon: Icons.tune_rounded,
                        onPressed:
                            _busy || _recording || _picking || _savingProposal
                            ? null
                            : _settings,
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: AppColors.surfaceDecoration(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        key: const Key('chat-add-photo'),
                        tooltip: t('Bild hinzufügen', 'Add image'),
                        onPressed: _busy || _recording || _picking
                            ? null
                            : _pickPhoto,
                        icon: Icon(_picking ? Icons.hourglass_top : Icons.add),
                      ),
                      Expanded(
                        child: TextField(
                          key: const Key('chat-input'),
                          controller: _input,
                          enabled: !_busy && !_recording,
                          minLines: 1,
                          maxLines: 5,
                          maxLength: 8000,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: t(
                              'Frag deinen Fitness-Coach …',
                              'Ask your fitness coach …',
                            ),
                            hintStyle: TextStyle(
                              color: AppColors.textMuted.withValues(
                                alpha: 0.85,
                              ),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      ChatVoiceInput(
                        controller: _input,
                        enabled:
                            !_busy &&
                            !_picking &&
                            !_savingProposal &&
                            !_importing,
                        isActive: widget.isActive,
                        onActiveChanged: (active) => setState(() {
                          _recording = active;
                          if (active) _error = null;
                        }),
                        onError: (error) => setState(() => _error = error),
                      ),
                      IconButton.filled(
                        key: const Key('chat-send'),
                        tooltip: t('Senden', 'Send'),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.actionBackground,
                          foregroundColor: AppColors.onAction,
                          fixedSize: const Size(46, 46),
                        ),
                        onPressed: _busy || _recording || _picking
                            ? null
                            : () => _send(),
                        icon: const Icon(Icons.arrow_upward_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    t(
                      'Eigener API-Schlüssel · Nutzung wird separat berechnet',
                      'Your API key · Usage billed separately',
                    ),
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatHeaderAction extends StatelessWidget {
  const _ChatHeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primary.withValues(alpha: 0.07),
        foregroundColor: AppColors.textPrimary,
      ),
      icon: Icon(icon, size: 16),
    );
  }
}
