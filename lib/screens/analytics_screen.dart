import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header_logo.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  static const String _fontFamily = 'Roboto';

  String _monthLabel(DateTime date, BuildContext context) {
    final l10n = context.l10n;
    final months = [
      l10n.month_january,
      l10n.month_february,
      l10n.month_march,
      l10n.month_april,
      l10n.month_may,
      l10n.month_june,
      l10n.month_july,
      l10n.month_august,
      l10n.month_september,
      l10n.month_october,
      l10n.month_november,
      l10n.month_december,
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  Future<void> _editWeight(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: ProgressStore.currentWeightKg?.toStringAsFixed(1) ?? '',
    );
    final saved = await showDialog<double?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            l10n.profile_updateWeight,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: _fontFamily,
            ),
            decoration: InputDecoration(
              labelText: l10n.profile_weightKgLabel,
              labelStyle: TextStyle(
                color: AppColors.textMuted,
                fontFamily: _fontFamily,
              ),
              hintText: l10n.profile_weightHint,
              hintStyle: TextStyle(
                color: AppColors.textMuted,
                fontFamily: _fontFamily,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(
                l10n.common_cancel,
                style: const TextStyle(fontFamily: _fontFamily),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.actionBackground,
                foregroundColor: AppColors.onAction,
              ),
              onPressed: () {
                final raw = controller.text.trim().replaceAll(',', '.');
                final value = double.tryParse(raw);
                if (value == null || value <= 0) return;
                Navigator.of(context).pop(value);
              },
              child: Text(
                l10n.common_save,
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (saved != null) {
      await ProgressStore.setWeightForToday(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final days = _daysInMonth(now.year, now.month);

    return SafeArea(
      child: ValueListenableBuilder(
        valueListenable: ProgressStore.listenable(),
        builder: (context, tick, child) {
          final currentWeight = ProgressStore.currentWeightKg;
          final entries = ProgressStore.weightEntries;
          final completedDays = ProgressStore.completedWorkoutDaysForMonth(
            year: now.year,
            month: now.month,
          ).map((d) => d.day).toSet();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppHeaderLogo(),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        _monthLabel(now, context),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontFamily: _fontFamily,
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: AppColors.surfaceDecoration(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${ProgressStore.workoutStreakDays} ${l10n.achievements_streaks}',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: _fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var d = 1; d <= days; d++)
                      _DayDot(filled: completedDays.contains(d)),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text(
                      currentWeight == null
                          ? '-- ${l10n.analytics_unitKg}'
                          : '${currentWeight.toStringAsFixed(1)} ${l10n.analytics_unitKg}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontFamily: _fontFamily,
                              ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.actionBackground,
                        foregroundColor: AppColors.onAction,
                      ),
                      onPressed: () => _editWeight(context),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: AppColors.surfaceDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    height: 180,
                    child: _WeightChart(entries: entries),
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

class _DayDot extends StatelessWidget {
  const _DayDot({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: filled ? AppColors.primary : AppColors.stroke,
          width: 2,
        ),
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.entries});

  final List<Map<String, dynamic>> entries;

  List<_WeightPoint> _parse() {
    final points = <_WeightPoint>[];
    for (final entry in entries) {
      final date = entry['date']?.toString();
      final recordedAtRaw = entry['recordedAt']?.toString();
      final weightRaw = entry['weight'];
      if (date == null) continue;
      final recordedAt =
          DateTime.tryParse(recordedAtRaw ?? '') ?? _parseDate(date);
      if (recordedAt == null) continue;
      final weight = weightRaw is num
          ? weightRaw.toDouble()
          : double.tryParse(weightRaw.toString());
      if (weight == null) continue;
      points.add(_WeightPoint(recordedAt, weight));
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  DateTime? _parseDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  @override
  Widget build(BuildContext context) {
    final points = _parse();
    if (points.length < 2) {
      return Center(
        child: Text(
          context.l10n.analytics_addWeightHint,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
                color: AppColors.textMuted,
                fontFamily: AnalyticsScreen._fontFamily,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return CustomPaint(
      painter: _WeightChartPainter(points: points),
    );
  }
}

class _WeightPoint {
  const _WeightPoint(this.date, this.weightKg);

  final DateTime date;
  final double weightKg;
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter({required this.points});

  final List<_WeightPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const leftGutter = 42.0;
    const bottomGutter = 26.0;
    const topPadding = 10.0;
    const rightPadding = 10.0;
    final w = size.width - leftGutter - rightPadding;
    final h = size.height - topPadding - bottomGutter;
    if (w <= 0 || h <= 0) return;

    double minW = points.first.weightKg;
    double maxW = points.first.weightKg;
    for (final p in points) {
      if (p.weightKg < minW) minW = p.weightKg;
      if (p.weightKg > maxW) maxW = p.weightKg;
    }
    final range = (maxW - minW).abs();
    final paddedRange = range < 0.5 ? 0.5 : range;
    final minY = minW - paddedRange * 0.15;
    final maxY = maxW + paddedRange * 0.15;

    final chartLeft = leftGutter;
    final chartTop = topPadding;
    final chartBottom = topPadding + h;
    final chartRight = leftGutter + w;

    final linePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = AppColors.stroke.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = AppColors.stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final labelStyle = TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
      fontFamily: 'Roboto',
    );

    final yAxisValues = [maxW, (maxW + minW) / 2, minW];
    for (final value in yAxisValues) {
      final t = (value - minY) / (maxY - minY);
      final y = chartTop + (1 - t) * h;
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      final text = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(1),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftGutter - 8);
      text.paint(canvas, Offset(chartLeft - text.width - 8, y - text.height / 2));
    }

    canvas.drawLine(
      Offset(chartLeft, chartTop),
      Offset(chartLeft, chartBottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(chartLeft, chartBottom),
      Offset(chartRight, chartBottom),
      axisPaint,
    );

    Offset toPoint(int index) {
      final p = points[index];
      final x = points.length == 1
          ? chartLeft + w / 2
          : chartLeft + (index / (points.length - 1)) * w;
      final t = (p.weightKg - minY) / (maxY - minY);
      final y = chartTop + (1 - t) * h;
      return Offset(x, y);
    }

    final path = Path()..moveTo(toPoint(0).dx, toPoint(0).dy);
    for (var i = 1; i < points.length; i++) {
      final pt = toPoint(i);
      path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(path, linePaint);

    for (var i = 0; i < points.length; i++) {
      final pt = toPoint(i);
      canvas.drawCircle(pt, 4.5, dotPaint);
      final text = TextPainter(
        text: TextSpan(
          text: _timeLabel(points[i].date),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: 36);
      final dx = (pt.dx - text.width / 2).clamp(chartLeft, chartRight - text.width);
      text.paint(canvas, Offset(dx, chartBottom + 6));
    }
  }

  String _timeLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month';
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    if (oldDelegate.points.length != points.length) return true;
    for (var i = 0; i < points.length; i++) {
      if (oldDelegate.points[i].date != points[i].date) return true;
      if (oldDelegate.points[i].weightKg != points[i].weightKg) return true;
    }
    return false;
  }
}
