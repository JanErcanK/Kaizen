import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/intermittent_fasting_service.dart';
import '../services/progress_store.dart';
import '../services/training_notification_service.dart';
import '../theme/app_colors.dart';

enum _DragMode { none, left, right, move }

class EatingWindowPickerDialog extends StatefulWidget {
  const EatingWindowPickerDialog({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  State<EatingWindowPickerDialog> createState() =>
      _EatingWindowPickerDialogState();
}

class _EatingWindowPickerDialogState extends State<EatingWindowPickerDialog> {
  static const int _minWindowMinutes = 60;
  static const int _dayMinutes = 24 * 60;

  late int _startMinutes;
  late int _endMinutes;
  late bool _remindersEnabled;
  _DragMode _dragMode = _DragMode.none;

  @override
  void initState() {
    super.initState();
    _startMinutes = ProgressStore.eatingWindowStartMinutes;
    _endMinutes = ProgressStore.eatingWindowEndMinutes;
    _remindersEnabled = ProgressStore.fastingRemindersEnabled;
    if (_endMinutes - _startMinutes < _minWindowMinutes) {
      _endMinutes = math.min(_startMinutes + _minWindowMinutes, _dayMinutes);
    }
  }

  double _xForMinutes(double width, int minutes) {
    return (minutes / _dayMinutes) * width;
  }

  void _onPanStart(DragStartDetails details, double width) {
    final x = details.localPosition.dx;
    final startX = _xForMinutes(width, _startMinutes);
    final endX = _xForMinutes(width, _endMinutes);
    const handleRadius = 18.0;

    if ((x - startX).abs() <= handleRadius) {
      _dragMode = _DragMode.left;
    } else if ((x - endX).abs() <= handleRadius) {
      _dragMode = _DragMode.right;
    } else if (x > startX && x < endX) {
      _dragMode = _DragMode.move;
    } else {
      _dragMode = _DragMode.none;
    }
  }

  void _onPanUpdate(DragUpdateDetails details, double width) {
    if (_dragMode == _DragMode.none) return;
    final deltaMinutes =
        (details.delta.dx / width * _dayMinutes).round();

    setState(() {
      switch (_dragMode) {
        case _DragMode.left:
          final next = (_startMinutes + deltaMinutes)
              .clamp(0, _endMinutes - _minWindowMinutes);
          _startMinutes = next;
        case _DragMode.right:
          final next = (_endMinutes + deltaMinutes)
              .clamp(_startMinutes + _minWindowMinutes, _dayMinutes);
          _endMinutes = next;
        case _DragMode.move:
          final window = _endMinutes - _startMinutes;
          var nextStart = _startMinutes + deltaMinutes;
          var nextEnd = _endMinutes + deltaMinutes;
          if (nextStart < 0) {
            nextStart = 0;
            nextEnd = window;
          }
          if (nextEnd > _dayMinutes) {
            nextEnd = _dayMinutes;
            nextStart = _dayMinutes - window;
          }
          _startMinutes = nextStart;
          _endMinutes = nextEnd;
        case _DragMode.none:
          break;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _dragMode = _DragMode.none;
  }

  Future<void> _save() async {
    final l10n = widget.l10n;
    await ProgressStore.saveEatingWindow(
      startMinutes: _startMinutes,
      endMinutes: _endMinutes,
      remindersEnabled: _remindersEnabled,
    );
    if (_remindersEnabled) {
      await TrainingNotificationService.requestPermission();
    }
    await IntermittentFastingService.syncNotifications(l10n: l10n);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final windowLabel =
        '${IntermittentFastingService.formatMinutesOfDay(_startMinutes)} – ${IntermittentFastingService.formatMinutesOfDay(_endMinutes)}';

    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.fasting_setupTitle,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.fasting_setupSubtitle,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.35,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 18),
            Text(
              windowLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF3DDC84),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                const height = 88.0;
                return GestureDetector(
                  onPanStart: (d) => _onPanStart(d, width),
                  onPanUpdate: (d) => _onPanUpdate(d, width),
                  onPanEnd: _onPanEnd,
                  child: SizedBox(
                    height: height,
                    child: CustomPaint(
                      size: Size(width, height),
                      painter: _EatingWindowTimelinePainter(
                        startMinutes: _startMinutes,
                        endMinutes: _endMinutes,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _timeTick('0'),
                _timeTick('6'),
                _timeTick('12'),
                _timeTick('18'),
                _timeTick('24'),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.fasting_reminders,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto',
                ),
              ),
              subtitle: Text(
                l10n.fasting_remindersSubtitle,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontFamily: 'Roboto',
                ),
              ),
              value: _remindersEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => _remindersEnabled = v),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.actionBackground,
                foregroundColor: AppColors.onAction,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.fasting_save,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeTick(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontFamily: 'Roboto',
      ),
    );
  }
}

class _EatingWindowTimelinePainter extends CustomPainter {
  _EatingWindowTimelinePainter({
    required this.startMinutes,
    required this.endMinutes,
  });

  final int startMinutes;
  final int endMinutes;

  @override
  void paint(Canvas canvas, Size size) {
    const dayMinutes = 24 * 60;
    final trackY = size.height * 0.55;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, trackY - 6, size.width, 12),
      const Radius.circular(6),
    );

    final trackPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF2A2A2E),
          const Color(0xFF3A3A40),
          const Color(0xFF2A2A2E),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(trackRect, trackPaint);

  final startX = (startMinutes / dayMinutes) * size.width;
    final endX = (endMinutes / dayMinutes) * size.width;
    final windowRect = Rect.fromLTRB(
      startX,
      trackY - 18,
      endX,
      trackY + 18,
    );

    final glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF3DDC84).withValues(alpha: 0.25),
          const Color(0xFF3DDC84).withValues(alpha: 0.85),
          const Color(0xFF3DDC84).withValues(alpha: 0.25),
        ],
      ).createShader(windowRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(windowRect, const Radius.circular(14)),
      glowPaint,
    );

    final corePaint = Paint()..color = const Color(0xFF3DDC84);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(startX + 4, trackY - 10, endX - 4, trackY + 10),
        const Radius.circular(10),
      ),
      corePaint,
    );

    final handlePaint = Paint()..color = Colors.white;
    final handleBorder = Paint()
      ..color = const Color(0xFF3DDC84)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (final cx in [startX, endX]) {
      canvas.drawCircle(Offset(cx, trackY), 11, handlePaint);
      canvas.drawCircle(Offset(cx, trackY), 11, handleBorder);
    }

    final curvePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path();
    for (var i = 0; i <= 48; i++) {
      final t = i / 48;
      final x = t * size.width;
      final y = trackY - 28 - math.sin(t * math.pi) * 18;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, curvePaint);
  }

  @override
  bool shouldRepaint(covariant _EatingWindowTimelinePainter oldDelegate) {
    return oldDelegate.startMinutes != startMinutes ||
        oldDelegate.endMinutes != endMinutes;
  }
}
