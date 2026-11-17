import 'anatomy_structure_card.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/body_map_view_mode.dart';
import '../models/body_muscle_group.dart';
import '../services/anatomy_catalog.dart';
import '../services/progress_store.dart';
import '../services/organ_health_service.dart';
import '../theme/app_colors.dart';
import 'anatomy_webview.dart';
import 'anatomy_scene_session.dart';
import 'muscle_exercise_popup.dart';
import 'muscle_segment_labels.dart';
import 'organ_detail_card.dart';
import 'movable_anatomy_card.dart';

/// Lets the surrounding anatomy toolbar turn the currently mounted model.
class Anatomy3DController extends ChangeNotifier {
  void toggleFrontBack() => notifyListeners();
}

/// A single active atlas surface; an optional session retains its loaded scene
/// across a sequential compact/fullscreen handoff, never two mounts at once.
class Anatomy3DView extends StatefulWidget {
  const Anatomy3DView({
    super.key,
    required this.mode,
    required this.expanded,
    required this.snapshot,
    this.onExpandTap,
    this.webViewFactory,
    this.catalog,
    this.fallback,
    this.controller,
    this.session,
    this.onDetailsChanged,
    this.onMuscleSelected,
    this.selectedSegments = const {},
  });

  final BodyMapViewMode mode;
  final bool expanded;
  final MuscleRecoverySnapshot snapshot;
  final VoidCallback? onExpandTap;

  /// Optional injection keeps bridge/lifecycle tests independent of native views.
  final AnatomyWebViewFactory? webViewFactory;
  final AnatomyCatalog? catalog;
  final Widget? fallback;
  final Anatomy3DController? controller;
  final AnatomySceneSession? session;

  /// Reports picks/dismissals so the host keeps its toolbar clear of the card.
  final ValueChanged<bool>? onDetailsChanged;

  /// A workout picker handles muscle taps itself instead of opening details.
  final ValueChanged<String>? onMuscleSelected;
  final Set<String> selectedSegments;

  @override
  State<Anatomy3DView> createState() => _Anatomy3DViewState();
}

class _Anatomy3DViewState extends State<Anatomy3DView> {
  AnatomyWebView? _webView;
  final Object _sessionOwner = Object();
  AnatomyCatalog _catalog = const AnatomyCatalog.empty();
  bool _started = false;
  bool _ready = false;
  bool _loaded = false;
  bool _unsupported = false;
  String? _error;
  Map<String, dynamic>? _selection;

