import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/progress_store.dart';
import '../theme/app_colors.dart';

/// Bottom-sheet popup showing per-exercise lift history as a line graph.
/// Call [ExerciseStatsSheet.show] to display it.
class ExerciseStatsSheet extends StatefulWidget {
  const ExerciseStatsSheet({super.key, required this.exerciseName});

  final String exerciseName;

  static Future<void> show(BuildContext context, String exerciseName) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseStatsSheet(exerciseName: exerciseName),
    );
  }

  @override
  State<ExerciseStatsSheet> createState() => _ExerciseStatsSheetState();
}

class _ExerciseStatsSheetState extends State<ExerciseStatsSheet> {
  // 0 = Volume, 1 = Max Weight, 2 = Reps
  int _metric = 0;

  static const _metricLabels = ['Volumen', 'Gewicht', 'Wiederholungen'];
  static const _metricUnits = ['kg·Wdh', 'kg', 'Wdh'];

  List<Map<String, dynamic>> get _entries =>
      ProgressStore.liftLogForExercise(widget.exerciseName);

  double _valueFor(Map<String, dynamic> entry) {
    return switch (_metric) {
      0 => (entry['volume'] as num? ?? 0).toDouble(),
      1 => (entry['weight'] as num? ?? 0).toDouble(),
      _ => (entry['reps'] as num? ?? 0).toDouble(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.72;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHandle(),
          _buildHeader(entries),
          _buildMetricToggle(),
          Expanded(child: _buildBody(entries)),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.stroke,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(List<Map<String, dynamic>> entries) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.exerciseName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textMuted, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        children: List.generate(_metricLabels.length, (i) {
          final active = _metric == i;
          return Padding(
            padding: EdgeInsets.only(right: i < _metricLabels.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _metric = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : AppColors.stroke,
                  ),
                ),
                child: Text(
                  _metricLabels[i],
                  style: TextStyle(
                    color: active ? AppColors.accentText : AppColors.textMuted,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) {
      return _buildEmptyState();
    }

    final values = entries.map(_valueFor).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _LiftLineChart(
              entries: entries,
              values: values,
              unit: _metricUnits[_metric],
            ),
          ),
        ),
        _buildRecentTable(entries),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded, color: AppColors.stroke, size: 56),
          const SizedBox(height: 12),
          Text(
            'Noch keine Daten',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Schließe ein Workout ab, um\ndeine Fortschritte zu sehen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTable(List<Map<String, dynamic>> entries) {
    // Show up to 5 most recent entries.
    final recent = entries.reversed.take(5).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(child: _tableHeader('Datum')),
                _tableHeader('Sets'),
                const SizedBox(width: 16),
                _tableHeader('Wdh'),
                const SizedBox(width: 16),
                _tableHeader('Gewicht'),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.stroke),
          ...recent.map((e) {
            final date = e['date']?.toString() ?? '';
            final parts = date.split('-');
            final label = parts.length == 3 ? '${parts[2]}.${parts[1]}' : date;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ),
                  _tableCell('${e['sets'] ?? '-'}'),
                  const SizedBox(width: 16),
                  _tableCell('${e['reps'] ?? '-'}'),
                  const SizedBox(width: 16),
                  _tableCell(
                    '${(e['weight'] as num?)?.toStringAsFixed(1) ?? '-'} kg',
                    accent: true,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) => Text(
        text,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );

  Widget _tableCell(String text, {bool accent = false}) => Text(
        text,
        style: TextStyle(
          color: accent ? AppColors.accentText : AppColors.textPrimary,
          fontSize: 13,
          fontWeight: accent ? FontWeight.w700 : FontWeight.w500,
        ),
      );
}

// ─── Line Chart ───────────────────────────────────────────────────────────────

class _LiftLineChart extends StatelessWidget {
  const _LiftLineChart({
    required this.entries,
    required this.values,
    required this.unit,
  });

  final List<Map<String, dynamic>> entries;
  final List<double> values;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        entries: entries,
        values: values,
        unit: unit,
        primaryColor: AppColors.primary,
        textColor: AppColors.textMuted,
        gridColor: AppColors.stroke,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.entries,
    required this.values,
    required this.unit,
    required this.primaryColor,
    required this.textColor,
    required this.gridColor,
  });

  final List<Map<String, dynamic>> entries;
  final List<double> values;
  final String unit;
  final Color primaryColor;
  final Color textColor;
  final Color gridColor;

  static const _leftPad = 52.0;
  static const _rightPad = 16.0;
  static const _topPad = 20.0;
  static const _bottomPad = 36.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final chartRect = Rect.fromLTRB(
      _leftPad,
      _topPad,
      size.width - _rightPad,
      size.height - _bottomPad,
    );
    if (chartRect.width <= 0 || chartRect.height <= 0) return;

    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    // Y ticks (4 lines)
    final tickCount = 4;
    final yStep = range / tickCount;
    for (var i = 0; i <= tickCount; i++) {
      final v = minVal + yStep * i;
      final y = chartRect.bottom - (v - minVal) / range * chartRect.height;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        Paint()
          ..color = gridColor.withValues(alpha: 0.4)
          ..strokeWidth = 0.6,
      );
      final label = v >= 1000
          ? '${(v / 1000).toStringAsFixed(1)}k'
          : v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
      _drawText(canvas, label, Offset(_leftPad - 4, y - 6),
          align: TextAlign.right, width: _leftPad - 8);
    }

    // Build point positions
    final pts = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = chartRect.left +
          (values.length == 1 ? 0.5 : i / (values.length - 1)) *
              chartRect.width;
      final y = chartRect.bottom - (values[i] - minVal) / range * chartRect.height;
      pts.add(Offset(x, y));
    }

    // Fill gradient under the line
    final fillPath = Path()..moveTo(pts.first.dx, chartRect.bottom);
    for (final p in pts) { fillPath.lineTo(p.dx, p.dy); }
    fillPath
      ..lineTo(pts.last.dx, chartRect.bottom)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withValues(alpha: 0.22),
            primaryColor.withValues(alpha: 0.0),
          ],
        ).createShader(chartRect),
    );

    // Line
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      // Smooth cubic bezier
      final prev = pts[i - 1];
      final cur = pts[i];
      final cx = (prev.dx + cur.dx) / 2;
      linePath.cubicTo(cx, prev.dy, cx, cur.dy, cur.dx, cur.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots + value labels
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      canvas.drawCircle(
          p,
          5,
          Paint()
            ..color = primaryColor.withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(p, 4, Paint()..color = primaryColor);
      canvas.drawCircle(p, 2, Paint()..color = Colors.black);

      // Value label above dot (only first, last and highest)
      final isFirst = i == 0;
      final isLast = i == pts.length - 1;
      final isMax = values[i] == values.reduce(math.max);
      if (isFirst || isLast || isMax) {
        final label = values[i] >= 1000
            ? '${(values[i] / 1000).toStringAsFixed(1)}k'
            : values[i].toStringAsFixed(values[i] % 1 == 0 ? 0 : 1);
        _drawText(
          canvas,
          label,
          Offset(p.dx - 20, p.dy - 18),
          width: 40,
          align: TextAlign.center,
          color: primaryColor,
          bold: true,
        );
      }
    }

    // X axis labels (dates)
    final step = values.length <= 7 ? 1 : (values.length / 6).ceil();
    for (var i = 0; i < pts.length; i += step) {
      if (i >= entries.length) break;
      final date = entries[i]['date']?.toString() ?? '';
      final parts = date.split('-');
      final label = parts.length == 3 ? '${parts[2]}.${parts[1]}' : date;
      _drawText(
        canvas,
        label,
        Offset(pts[i].dx - 18, chartRect.bottom + 4),
        width: 36,
        align: TextAlign.center,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    double width = 60,
    TextAlign align = TextAlign.left,
    Color? color,
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color ?? textColor,
          fontSize: 10,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.values != values || old.unit != unit;
}
