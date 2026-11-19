import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../models/body_map_view_mode.dart';
import '../models/body_muscle_group.dart';
import '../navigation/app_tab_navigation.dart';
import '../services/joint_activity_service.dart';
import '../services/muscle_activity_service.dart';
import '../services/organ_health_service.dart';
import 'organ_guidance_panel.dart';
import '../services/progress_store.dart';
import '../services/health_sleep_service.dart';
import '../services/health_steps_service.dart';
import '../services/home_weekly_summary_service.dart';
import '../theme/app_colors.dart';
import 'anatomy_3d_view.dart';
import 'anatomy_mode_icon.dart';
import 'anatomy_scene_session.dart';
import 'body_hud_overlay.dart';
import 'home_activity_panel.dart';
import 'home_fasting_hud.dart';
import 'body_map_tab_intro_dialog.dart';
import 'body_overlay_painter.dart';
import 'cached_body_paint.dart';
import 'muscle_exercise_popup.dart';
import 'muscle_segment_labels.dart';
import 'movable_anatomy_card.dart';

typedef MuscleSegmentTapCallback =
    void Function(MuscleSegmentHit hit, Size bodySize, Rect globalBounds);

// The old geometry is preserved in body_muscle_paths.dart and can be restored
// together with its original renderer by changing this switch to false.
const bool _kUseSculptedMaleMannequin = useGeneratedMaleMannequin;

/// The recovery view also renders the afterburn outlines, so it is labelled
/// with both names. Composed from the existing strings so no new translation
/// entries are needed.
String recoveryAfterburnLabel(AppLocalizations l10n) =>
    '${l10n.home_bodyViewRecovery} & ${l10n.home_bodyViewAfterburn}';

Size? _boundedLayoutSize(BoxConstraints constraints) {
  final width = constraints.maxWidth;
  final height = constraints.maxHeight;
  if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
    return null;
  }
  return Size(width, height);
}

class RecoveryBodyCard extends StatefulWidget {
  // Shared top inset for the profile heading and dashboard card.
  static const compactPanelTopWithHeading = 30.0;

  const RecoveryBodyCard({
    super.key,
    this.onExpansionProgress,
    this.onStartIntro,
    this.compactSidePanel,
    this.compactHeading,
    this.compactSidePanelWidthFactor = 0.32,
    this.compactSidePanelHeight,
    this.compactDashboard = false,
    this.anatomySession,
    this.mannequinTourKey,
  });

  final ValueChanged<double>? onExpansionProgress;
  final VoidCallback? onStartIntro;
  final Widget? compactSidePanel;
  final Widget? compactHeading;
  final double compactSidePanelWidthFactor;
  final double? compactSidePanelHeight;
  final bool compactDashboard;
  final AnatomySceneSession? anatomySession;
  final GlobalKey? mannequinTourKey;

  @override
  State<RecoveryBodyCard> createState() => _RecoveryBodyCardState();
}

