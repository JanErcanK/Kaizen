import 'app_back_button.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../navigation/app_tab_navigation.dart';
import '../theme/app_colors.dart';

enum AppTourArrowSide { top, bottom, left, right }

class AppTourStep {
  const AppTourStep({
    required this.targetKeyId,
    required this.tabIndex,
    required this.title,
    required this.description,
    this.arrowSide = AppTourArrowSide.top,
    this.spotlightPadding = 8,
    this.spotlightRadius = 16,
    this.startAtTop = false,
  });

  final String targetKeyId;
  final int tabIndex;
  final String title;
  final String description;
  final AppTourArrowSide arrowSide;
  final double spotlightPadding;
  final double spotlightRadius;
  final bool startAtTop;
}

List<AppTourStep> buildTourSteps(AppLocalizations l10n) => [
  AppTourStep(
    targetKeyId: 'mannequin',
    tabIndex: AppTabNavigation.home,
    title: l10n.tour_stepMannequinTitle,
    description: l10n.tour_stepMannequinDescription,
    spotlightPadding: 4,
    spotlightRadius: 100,
  ),
  AppTourStep(
    targetKeyId: 'workout',
    tabIndex: 0,
    title: l10n.tour_stepWorkoutTitle,
    description: l10n.tour_stepWorkoutDescription,
    arrowSide: AppTourArrowSide.bottom,
  ),
  AppTourStep(
    targetKeyId: 'running',
    tabIndex: 0,
    title: l10n.tour_stepRunningTitle,
    description: l10n.tour_stepRunningDescription,
    arrowSide: AppTourArrowSide.bottom,
  ),
  AppTourStep(
    targetKeyId: 'food',
    tabIndex: 0,
    title: l10n.tour_stepFoodTitle,
    description: l10n.tour_stepFoodDescription,
    arrowSide: AppTourArrowSide.bottom,
  ),
  AppTourStep(
    targetKeyId: 'shopping',
    tabIndex: AppTabNavigation.home,
    title: l10n.tour_stepShoppingTitle,
    description: l10n.tour_stepShoppingDescription,
    arrowSide: AppTourArrowSide.bottom,
    spotlightPadding: 3,
    spotlightRadius: 12,
  ),
  AppTourStep(
    targetKeyId: 'friends',
    tabIndex: 0,
    title: l10n.tour_stepFriendsTitle,
    description: l10n.tour_stepFriendsDescription,
    arrowSide: AppTourArrowSide.bottom,
  ),
  AppTourStep(
    targetKeyId: 'leveling',
    tabIndex: AppTabNavigation.profile,
    title: l10n.tour_stepLevelingTitle,
    description: l10n.tour_stepLevelingDescription,
    startAtTop: true,
  ),
  AppTourStep(
    targetKeyId: 'metabolic',
    tabIndex: 1,
    title: l10n.tour_stepMetabolicTitle,
    description: l10n.tour_stepMetabolicDescription,
    arrowSide: AppTourArrowSide.bottom,
  ),
  AppTourStep(
    targetKeyId: 'calendar',
    tabIndex: 1,
    title: l10n.tour_stepCalendarTitle,
    description: l10n.tour_stepCalendarDescription,
    arrowSide: AppTourArrowSide.bottom,
  ),
  AppTourStep(
    targetKeyId: 'gallery',
    tabIndex: 1,
    title: l10n.tour_stepGalleryTitle,
    description: l10n.tour_stepGalleryDescription,
    arrowSide: AppTourArrowSide.bottom,
  ),
  AppTourStep(
    targetKeyId: 'health',
    tabIndex: 1,
    title: l10n.tour_stepHealthTitle,
    description: l10n.tour_stepHealthDescription,
    arrowSide: AppTourArrowSide.bottom,
  ),
  AppTourStep(
    targetKeyId: 'weight',
    tabIndex: 1,
    title: l10n.tour_stepWeightTitle,
    description: l10n.tour_stepWeightDescription,
    arrowSide: AppTourArrowSide.bottom,
  ),
];

class AppTourController extends ChangeNotifier {
  AppTourController({required Map<String, GlobalKey> keys}) : _keys = keys;

