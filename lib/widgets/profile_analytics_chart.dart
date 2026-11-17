import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../services/health_steps_service.dart';
import '../services/muscle_activity_service.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';

enum ProfileAnalyticsMetric {
  steps,
  weight,
  calorieBurn,
  water,
  afterburn,
  calorieIntake,
  protein,
  fat,
  carbs,
  workouts,
}

const List<ProfileAnalyticsMetric> profileAnalyticsTabOrder = [
  ProfileAnalyticsMetric.steps,
  ProfileAnalyticsMetric.weight,
  ProfileAnalyticsMetric.calorieBurn,
  ProfileAnalyticsMetric.water,
  ProfileAnalyticsMetric.afterburn,
  ProfileAnalyticsMetric.calorieIntake,
  ProfileAnalyticsMetric.protein,
  ProfileAnalyticsMetric.fat,
  ProfileAnalyticsMetric.carbs,
  ProfileAnalyticsMetric.workouts,
];

extension ProfileAnalyticsMetricX on ProfileAnalyticsMetric {
  String label(AppLocalizations l10n) => switch (this) {
        ProfileAnalyticsMetric.steps => l10n.analytics_steps,
        ProfileAnalyticsMetric.weight => l10n.analytics_weight,
        ProfileAnalyticsMetric.calorieIntake => l10n.analytics_calories,
        ProfileAnalyticsMetric.calorieBurn => l10n.analytics_burn,
        ProfileAnalyticsMetric.water => l10n.analytics_water,
        ProfileAnalyticsMetric.afterburn => l10n.analytics_afterburn,
        ProfileAnalyticsMetric.protein => l10n.analytics_protein,
        ProfileAnalyticsMetric.fat => l10n.analytics_fat,
        ProfileAnalyticsMetric.carbs => l10n.analytics_carbs,
        ProfileAnalyticsMetric.workouts => l10n.analytics_workouts,
      };

  String emptyMessage(AppLocalizations l10n) => switch (this) {
        ProfileAnalyticsMetric.steps => l10n.analytics_emptySteps,
        ProfileAnalyticsMetric.weight => l10n.analytics_emptyWeight,
        ProfileAnalyticsMetric.calorieIntake => l10n.analytics_emptyCalories,
        ProfileAnalyticsMetric.calorieBurn => l10n.analytics_emptyBurn,
        ProfileAnalyticsMetric.water => l10n.analytics_emptyWater,
        ProfileAnalyticsMetric.afterburn => l10n.analytics_emptyAfterburn,
        ProfileAnalyticsMetric.protein => l10n.analytics_emptyProtein,
        ProfileAnalyticsMetric.fat => l10n.analytics_emptyFat,
        ProfileAnalyticsMetric.carbs => l10n.analytics_emptyCarbs,
        ProfileAnalyticsMetric.workouts => l10n.analytics_emptyWorkouts,
      };

  String formatValue(double value) => switch (this) {
        ProfileAnalyticsMetric.weight => value.toStringAsFixed(1),
        ProfileAnalyticsMetric.protein ||
        ProfileAnalyticsMetric.fat ||
        ProfileAnalyticsMetric.carbs ||
        ProfileAnalyticsMetric.steps =>
          value.round().toString(),
        _ => value.round().toString(),
      };

  String valueUnit(AppLocalizations l10n) => switch (this) {
        ProfileAnalyticsMetric.weight => l10n.analytics_unitKg,
        ProfileAnalyticsMetric.calorieIntake ||
        ProfileAnalyticsMetric.calorieBurn ||
        ProfileAnalyticsMetric.afterburn =>
          l10n.analytics_unitKcal,
        ProfileAnalyticsMetric.water => l10n.analytics_unitMl,
        ProfileAnalyticsMetric.protein ||
        ProfileAnalyticsMetric.fat ||
        ProfileAnalyticsMetric.carbs =>
          l10n.analytics_unitG,
        ProfileAnalyticsMetric.steps || ProfileAnalyticsMetric.workouts => '',
      };
}

const double _kChartLeftGutter = 38.0;
const double _kChartBottomGutter = 28.0;
const double _kChartTopPadding = 8.0;
const double _kChartRightPadding = 8.0;

/// Screen-space position of each data point, shared by the painter and the
/// tap hit-testing so they never disagree on where a point actually is.
List<Offset> _chartVertices(Size size, List<AnalyticsChartPoint> points) {
  final w = size.width - _kChartLeftGutter - _kChartRightPadding;
  final h = size.height - _kChartTopPadding - _kChartBottomGutter;
  if (w <= 0 || h <= 0 || points.isEmpty) return const [];

  var maxY = points.first.value;
  for (final p in points) {
    if (p.value > maxY) maxY = p.value;
  }
  maxY = maxY <= 0 ? 1 : maxY + maxY * 0.12;

  final slotWidth = w / points.length;
  return [
    for (var i = 0; i < points.length; i++)
      Offset(
        _kChartLeftGutter + slotWidth * (i + 0.5),
        _kChartTopPadding +
            (1 - (points[i].value / maxY).clamp(0.0, 1.0)) * h,
      ),
  ];
}

