import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../services/home_daily_hud_service.dart';
import '../services/home_weekly_summary_service.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';

/// Clean, modern readout panels for the home body map.
class BodyHudPalette {
  BodyHudPalette._();

  static const double cardRadius = 16;
  static const String fontFamily = 'Roboto';

  static BoxDecoration cardDecoration(
    BuildContext context, {
    bool transparent = false,
  }) {
    if (transparent) {
      return const BoxDecoration(color: Colors.transparent);
    }
    return AppColors.surfaceDecoration(
      borderRadius: BorderRadius.circular(cardRadius),
    );
  }

  static TextStyle titleStyle({Color? accent, bool large = false}) => TextStyle(
        color: AppColors.textPrimary,
        fontSize: large ? 18 : 15,
        height: 1.2,
        fontWeight: FontWeight.w700,
        fontFamily: fontFamily,
      );

  static TextStyle sectionLabelStyle(Color accent, {bool large = false}) =>
      TextStyle(
        color: accent.withValues(alpha: 0.9),
        fontSize: large ? 13 : 11,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        fontFamily: fontFamily,
      );

  static TextStyle bodyStyle({bool large = false}) => TextStyle(
        color: AppColors.textPrimary.withValues(alpha: 0.9),
        fontSize: large ? 14 : 12,
        height: 1.45,
        fontWeight: FontWeight.w400,
        fontFamily: fontFamily,
      );

  static TextStyle mutedStyle({bool large = false}) => TextStyle(
        color: AppColors.textMuted,
        fontSize: large ? 13 : 11,
        height: 1.4,
        fontWeight: FontWeight.w400,
        fontFamily: fontFamily,
      );

  static TextStyle accentLineStyle(Color accent, {bool large = false}) =>
      TextStyle(
        color: accent.withValues(alpha: 0.95),
        fontSize: large ? 14 : 11,
        height: 1.45,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
      );

  static TextStyle metricValueStyle(Color accent, {bool large = false}) =>
      TextStyle(
        color: accent,
        fontSize: large ? 32 : 24,
        height: 1,
        fontWeight: FontWeight.w800,
        fontFamily: fontFamily,
      );

  // Legacy aliases used by recovery_body_map detail overlays.
  static TextStyle summaryLineStyle(Color accent, {bool large = false}) =>
      bodyStyle(large: large);
  static TextStyle tabDetailLineStyle(Color accent, {bool large = false}) =>
      accentLineStyle(accent, large: large);
  static TextStyle nameStyle(Color accent, {bool large = false}) =>
      titleStyle(accent: accent, large: large);
  static TextStyle dailyLineStyle({
    double indent = 0,
    bool compact = true,
    bool large = false,
  }) =>
      bodyStyle(large: large).copyWith(fontSize: large ? 14 : (compact ? 10 : 11));

  static Color panelBackground(BuildContext context, {bool transparent = false}) {
    if (transparent) return Colors.transparent;
    return AppColors.card;
  }

  static Color panelBorder(Color accent) => AppColors.stroke;
  static List<BoxShadow> panelGlow(Color accent) => const [];

  static const double dailyPanelIndent = 10;
}

class BodyHudStatusPanel extends StatefulWidget {
  const BodyHudStatusPanel({
    super.key,
    required this.name,
    required this.summaryLines,
    required this.tabDetailLines,
    this.hudSnapshot,
    this.stepsLabel = 'Steps',
    this.availableLabel = 'Available',
    this.waterLabel = 'Water',
    this.onWaterTap,
    this.onWaterLongPress,
    this.accent,
    this.fillWidth = false,
    this.transparentBackground = false,
    this.maxContentWidth,
    this.large = false,
    this.initiallyExpanded = true,
  });

  final Color? accent;
  final String name;
  final List<String> summaryLines;
  final List<String> tabDetailLines;
  final HomeHudSnapshot? hudSnapshot;
  final String stepsLabel;
  final String availableLabel;
  final String waterLabel;
  final VoidCallback? onWaterTap;
  final VoidCallback? onWaterLongPress;
  final bool fillWidth;
  final bool transparentBackground;
  /// Caps panel width; body text wraps inside this width instead of ellipsizing.
  final double? maxContentWidth;
  final bool large;
  final bool initiallyExpanded;

  @override
  State<BodyHudStatusPanel> createState() => _BodyHudStatusPanelState();
}

class _BodyHudStatusPanelState extends State<BodyHudStatusPanel> {
  late bool _summaryExpanded;