  final Map<String, GlobalKey> _keys;
  bool _active = false;
  bool _preparing = false;
  int _stepIndex = 0;
  List<AppTourStep> _steps = const [];
  VoidCallback? onFinished;
  Future<void> Function(int tab)? navigateToTab;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _active = false;
    super.dispose();
  }

  bool get isActive => _active;
  bool get isPreparing => _preparing;
  int get stepIndex => _stepIndex;
  int get stepCount => _steps.length;
  AppTourStep get currentStep => _steps[_stepIndex];

  GlobalKey? keyForStep(AppTourStep step) => _keys[step.targetKeyId];

  Future<void> start(AppLocalizations l10n) async {
    _steps = buildTourSteps(l10n);
    _stepIndex = 0;
    _active = true;
    _preparing = true;
    notifyListeners();
    await _prepareStep();
  }

  Future<void> next() async {
    if (!_active || _preparing) return;
    if (_stepIndex >= _steps.length - 1) {
      finish();
      return;
    }
    _stepIndex++;
    _preparing = true;
    notifyListeners();
    await _prepareStep();
  }

  void previous() {
    if (!_active || _preparing || _stepIndex <= 0) return;
    _stepIndex--;
    _preparing = true;
    notifyListeners();
    _prepareStep();
  }

  void finish() {
    if (!_active) return;
    _active = false;
    _preparing = false;
    notifyListeners();
    onFinished?.call();
  }

  Future<void> _prepareStep() async {
    if (!_active) return;
    final step = currentStep;
    if (navigateToTab != null) {
      await navigateToTab!(step.tabIndex);
    } else {
      AppTabNavigation.selectedTab.value = step.tabIndex;
    }
    if (!_active || _disposed || currentStep != step) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!_active || currentStep != step) return;

    BuildContext? ctx;
    for (var attempt = 0; attempt < 6; attempt++) {
      ctx = keyForStep(step)?.currentContext;
      if (ctx != null && ctx.mounted) break;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!_active || _disposed || currentStep != step) return;
      await WidgetsBinding.instance.endOfFrame;
    }

    if (!_active || _disposed || currentStep != step) return;
    if (ctx != null && ctx.mounted) {
      // Move only the vertical list; the shell owns horizontal tab motion.
      ScrollableState? vertical;
      ctx.visitAncestorElements((element) {
        if (element is StatefulElement && element.state is ScrollableState) {
          final scrollable = element.state as ScrollableState;
          if (scrollable.position.axis == Axis.vertical) {
            vertical = scrollable;
            return false;
          }
        }
        return true;
      });
      final target = ctx.findRenderObject();
      if (target != null && vertical != null) {
        final duration = MediaQuery.disableAnimationsOf(ctx)
            ? Duration.zero
            : const Duration(milliseconds: 340);
        if (step.startAtTop) {
          if (duration == Duration.zero) {
            vertical!.position.jumpTo(vertical!.position.minScrollExtent);
          } else if ((vertical!.position.pixels -
                      vertical!.position.minScrollExtent)
                  .abs() >
              .5) {
            await vertical!.position.animateTo(
              vertical!.position.minScrollExtent,
              duration: duration,
              curve: Curves.easeInOutCubic,
            );
          }
        } else {
          await vertical!.position.ensureVisible(
            target,
            alignment: .12,
            duration: duration,
            curve: Curves.easeInOutCubic,
          );
        }
      }
    }
    await WidgetsBinding.instance.endOfFrame;
    if (_active && currentStep == step) {
      _preparing = false;
      notifyListeners();
    }
  }
}

class AppTourOverlay extends StatefulWidget {
  const AppTourOverlay({super.key, required this.controller});

  final AppTourController controller;