class _RecoveryBodyCardState extends State<RecoveryBodyCard>
    with TickerProviderStateMixin {
  // Recovery and afterburn share one view: recovery fills a muscle, afterburn
  // outlines it, so both read at once without a second tab.
  static const _modes = [
    BodyMapViewMode.recovery,
    BodyMapViewMode.skeleton,
    BodyMapViewMode.connective,
    BodyMapViewMode.organs,
  ];
  static const _expandDuration = Duration(milliseconds: 440);
  static const _collapseDuration = Duration(milliseconds: 360);

  BodyMapViewMode _mode = BodyMapViewMode.recovery;

  late final AnimationController _flip;
  late final Animation<double> _flipCurved;
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandCurved;
  late final Animation<double> _chromeAnimation;

  final GlobalKey _compactMannequinKey = GlobalKey();
  final GlobalKey _atlasKey = GlobalKey();
  final _overlayNavigatorKey = GlobalKey<NavigatorState>();
  final _overlayContentRevision = ValueNotifier<int>(0);
  final _anatomyController = Anatomy3DController();
  Timer? _recoveryRefresh;
  late final AnatomySceneSession _anatomySession;
  ui.Image? _flightImage;
  bool _preparingExpansion = false;
  bool _nativeHandoffPending = false;
  bool _showCompactDuringCollapse = false;
  OverlayEntry? _overlayEntry;
  bool _expanded = false;
  bool _collapsing = false;
  MuscleSegmentHit? _expandedMuscleSegment;
  Size _expandedBodySize = Size.zero;
  Rect? _expandedMuscleGlobalBounds;
  Organ? _expandedOrgan;
  bool _detailsVisible = false;
  BodyJoint? _expandedJoint;

  @override
  void initState() {
    super.initState();
    _anatomySession = widget.anatomySession ?? AnatomySceneSession();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      value: 1,
    );
    _flipCurved = CurvedAnimation(parent: _flip, curve: Curves.easeInOut);
    _expandCtrl = AnimationController(
      vsync: this,
      duration: _expandDuration,
      reverseDuration: _collapseDuration,
    );
    _expandCurved = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _chromeAnimation = CurvedAnimation(
      parent: _expandCtrl,
      curve: _ChromeCurve(),
      reverseCurve: Curves.easeInCubic,
    );
    _expandCtrl.addListener(_onExpandTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HealthSleepService.refreshLastNightSleepIfStale();
      HealthStepsService.refreshTodayStepsIfStale();
    });
  }

  void _onExpandTick() {
    final progress =
        _flightImage != null || _expandCtrl.status == AnimationStatus.reverse
        ? _expandCurved.value
        : _expansionFigureT(_expandCurved.value);
    widget.onExpansionProgress?.call(progress);
  }

  @override
  void dispose() {
    _recoveryRefresh?.cancel();
    _removeOverlay(immediate: true);
    if (!AppTabNavigation.tabSwipeEnabled.value) {
      AppTabNavigation.tabSwipeEnabled.value = true;
    }
    _flip.dispose();
    _expandCtrl.removeListener(_onExpandTick);
    _expandCtrl.dispose();
    _overlayContentRevision.dispose();
    _anatomyController.dispose();
    _flightImage?.dispose();
    _flightImage = null;
    if (widget.anatomySession == null) unawaited(_anatomySession.dispose());
    super.dispose();
  }

  void _refreshOverlay() {
    if (_overlayEntry == null) return;
    _overlayContentRevision.value++;
  }

  void _onDetailsChanged(bool visible) {
    if (!mounted || !_expanded || _detailsVisible == visible) return;
    _detailsVisible = visible;
    _refreshOverlay();
  }

  void _scheduleRecoveryRefresh() {
    _recoveryRefresh?.cancel();
    final now = DateTime.now();
    final next = MuscleActivityService.nextRecoveryChange(now: now);
    if (next == null) return;
    _recoveryRefresh = Timer(next.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _refreshOverlay();
    });
  }

  void _handleSystemBack() {
    final navigator = _overlayNavigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    } else {
      _collapseBodyMap();
    }
  }

  void _removeOverlay({bool immediate = false}) {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
    if (immediate && _expandCtrl.isAnimating) {
      _expandCtrl.stop();
    }
  }

  Future<void> _expandBodyMap() async {
    if (_expanded ||
        _preparingExpansion ||
        _collapsing ||
        _expandCtrl.isAnimating)
      return;
    final box = _atlasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _preparingExpansion = true;
    AppTabNavigation.tabSwipeEnabled.value = false;
    final originRect = _globalRect(box);
    _flightImage = await _captureFlight();
    if (!mounted) return;
    if (AppTabNavigation.selectedTab.value != AppTabNavigation.home ||
        ModalRoute.of(context)?.isCurrent == false) {
      _preparingExpansion = false;
      _releaseFlight();
      unawaited(_anatomySession.resume());
      AppTabNavigation.tabSwipeEnabled.value = true;
      return;
    }
    _nativeHandoffPending = true;
    _preparingExpansion = false;
    setState(() => _expanded = true);
    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        // Keep theme/locale from the host card; root overlay context can differ
        // on Android release builds. Directionality is forwarded explicitly so
        // that Text/Icon widgets inside the overlay work correctly.
        final host = context;
        return Directionality(
          textDirection: Directionality.of(host),
          child: MediaQuery(
            // The compact card lives inside SafeArea, which removes padding
            // from its MediaQuery. Fullscreen content needs the root insets.
            data: MediaQuery.of(overlayContext),
            child: Theme(
              data: Theme.of(host),
              child: Navigator(
                key: _overlayNavigatorKey,
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (context) => ValueListenableBuilder<int>(
                    valueListenable: _overlayContentRevision,
                    builder: (context, _, child) => _BodyMapExpansionOverlay(
                      originRect: originRect,
                      flightImage: _flightImage,
                      flightClosing: _collapsing,
                      expandController: _expandCtrl,
                      expandAnimation: _expandCurved,
                      // Dismissal and tab swipes are observed passively on
                      // the body surface, leaving pinch zoom unclaimed.
                      enableVerticalDragToDismiss: false,
                      // Horizontal navigation is observed passively by the
                      // body surface so it does not compete with pinch zoom.
                      enableHorizontalDragNavigation: false,
                      onDismiss: _collapseBodyMap,
                      onHorizontalSwipe: _stepMode,
                      childBuilder: _buildExpandedBodyContent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    final overlay =
        Navigator.of(context, rootNavigator: true).overlay ??
        Overlay.of(context, rootOverlay: true);
    overlay.insert(_overlayEntry!);
    // The flight covers the old slot immediately. Only after its native surface
    // has unmounted may the retained controller attach at the destination size.
    await _finishHandoffFrame();
    if (!mounted || !_expanded || _collapsing) return;
    _nativeHandoffPending = false;
    _refreshOverlay();
    try {
      await _expandCtrl.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Closing or removing the card can interrupt the opening animation.
    }
    if (mounted && !_collapsing) {
      _releaseFlight();
      await _anatomySession.resume();
    }
  }

  Future<void> _finishHandoffFrame() async {
    // Native surfaces retire at frame finalization. The overlay navigator is
    // already mounted, so the next destination only needs this one frame.
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<ui.Image?> _captureFlight() async {
    final bytes = await _anatomySession.captureFrame();
    if (bytes == null || !mounted) return null;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return null;
      }
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  void _releaseFlight() {
    final image = _flightImage;
    _flightImage = null;
    _refreshOverlay();
    if (image != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => image.dispose());
    }
  }

  Future<void> _collapseBodyMap() async {
    if (!_expanded || _collapsing) return;
    _collapsing = true;
    // A close during opening uses the same frozen frame instead of requesting
    // another WebGL readback while the first transition is still running.
    _flightImage ??= await _captureFlight();
    if (!mounted) return;
    _expandedMuscleSegment = null;
    _expandedBodySize = Size.zero;
    _expandedMuscleGlobalBounds = null;
    _expandedOrgan = null;
    _expandedJoint = null;
    _detailsVisible = false;
    if (_flightImage != null) _nativeHandoffPending = true;
    _refreshOverlay();
    if (_flightImage != null) {
      await _finishHandoffFrame();
      if (!mounted) return;
      setState(() => _showCompactDuringCollapse = true);
    }
    try {
      await _expandCtrl.reverse().orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    if (!_showCompactDuringCollapse) {
      _nativeHandoffPending = true;
      _refreshOverlay();
      await _finishHandoffFrame();
      if (!mounted) return;
    }
    _removeOverlay();
    setState(() {
      _expanded = false;
      _collapsing = false;
      _nativeHandoffPending = false;
      _showCompactDuringCollapse = false;
    });
    _releaseFlight();
    await _anatomySession.resume();
    AppTabNavigation.tabSwipeEnabled.value = true;
  }

  Rect _globalRect(RenderBox box) {
    return MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
  }

  void _onExpandedMuscleTap(
    MuscleSegmentHit hit,
    Size bodySize,
    Rect globalBounds,
  ) {
    setState(() {
      if (_expandedMuscleSegment == hit) {
        _expandedMuscleSegment = null;
        _expandedBodySize = Size.zero;
        _expandedMuscleGlobalBounds = null;
      } else {
        _expandedMuscleSegment = hit;
        _expandedBodySize = bodySize;
        _expandedMuscleGlobalBounds = globalBounds;
        _expandedOrgan = null;
        _expandedJoint = null;
      }
    });
    _refreshOverlay();
  }

  void _clearExpandedMuscleSelection() {
    if (_expandedMuscleSegment == null) return;
    setState(() {
      _expandedMuscleSegment = null;
      _expandedBodySize = Size.zero;
      _expandedMuscleGlobalBounds = null;
    });
    _refreshOverlay();
  }

  void _onExpandedOrganTap(Organ organ) {
    setState(() {
      if (_expandedOrgan == organ) {
        _expandedOrgan = null;
      } else {
        _expandedOrgan = organ;
        _expandedMuscleSegment = null;
        _expandedBodySize = Size.zero;
        _expandedMuscleGlobalBounds = null;
        _expandedJoint = null;
      }
    });
    _refreshOverlay();
  }

  void _clearExpandedOrganSelection() {
    if (_expandedOrgan == null) return;
    setState(() {
      _expandedOrgan = null;
    });
    _refreshOverlay();
  }

  void _onExpandedJointTap(BodyJoint joint) {
    setState(() {
      if (_expandedJoint == joint) {
        _expandedJoint = null;
      } else {
        _expandedJoint = joint;
        _expandedMuscleSegment = null;
        _expandedBodySize = Size.zero;
        _expandedMuscleGlobalBounds = null;
        _expandedOrgan = null;
      }
    });
    _refreshOverlay();
  }

  void _clearExpandedJointSelection() {
    if (_expandedJoint == null) return;
    setState(() {
      _expandedJoint = null;
    });
    _refreshOverlay();
  }

  String _modeLabel(AppLocalizations l10n) =>
      _mode.anatomyLabel(l10n.localeName.startsWith('de'));

  void _goToMode(BodyMapViewMode mode) {
    final index = _modes.indexOf(mode);
    if (index < 0) return;
    final modeChanged = _mode != mode;
    if (modeChanged) {
      setState(() {
        _mode = mode;
        _detailsVisible = false;
        _expandedOrgan = null;
        _expandedJoint = null;
        _expandedMuscleSegment = null;
        _expandedBodySize = Size.zero;
        _expandedMuscleGlobalBounds = null;
      });
    }
    if (_expanded) _refreshOverlay();
  }

  void _stepMode(int delta) {
    final next = _modes.indexOf(_mode) + delta;
    if (next < 0 || next >= _modes.length) return;
    _goToMode(_modes[next]);
  }

  void _onModeSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 40) return;
    _stepMode(velocity < 0 ? 1 : -1);
  }

  Widget _modeSwipeDetector({required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: _onModeSwipe,
      child: child,
    );
  }

  Widget _buildModePage({
    required AppLocalizations l10n,
    required BodyMapViewMode mode,
    required MuscleRecoverySnapshot snapshot,
    required bool expanded,
    VoidCallback? onExpandTap,
    MuscleSegmentTapCallback? onMuscleTap,
    VoidCallback? onMuscleSelectionClear,
    Organ? selectedOrgan,
    ValueChanged<Organ>? onOrganTap,
    VoidCallback? onOrganSelectionClear,
    BodyJoint? selectedJoint,
    ValueChanged<BodyJoint>? onJointTap,
    VoidCallback? onJointSelectionClear,
    VoidCallback? onCollapseTap,
    ValueChanged<int>? onFullscreenSwipe,
    bool compactDashboard = false,
  }) {
    return Anatomy3DView(
      key: _atlasKey,
      controller: _anatomyController,
      session: _anatomySession,
      mode: mode,
      expanded: expanded,
      snapshot: snapshot,
      onExpandTap: onExpandTap,
      onDetailsChanged: expanded ? _onDetailsChanged : null,
      // Retain the established 2D canvas on unsupported platforms and in
      // widget tests; no native plugin is initialized for those environments.
      fallback: switch (mode) {
        BodyMapViewMode.organs => _OrganView(
          l10n: l10n,
          expanded: expanded,
          compactDashboard: compactDashboard && !expanded,
          onBackgroundTap: onExpandTap,
          selectedOrgan: selectedOrgan,
          onOrganTap: onOrganTap,
          onOrganSelectionClear: onOrganSelectionClear,
          onCollapseTap: onCollapseTap,
          onFullscreenSwipe: onFullscreenSwipe,
        ),
        BodyMapViewMode.skeleton => _SkeletonView(
          l10n: l10n,
          expanded: expanded,
          compactDashboard: compactDashboard && !expanded,
          onBackgroundTap: onExpandTap,
          selectedJoint: selectedJoint,
          onJointTap: onJointTap,
          onJointSelectionClear: onJointSelectionClear,
          onCollapseTap: onCollapseTap,
          onFullscreenSwipe: onFullscreenSwipe,
        ),
        BodyMapViewMode.connective => Center(
          child: Text(
            mode.anatomyLabel(l10n.localeName.startsWith('de')),
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        _ => _MuscleFigure(
          flip: _flipCurved,
          mode: mode,
          snapshot: snapshot,
          l10n: l10n,
          compactDashboard: compactDashboard && !expanded,
          expanded: expanded,
          onExpandTap: onExpandTap,
          onMuscleTap: onMuscleTap,
          onMuscleSelectionClear: onMuscleSelectionClear,
          selectedSegment: expanded ? _expandedMuscleSegment : null,
          onCollapseTap: onCollapseTap,
          onFullscreenSwipe: onFullscreenSwipe,
        ),
      },
    );
  }

  Widget _buildBodyMapStack({
    required AppLocalizations l10n,
    required MuscleRecoverySnapshot snapshot,
    required bool expanded,
    VoidCallback? onExpandTap,
    MuscleSegmentTapCallback? onMuscleTap,
    VoidCallback? onMuscleSelectionClear,
    bool showSidePanel = true,
    VoidCallback? onStartIntro,
    VoidCallback? onCollapseTap,
    ValueChanged<int>? onFullscreenSwipe,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mq = MediaQuery.sizeOf(context);
        final screenWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : mq.width;
        final screenHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : mq.height;
        final statusPanelWidth = expanded
            ? 220.0
            : screenWidth * widget.compactSidePanelWidthFactor;
        final bodyMapLeft = widget.compactDashboard && !expanded
            ? screenWidth * 0.31
            : statusPanelWidth;

        // Only the active mode owns a native WebView. PageView prebuilds
        // neighbours and can otherwise mount several expensive atlas scenes.
        final activeBodyMap = _buildModePage(
          l10n: l10n,
          mode: _mode,
          snapshot: snapshot,
          expanded: expanded,
          compactDashboard: widget.compactDashboard,
          onExpandTap: onExpandTap,
          onMuscleTap: onMuscleTap,
          onMuscleSelectionClear: onMuscleSelectionClear,
          selectedOrgan: _expandedOrgan,
          onOrganTap: _onExpandedOrganTap,
          onOrganSelectionClear: _clearExpandedOrganSelection,
          selectedJoint: _expandedJoint,
          onJointTap: _onExpandedJointTap,
          onJointSelectionClear: _clearExpandedJointSelection,
          onCollapseTap: onCollapseTap,
          onFullscreenSwipe: onFullscreenSwipe,
        );
        final bodyMap = expanded
            ? activeBodyMap
            : _modeSwipeDetector(child: activeBodyMap);

        final statusPanel = showSidePanel
            ? (widget.compactSidePanel ??
                  _HomeHudSidePanel(
                    l10n: l10n,
                    expanded: expanded,
                    maxPanelWidth: statusPanelWidth,
                  ))
            : null;

        Widget hudChrome(Widget child) {
          return expanded
              ? FadeTransition(opacity: _chromeAnimation, child: child)
              : child;
        }

        return SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              if (expanded)
                Positioned.fill(child: bodyMap)
              else
                // Mannequin stays behind the left dashboard cards. Its slightly
                // wider canvas gives the figure a larger, more centered pose.
                // The left HUD panel stays above it in the stack order.
                Stack(
                  key: _compactMannequinKey,
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.compactHeading case final heading?)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              statusPanelWidth + 6,
                              RecoveryBodyCard.compactPanelTopWithHeading,
                              6,
                              8,
                            ),
                            child: heading,
                          ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, stage) => Stack(
                              clipBehavior: widget.compactHeading == null
                                  ? Clip.none
                                  : Clip.hardEdge,
                              children: [
                                // Widen the canvas modestly and preserve the card foreground.
                                Positioned(
                                  left: bodyMapLeft,
                                  height: widget.compactDashboard
                                      ? math.min(
                                          stage.maxHeight,
                                          (widget.compactSidePanelHeight ??
                                                  screenHeight) +
                                              84,
                                        )
                                      : screenHeight,
                                  bottom: 0,
                                  right: 0,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) =>
                                        OverflowBox(
                                          minWidth: constraints.maxWidth + 48,
                                          maxWidth: constraints.maxWidth + 48,
                                          alignment: Alignment.center,
                                          child: widget.compactDashboard
                                              ? Transform.translate(
                                                  offset: const Offset(-4, 0),
                                                  child: Transform.scale(
                                                    scale: 1.14,
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    child: bodyMap,
                                                  ),
                                                )
                                              : bodyMap,
                                        ),
                                  ),
                                ),
                                // Track the visible figure, excluding the dashboard and
                                // sidebar, rather than the overflowing WebView canvas.
                                if (widget.mannequinTourKey != null &&
                                    widget.compactDashboard)
                                  Positioned(
                                    left: statusPanelWidth - 4,
                                    right: 36,
                                    top: 16,
                                    bottom: 40,
                                    child: IgnorePointer(
                                      child: SizedBox.expand(
                                        key: widget.mannequinTourKey,
                                      ),
                                    ),
                                  ),
                                // Selected tab's title, centered above the mannequin.
                                // Right must match the mannequin's own box (right: 0),
                                // not the sidebar's inset, or the centers won't line up.
                                if (!widget.compactDashboard)
                                  Positioned(
                                    top: 6,
                                    left: statusPanelWidth,
                                    right: 0,
                                    child: IgnorePointer(
                                      child: Center(
                                        child: Padding(
                                          // Symmetric padding keeps the text centered on
                                          // the same box as the mannequin while still
                                          // clearing the top-right info icon.
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 36,
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: Text(
                                              _modeLabel(l10n),
                                              key: ValueKey(_mode),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: AppColors.accentText,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Right sidebar
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  bottom: widget.compactDashboard && !expanded
                                      ? 42
                                      : 4,
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: SingleChildScrollView(
                                      primary: false,
                                      child: _BodyMapSidebar(
                                        mode: _mode,
                                        onInfoTap: () =>
                                            BodyMapTabIntroDialog.show(
                                              context,
                                              _mode,
                                            ),
                                        onModeTap: _goToMode,
                                        // The recovery/muscle figure supports front and back
                                        // views in both compact and expanded layouts.
                                        showInfo: true,
                                        recoveryLabel: BodyMapViewMode.recovery
                                            .anatomyLabel(
                                              l10n.localeName.startsWith('de'),
                                            ),
                                        organsLabel: BodyMapViewMode.organs
                                            .anatomyLabel(
                                              l10n.localeName.startsWith('de'),
                                            ),
                                        skeletonLabel: BodyMapViewMode.skeleton
                                            .anatomyLabel(
                                              l10n.localeName.startsWith('de'),
                                            ),
                                        connectiveLabel: BodyMapViewMode
                                            .connective
                                            .anatomyLabel(
                                              l10n.localeName.startsWith('de'),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (showSidePanel)
                      Positioned(
                        left: 0,
                        top: widget.compactHeading == null
                            ? 0
                            : RecoveryBodyCard.compactPanelTopWithHeading,
                        bottom: widget.compactDashboard && !expanded ? null : 0,
                        height: widget.compactDashboard && !expanded
                            ? (widget.compactSidePanelHeight ?? screenHeight)
                            : null,
                        width: statusPanelWidth,
                        child: _modeSwipeDetector(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              // Shadow only in dark mode — in light mode the
                              // same black shadow would appear as a visible
                              // dark rectangle over the light mannequin canvas.
                              boxShadow: ProgressStore.useLightTheme
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 4,
                                        offset: const Offset(8, 0),
                                      ),
                                    ],
                            ),
                            child: statusPanel!,
                          ),
                        ),
                      ),
                    if (onStartIntro != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 4,
                        child: Center(
                          child: _HomeIntroStartButton(
                            label: l10n.home_startIntro,
                            onTap: onStartIntro,
                          ),
                        ),
                      ),
                  ],
                ),
              if (expanded && _expandedOrgan != null)
                Positioned.fill(
                  child: hudChrome(
                    MovableAnatomyCard(
                      key: ValueKey('fallback-organ-$_expandedOrgan'),
                      insets: const EdgeInsets.fromLTRB(12, 72, 12, 12),
                      initialPosition: Offset(
                        screenWidth * .24,
                        screenHeight * .11,
                      ),
                      child: SizedBox(
                        width: screenWidth * .76 - 20,
                        child: _ExpandedBodyDetailCard(
                          child: _OrganDetailOverlay(
                            organ: _expandedOrgan!,
                            large: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (expanded && _expandedJoint != null)
                Positioned.fill(
                  child: hudChrome(
                    MovableAnatomyCard(
                      key: ValueKey('fallback-joint-$_expandedJoint'),
                      insets: const EdgeInsets.fromLTRB(12, 72, 12, 12),
                      initialPosition: Offset(
                        screenWidth * .24,
                        screenHeight * .11,
                      ),
                      child: SizedBox(
                        width: screenWidth * .76 - 20,
                        child: _ExpandedBodyDetailCard(
                          child: SingleChildScrollView(
                            child: _JointDetailOverlay(
                              joint: _expandedJoint!,
                              strengthened:
                                  JointActivityService.strengthenedThisWeek()
                                      .contains(_expandedJoint!),
                              large: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandedBodyContent(BuildContext context) {
    if (_nativeHandoffPending) return const SizedBox.expand();
    final l10n = context.l10n;
    return ValueListenableBuilder<int>(
      valueListenable: ProgressStore.listenable(),
      builder: (context, _, child) {
        _scheduleRecoveryRefresh();
        final snapshot = MuscleActivityService.snapshot();
        final safeTop = MediaQuery.paddingOf(context).top;
        return SizedBox.expand(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildBodyMapStack(
                          l10n: l10n,
                          snapshot: snapshot,
                          expanded: true,
                          onMuscleTap: _onExpandedMuscleTap,
                          onMuscleSelectionClear: _clearExpandedMuscleSelection,
                          onCollapseTap: _collapseBodyMap,
                          onFullscreenSwipe: _stepMode,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: safeTop,
                left: 64,
                right: 64,
                child: FadeTransition(
                  opacity: _chromeAnimation,
                  child: IgnorePointer(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          _modeLabel(l10n),
                          key: ValueKey(_mode),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ProgressStore.useLightTheme
                                ? const Color(0xFF799567)
                                : AppColors.darkPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: safeTop,
                right: 8,
                bottom: 64,
                width: 44,
                child: FadeTransition(
                  opacity: _chromeAnimation,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: SingleChildScrollView(
                      hitTestBehavior: HitTestBehavior.deferToChild,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SidebarIcon(
                            icon: Icons.keyboard_arrow_down_rounded,
                            label: l10n.localeName.startsWith('de')
                                ? 'Vollbild schließen'
                                : 'Close fullscreen',
                            onTap: _collapseBodyMap,
                            active: false,
                            flat: true,
                            touchSize: 44,
                          ),
                          const SizedBox(height: 4),
                          Visibility(
                            visible: !_detailsVisible,
                            maintainState: true,
                            maintainAnimation: true,
                            maintainSize: true,
                            child: _BodyMapSidebar(
                              mode: _mode,
                              onInfoTap: () =>
                                  BodyMapTabIntroDialog.show(context, _mode),
                              onModeTap: _goToMode,
                              showInfo: true,
                              expanded: true,
                              onToggleView: () {
                                _anatomyController.toggleFrontBack();
                                _toggleSide();
                              },
                              recoveryLabel: BodyMapViewMode.recovery
                                  .anatomyLabel(
                                    l10n.localeName.startsWith('de'),
                                  ),
                              organsLabel: BodyMapViewMode.organs.anatomyLabel(
                                l10n.localeName.startsWith('de'),
                              ),
                              skeletonLabel: BodyMapViewMode.skeleton
                                  .anatomyLabel(
                                    l10n.localeName.startsWith('de'),
                                  ),
                              connectiveLabel: BodyMapViewMode.connective
                                  .anatomyLabel(
                                    l10n.localeName.startsWith('de'),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_expandedMuscleSegment != null)
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _chromeAnimation,
                    child: MuscleExercisePopup(
                      segment: _expandedMuscleSegment!,
                      bodySize: _expandedBodySize,
                      muscleBounds: _expandedMuscleGlobalBounds?.shift(
                        Offset(0, -safeTop),
                      ),
                      onClose: _clearExpandedMuscleSelection,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _toggleSide() {
    _flip.animateTo(_flip.value > 0.5 ? 0.0 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<int>(
      valueListenable: ProgressStore.listenable(),
      builder: (context, _, child) {
        _scheduleRecoveryRefresh();
        // The host screen may animate underneath the overlay. Do not rescan
        // workout history while the compact mannequin is hidden.
        if (_expanded && !_showCompactDuringCollapse) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _handleSystemBack();
            },
            child: const SizedBox.expand(),
          );
        }
        final snapshot = MuscleActivityService.snapshot();
        return PopScope(
          canPop: !_expanded,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleSystemBack();
          },
          child: SizedBox.expand(
            child: _buildBodyMapStack(
              l10n: l10n,
              snapshot: snapshot,
              expanded: false,
              onExpandTap: _expandBodyMap,
              onStartIntro: widget.onStartIntro,
            ),
          ),
        );
      },
    );
  }
}

/// Pinch-zoom in fullscreen mode with fixed controls for precise zoom changes.
class _BodyMapInteractiveSurface extends StatefulWidget {
  const _BodyMapInteractiveSurface({
    required this.expanded,
    required this.child,
    this.onVerticalSwipe,
    this.onHorizontalSwipe,
  });

  final bool expanded;
  final Widget child;
  final VoidCallback? onVerticalSwipe;
  final ValueChanged<int>? onHorizontalSwipe;

  @override
  State<_BodyMapInteractiveSurface> createState() =>
      _BodyMapInteractiveSurfaceState();
}

class _BodyMapInteractiveSurfaceState
    extends State<_BodyMapInteractiveSurface> {
  final TransformationController _transform = TransformationController();
  final Set<int> _activePointers = <int>{};
  int? _primaryPointer;
  Offset _swipeStart = Offset.zero;
  Duration _swipeStartTime = Duration.zero;
  var _gestureHadMultiplePointers = false;
  var _zoomed = false;
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransformChanged);
  }

  @override
  void didUpdateWidget(covariant _BodyMapInteractiveSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.expanded && oldWidget.expanded) {
      _transform.value = Matrix4.identity();
      _zoomed = false;
      _scale = 1;
    }
  }

  void _onTransformChanged() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.001;
    final scale = _transform.value.getMaxScaleOnAxis();
    if (zoomed != _zoomed || (scale - _scale).abs() > 0.015) {
      setState(() {
        _zoomed = zoomed;
        _scale = scale;
      });
    }
  }

  void _zoomBy(double factor, Size viewportSize) {
    final nextScale = (_scale * factor).clamp(1.0, 4.5).toDouble();
    if ((nextScale - _scale).abs() < 0.001) return;
    final focalPoint = Offset(viewportSize.width / 2, viewportSize.height / 2);
    final scenePoint = _transform.toScene(focalPoint);
    _transform.value = Matrix4.identity()
      ..setEntry(0, 0, nextScale)
      ..setEntry(1, 1, nextScale)
      ..setEntry(0, 3, focalPoint.dx - scenePoint.dx * nextScale)
      ..setEntry(1, 3, focalPoint.dy - scenePoint.dy * nextScale);
  }

  void _resetZoom() {
    _transform.value = Matrix4.identity();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.expanded ||
        (widget.onVerticalSwipe == null && widget.onHorizontalSwipe == null)) {
      return;
    }
    if (_activePointers.isEmpty) {
      _primaryPointer = event.pointer;
      _swipeStart = event.localPosition;
      _swipeStartTime = event.timeStamp;
      _gestureHadMultiplePointers = false;
    } else {
      _gestureHadMultiplePointers = true;
    }
    _activePointers.add(event.pointer);
  }

  void _onPointerUp(PointerEvent event) {
    if (!_activePointers.contains(event.pointer)) return;
    if (event.pointer == _primaryPointer &&
        _activePointers.length == 1 &&
        !_gestureHadMultiplePointers) {
      _dispatchSwipe(event);
    }
    _removePointer(event.pointer);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _removePointer(event.pointer);
  }

  void _removePointer(int pointer) {
    _activePointers.remove(pointer);
    if (_activePointers.isEmpty) {
      _primaryPointer = null;
      _gestureHadMultiplePointers = false;
    }
  }

  void _dispatchSwipe(PointerEvent event) {
    final delta = event.localPosition - _swipeStart;
    final elapsed = event.timeStamp - _swipeStartTime;
    final seconds = math.max(elapsed.inMicroseconds / 1000000, 0.001);
    final speed = delta.distance / seconds;
    final zoomMultiplier = _zoomed ? 1.8 : 1.0;
    final horizontalDistance = 76 * zoomMultiplier;
    final verticalDistance = 88 * zoomMultiplier;

    // A fast, deliberate one-finger swipe navigates; normal movement while
    // inspecting a zoomed figure remains a pan. Pinches are ignored entirely.
    if (_zoomed && speed < 360) return;
    if (delta.dy.abs() >= verticalDistance &&
        delta.dy.abs() >= delta.dx.abs() * 1.2) {
      widget.onVerticalSwipe?.call();
      return;
    }
    if (delta.dx.abs() >= horizontalDistance &&
        delta.dx.abs() >= delta.dy.abs() * 1.2) {
      widget.onHorizontalSwipe?.call(delta.dx < 0 ? 1 : -1);
    }
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransformChanged);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Listener(
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                transformationController: widget.expanded ? _transform : null,
                minScale: 1,
                maxScale: 4.5,
                panEnabled: widget.expanded && _zoomed,
                scaleEnabled: widget.expanded,
                child: widget.child,
              ),
              if (widget.expanded)
                Positioned(
                  right: 46,
                  bottom: 18,
                  child: _BodyMapZoomControls(
                    scale: _scale,
                    onZoomIn: () => _zoomBy(1.35, viewportSize),
                    onZoomOut: () => _zoomBy(1 / 1.35, viewportSize),
                    onReset: _resetZoom,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BodyMapZoomControls extends StatelessWidget {
  const _BodyMapZoomControls({
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final german = Localizations.localeOf(context).languageCode == 'de';
    final canZoomOut = scale > 1.001;

    Widget button({
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
      bool enabled = true,
    }) {
      return Tooltip(
        message: label,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 38,
              height: 36,
              child: Icon(
                icon,
                size: 19,
                color: enabled ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppColors.card.withValues(alpha: 0.96),
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.stroke.withValues(alpha: 0.7)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(
              icon: Icons.add_rounded,
              label: german ? 'Vergrößern' : 'Zoom in',
              onPressed: onZoomIn,
              enabled: scale < 4.49,
            ),
            Text(
              '${(scale * 100).round()}%',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            button(
              icon: Icons.remove_rounded,
              label: german ? 'Verkleinern' : 'Zoom out',
              onPressed: onZoomOut,
              enabled: canZoomOut,
            ),
            if (canZoomOut) ...[
              Container(
                width: 24,
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: AppColors.stroke,
              ),
              button(
                icon: Icons.center_focus_strong_rounded,
                label: german ? 'Ansicht zurücksetzen' : 'Reset view',
                onPressed: onReset,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrganView extends StatelessWidget {
  const _OrganView({
    required this.l10n,
    this.expanded = false,
    this.compactDashboard = false,
    this.onBackgroundTap,
    this.selectedOrgan,
    this.onOrganTap,
    this.onOrganSelectionClear,
    this.onCollapseTap,
    this.onFullscreenSwipe,
  });

  final AppLocalizations l10n;
  final bool expanded;
  final bool compactDashboard;
  final VoidCallback? onBackgroundTap;
  final Organ? selectedOrgan;
  final ValueChanged<Organ>? onOrganTap;
  final VoidCallback? onOrganSelectionClear;
  final VoidCallback? onCollapseTap;
  final ValueChanged<int>? onFullscreenSwipe;

  @override
  Widget build(BuildContext context) {
    final l10n = this.l10n;
    final statuses = <Organ, OrganStatus>{
      for (final o in Organ.values) o: OrganHealthService.displayStatus(o),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _boundedLayoutSize(constraints);
        if (size == null) return const SizedBox.expand();
        final layout = computeBodyLayout(size, reserveStage: !compactDashboard);
        final bw = layout.bounds.width;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _BodyMapInteractiveSurface(
                expanded: expanded,
                onVerticalSwipe: expanded ? onCollapseTap : null,
                onHorizontalSwipe: expanded ? onFullscreenSwipe : null,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: expanded ? onOrganSelectionClear : onBackgroundTap,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CachedBodyPaint(
                            painter: OrganMapPainter(
                              statuses: statuses,
                              selected: selectedOrgan,
                              female: ProgressStore.profileGender == 'female',
                              reserveStage: !compactDashboard,
                            ),
                          ),
                        ),
                        for (final spec in organSpecs)
                          _tapTarget(
                            center: layout.frac(spec.fx, spec.fy),
                            radius: (spec.r * bw).clamp(20.0, 60.0).toDouble(),
                            onTap: () {
                              if (!expanded) {
                                onBackgroundTap?.call();
                                return;
                              }
                              onOrganTap?.call(spec.organ);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (expanded)
              Positioned(
                right: 0,
                bottom: 4,
                child: _AfterburnHintOverlay(text: l10n.home_organsHint),
              ),
          ],
        );
      },
    );
  }
}

class _SkeletonView extends StatelessWidget {
  const _SkeletonView({
    required this.l10n,
    this.expanded = false,
    this.compactDashboard = false,
    this.onBackgroundTap,
    this.selectedJoint,
    this.onJointTap,
    this.onJointSelectionClear,
    this.onCollapseTap,
    this.onFullscreenSwipe,
  });

  final AppLocalizations l10n;
  final bool expanded;
  final bool compactDashboard;
  final VoidCallback? onBackgroundTap;
  final BodyJoint? selectedJoint;
  final ValueChanged<BodyJoint>? onJointTap;
  final VoidCallback? onJointSelectionClear;
  final VoidCallback? onCollapseTap;
  final ValueChanged<int>? onFullscreenSwipe;

  @override
  Widget build(BuildContext context) {
    final l10n = this.l10n;
    final strengthened = JointActivityService.strengthenedThisWeek();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _boundedLayoutSize(constraints);
        if (size == null) return const SizedBox.expand();
        final layout = computeBodyLayout(size, reserveStage: !compactDashboard);
        final bw = layout.bounds.width;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _BodyMapInteractiveSurface(
                expanded: expanded,
                onVerticalSwipe: expanded ? onCollapseTap : null,
                onHorizontalSwipe: expanded ? onFullscreenSwipe : null,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: expanded ? onJointSelectionClear : onBackgroundTap,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CachedBodyPaint(
                            painter: SkeletonMapPainter(
                              strengthened: strengthened,
                              selected: selectedJoint,
                              female: ProgressStore.profileGender == 'female',
                              reserveStage: !compactDashboard,
                            ),
                          ),
                        ),
                        for (final spec in jointSpecs)
                          _tapTarget(
                            center: layout.frac(spec.fx, spec.fy),
                            radius: _jointTapRadius(bw, spec.joint),
                            onTap: () {
                              if (!expanded) {
                                onBackgroundTap?.call();
                                return;
                              }
                              onJointTap?.call(spec.joint);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (expanded)
              Positioned(
                right: 0,
                bottom: 4,
                child: _AfterburnHintOverlay(text: l10n.home_skeletonHint),
              ),
          ],
        );
      },
    );
  }
}

double _jointTapRadius(double bodyWidth, BodyJoint joint) {
  final base = (bodyWidth * 0.042).clamp(12.0, 28.0);
  return switch (joint) {
    BodyJoint.elbows => base * 0.82,
    BodyJoint.wrists => base * 1.05,
    _ => base,
  };
}

Widget _tapTarget({
  required Offset center,
  required double radius,
  required VoidCallback onTap,
}) {
  return Positioned(
    left: center.dx - radius,
    top: center.dy - radius,
    width: radius * 2,
    height: radius * 2,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox.expand(),
    ),
  );
}

class _HomeHudSidePanel extends StatelessWidget {
  const _HomeHudSidePanel({
    required this.l10n,
    this.expanded = false,
    this.maxPanelWidth,
  });

  final AppLocalizations l10n;
  final bool expanded;
  final double? maxPanelWidth;

  @override
  Widget build(BuildContext context) {
    final panel = HomeActivityPanel(
      snapshot: HomeWeeklySummaryService.snapshot(l10n),
      recovery: MuscleActivityService.snapshot(),
      isGerman: l10n.localeName.startsWith('de'),
      streakDays: ProgressStore.workoutStreakDays,
      fastingCard: ProgressStore.fastingHudEnabled
          ? const HomeFastingHud()
          : null,
      onWaterTap: () => ProgressStore.addWaterGlass(),
      onWaterLongPress: () => ProgressStore.removeWaterGlass(),
    );
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Keep all five readouts visible on the normal portrait home screen.
          // On very short screens or enlarged text, preserve legibility by scrolling.
          if (constraints.maxHeight < 320 ||
              MediaQuery.textScalerOf(context).scale(10) > 13) {
            return SingleChildScrollView(child: panel);
          }
          return Align(
            alignment: Alignment.topLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: SizedBox(width: constraints.maxWidth, child: panel),
            ),
          );
        },
      ),
    );
  }
}

class _HomeIntroStartButton extends StatelessWidget {
  const _HomeIntroStartButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 148),
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.softSurface,
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: .65),
            width: 1.4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.explore_outlined, size: 18),
        label: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _MuscleFigure extends StatelessWidget {
  const _MuscleFigure({
    required this.flip,
    required this.mode,
    required this.snapshot,
    required this.l10n,
    this.compactDashboard = false,
    this.expanded = false,
    this.onExpandTap,
    this.onMuscleTap,
    this.onMuscleSelectionClear,
    this.selectedSegment,
    this.onCollapseTap,
    this.onFullscreenSwipe,
  });

  final Animation<double> flip;
  final BodyMapViewMode mode;
  final MuscleRecoverySnapshot snapshot;
  final AppLocalizations l10n;
  final bool compactDashboard;
  final bool expanded;
  final VoidCallback? onExpandTap;
  final MuscleSegmentTapCallback? onMuscleTap;
  final VoidCallback? onMuscleSelectionClear;
  final MuscleSegmentHit? selectedSegment;
  final VoidCallback? onCollapseTap;
  final ValueChanged<int>? onFullscreenSwipe;

  void _handleTap(BuildContext context, Size size, Offset pos) {
    final front = flip.value > 0.5;
    final female = ProgressStore.profileGender == 'female';
    final paths = transformedMusclePaths(size, front: front, female: female);
    final hit = findMuscleSegmentAt(
      size: size,
      pos: pos,
      front: front,
      paths: paths,
    );
    if (hit != null) {
      if (expanded) {
        final bounds = paths[hit.slug]![hit.pathIndex].getBounds();
        final renderObject = context.findRenderObject();
        final globalBounds = renderObject is RenderBox
            ? Rect.fromPoints(
                renderObject.localToGlobal(bounds.topLeft),
                renderObject.localToGlobal(bounds.bottomRight),
              )
            : bounds;
        onMuscleTap?.call(hit, size, globalBounds);
      } else {
        onExpandTap?.call();
      }
      return;
    }
    if (expanded) {
      onMuscleSelectionClear?.call();
      return;
    }
    onExpandTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _boundedLayoutSize(constraints);
        if (size == null) return const SizedBox.expand();
        final female = ProgressStore.profileGender == 'female';
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _BodyMapInteractiveSurface(
                expanded: expanded,
                onVerticalSwipe: expanded ? onCollapseTap : null,
                onHorizontalSwipe: expanded ? onFullscreenSwipe : null,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _handleTap(context, size, d.localPosition),
                  child: AnimatedBuilder(
                    animation: flip,
                    builder: (context, _) {
                      final t = flip.value;
                      final front = t >= 0.5;
                      // Fold the figure through the turn instead of
                      // cross-fading both sides. Cross-fading let the back
                      // hair and face show through the front view.
                      final scaleX = math.max(
                        0.08,
                        math.cos(math.pi * t).abs(),
                      );
                      return Transform.scale(
                        scaleX: scaleX,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: size.width,
                          height: size.height,
                          child: RepaintBoundary(
                            child: CachedBodyPaint(
                              painter: BodyMuscleMapPainter(
                                front: front,
                                mode: mode,
                                snapshot: snapshot,
                                female: female,
                                sculptedMale: _kUseSculptedMaleMannequin,
                                showStage: !compactDashboard,
                                selectedSegment: selectedSegment?.front == front
                                    ? selectedSegment
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AfterburnHintOverlay extends StatelessWidget {
  const _AfterburnHintOverlay({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: BodyHudPalette.mutedStyle().copyWith(fontSize: 10),
      ),
    );
  }
}

BodyMuscleGroup? _slugToGroup(String slug) {
  switch (slug) {
    case 'chest':
      return BodyMuscleGroup.chest;
    case 'abs':
    case 'obliques':
      return BodyMuscleGroup.abs;
    case 'biceps':
      return BodyMuscleGroup.biceps;
    case 'triceps':
      return BodyMuscleGroup.triceps;
    case 'neck':
      return BodyMuscleGroup.neck;
    case 'trapezius':
    case 'upper-back':
    case 'lower-back':
      return BodyMuscleGroup.back;
    case 'deltoids':
      return BodyMuscleGroup.shoulders;
    case 'forearm':
      return BodyMuscleGroup.forearms;
    case 'quadriceps':
    case 'adductors':
    case 'hamstring':
    case 'gluteal':
    case 'calves':
    case 'tibialis':
    case 'knees':
      return BodyMuscleGroup.legs;
    default:
      return null;
  }
}

class BodyMuscleMapPainter extends CustomPainter {
  BodyMuscleMapPainter({
    required this.front,
    required this.mode,
    required this.snapshot,
    this.selectedSegment,
    this.selectedSlugs = const {},
    this.female = false,
    this.sculptedMale = true,
    this.showStage = true,
  });

  final bool front;
  final BodyMapViewMode mode;
  final MuscleRecoverySnapshot snapshot;
  final MuscleSegmentHit? selectedSegment;
  final Set<String> selectedSlugs;

  bool _isSelected(String slug, int pathIndex) =>
      selectedSlugs.contains(slug) ||
      (selectedSegment?.slug == slug &&
          selectedSegment?.pathIndex == pathIndex);

  final bool female;
  final bool sculptedMale;
  final bool showStage;

  static const Color _recentColor = Color(0xFFE51C05);
  static const Color _almostColor = Color(0xFFFFB020);
  static const Color _lightCircuitColor = Color(0xFFD8B84E);
  static const Color _trainedColor = Color(0xFFD8B84E);
  static const Color _selectedColor = Color(0xFF3FD07A);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final useSculptedMale =
        !female && sculptedMale && useGeneratedMaleMannequin;

    if (useSculptedMale) {
      _paintMaleBackdrop(canvas, size);
    } else {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = AppColors.bodyMapBackground,
      );
    }

    final data = bodyMusclePathsForView(front: front, female: female);
    Rect? bounds;
    final parsedBySlug = <String, List<Path>>{};
    data.forEach((slug, list) {
      final paths = <Path>[];
      for (final p in list) {
        paths.add(p);
        final b = p.getBounds();
        bounds = bounds == null ? b : bounds!.expandToInclude(b);
      }
      parsedBySlug[slug] = paths;
    });
    if (!female && sculptedMale && useGeneratedMaleMannequin) {
      bounds = bodyMuscleBounds(front: front);
    }
    if (bounds == null) return;

    final t = bodyFitTransform(size, bounds!, reserveStage: showStage);
    final matrix =
        (Matrix4.identity()
              ..translateByDouble(t.dx, t.dy, 0, 1)
              ..scaleByDouble(t.scale, t.scale, 1, 1))
            .storage;

    if (showStage && !useSculptedMale) {
      _paintStage(canvas, size, female: female);
    }

    final bodyWidth = computeBodyLayout(
      size,
      female: female,
      reserveStage: showStage,
    ).bounds.width;
    final isLight =
        !useSculptedMale &&
        AppColors.bodyMapBackground.computeLuminance() > 0.5;
    final afterburnColor = AppColors.bodyMapBackground.computeLuminance() > 0.5
        ? const Color(0xFF0074C9)
        : const Color(0xFF45CFFF);
    final edgeWidth = (bodyWidth * 0.012).clamp(1.4, 2.5).toDouble();
    final afterburnHalo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = edgeWidth + 3
      ..color = afterburnColor.withValues(alpha: 0.78)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    final afterburnEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = edgeWidth
      ..color = afterburnColor;

    // Theme-aware skin palette.
    final skinLight = useSculptedMale
        ? const Color(0xFFF9FAF3)
        : isLight
        ? const Color(0xFFD4D9E4)
        : const Color(0xFF545F72);
    final skinMid = useSculptedMale
        ? const Color(0xFFD8DED4)
        : isLight
        ? const Color(0xFFBCC2CE)
        : const Color(0xFF35404F);
    final skinDark = useSculptedMale
        ? const Color(0xFF9EAA9F)
        : isLight
        ? const Color(0xFF9EA6B6)
        : const Color(0xFF1C2636);
    final rimColor = useSculptedMale
        ? const Color(0xFFFAFFF5)
        : isLight
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF8A9BB5);
    final outline = useSculptedMale
        ? const Color(0xFF27362E)
        : isLight
        ? const Color(0xFF8892A4)
        : const Color(0xFF0A1020);
    final aoAlpha = useSculptedMale
        ? (isLight ? 0.10 : 0.26)
        : female
        ? (isLight ? 0.09 : 0.28)
        : (isLight ? 0.18 : 0.50);
    final shadAlpha = useSculptedMale
        ? (isLight ? 0.16 : 0.40)
        : female
        ? (isLight ? 0.13 : 0.34)
        : (isLight ? 0.22 : 0.60);

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = female ? 0.58 : (useSculptedMale ? 1.3 : 0.85)
      ..strokeJoin = StrokeJoin.round
      ..color = female
          ? outline.withValues(alpha: isLight ? 0.42 : 0.58)
          : useSculptedMale
          ? outline.withValues(alpha: 0.98)
          : outline;

    if (female) {
      final silhouette = bodyMuscleSilhouette(
        front: front,
        female: true,
      ).transform(matrix);
      final silhouetteBounds = silhouette.getBounds();
      canvas.drawPath(
        silhouette,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [skinLight, skinMid],
          ).createShader(silhouetteBounds),
      );
      canvas.drawPath(silhouette, outlinePaint);
    } else if (useSculptedMale) {
      // A continuous, softly lit hull gives the individual SVG regions a
      // coherent body volume while preserving their separate hit targets.
      final silhouette = bodyMuscleSilhouette(
        front: front,
        female: false,
      ).transform(matrix);
      final silhouetteBounds = silhouette.getBounds();
      canvas.drawPath(
        silhouette.shift(Offset(bodyWidth * 0.018, bodyWidth * 0.026)),
        Paint()
          ..color = Colors.black.withValues(alpha: isLight ? 0.12 : 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13),
      );
      canvas.drawPath(
        silhouette,
        Paint()
          // Keep the whole figure in a light ivory range. The former radial
          // gradient darkened the lower legs almost to charcoal at small
          // display sizes and hid their muscle shapes.
          ..shader = RadialGradient(
            center: const Alignment(-0.28, -0.42),
            radius: 1.22,
            colors: [skinLight, skinMid, skinDark],
            stops: const [0.0, 0.56, 1.0],
          ).createShader(silhouetteBounds),
      );
      canvas.drawPath(silhouette, outlinePaint);
      canvas.drawPath(
        silhouette.shift(const Offset(-1.0, -1.2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = rimColor.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
      );
    }

    parsedBySlug.forEach((slug, paths) {
      final group = _slugToGroup(slug);
      final highlight = group != null ? _highlightColor(group) : null;
      final afterburnActive =
          group != null &&
          mode == BodyMapViewMode.recovery &&
          (snapshot.afterburn[group]?.active ?? false);

      for (var pathIndex = 0; pathIndex < paths.length; pathIndex++) {
        final raw = paths[pathIndex];
        final p = raw.transform(matrix);
        final isSelected = _isSelected(slug, pathIndex);

        final pb = p.getBounds();
        if (pb.isEmpty) continue;

        if (useSculptedMale) {
          final fillColor = isSelected ? _selectedColor : highlight;
          final lightColor = fillColor == null
              ? skinLight
              : Color.lerp(fillColor, Colors.white, 0.38)!;
          final midColor = fillColor ?? skinMid;
          final darkColor = fillColor == null
              ? skinDark
              : Color.lerp(fillColor, Colors.black, 0.30)!;
          canvas.drawPath(
            p,
            Paint()
              ..shader = RadialGradient(
                center: const Alignment(-0.48, -0.68),
                radius: 1.2,
                colors: [lightColor, midColor, darkColor],
                stops: const [0.0, 0.54, 1.0],
              ).createShader(pb),
          );
          continue;
        }

        // Depth scales with the muscle's own size so big muscles bulge more
        // than small ones, but stays bounded by the overall figure size.
        final relief = female ? 0.105 : (useSculptedMale ? 0.19 : 0.17);
        final depth = (math.min(pb.width, pb.height) * relief).clamp(
          1.2,
          math.max(1.2, bodyWidth * (female ? 0.03 : 0.045)),
        );

        if (highlight != null && !isSelected) {
          canvas.drawPath(
            p,
            Paint()
              ..color = highlight.withValues(alpha: 0.50)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
          );
        }

        if (isSelected) {
          canvas.drawPath(
            p,
            Paint()
              ..color = _selectedColor.withValues(alpha: 0.50)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
          );
        }

        // ── Ambient occlusion: lifts each muscle off its neighbours ──
        canvas.drawPath(
          p,
          Paint()
            ..color = Colors.black.withValues(alpha: aoAlpha)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, depth * 0.85),
        );

        // ── Base fill: per-path radial gradient, light from the top-left ──
        final Color cLight;
        final Color cMid;
        final Color cDark;
        if (slug == 'hair') {
          cLight = pathIndex == 0
              ? const Color(0xFF302B2D)
              : const Color(0xFF55494A);
          cMid = pathIndex == 0
              ? const Color(0xFF121318)
              : const Color(0xFF272226);
          cDark = const Color(0xFF030405);
        } else if (isSelected) {
          cLight = Color.lerp(_selectedColor, Colors.white, 0.40)!;
          cMid = _selectedColor;
          cDark = Color.lerp(_selectedColor, Colors.black, 0.62)!;
        } else if (highlight != null) {
          cLight = Color.lerp(highlight, Colors.white, 0.38)!;
          cMid = highlight;
          cDark = Color.lerp(highlight, Colors.black, 0.65)!;
        } else if (useSculptedMale && (slug == 'forearm' || slug == 'hands')) {
          cLight = const Color(0xFFC6D0C8);
          cMid = const Color(0xFF8B9790);
          cDark = const Color(0xFF4B5750);
        } else {
          cLight = skinLight;
          cMid = skinMid;
          cDark = skinDark;
        }

        canvas.drawPath(
          p,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.5, -0.7),
              radius: 1.25,
              colors: [cLight, cMid, cDark],
              stops: const [0.0, 0.45, 1.0],
            ).createShader(pb),
        );

        // ── Inner shading: dark on the bottom-right, rim light top-left ──
        canvas.save();
        canvas.clipPath(p, doAntiAlias: false);
        canvas.drawPath(
          p.shift(Offset(depth * 0.55, depth * 0.70)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = depth * 1.5
            ..color = Colors.black.withValues(alpha: shadAlpha)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, depth * 0.85),
        );
        canvas.drawPath(
          p.shift(Offset(-depth * 0.45, -depth * 0.55)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = depth * 0.95
            ..color = rimColor.withValues(alpha: isSelected ? 0.30 : 0.42)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, depth * 0.6),
        );
        canvas.restore();

        canvas.drawPath(p, outlinePaint);

        if (afterburnActive && !isSelected) {
          canvas.drawPath(p, afterburnHalo);
          canvas.drawPath(p, afterburnEdge);
        }

        if (isSelected) {
          canvas.drawPath(
            p,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.0
              ..color = _selectedColor.withValues(alpha: 0.65)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
          canvas.drawPath(
            p,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0
              ..color = _selectedColor,
          );
        }
      }
    });

    if (useSculptedMale) {
      final muscleLine = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, bodyWidth * 0.0075)
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF25352C).withValues(alpha: 0.94);

      parsedBySlug.forEach((slug, paths) {
        final group = _slugToGroup(slug);
        final afterburnActive =
            group != null &&
            mode == BodyMapViewMode.recovery &&
            (snapshot.afterburn[group]?.active ?? false);
        for (var pathIndex = 0; pathIndex < paths.length; pathIndex++) {
          final path = paths[pathIndex].transform(matrix);
          if (path.getBounds().isEmpty) continue;
          canvas.drawPath(path, muscleLine);

          final isSelected = _isSelected(slug, pathIndex);
          if (afterburnActive && !isSelected) {
            canvas.drawPath(path, afterburnHalo);
            canvas.drawPath(path, afterburnEdge);
          }
          if (isSelected) {
            canvas.drawPath(
              path,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.3
                ..color = _selectedColor,
            );
          }
        }
      });

      final silhouette = bodyMuscleSilhouette(
        front: front,
        female: false,
      ).transform(matrix);
      canvas.drawPath(silhouette, outlinePaint);
    }

    // Joint dots only in skeleton view, heart only in organ view.
    if (mode == BodyMapViewMode.skeleton) _paintJointNodes(canvas, size);
    if (mode == BodyMapViewMode.organs && front) _paintHeartGlow(canvas, size);
  }

  void _paintMaleBackdrop(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.08, -0.18),
          radius: 1.18,
          colors: [Color(0xFF17221B), Color(0xFF0B130E), Color(0xFF060C08)],
          stops: [0.0, 0.64, 1.0],
        ).createShader(bounds),
    );

    final body = computeBodyLayout(size, reserveStage: showStage).bounds;
    if (body.isEmpty) return;
    final center = Offset(body.center.dx, body.top + body.height * 0.59);
    final radiusY = body.height * 0.44;
    final radiusX = math.max(body.width * 0.92, radiusY * 0.92);
    for (final scale in const [0.94, 1.22]) {
      final ring = Rect.fromCenter(
        center: center,
        width: radiusX * 2 * scale,
        height: radiusY * 2 * scale,
      );
      canvas.drawOval(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..color = const Color(0xFF9AA56A).withValues(alpha: 0.055)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawOval(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = const Color(0xFF8C995A).withValues(alpha: 0.48),
      );
    }
  }

  void _paintStage(Canvas canvas, Size size, {bool female = false}) {
    final layout = computeBodyLayout(size, female: female);
    final center = Offset(layout.bounds.center.dx, layout.bounds.bottom - 4);
    final w = layout.bounds.width * 1.2;
    final h = layout.bounds.width * 0.30;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: w * 1.15, height: h * 1.4),
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    for (var i = 1; i <= 4; i++) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: w * i / 4, height: h * i / 4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 4 ? 1.2 : 0.7
          ..color = AppColors.primary.withValues(alpha: i == 4 ? 0.28 : 0.12),
      );
    }

    canvas.drawLine(
      Offset(center.dx - w * 0.42, center.dy),
      Offset(center.dx + w * 0.42, center.dy),
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.10)
        ..strokeWidth = 0.7,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - h * 0.42),
      Offset(center.dx, center.dy + h * 0.42),
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.10)
        ..strokeWidth = 0.7,
    );
  }

  static const _nodeJoints = {
    BodyJoint.shoulders,
    BodyJoint.elbows,
    BodyJoint.wrists,
    BodyJoint.knees,
    BodyJoint.ankles,
  };

  void _paintJointNodes(Canvas canvas, Size size) {
    final layout = computeBodyLayout(size);
    final r = math.max(2.6, layout.bounds.width * 0.018);
    const glow = Color(0xFFCCFF00);
    for (final spec in jointSpecs) {
      if (!_nodeJoints.contains(spec.joint)) continue;
      final c = layout.frac(spec.fx, spec.fy);
      canvas.drawCircle(
        c,
        r * 2.4,
        Paint()
          ..color = glow.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(c, r, Paint()..color = glow);
      canvas.drawCircle(c, r * 0.38, Paint()..color = const Color(0xFFF7FFE0));
    }
  }

  void _paintHeartGlow(Canvas canvas, Size size) {
    final layout = computeBodyLayout(size);
    final c = layout.frac(0.455, 0.265);
    final r = layout.bounds.width * 0.045;
    const glow = Color(0xFFCCFF00);
    canvas.drawCircle(
      c,
      r * 2.2,
      Paint()
        ..color = glow.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    final path = Path()
      ..moveTo(c.dx, c.dy + r * 0.85)
      ..cubicTo(
        c.dx - r * 1.35,
        c.dy - r * 0.15,
        c.dx - r * 0.65,
        c.dy - r * 1.05,
        c.dx,
        c.dy - r * 0.28,
      )
      ..cubicTo(
        c.dx + r * 0.65,
        c.dy - r * 1.05,
        c.dx + r * 1.35,
        c.dy - r * 0.15,
        c.dx,
        c.dy + r * 0.85,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = glow);
  }

  Color? _highlightColor(BodyMuscleGroup group) {
    return switch (mode) {
      BodyMapViewMode.recovery => _recoveryColor(group),
      BodyMapViewMode.trained =>
        snapshot.trainedThisWeek.contains(group) ? _trainedColor : null,
      BodyMapViewMode.afterburn => null,
      BodyMapViewMode.organs => null,
      BodyMapViewMode.skeleton => null,
      BodyMapViewMode.connective => null,
    };
  }

  Color? _recoveryColor(BodyMuscleGroup group) {
    final state = snapshot.recovery[group] ?? MuscleRecoveryHighlight.none;
    return switch (state) {
      MuscleRecoveryHighlight.recent => _recentColor,
      MuscleRecoveryHighlight.almostReady => _almostColor,
      MuscleRecoveryHighlight.lightCircuit => _lightCircuitColor,
      MuscleRecoveryHighlight.none => null,
    };
  }

  @override
  bool shouldRepaint(covariant BodyMuscleMapPainter oldDelegate) {
    return oldDelegate.front != front ||
        oldDelegate.mode != mode ||
        oldDelegate.selectedSegment != selectedSegment ||
        oldDelegate.selectedSlugs != selectedSlugs ||
        oldDelegate.female != female ||
        oldDelegate.sculptedMale != sculptedMale ||
        BodyMuscleGroup.values.any(
          (group) =>
              oldDelegate._highlightColor(group) != _highlightColor(group) ||
              (mode == BodyMapViewMode.recovery &&
                  (oldDelegate.snapshot.afterburn[group]?.active ?? false) !=
                      (snapshot.afterburn[group]?.active ?? false)),
        );
  }
}

// ─── Organ / joint detail popups ────────────────────────────────────────────

bool _isGerman(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'de';

class _Copy {
  const _Copy(this.en, this.de);
  final String en;
  final String de;
  String of(BuildContext c) => _isGerman(c) ? de : en;
}

const Map<Organ, ({_Copy name, _Copy function, _Copy food})> _organCopy = {
  Organ.brain: (
    name: _Copy('Brain', 'Gehirn'),
    function: _Copy(
      'Controls thoughts, memory and movement. Needs steady energy and healthy fats.',
      'Steuert Gedanken, Gedächtnis und Bewegung. Braucht gleichmäßige Energie und gesunde Fette.',
    ),
    food: _Copy(
      'Omega-3 (salmon, walnuts), berries, leafy greens and olive oil support focus and memory.',
      'Omega-3 (Lachs, Walnüsse), Beeren, grünes Blattgemüse und Olivenöl fördern Konzentration und Gedächtnis.',
    ),
  ),
  Organ.heart: (
    name: _Copy('Heart', 'Herz'),
    function: _Copy(
      'Pumps blood through your body. Loves healthy fats, dislikes sugar and trans fats.',
      'Pumpt Blut durch den Körper. Mag gesunde Fette, nicht Zucker und Transfette.',
    ),
    food: _Copy(
      'Omega-3 fish, olive oil, nuts and fibre-rich foods keep your heart strong.',
      'Omega-3-Fisch, Olivenöl, Nüsse und ballaststoffreiche Lebensmittel halten dein Herz stark.',
    ),
  ),
  Organ.lungs: (
    name: _Copy('Lungs', 'Lunge'),
    function: _Copy(
      'Bring oxygen into the blood. Antioxidants protect lung tissue.',
      'Bringt Sauerstoff ins Blut. Antioxidantien schützen das Lungengewebe.',
    ),
    food: _Copy(
      'Colourful vegetables, berries and vitamin-C rich foods support your lungs.',
      'Buntes Gemüse, Beeren und Vitamin-C-reiche Lebensmittel unterstützen die Lunge.',
    ),
  ),
  Organ.liver: (
    name: _Copy('Liver', 'Leber'),
    function: _Copy(
      'Detoxifies the body and processes nutrients. Alcohol and sugar strain it most.',
      'Entgiftet den Körper und verarbeitet Nährstoffe. Alkohol und Zucker belasten sie am meisten.',
    ),
    food: _Copy(
      'Leafy greens, antioxidants and fibre help the liver detox — avoid alcohol.',
      'Grünes Blattgemüse, Antioxidantien und Ballaststoffe helfen beim Entgiften — Alkohol meiden.',
    ),
  ),
  Organ.stomach: (
    name: _Copy('Stomach', 'Magen'),
    function: _Copy(
      'Breaks down food. Likes gentle, fibre-rich and fermented foods.',
      'Zerlegt die Nahrung. Mag schonende, ballaststoffreiche und fermentierte Lebensmittel.',
    ),
    food: _Copy(
      'Fibre and probiotics (yoghurt, sauerkraut) support healthy digestion.',
      'Ballaststoffe und Probiotika (Joghurt, Sauerkraut) unterstützen die Verdauung.',
    ),
  ),
  Organ.intestines: (
    name: _Copy('Intestines', 'Darm'),
    function: _Copy(
      'Absorb nutrients and host your gut microbiome.',
      'Nimmt Nährstoffe auf und beherbergt deine Darmflora.',
    ),
    food: _Copy(
      'Fibre, probiotics and plenty of water keep your gut flora balanced.',
      'Ballaststoffe, Probiotika und viel Wasser halten die Darmflora im Gleichgewicht.',
    ),
  ),
  Organ.kidneys: (
    name: _Copy('Kidneys', 'Nieren'),
    function: _Copy(
      'Filter waste and balance fluids and salt.',
      'Filtern Abfallstoffe und regulieren Flüssigkeit und Salz.',
    ),
    food: _Copy(
      'Stay hydrated and favour fresh, low-salt foods; limit processed food and alcohol.',
      'Viel trinken und frische, salzarme Lebensmittel bevorzugen; verarbeitete Kost und Alkohol begrenzen.',
    ),
  ),
};

const Map<BodyJoint, ({_Copy name, _Copy hint})> _jointCopy = {
  BodyJoint.neck: (
    name: _Copy('Neck', 'Nacken'),
    hint: _Copy(
      'Neck curls and chin tucks strengthen the neck.',
      'Nacken-Curls und Chin-Tucks stärken den Nacken.',
    ),
  ),
  BodyJoint.shoulders: (
    name: _Copy('Shoulders', 'Schultern'),
    hint: _Copy(
      'Presses, pike and handstand work build shoulder stability.',
      'Drücken, Pike und Handstand stärken die Schulterstabilität.',
    ),
  ),
  BodyJoint.elbows: (
    name: _Copy('Elbows', 'Ellbogen'),
    hint: _Copy(
      'Curls, dips and push-ups strengthen the elbow tendons.',
      'Curls, Dips und Liegestütze stärken die Ellbogensehnen.',
    ),
  ),
  BodyJoint.wrists: (
    name: _Copy('Wrists', 'Handgelenke'),
    hint: _Copy(
      'Push-ups, planks and grip work strengthen the wrists.',
      'Liegestütze, Planks und Grifftraining stärken die Handgelenke.',
    ),
  ),
  BodyJoint.spine: (
    name: _Copy('Spine', 'Wirbelsäule'),
    hint: _Copy(
      'Deadlifts, back extensions and reverse planks support the spine.',
      'Kreuzheben, Rückenstrecker und Reverse Planks stützen die Wirbelsäule.',
    ),
  ),
  BodyJoint.hips: (
    name: _Copy('Hips', 'Hüfte'),
    hint: _Copy(
      'Squats, lunges and glute bridges strengthen the hips.',
      'Kniebeugen, Ausfallschritte und Glute Bridges stärken die Hüfte.',
    ),
  ),
  BodyJoint.knees: (
    name: _Copy('Knees', 'Knie'),
    hint: _Copy(
      'Squats, step-ups and lunges build strong knees.',
      'Kniebeugen, Step-Ups und Ausfallschritte bauen starke Knie auf.',
    ),
  ),
  BodyJoint.shins: (
    name: _Copy('Shins', 'Schienbeine'),
    hint: _Copy(
      'Tibialis raises protect against shin splints.',
      'Tibialis-Raises beugen dem Schienbeinkantensyndrom vor.',
    ),
  ),
  BodyJoint.ankles: (
    name: _Copy('Ankles', 'Knöchel'),
    hint: _Copy(
      'Calf raises and balance work strengthen the ankles.',
      'Wadenheben und Balanceübungen stärken die Knöchel.',
    ),
  ),
};

String _organStatusLabel(AppLocalizations l10n, OrganStatus status) {
  return switch (status) {
    OrganStatus.good => l10n.home_organStatusGood,
    OrganStatus.mixed => l10n.home_organStatusMixed,
    OrganStatus.careful => l10n.home_organStatusCareful,
    OrganStatus.noData => l10n.home_organStatusNoData,
  };
}

List<Widget> _buildOrganDetailSections(
  BuildContext context,
  Organ organ, {
  bool large = false,
}) {
  final l10n = context.l10n;
  final copy = _organCopy[organ]!;
  final analysis = OrganHealthService.analyze(organ);
  final display = OrganHealthService.displayStatus(organ);
  final activeGlow = OrganHealthService.isGreenGlowActive(organ);
  final recentGoodFoods = OrganHealthService.helpfulFoodsLast24h(organ);
  final status = statusColor(display);
  final lineStyle = BodyHudPalette.bodyStyle(
    large: large,
  ).copyWith(height: 1.45);
  final labelStyle = lineStyle.copyWith(
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
  );

  return [
    OrganGuidancePanel(organId: organ.name, prioritizeActions: true),
    const SizedBox(height: 12),
    Text(
      activeGlow
          ? l10n.home_organStatusGoodActive
          : _organStatusLabel(l10n, display),
      textAlign: TextAlign.center,
      style: lineStyle.copyWith(color: status),
    ),
    const SizedBox(height: 8),
    Text(
      copy.function.of(context),
      textAlign: TextAlign.center,
      style: lineStyle,
    ),
    const SizedBox(height: 8),
    Text(
      l10n.home_organRecommended,
      textAlign: TextAlign.center,
      style: labelStyle,
    ),
    const SizedBox(height: 3),
    Text(copy.food.of(context), textAlign: TextAlign.center, style: lineStyle),
    if (recentGoodFoods.isNotEmpty) ...[
      const SizedBox(height: 8),
      Text(
        l10n.home_organGoodFoods24h,
        textAlign: TextAlign.center,
        style: labelStyle,
      ),
      const SizedBox(height: 3),
      Text(
        recentGoodFoods.join(', '),
        textAlign: TextAlign.center,
        style: lineStyle.copyWith(color: statusColor(OrganStatus.good)),
      ),
    ],
    if (analysis.goodFoods.isNotEmpty) ...[
      const SizedBox(height: 8),
      Text(
        l10n.home_organGoodFoods,
        textAlign: TextAlign.center,
        style: labelStyle,
      ),
      const SizedBox(height: 3),
      Text(
        analysis.goodFoods.join(', '),
        textAlign: TextAlign.center,
        style: lineStyle.copyWith(color: const Color(0xFF3FD07A)),
      ),
    ],
    if (analysis.badFoods.isNotEmpty) ...[
      const SizedBox(height: 8),
      Text(
        l10n.home_organBadFoods,
        textAlign: TextAlign.center,
        style: labelStyle,
      ),
      const SizedBox(height: 3),
      Text(
        analysis.badFoods.join(', '),
        textAlign: TextAlign.center,
        style: lineStyle.copyWith(color: const Color(0xFFFF453A)),
      ),
    ],
  ];
}

List<Widget> _buildJointDetailSections(
  BuildContext context,
  BodyJoint joint,
  bool strengthened, {
  bool large = false,
}) {
  final l10n = context.l10n;
  final copy = _jointCopy[joint]!;
  final color = strengthened ? const Color(0xFF3FD07A) : AppColors.textMuted;
  final lineStyle = BodyHudPalette.bodyStyle(
    large: large,
  ).copyWith(height: 1.45);

  return [
    Text(
      strengthened
          ? l10n.home_jointTrainedThisWeek
          : l10n.home_jointNotTrainedThisWeek,
      textAlign: TextAlign.center,
      style: lineStyle.copyWith(color: color),
    ),
    const SizedBox(height: 8),
    Text(copy.hint.of(context), textAlign: TextAlign.center, style: lineStyle),
  ];
}

Widget _expandedHudDetailTitle(
  String title,
  Color accent, {
  bool large = false,
}) {
  final titleStyle = BodyHudPalette.titleStyle(
    accent: accent,
    large: large,
  ).copyWith(fontStyle: FontStyle.normal, letterSpacing: 0);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(title, textAlign: TextAlign.center, style: titleStyle),
      Container(
        margin: EdgeInsets.only(top: large ? 8 : 6, bottom: large ? 10 : 8),
        width: large ? 40 : 28,
        height: large ? 4 : 3,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ],
  );
}

class _ExpandedBodyDetailCard extends StatelessWidget {
  const _ExpandedBodyDetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: AppColors.surfaceDecoration(
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      ),
    );
  }
}

const _kFigurePhaseEnd = 0.42;
const _kBackgroundPhaseStart = 0.34;
const _kBackgroundPhaseEnd = 0.72;
const _kChromePhaseStart = 0.64;

double _expansionPhaseT(double t, double start, double end) {
  if (t <= start) return 0;
  if (t >= end) return 1;
  return (t - start) / (end - start);
}

/// Phase 1: mannequin grows from compact slot to fullscreen.
double _expansionFigureT(double t) =>
    Curves.easeOutCubic.transform(_expansionPhaseT(t, 0, _kFigurePhaseEnd));

/// Phase 2: solid app background fades in behind the figure.
double _expansionBackgroundT(double t) => Curves.easeInOutCubic.transform(
  _expansionPhaseT(t, _kBackgroundPhaseStart, _kBackgroundPhaseEnd),
);

/// Phase 3: header, tabs and HUD panels appear.
double _expansionChromeT(double t) =>
    Curves.easeOutCubic.transform(_expansionPhaseT(t, _kChromePhaseStart, 1));

class _ChromeCurve extends Curve {
  @override
  double transformInternal(double t) => _expansionChromeT(t);
}

class _BodyMapExpansionOverlay extends StatefulWidget {
  const _BodyMapExpansionOverlay({
    required this.originRect,
    this.flightImage,
    this.flightClosing = false,
    required this.expandController,
    required this.expandAnimation,
    required this.enableVerticalDragToDismiss,
    required this.enableHorizontalDragNavigation,
    required this.onDismiss,
    required this.onHorizontalSwipe,
    required this.childBuilder,
  });

  final Rect originRect;
  final ui.Image? flightImage;
  final bool flightClosing;
  final AnimationController expandController;
  final Animation<double> expandAnimation;
  final bool enableVerticalDragToDismiss;
  final bool enableHorizontalDragNavigation;
  final Future<void> Function() onDismiss;
  final ValueChanged<int> onHorizontalSwipe;
  final WidgetBuilder childBuilder;

  @override
  State<_BodyMapExpansionOverlay> createState() =>
      _BodyMapExpansionOverlayState();
}

class _BodyMapExpansionOverlayState extends State<_BodyMapExpansionOverlay> {
  static const _collapseThreshold = 0.62;
  static const _dismissVelocity = 280.0;

  var _dragging = false;
  var _dragStartValue = 1.0;
  var _dragOffset = Offset.zero;

  double get _displayT =>
      _dragging ? widget.expandController.value : widget.expandAnimation.value;

  void _onVerticalDragStart(DragStartDetails details) {
    if (widget.expandController.isAnimating) return;
    _dragging = true;
    _dragStartValue = widget.expandController.value;
    _dragOffset = Offset.zero;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_dragging || widget.expandController.isAnimating) return;
    _dragOffset += details.delta;
    final screenSize = MediaQuery.sizeOf(context);
    final collapseDistance = screenSize.shortestSide * 0.32;
    final collapseProgress = _dragOffset.dy.abs() / collapseDistance;
    widget.expandController.value = (_dragStartValue - collapseProgress).clamp(
      0.0,
      1.0,
    );
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    if (widget.expandController.isAnimating) return;
    final velocity = details.velocity.pixelsPerSecond.dy.abs();
    if (widget.expandController.value < _collapseThreshold ||
        velocity > _dismissVelocity) {
      widget.onDismiss();
      return;
    }
    widget.expandController.forward();
  }

  void _onVerticalDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    if (!widget.expandController.isAnimating) widget.expandController.forward();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 100) return;
    widget.onHorizontalSwipe(velocity < 0 ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.expandController,
        widget.expandAnimation,
      ]),
      child: widget.childBuilder(context),
      builder: (context, child) {
        final t = _displayT;
        final closing =
            widget.expandController.status == AnimationStatus.reverse;
        final figureT = closing ? t : _expansionFigureT(t);
        final backgroundT = closing ? t : _expansionBackgroundT(t);
        final media = MediaQuery.of(context);
        final safeTop = media.padding.top;
        final safeBottom = media.padding.bottom;
        final screen = media.size;
        final target = Rect.fromLTWH(
          0,
          safeTop,
          screen.width,
          screen.height - safeTop - safeBottom,
        );
        final image = widget.flightImage;
        if (image != null) {
          // A plain Flutter image handles every animated frame. The native
          // surface is attached once at its final size behind it, so neither
          // WebView resizing nor GLB loading can stall the visible flight.
          Rect imageRect(Rect bounds) {
            final fitted = applyBoxFit(
              BoxFit.contain,
              Size(image.width.toDouble(), image.height.toDouble()),
              bounds.size,
            ).destination;
            return Alignment.center.inscribe(fitted, bounds);
          }

          final rect = Rect.lerp(
            imageRect(widget.originRect),
            imageRect(target),
            t,
          )!;
          final liveOpacity = widget.flightClosing
              ? 0.0
              : ((t - .84) / .16).clamp(0.0, 1.0);
          final flightOpacity = widget.flightClosing
              ? (t / .10).clamp(0.0, 1.0)
              : 1 - liveOpacity;
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) widget.onDismiss();
            },
            child: Material(
              color: Colors.transparent,
              child: AbsorbPointer(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: AppColors.background.withValues(alpha: t),
                      ),
                    ),
                    Positioned.fromRect(
                      rect: target,
                      child: Opacity(opacity: liveOpacity, child: child),
                    ),
                    Positioned.fromRect(
                      rect: rect,
                      child: Opacity(
                        opacity: flightOpacity,
                        child: RawImage(
                          key: const ValueKey('anatomy-transition-frame'),
                          image: image,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final radius = ui.lerpDouble(20, 0, figureT)!;
        final shellBackgroundAlpha = backgroundT;

        // A single uniform scale factor — never separate x/y factors — so the
        // mannequin grows proportionally instead of being squeezed into the
        // origin card's aspect ratio and then stretched back out. The card's
        // shorter-side coverage sets the starting size; growing is anchored
        // on the card's on-screen center so it visually expands from where
        // it was tapped.
        final startScale = target.width <= 0 || target.height <= 0
            ? 1.0
            : math
                  .min(
                    widget.originRect.width / target.width,
                    widget.originRect.height / target.height,
                  )
                  .clamp(0.05, 1.0);
        final scale = ui.lerpDouble(startScale, 1.0, figureT)!;
        final anchorX = target.width <= 0
            ? 0.0
            : (((widget.originRect.center.dx - target.left) / target.width) *
                          2 -
                      1)
                  .clamp(-1.0, 1.0);
        final anchorY = target.height <= 0
            ? 0.0
            : (((widget.originRect.center.dy - target.top) / target.height) *
                          2 -
                      1)
                  .clamp(-1.0, 1.0);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && t > 0.85) widget.onDismiss();
          },
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: widget.enableHorizontalDragNavigation
                  ? _onHorizontalDragEnd
                  : null,
              onVerticalDragStart: widget.enableVerticalDragToDismiss
                  ? _onVerticalDragStart
                  : null,
              onVerticalDragUpdate: widget.enableVerticalDragToDismiss
                  ? _onVerticalDragUpdate
                  : null,
              onVerticalDragEnd: widget.enableVerticalDragToDismiss
                  ? _onVerticalDragEnd
                  : null,
              onVerticalDragCancel: widget.enableVerticalDragToDismiss
                  ? _onVerticalDragCancel
                  : null,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: AppColors.background.withValues(
                        alpha: backgroundT,
                      ),
                    ),
                  ),
                  // Keep layout and the cached body image at fullscreen size;
                  // only the outer transform changes during the transition.
                  Positioned.fromRect(
                    rect: target,
                    child: Transform(
                      alignment: Alignment(anchorX, anchorY),
                      transform: Matrix4.identity()
                        ..scaleByDouble(scale, scale, 1, 1),
                      child: RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(radius),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(
                                alpha: shellBackgroundAlpha,
                              ),
                              borderRadius: BorderRadius.circular(radius),
                              boxShadow: [
                                if (figureT > 0.05 && backgroundT < 0.95)
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.1 * figureT * (1 - backgroundT),
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                              ],
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrganDetailOverlay extends StatelessWidget {
  const _OrganDetailOverlay({required this.organ, this.large = false});

  final Organ organ;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final copy = _organCopy[organ]!;
    final accent = AppColors.primary;
    final maxHeight = MediaQuery.sizeOf(context).height * (large ? 0.62 : 0.58);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _expandedHudDetailTitle(
              copy.name.of(context),
              accent,
              large: large,
            ),
            ..._buildOrganDetailSections(context, organ, large: large),
          ],
        ),
      ),
    );
  }
}

class _JointDetailOverlay extends StatelessWidget {
  const _JointDetailOverlay({
    required this.joint,
    required this.strengthened,
    this.large = false,
  });

  final BodyJoint joint;
  final bool strengthened;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final copy = _jointCopy[joint]!;
    final accent = AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _expandedHudDetailTitle(copy.name.of(context), accent, large: large),
        ..._buildJointDetailSections(
          context,
          joint,
          strengthened,
          large: large,
        ),
      ],
    );
  }
}

class _BodyMapSidebar extends StatelessWidget {
  const _BodyMapSidebar({
    required this.mode,
    required this.onInfoTap,
    required this.onModeTap,
    this.showInfo = true,
    this.expanded = false,
    this.onToggleView,
    this.recoveryLabel = 'Recovery',
    this.organsLabel = 'Organs',
    this.skeletonLabel = 'Joints',
    this.connectiveLabel = 'Tendons & ligaments',
  });

  final BodyMapViewMode mode;
  final VoidCallback onInfoTap;
  final ValueChanged<BodyMapViewMode> onModeTap;

  final bool showInfo;
  final bool expanded;
  final VoidCallback? onToggleView;
  final String recoveryLabel;
  final String organsLabel;
  final String skeletonLabel;
  final String connectiveLabel;

  /// A mode-icon button; the label is shown as a title above the mannequin
  /// instead of inline, but stays available to screen readers here.
  Widget _modeRow({required BodyMapViewMode forMode, required String label}) {
    final active = mode == forMode;
    return Semantics(
      label: label,
      button: true,
      selected: active,
      excludeSemantics: true,
      onTap: () => onModeTap(forMode),
      child: _SidebarIcon(
        anatomyMode: forMode,
        label: label,
        onTap: () => onModeTap(forMode),
        active: active,
        touchSize: expanded ? 44 : 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mode icons with slide-in labels grouped at the bottom
        _modeRow(forMode: BodyMapViewMode.recovery, label: recoveryLabel),
        const SizedBox(height: 6),
        _modeRow(forMode: BodyMapViewMode.skeleton, label: skeletonLabel),
        const SizedBox(height: 6),
        _modeRow(forMode: BodyMapViewMode.connective, label: connectiveLabel),
        const SizedBox(height: 6),
        _modeRow(forMode: BodyMapViewMode.organs, label: organsLabel),
        if (showInfo || onToggleView != null)
          SizedBox(height: expanded ? 22 : 14),
        if (onToggleView != null) ...[
          _SidebarIcon(
            icon: Icons.flip_rounded,
            label: context.l10n.localeName.startsWith('de')
                ? 'Vorder- und Rückseite wechseln'
                : 'Switch front and back',
            onTap: onToggleView!,
            active: false,
            flat: true,
            outlined: expanded,
            touchSize: expanded ? 44 : 28,
          ),
          const SizedBox(height: 4),
        ],
        if (showInfo) ...[
          _SidebarIcon(
            icon: Icons.info_outline_rounded,
            label: context.l10n.localeName.startsWith('de')
                ? 'Tipps zur Anatomie'
                : 'Anatomy tips',
            onTap: onInfoTap,
            active: false,
            flat: true,
            muted: true,
            touchSize: expanded ? 44 : 28,
          ),
        ],
      ],
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  const _SidebarIcon({
    this.icon,
    this.anatomyMode,
    required this.onTap,
    required this.active,
    required this.label,
    this.flat = false,
    this.outlined = false,
    this.muted = false,
    this.touchSize = 28,
  }) : assert((icon != null) != (anatomyMode != null));

  final IconData? icon;
  final BodyMapViewMode? anatomyMode;
  final VoidCallback onTap;
  final bool active;
  final bool flat;
  final bool outlined;
  final bool muted;
  final String label;
  final double touchSize;

  @override
  Widget build(BuildContext context) {
    final iconSize = touchSize > 28 ? 19.0 : (flat ? 16.0 : 15.0);
    final iconColor = muted
        ? const Color(0xFF96989B)
        : active
        ? AppColors.primary
        : AppColors.textMuted;
    final iconWidget = Center(
      child: anatomyMode != null
          ? AnatomyModeIcon(
              mode: anatomyMode!,
              color: iconColor,
              size: iconSize,
            )
          : Icon(icon, size: iconSize, color: iconColor),
    );

    return IconButton(
      onPressed: onTap,
      tooltip: label,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: touchSize, height: touchSize),
      style: IconButton.styleFrom(
        minimumSize: Size.square(touchSize),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppColors.textMuted,
        backgroundColor: Colors.transparent,
      ),
      icon: flat && !outlined
          ? iconWidget
          : AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: touchSize > 28 ? 34 : 28,
              height: touchSize > 28 ? 34 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: outlined
                    ? Colors.transparent
                    : active
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : AppColors.card.withValues(alpha: 0.7),
                border: Border.all(
                  color: outlined
                      ? AppColors.textMuted.withValues(alpha: 0.45)
                      : active
                      ? AppColors.primary.withValues(alpha: 0.24)
                      : AppColors.stroke.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: iconWidget,
            ),
    );
  }
}