  @override
  void initState() {
    super.initState();
    _summaryExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant BodyHudStatusPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded &&
        widget.initiallyExpanded != _summaryExpanded) {
      _summaryExpanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = widget.accent ?? AppColors.primary;
    final snapshot = widget.hudSnapshot;
    final tip = snapshot?.tip ??
        (widget.summaryLines.isNotEmpty ? widget.summaryLines.first : null);
    final hasSummaryBody = tip != null ||
        snapshot != null ||
        widget.tabDetailLines.isNotEmpty;

    return _HudExpandablePanel(
      accent: resolvedAccent,
      fillWidth: widget.fillWidth,
      maxContentWidth: widget.maxContentWidth,
      expanded: _summaryExpanded,
      transparentBackground: widget.transparentBackground,
      large: widget.large,
      onToggle: () => setState(() => _summaryExpanded = !_summaryExpanded),
      header: Text(
        widget.name,
        softWrap: true,
        style: BodyHudPalette.titleStyle(
          accent: resolvedAccent,
          large: widget.large,
        ),
      ),
      child: hasSummaryBody
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tip != null) ...[
                  SizedBox(height: widget.large ? 8 : 6),
                  Text(
                    tip,
                    softWrap: true,
                    style: BodyHudPalette.accentLineStyle(
                      AppColors.primary,
                      large: widget.large,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: widget.large ? 14 : 12,
                    ),
                  ),
                ],
                if (snapshot != null) ...[
                  SizedBox(height: widget.large ? 10 : 8),
                  _HudMetricProgressRow(
                    label: widget.stepsLabel,
                    value: '${snapshot.steps}',
                    progress: snapshot.stepsProgress,
                    color: const Color(0xFF43B86B),
                    large: widget.large,
                  ),
                  SizedBox(height: widget.large ? 8 : 6),
                  _HudMetricProgressRow(
                    label: widget.availableLabel,
                    value: snapshot.availableKcal == null
                        ? '--'
                        : '${snapshot.availableKcal} kcal',
                    progress: snapshot.availableProgress,
                    color: AppColors.burn,
                    large: widget.large,
                  ),
                  if (snapshot.waterEnabled) ...[
                    SizedBox(height: widget.large ? 8 : 6),
                    GestureDetector(
                      onTap: widget.onWaterTap,
                      onLongPress: widget.onWaterLongPress,
                      behavior: HitTestBehavior.opaque,
                      child: _HudMetricProgressRow(
                        label: widget.waterLabel,
                        value:
                            '${snapshot.waterMl} / ${snapshot.waterGoalMl} ml',
                        progress: snapshot.waterProgress,
                        color: const Color(0xFF4A9FE0),
                        large: widget.large,
                      ),
                    ),
                  ],
                ],
                if (widget.tabDetailLines.isNotEmpty) ...[
                  SizedBox(height: widget.large ? 8 : 6),
                  for (var i = 0; i < widget.tabDetailLines.length; i++) ...[
                    if (i > 0) SizedBox(height: widget.large ? 4 : 2),
                    Text(
                      widget.tabDetailLines[i],
                      softWrap: true,
                      style: BodyHudPalette.tabDetailLineStyle(
                        resolvedAccent,
                        large: widget.large,
                      ),
                    ),
                  ],
                ],
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class _HudMetricProgressRow extends StatelessWidget {
  const _HudMetricProgressRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    this.large = false,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BodyHudPalette.mutedStyle(large: large).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: large ? 12 : 10,
                ),
              ),
            ),
            Text(
              value,
              style: BodyHudPalette.bodyStyle(large: large).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: large ? 13 : 11,
              ),
            ),
          ],
        ),
        SizedBox(height: large ? 5 : 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: large ? 7 : 5,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: color.withValues(alpha: 0.16)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: ColoredBox(color: color),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HudExpandablePanel extends StatelessWidget {
  const _HudExpandablePanel({
    required this.accent,
    required this.fillWidth,
    required this.expanded,
    required this.onToggle,
    required this.header,
    required this.child,
    this.transparentBackground = false,
    this.maxContentWidth,
    this.large = false,
  });

  final Color accent;
  final bool fillWidth;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget header;
  final Widget child;
  final bool transparentBackground;
  final double? maxContentWidth;
  final bool large;

  static const _duration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final pad = large
        ? const EdgeInsets.fromLTRB(16, 14, 14, 14)
        : const EdgeInsets.fromLTRB(12, 10, 10, 10);
    return _HudFramedPanel(
      maxWidth: maxContentWidth ?? (large ? 320 : 248),
      fillWidth: fillWidth,
      transparentBackground: transparentBackground,
      padding: pad,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          splashColor: accent.withValues(alpha: 0.08),
          highlightColor: accent.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(BodyHudPalette.cardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1,
                      child: header,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: _duration,
                    curve: Curves.easeInOutCubic,
                    child: Icon(
                      Icons.expand_more,
                      size: large ? 22 : 16,
                      color: accent.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: _duration,
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topLeft,
                clipBehavior: Clip.hardEdge,
                child: AnimatedOpacity(
                  duration: _duration,
                  curve: Curves.easeInOut,
                  opacity: expanded ? 1 : 0,
                  child: expanded
                      ? child
                      : const SizedBox(width: double.infinity),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudDailyLine extends StatelessWidget {
  const _HudDailyLine({
    required this.line,
    this.compact = true,
    this.large = false,
  });

  final HomeDailyHudLine line;
  final bool compact;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: line.indent),
      child: Text(
        line.text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: BodyHudPalette.dailyLineStyle(
          indent: line.indent,
          compact: compact,
          large: large,
        ),
      ),
    );
  }
}

enum BodyHudDailyLayout { compact, expanded }

/// Collapses into a pill chip; expands to a clean analytics card.
class BodyHudDailyFloatingPanel extends StatefulWidget {
  const BodyHudDailyFloatingPanel({
    super.key,
    required this.dailyLines,
    required this.title,
    required this.dailyLabel,
    required this.analyticsLabel,
    this.accent,
    this.layout = BodyHudDailyLayout.compact,
    this.transparentBackground = false,
    this.onCompactExpansionProgress,
    this.expandDownward = false,
  });

  final List<HomeDailyHudLine> dailyLines;
  final String title;
  final String dailyLabel;
  final String analyticsLabel;
  final Color? accent;
  final BodyHudDailyLayout layout;
  final bool transparentBackground;
  final ValueChanged<double>? onCompactExpansionProgress;
  final bool expandDownward;

  @override
  State<BodyHudDailyFloatingPanel> createState() =>
      _BodyHudDailyFloatingPanelState();
}

class _BodyHudDailyFloatingPanelState extends State<BodyHudDailyFloatingPanel>
    with SingleTickerProviderStateMixin {
  static const _chipSize = 40.0;
  static const _duration = Duration(milliseconds: 420);

  late final AnimationController _controller;
  late final Animation<double> _curved;

  bool get _isExpandedLayout =>
      widget.layout == BodyHudDailyLayout.expanded;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    if (_isExpandedLayout) {
      _controller.value = 1.0;
    }
    _curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    if (!_isExpandedLayout) {
      _controller.addListener(_notifyCompactExpansionProgress);
    }
  }

  void _notifyCompactExpansionProgress() {
    widget.onCompactExpansionProgress?.call(_curved.value);
  }

  @override
  void didUpdateWidget(covariant BodyHudDailyFloatingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isExpandedLayout && _controller.value < 1) {
      _controller.value = 1.0;
    }
    if (oldWidget.onCompactExpansionProgress !=
        widget.onCompactExpansionProgress) {
      _notifyCompactExpansionProgress();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_notifyCompactExpansionProgress);
    _controller.dispose();
    super.dispose();
  }

  void _expand() => _controller.forward();
  void _collapse() {
    if (_isExpandedLayout) return;
    _controller.reverse();
  }

  Widget _buildPanel(Color accent, {required bool compact}) {
    return _HudFramedPanel(
      maxWidth: _dailyPanelMaxWidth,
      fillWidth: true,
      transparentBackground: widget.transparentBackground,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isExpandedLayout ? null : _collapse,
          borderRadius: BorderRadius.circular(BodyHudPalette.cardRadius),
          splashColor: accent.withValues(alpha: 0.08),
          highlightColor: accent.withValues(alpha: 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.dailyLines.length; i++) ...[
                if (i > 0) const SizedBox(height: 2),
                _HudDailyLine(
                  line: widget.dailyLines[i],
                  compact: true,
                  large: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static const _dailyPanelMinWidth = 168.0;
  static const _dailyPanelMaxWidth = 220.0;
  static const _dailyPanelMaxHeight = 240.0;

  Widget _wrapOpenedDailyPanel(Widget panel) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: _dailyPanelMinWidth,
        maxWidth: _dailyPanelMaxWidth,
        maxHeight: _dailyPanelMaxHeight,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: panel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dailyLines.isEmpty) return const SizedBox.shrink();

    final accent = widget.accent ?? AppColors.primary;

    if (_isExpandedLayout) {
      return Align(
        alignment: Alignment.bottomLeft,
        child: _wrapOpenedDailyPanel(_buildPanel(accent, compact: true)),
      );
    }

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _curved,
        builder: (context, _) {
          final t = _curved.value;
          final panelOpacity = ((t - 0.08) / 0.92).clamp(0.0, 1.0);
          final panelSlide = ui.lerpDouble(16, 0, panelOpacity)!;
          final panelScale = ui.lerpDouble(0.92, 1.0, panelOpacity)!;
          final isOpen = t > 0.05;
          final panelOffset = widget.expandDownward
              ? Offset(0, -panelSlide)
              : Offset(0, panelSlide);
          final panelAlign = widget.expandDownward
              ? Alignment.topLeft
              : Alignment.bottomLeft;

          return SizedBox(
            height: _chipSize,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: widget.expandDownward
                  ? Alignment.topLeft
                  : Alignment.bottomLeft,
              children: [
                Positioned(
                  left: 0,
                  top: widget.expandDownward ? _chipSize + 6 : null,
                  bottom: widget.expandDownward ? null : _chipSize + 6,
                  child: Opacity(
                    opacity: panelOpacity,
                    child: IgnorePointer(
                      ignoring: panelOpacity < 0.01,
                      child: Transform.translate(
                        offset: panelOffset,
                        child: Transform.scale(
                          scale: panelScale,
                          alignment: panelAlign,
                          child: _wrapOpenedDailyPanel(
                            _buildPanel(accent, compact: true),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: widget.expandDownward ? 0 : null,
                  bottom: widget.expandDownward ? null : 0,
                  child: _DailySummaryChip(
                    size: _chipSize,
                    accent: accent,
                    dailyLabel: widget.dailyLabel,
                    analyticsLabel: widget.analyticsLabel,
                    onTap: isOpen ? _collapse : _expand,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DailySummaryChip extends StatelessWidget {
  const _DailySummaryChip({
    required this.size,
    required this.accent,
    required this.dailyLabel,
    required this.analyticsLabel,
    this.onTap,
  });

  final double size;
  final Color accent;
  final String dailyLabel;
  final String analyticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$dailyLabel · $analyticsLabel',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              boxShadow: ProgressStore.useLightTheme
                  ? const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 18,
                        offset: Offset(0, 5),
                      ),
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
              border: ProgressStore.useLightTheme
                  ? null
                  : Border.all(color: AppColors.stroke),
            ),
            child: Icon(
              Icons.insights_rounded,
              size: 20,
              color: accent,
            ),
          ),
        ),
      ),
    );
  }
}

class BodyHudStreakPanel extends StatelessWidget {
  const BodyHudStreakPanel({
    super.key,
    required this.label,
    required this.days,
    this.accent,
    this.transparentBackground = false,
    this.large = false,
  });

  final String label;
  final int days;
  final Color? accent;
  final bool transparentBackground;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accent ?? AppColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final box = context.findRenderObject() as RenderBox?;
        final overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox?;
        if (box == null || overlay == null) return;
        final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
        final bottomRight = box.localToGlobal(
          box.size.bottomRight(Offset.zero),
          ancestor: overlay,
        );
        await showMenu<void>(
          context: context,
          color: AppColors.card,
          position: RelativeRect.fromLTRB(
            topLeft.dx,
            topLeft.dy - 44,
            overlay.size.width - bottomRight.dx,
            overlay.size.height - topLeft.dy,
          ),
          items: [
            PopupMenuItem<void>(
              enabled: false,
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
      child: _HudFramedPanel(
        maxWidth: large ? 110 : 84,
        transparentBackground: transparentBackground,
        padding: EdgeInsets.fromLTRB(
          large ? 14 : 10,
          large ? 12 : 8,
          large ? 14 : 10,
          large ? 12 : 8,
        ),
        child: Text(
          '$days',
          style: BodyHudPalette.metricValueStyle(
            resolvedAccent,
            large: large,
          ).copyWith(
            fontSize: large ? 34 : 28,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class BodyHudMetricPanel extends StatelessWidget {
  const BodyHudMetricPanel({
    super.key,
    required this.accent,
    required this.title,
    required this.value,
    required this.subtitle,
    this.alignRight = true,
  });

  final Color accent;
  final String title;
  final String value;
  final String subtitle;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final cross =
        alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignRight ? TextAlign.right : TextAlign.left;

    return _HudFramedPanel(
      maxWidth: 196,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: cross,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: textAlign,
            style: BodyHudPalette.sectionLabelStyle(accent),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: textAlign,
            style: BodyHudPalette.metricValueStyle(accent),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: textAlign,
            style: BodyHudPalette.mutedStyle(),
          ),
        ],
      ),
    );
  }
}

class _HudFramedPanel extends StatelessWidget {
  const _HudFramedPanel({
    required this.child,
    required this.maxWidth,
    required this.padding,
    this.fillWidth = false,
    this.transparentBackground = false,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  final bool fillWidth;
  final bool transparentBackground;

  @override
  Widget build(BuildContext context) {
    final resolvedMaxWidth = maxWidth.isFinite
        ? maxWidth
        : (fillWidth ? double.infinity : maxWidth);
    Widget content = padding == EdgeInsets.zero
        ? child
        : Padding(padding: padding, child: child);

    if (!transparentBackground) {
      content = Container(
        decoration: BodyHudPalette.cardDecoration(context),
        child: content,
      );
    }

    final panel = content;

    return ExcludeSemantics(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: resolvedMaxWidth,
        ),
        child: fillWidth ? panel : IntrinsicWidth(child: panel),
      ),
    );
  }
}