  @override
  State<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends State<AppTourOverlay>
    with WidgetsBindingObserver {
  final _overlayKey = GlobalKey();
  Rect? _targetRect;
  AppTourStep? _displayedStep;
  bool _trackingScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onControllerChanged);
    _scheduleTracking();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    _scheduleTracking();
    setState(() {});
  }

  void _scheduleTracking() {
    if (_trackingScheduled || !mounted) return;
    _trackingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackingScheduled = false;
      if (!mounted) return;
      _updateTargetRect();
      if (widget.controller.isActive && widget.controller.isPreparing) {
        _scheduleTracking();
      }
    });
  }

  void _updateTargetRect() {
    if (!mounted) return;
    if (!widget.controller.isActive) return;
    final step = widget.controller.currentStep;
    final key = widget.controller.keyForStep(step);
    final ctx = key?.currentContext;
    if (ctx == null) {
      return;
    }
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final overlay =
        _overlayKey.currentContext?.findRenderObject() as RenderBox?;
    if (overlay == null || !overlay.hasSize) return;
    final offset = overlay.globalToLocal(box.localToGlobal(Offset.zero));
    final pad = step.spotlightPadding;
    setState(() {
      if (!widget.controller.isPreparing) _displayedStep = step;
      _targetRect = Rect.fromLTWH(
        offset.dx - pad,
        offset.dy - pad,
        box.size.width + pad * 2,
        box.size.height + pad * 2,
      );
    });
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isActive) return const SizedBox.shrink();

    final step = _displayedStep ?? widget.controller.currentStep;
    final rect = _targetRect;
    final media = MediaQuery.of(context);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        key: _overlayKey,
        children: [
          if (rect != null)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    hole: RRect.fromRectAndRadius(
                      rect,
                      Radius.circular(
                        widget.controller.currentStep.spotlightRadius,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.72)),
            ),
          if (rect != null)
            Positioned.fromRect(
              rect: rect,
              child: IgnorePointer(
                key: const ValueKey('tour-spotlight'),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      widget.controller.currentStep.spotlightRadius,
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: CustomMultiChildLayout(
              delegate: _TourCardLayout(
                target: rect,
                safeInsets: media.padding.copyWith(
                  bottom: math.max(
                    media.padding.bottom,
                    media.viewInsets.bottom,
                  ),
                ),
              ),
              children: [
                if (rect != null)
                  LayoutId(
                    id: _TourCard.tooltip,
                    child: AnimatedOpacity(
                      opacity: widget.controller.isPreparing ? 0 : 1,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 140),
                      child: _buildTooltip(context, step),
                    ),
                  ),
                LayoutId(
                  id: _TourCard.controls,
                  child: _buildControls(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final l10n = context.l10n;
    final step = widget.controller.stepIndex + 1;
    final total = widget.controller.stepCount;
    final progress = step / total;
    return Container(
      key: const ValueKey('tour-controls'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.explore_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.profile_appTour,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  l10n.tour_progress(step, total),
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.stroke.withValues(alpha: 0.55),
                color: AppColors.primary,
              ),
            ),
            if (_targetRect == null && !widget.controller.isPreparing) ...[
              const SizedBox(height: 12),
              Text(
                widget.controller.currentStep.title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.controller.currentStep.description,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.controller.stepIndex > 0)
                  AppBackButton(onPressed: widget.controller.previous)
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: OverflowBar(
                    alignment: MainAxisAlignment.end,
                    overflowAlignment: OverflowBarAlignment.end,
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: widget.controller.finish,
                        child: Text(
                          l10n.common_skip,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.actionBackground,
                          foregroundColor: AppColors.onAction,
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: widget.controller.isPreparing
                            ? null
                            : () => widget.controller.next(),
                        child: Text(
                          step >= total
                              ? l10n.common_done
                              : l10n.common_continue,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(BuildContext context, AppTourStep step) {
    return SingleChildScrollView(
      key: const ValueKey('tour-tooltip'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration:
            AppColors.surfaceDecoration(
              borderRadius: BorderRadius.circular(16),
            ).copyWith(
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step.title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              step.description,
              style: TextStyle(
                color: AppColors.textMuted,
                fontFamily: 'Roboto',
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TourCard { tooltip, controls }

class _TourCardLayout extends MultiChildLayoutDelegate {
  _TourCardLayout({required this.target, required this.safeInsets});

  final Rect? target;
  final EdgeInsets safeInsets;

  @override
  void performLayout(Size size) {
    const margin = 16.0;
    const gap = 18.0;
    final left = safeInsets.left + margin;
    final top = safeInsets.top + margin;
    final width = math.max(0.0, size.width - left - safeInsets.right - margin);
    final bottom = math.max(top, size.height - safeInsets.bottom - margin);
    final controls = layoutChild(
      _TourCard.controls,
      BoxConstraints.tightFor(width: width).copyWith(maxHeight: bottom - top),
    );
    final controlsTop = bottom - controls.height;
    positionChild(_TourCard.controls, Offset(left, controlsTop));

    final target = this.target;
    if (target == null || !hasChild(_TourCard.tooltip)) return;
    final tooltipBottom = math.max(top, controlsTop - gap);
    final tooltip = layoutChild(
      _TourCard.tooltip,
      BoxConstraints(
        minWidth: math.min(320.0, width),
        maxWidth: math.min(320.0, width),
        maxHeight: tooltipBottom - top,
      ),
    );
    final below = target.bottom + gap;
    final above = target.top - gap - tooltip.height;
    // Large targets can leave no room beside them. Overlap the spotlight
    // in that case, while keeping the card inside the available overlay.
    final preferredTop = below + tooltip.height <= tooltipBottom
        ? below
        : above;
    final tooltipTop = preferredTop.clamp(top, tooltipBottom - tooltip.height);
    final tooltipLeft = (target.center.dx - tooltip.width / 2).clamp(
      left,
      left + width - tooltip.width,
    );
    positionChild(_TourCard.tooltip, Offset(tooltipLeft, tooltipTop));
  }

  @override
  bool shouldRelayout(covariant _TourCardLayout oldDelegate) {
    return target != oldDelegate.target || safeInsets != oldDelegate.safeInsets;
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.hole});

  final RRect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(hole)
      ..fillType = PathFillType.evenOdd;

    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.hole != hole;
  }
}