  bool get _german => Localizations.localeOf(context).languageCode == 'de';

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_toggleFrontBack);
  }

  void _toggleFrontBack() {
    if (widget.expanded) {
      unawaited(_run('window.kaizenAnatomy?.toggleFrontBack();'));
    }
  }

  Map<String, Object?> get _state => {
    'mode': widget.mode.anatomyMode,
    'expanded': widget.expanded,
    'musclePicker': widget.onMuscleSelected != null,
    'selectedSegments': widget.selectedSegments.toList(),
    'theme': ProgressStore.useLightTheme ? 'light' : 'dark',
    'locale': _german ? 'de' : 'en',
    'recovery': {
      for (final entry in widget.snapshot.recovery.entries)
        entry.key.name: entry.value.name,
    },
    'afterburn': [
      for (final entry in widget.snapshot.afterburn.entries)
        if (entry.value.active) entry.key.name,
    ],
    'trained': widget.snapshot.trainedThisWeek
        .map((group) => group.name)
        .toList(),
    'organHealth': {
      for (final organ in Organ.values)
        organ.name: OrganHealthService.displayStatus(organ).name,
    },
    'paused': widget.session?.transitioning ?? false,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      unawaited(_start());
      unawaited(_loadCatalog());
    } else {
      unawaited(_syncState());
    }
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = widget.catalog ?? await AnatomyCatalog.load();
      if (mounted) setState(() => _catalog = catalog);
    } catch (error) {
      debugPrint('Anatomy catalog unavailable: $error');
    }
  }

  Future<void> _start() async {
    final session = widget.session;
    if (session != null) {
      try {
        final view = await session.attach(
          owner: _sessionOwner,
          initialState: _state,
          backgroundColor: AppColors.bodyMapBackground,
          onMessage: _onMessage,
          onError: _onError,
          onPageFinished: () => unawaited(_syncState()),
        );
        if (!mounted) return;
        setState(() {
          _webView = view;
          _ready = view != null;
          _unsupported = view == null;
          _loaded = session.loadedMode == widget.mode.anatomyMode;
        });
        await _syncState();
      } catch (error) {
        _onError('$error');
      }
      return;
    }
    final view = (widget.webViewFactory ?? createAnatomyWebView)();
    _webView = view;
    if (view == null) {
      if (mounted) setState(() => _unsupported = true);
      return;
    }
    try {
      await view.initialize(
        initialState: _state,
        backgroundColor: AppColors.bodyMapBackground,
        onMessage: _onMessage,
        onError: _onError,
        onPageFinished: () => unawaited(_syncState()),
      );
      if (!mounted || !identical(view, _webView)) return;
      setState(() => _ready = true);
      await _syncState();
    } catch (error) {
      _onError('$error');
    }
  }

  @override
  void didUpdateWidget(covariant Anatomy3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_toggleFrontBack);
      widget.controller?.addListener(_toggleFrontBack);
    }
    if (oldWidget.mode != widget.mode ||
        oldWidget.expanded != widget.expanded) {
      _selection = null;
      if (oldWidget.mode != widget.mode) _loaded = false;
    }
    if (oldWidget.catalog != widget.catalog && widget.catalog != null) {
      _catalog = widget.catalog!;
    }
    unawaited(_syncState());
  }

  Future<void> _syncState() async {
    if (!mounted || !_ready) return;
    await _run('window.kaizenAnatomy?.setState(${jsonEncode(_state)});');
  }

  Future<void> _run(String script) async {
    try {
      await _webView?.runJavaScript(script);
    } catch (error) {
      if (mounted) _onError('$error');
    }
  }

  void _onError(String message) {
    if (!mounted) return;
    debugPrint('Anatomy3D: $message');
    setState(() {
      _error = message;
      _loaded = false;
    });
  }

  void _onMessage(Object? payload) {
    if (!mounted) return;
    try {
      if (payload is String) payload = jsonDecode(payload);
      if (payload is! Map) return;
      final message = Map<String, dynamic>.from(payload);
      switch (message['type']) {
        case 'loaded':
          if (message['mode'] != null &&
              message['mode'] != widget.mode.anatomyMode) {
            return;
          }
          setState(() {
            _loaded = true;
            _error = null;
          });
        case 'selected':
          // Enforce picking rules in Flutter as well as in JavaScript.
          if (!widget.expanded || message['id'] is! String) return;
          final tissue = message['tissue'];
          final allowed = switch (widget.mode.anatomyMode) {
            'muscles' => tissue == 'muscle',
            'skeleton' => tissue == 'bone' || tissue == 'cartilage',
            'connective' => tissue == 'tendon' || tissue == 'ligament',
            'organs' => tissue == 'organ',
            _ => false,
          };
          if (allowed) {
            if (tissue == 'muscle' && widget.onMuscleSelected != null) {
              final segment =
                  message['trainingSegment'] as String? ??
                  _catalog.muscle(message['id'] as String)?.trainingSegment;
              if (segment != null) widget.onMuscleSelected!(segment);
              return;
            }
            setState(() => _selection = message);
            widget.onDetailsChanged?.call(true);
          }
        case 'cleared':
          setState(() => _selection = null);
          widget.onDetailsChanged?.call(false);
        case 'error':
          _onError('${message['message'] ?? 'Model loading failed'}');
      }
    } on FormatException {
      /* Ignore malformed messages from a retiring page. */
    } on TypeError {
      /* The bridge accepts only the documented JSON fields. */
    }
  }

  void _clearSelection() {
    setState(() => _selection = null);
    widget.onDetailsChanged?.call(false);
    unawaited(_run('window.kaizenAnatomy?.clearSelection();'));
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_toggleFrontBack);
    final view = _webView;
    _webView = null;
    if (widget.session != null) {
      widget.session!.detach(_sessionOwner);
    } else if (view != null) {
      unawaited(view.dispose());
    }
    super.dispose();
  }

  Widget _selectedInfo(Map<String, dynamic> selection, Size size) {
    final dockToBottom = selection['upperBody'] != false;
    final id = selection['id'] as String;
    final tissue = selection['tissue'] as String;
    final muscle = tissue == 'muscle' ? _catalog.muscle(id) : null;
    final segment =
        selection['trainingSegment'] as String? ?? muscle?.trainingSegment;
    final info = _catalog.describe(
      id: id,
      tissue: tissue,
      name: selection['name'] as String?,
      nameLatin: selection['nameLatin'] as String?,
      organId: selection['organId'] as String?,
      trainingSegment: segment,
    );
    if (tissue == 'organ') {
      final organId = info.organId ?? selection['organId'] as String? ?? id;
      return Positioned.fill(
        child: MovableAnatomyCard(
          key: ValueKey('organ-position-$id'),
          initialAlignment: Alignment.bottomLeft,
          insets: const EdgeInsets.fromLTRB(12, 72, 12, 16),
          child: SizedBox(
            width: size.width - 24,
            child: OrganDetailCard(
              key: ValueKey('organ-detail-$id'),
              organId: organId,
              title: info.title(_german),
              description: info.description(_german),
              latinName: info.latinName,
              height: math.min(
                size.height * .67,
                math.max(160, size.height - 96),
              ),
              onClose: _clearSelection,
            ),
          ),
        ),
      );
    }
    if (tissue == 'muscle' && segment != null) {
      final region = _catalog.segment(segment)?.info;
      // Reserve the fullscreen title/close row, which is drawn by the host
      // above the platform view and must not overlap the exercise card.
      const headerHeight = 72.0;
      final popupArea = Size(
        size.width,
        math.max(0, size.height - headerHeight),
      );
      return Positioned.fill(
        top: headerHeight,
        child: MuscleExercisePopup(
          key: ValueKey('$id:$segment'),
          segment: MuscleSegmentHit(slug: segment, pathIndex: 0, front: true),
          bodySize: popupArea,
          dockToBottom: dockToBottom,
          dismissBarrier: false,
          // There is no 2D silhouette hitbox for a rotating 3D mesh.
          muscleBounds: Rect.fromCenter(
            center: popupArea.center(Offset.zero),
            width: size.width * .25,
            height: size.height * .35,
          ),
          titleOverride: (region ?? info).title(_german),
          descriptionOverride: (region ?? info).description(_german),
          onClose: _clearSelection,
        ),
      );
    }
    return Positioned.fill(
      child: MovableAnatomyCard(
        key: ValueKey('structure-position-$id'),
        initialAlignment: Alignment.bottomLeft,
        initialPosition: dockToBottom ? null : const Offset(12, 84),
        insets: const EdgeInsets.fromLTRB(12, 72, 12, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: math.min(480, math.max(0, size.width - 44)),
            maxHeight: math.max(100, size.height * .76),
          ),
          child: AnatomyStructureCard(
            key: ValueKey('structure-detail-$id'),
            bottomAnchored: dockToBottom,
            info: info,
            tissue: tissue,
            onClose: _clearSelection,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      if (_unsupported && widget.fallback != null) {
        return widget.expanded
            ? widget.fallback!
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onExpandTap,
                child: widget.fallback!,
              );
      }
      return ColoredBox(
        color: AppColors.bodyMapBackground,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_ready) _webView!.buildView(),
            if (_unsupported || _error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.accessibility_new_rounded,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _unsupported
                            ? (_german
                                  ? '3D-Ansicht auf diesem Gerät nicht verfügbar'
                                  : '3D view is unavailable on this device')
                            : (_german
                                  ? 'Die 3D-Ansicht konnte nicht geladen werden.'
                                  : 'The 3D view could not be loaded.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_loaded && !_unsupported && _error == null)
              Center(
                child: Semantics(
                  label: _german ? 'Anatomie wird geladen' : 'Loading anatomy',
                  child: const CircularProgressIndicator(),
                ),
              ),
            if (!widget.expanded)
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: _german ? '3D-Ansicht öffnen' : 'Open 3D view',
                  child: GestureDetector(
                    key: const ValueKey('anatomy-expand'),
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onExpandTap,
                  ),
                ),
              ),
            if (widget.expanded && _selection != null)
              _selectedInfo(_selection!, size),
          ],
        ),
      );
    },
  );
}