class ProfileAnalyticsChartCard extends StatefulWidget {
  const ProfileAnalyticsChartCard({super.key});

  @override
  State<ProfileAnalyticsChartCard> createState() =>
      _ProfileAnalyticsChartCardState();
}

class _ProfileAnalyticsChartCardState extends State<ProfileAnalyticsChartCard> {
  ProfileAnalyticsMetric _selected = ProfileAnalyticsMetric.steps;
  int? _selectedPointIndex;

  void _selectMetric(ProfileAnalyticsMetric metric) {
    setState(() {
      _selected = metric;
      _selectedPointIndex = null;
    });
  }

  void _handleChartTap(
    Offset localPosition,
    Size chartSize,
    List<AnalyticsChartPoint> points,
  ) {
    final vertices = _chartVertices(chartSize, points);
    if (vertices.isEmpty) return;
    var nearest = 0;
    var nearestDist = double.infinity;
    for (var i = 0; i < vertices.length; i++) {
      final dist = (vertices[i].dx - localPosition.dx).abs();
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = i;
      }
    }
    setState(() {
      _selectedPointIndex = _selectedPointIndex == nearest ? null : nearest;
    });
  }

  List<AnalyticsChartPoint> _pointsFor(ProfileAnalyticsMetric m) {
    return switch (m) {
      ProfileAnalyticsMetric.steps => ProgressStore.stepsAnalyticsSeries(),
      ProfileAnalyticsMetric.weight => ProgressStore.weightAnalyticsSeries(),
      ProfileAnalyticsMetric.calorieIntake =>
        ProgressStore.calorieIntakeAnalyticsSeries(),
      ProfileAnalyticsMetric.calorieBurn =>
        ProgressStore.calorieBurnAnalyticsSeries(),
      ProfileAnalyticsMetric.water => ProgressStore.waterAnalyticsSeries(),
      ProfileAnalyticsMetric.afterburn =>
        MuscleActivityService.afterburnAnalyticsSeries(),
      ProfileAnalyticsMetric.protein => ProgressStore.proteinAnalyticsSeries(),
      ProfileAnalyticsMetric.fat => ProgressStore.fatAnalyticsSeries(),
      ProfileAnalyticsMetric.carbs => ProgressStore.carbAnalyticsSeries(),
      ProfileAnalyticsMetric.workouts =>
        ProgressStore.workoutCountAnalyticsSeries(),
    };
  }

  bool _hasData(ProfileAnalyticsMetric m, List<AnalyticsChartPoint> points) {
    if (m == ProfileAnalyticsMetric.weight) {
      return points.any((p) => p.value > 0);
    }
    return points.any((p) => p.value > 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<int>(
      valueListenable: ProgressStore.listenable(),
      builder: (context, _, __) {
        final points = _pointsFor(_selected);
        final hasData = _hasData(_selected, points);
        final selectedIndex =
            (_selectedPointIndex != null && _selectedPointIndex! < points.length)
                ? _selectedPointIndex
                : null;
        final selectedTooltip = selectedIndex == null
            ? null
            : '${_selected.formatValue(points[selectedIndex].value)}'
                '${_selected.valueUnit(l10n).isEmpty ? '' : ' ${_selected.valueUnit(l10n)}'}';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: AppColors.themedCardDecoration(
            context,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: profileAnalyticsTabOrder.map((metric) {
                    final active = metric == _selected;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _selectMetric(metric),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          constraints: const BoxConstraints(minHeight: 44),
                          alignment: Alignment.center,
                          decoration: active
                              ? BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.45),
                                    width: 1.5,
                                  ),
                                )
                              : null,
                          child: Text(
                            metric.label(l10n),
                            style: TextStyle(
                              color: active
                                  ? AppColors.accentText
                                  : AppColors.textMuted,
                              fontWeight:
                                  active ? FontWeight.w800 : FontWeight.w500,
                              fontSize: active ? 13.5 : 13,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: hasData
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final chartSize = constraints.biggest;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) => _handleChartTap(
                              details.localPosition,
                              chartSize,
                              points,
                            ),
                            child: CustomPaint(
                              painter: _AnalyticsLineChartPainter(
                                points: points,
                                rangeStart:
                                    ProgressStore.profileAnalyticsRangeStart,
                                rangeEnd: ProgressStore.profileAnalyticsRangeEnd,
                                barColor: AppColors.primary,
                                metric: _selected,
                                isLightTheme: Theme.of(context).brightness ==
                                    Brightness.light,
                                selectedIndex: selectedIndex,
                                selectedValueText: selectedTooltip,
                              ),
                              size: Size.infinite,
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          _selected.emptyMessage(l10n),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textMuted,
                                    fontFamily: 'Roboto',
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
              if (_selected == ProfileAnalyticsMetric.steps) ...[
                const SizedBox(height: 10),
                const _AnalyticsStepsFooter(),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AnalyticsStepsFooter extends StatefulWidget {
  const _AnalyticsStepsFooter();

  @override
  State<_AnalyticsStepsFooter> createState() => _AnalyticsStepsFooterState();
}

class _AnalyticsStepsFooterState extends State<_AnalyticsStepsFooter> {
  bool _syncing = false;
  String? _hint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshIfNeeded());
  }

  Future<void> _refreshIfNeeded() async {
    if (!HealthStepsService.isSupported) {
      setState(() {
        _hint = context.l10n.steps_unavailableDevice;
      });
      return;
    }
    final result = await HealthStepsService.refreshTodayStepsIfStale();
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() => _hint = null);
      return;
    }
    if (ProgressStore.todaySteps == null) {
      setState(() {
        _hint = result.message ?? context.l10n.steps_connectHint;
      });
    }
  }

  Future<void> _connectOrRefresh() async {
    setState(() {
      _syncing = true;
      _hint = null;
    });
    final result = await HealthStepsService.refreshTodaySteps();
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _syncing = false;
      if (!result.isSuccess) {
        _hint = result.message ?? l10n.steps_loadFailed;
      }
    });
    if (result.isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.steps_todaySnack(result.steps ?? 0))),
      );
    }
  }

  String _sourceLabel(AppLocalizations l10n) {
    if (Platform.isIOS) return l10n.steps_appleHealth;
    if (Platform.isAndroid) return l10n.steps_healthConnect;
    return l10n.steps_notAvailable;
  }

  String _formatSyncedAt(AppLocalizations l10n, DateTime? syncedAt) {
    if (syncedAt == null) return l10n.steps_notSynced;
    final time =
        '${syncedAt.hour.toString().padLeft(2, '0')}:${syncedAt.minute.toString().padLeft(2, '0')}';
    return l10n.steps_updatedAt(time);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = ProgressStore.todaySteps;
    final syncedAt = ProgressStore.todayStepsSyncedAt;
    final supported = HealthStepsService.isSupported;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(
                        text: steps == null ? '--' : '$steps',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' ${l10n.steps_label}',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (supported)
                TextButton.icon(
                  onPressed: _syncing ? null : _connectOrRefresh,
                  icon: _syncing
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Icon(
                          steps == null
                              ? Icons.link_outlined
                              : Icons.refresh,
                          size: 16,
                          color: AppColors.primary,
                        ),
                  label: Text(
                    steps == null ? l10n.steps_connect : l10n.steps_refresh,
                    style: TextStyle(
                      color: AppColors.accentText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            supported
                ? '${_sourceLabel(l10n)} · ${_formatSyncedAt(l10n, syncedAt)}'
                : l10n.steps_mobileOnly,
            style: TextStyle(
              color: AppColors.textMuted,
              fontFamily: 'Roboto',
              fontSize: 11,
              height: 1.35,
            ),
          ),
          if (_hint != null) ...[
            const SizedBox(height: 4),
            Text(
              _hint!,
              style: TextStyle(
                color: AppColors.textMuted,
                fontFamily: 'Roboto',
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalyticsLineChartPainter extends CustomPainter {
  _AnalyticsLineChartPainter({
    required this.points,
    required this.rangeStart,
    required this.rangeEnd,
    required this.barColor,
    required this.metric,
    required this.isLightTheme,
    this.selectedIndex,
    this.selectedValueText,
  });

  final List<AnalyticsChartPoint> points;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final Color barColor;
  final ProfileAnalyticsMetric metric;
  final bool isLightTheme;
  final int? selectedIndex;
  final String? selectedValueText;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const leftGutter = _kChartLeftGutter;
    const bottomGutter = _kChartBottomGutter;
    const topPadding = _kChartTopPadding;
    const rightPadding = _kChartRightPadding;
    final w = size.width - leftGutter - rightPadding;
    final h = size.height - topPadding - bottomGutter;
    if (w <= 0 || h <= 0) return;

    final chartLeft = leftGutter;
    final chartTop = topPadding;
    final chartBottom = topPadding + h;
    final chartRight = leftGutter + w;

    var minY = 0.0;
    var maxY = points.first.value;
    for (final p in points) {
      if (p.value > maxY) maxY = p.value;
    }
    if (maxY <= 0) {
      maxY = 1;
    } else {
      maxY += maxY * 0.12;
    }

    final gridPaint = Paint()
      ..color = AppColors.stroke.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final labelStyle = TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
      fontFamily: 'Roboto',
    );

    canvas.drawLine(
      Offset(chartLeft, chartBottom),
      Offset(chartRight, chartBottom),
      gridPaint,
    );

    final count = points.length;
    final slotWidth = w / count;
    final lineColor = barColor.withValues(alpha: isLightTheme ? 0.9 : 0.95);

    final vertices = _chartVertices(size, points);
    if (vertices.isEmpty) return;

    if (vertices.length > 1) {
      final fillPath = Path()..moveTo(vertices.first.dx, chartBottom);
      for (final v in vertices) {
        fillPath.lineTo(v.dx, v.dy);
      }
      fillPath
        ..lineTo(vertices.last.dx, chartBottom)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lineColor.withValues(alpha: isLightTheme ? 0.22 : 0.28),
              lineColor.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom)),
      );
    }

    final linePath = Path()..moveTo(vertices.first.dx, vertices.first.dy);
    for (final v in vertices.skip(1)) {
      linePath.lineTo(v.dx, v.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = lineColor,
    );

    final dotFillPaint = Paint()..color = lineColor;
    final dotRingPaint = Paint()..color = AppColors.card;
    for (var i = 0; i < vertices.length; i++) {
      final isSelected = i == selectedIndex;
      canvas.drawCircle(vertices[i], isSelected ? 6 : 4.5, dotRingPaint);
      canvas.drawCircle(vertices[i], isSelected ? 4 : 3, dotFillPaint);
    }

    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < vertices.length &&
        selectedValueText != null) {
      _paintTooltip(
        canvas,
        size,
        point: vertices[selectedIndex!],
        text: selectedValueText!,
        color: lineColor,
        minTop: chartTop,
      );
    }

    final labelStep = count <= 7 ? 1 : (count / 5).ceil().clamp(1, count);
    for (var i = 0; i < count; i += labelStep) {
      final day = points[i].day;
      final xCenter = chartLeft + slotWidth * (i + 0.5);
      final text = TextPainter(
        text: TextSpan(text: _dayLabel(day), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: slotWidth + 4);
      final dx =
          (xCenter - text.width / 2).clamp(chartLeft, chartRight - text.width);
      text.paint(canvas, Offset(dx, chartBottom + 6));
    }

    final yValues = [maxY, maxY / 2];
    for (final value in yValues) {
      final yT = (value - minY) / (maxY - minY);
      final y = chartTop + (1 - yT) * h;
      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(chartRight, y),
        gridPaint,
      );
      final text = TextPainter(
        text: TextSpan(
          text: metric.formatValue(value),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftGutter - 6);
      text.paint(canvas, Offset(chartLeft - text.width - 6, y - text.height / 2));
    }
  }

  String _dayLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month';
  }

  /// Small value bubble next to a tapped point, flipped above/below and
  /// clamped horizontally so it never runs off the canvas.
  void _paintTooltip(
    Canvas canvas,
    Size size, {
    required Offset point,
    required String text,
    required Color color,
    required double minTop,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const hPad = 8.0;
    const vPad = 5.0;
    const gap = 10.0;
    final bubbleW = textPainter.width + hPad * 2;
    final bubbleH = textPainter.height + vPad * 2;

    final placeAbove = point.dy - gap - bubbleH >= minTop;
    final bubbleTop = placeAbove ? point.dy - gap - bubbleH : point.dy + gap;
    final bubbleLeft = (point.dx - bubbleW / 2).clamp(
      2.0,
      size.width - bubbleW - 2.0,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bubbleLeft, bubbleTop, bubbleW, bubbleH),
        const Radius.circular(6),
      ),
      Paint()..color = color,
    );
    textPainter.paint(canvas, Offset(bubbleLeft + hPad, bubbleTop + vPad));
  }

  @override
  bool shouldRepaint(covariant _AnalyticsLineChartPainter oldDelegate) {
    return oldDelegate.barColor != barColor ||
        oldDelegate.isLightTheme != isLightTheme ||
        oldDelegate.metric != metric ||
        oldDelegate.rangeStart != rangeStart ||
        oldDelegate.rangeEnd != rangeEnd ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.selectedValueText != selectedValueText ||
        oldDelegate.points.length != points.length ||
        !_pointsEqual(oldDelegate.points, points);
  }

  bool _pointsEqual(
    List<AnalyticsChartPoint> a,
    List<AnalyticsChartPoint> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].day != b[i].day || a[i].value != b[i].value) return false;
    }
    return true;
  }
}
