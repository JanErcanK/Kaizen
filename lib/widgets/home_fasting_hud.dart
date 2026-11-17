import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../services/intermittent_fasting_service.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import 'eating_window_picker_dialog.dart';

class HomeFastingHud extends StatefulWidget {
  const HomeFastingHud({super.key, this.compact = false});

  final bool compact;

  @override
  State<HomeFastingHud> createState() => _HomeFastingHudState();
}

class _HomeFastingHudState extends State<HomeFastingHud> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _openPicker() async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => EatingWindowPickerDialog(l10n: l10n),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ProgressStore.listenable(),
      builder: (context, _, __) {
        if (!ProgressStore.fastingHudEnabled) {
          return const SizedBox.shrink();
        }

        final l10n = context.l10n;
        final configured = ProgressStore.eatingWindowConfigured;
        final status = IntermittentFastingService.currentStatus();

        if (!configured) {
          return _FastingHudShell(
            accent: AppColors.textMuted,
            onTap: _openPicker,
            horizontalPadding: widget.compact ? 11 : 8,
            child: widget.compact
                ? _compactContent(configured: false, status: status)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.profile_fastingHud,
                        style: _labelStyle(AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.fasting_configureTap,
                        style: _valueStyle(
                          AppColors.textPrimary,
                        ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          );
        }

        final isEating = status.phase == FastingPhase.eating;
        final accent = IntermittentFastingService.phaseColor(status);
        final timeText = IntermittentFastingService.formatDuration(
          status.remaining,
          includeSeconds: false,
        );

        return _FastingHudShell(
          accent: accent,
          onTap: _openPicker,
          horizontalPadding: widget.compact ? 11 : 8,
          child: widget.compact
              ? _compactContent(configured: true, status: status)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.profile_fastingHud, style: _labelStyle(accent)),
                    const SizedBox(height: 2),
                    Text(
                      '${IntermittentFastingService.formatMinutesOfDay(status.startMinutes)}'
                      ' – ${IntermittentFastingService.formatMinutesOfDay(status.endMinutes)}',
                      style: _valueStyle(
                        AppColors.textPrimary,
                      ).copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isEating
                          ? l10n.fasting_untilEatingEnd
                          : l10n.fasting_untilEating,
                      style: _labelStyle(AppColors.textMuted),
                    ),
                    Text(
                      timeText,
                      style: _valueStyle(accent).copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: IntermittentFastingService.phaseProgress(status),
                      minHeight: 4,
                      color: accent,
                      backgroundColor: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _compactContent({
    required bool configured,
    required FastingStatus status,
  }) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startLabel = IntermittentFastingService.formatMinutesOfDay(
      status.startMinutes,
    );
    final endLabel = IntermittentFastingService.formatMinutesOfDay(
      status.endMinutes,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final startX = _HomeFastingTimelinePainter.xForMinutes(
          width,
          status.startMinutes,
        );
        final endX = _HomeFastingTimelinePainter.xForMinutes(
          width,
          status.endMinutes,
        );
        final labelsAreClose = (startX - endX).abs() < 42;

        double labelLeft(double x) => (x - 19).clamp(0.0, width - 38);
        final startLabelTop = startX < 38 ? 10.0 : 0.0;
        final endLabelTop = labelsAreClose || width - endX < 38 ? 10.0 : 0.0;

        return SizedBox(
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: 38,
                child: _timeTick('05:00', color: AppColors.textMuted),
              ),
              Positioned(
                right: 0,
                top: 0,
                width: 38,
                child: _timeTick('24:00', color: AppColors.textMuted),
              ),
              if (configured) ...[
                Positioned(
                  left: labelLeft(startX),
                  top: startLabelTop,
                  width: 38,
                  child: _windowTimeLabel(startLabel),
                ),
                Positioned(
                  left: labelLeft(endX),
                  top: endLabelTop,
                  width: 38,
                  child: _windowTimeLabel(endLabel),
                ),
              ],
              Positioned(
                left: 0,
                right: 0,
                top: 20,
                height: 16,
                child: CustomPaint(
                  painter: _HomeFastingTimelinePainter(
                    startMinutes: status.startMinutes,
                    endMinutes: status.endMinutes,
                    currentMinutes: currentMinutes,
                    trackColor: ProgressStore.useLightTheme
                        ? const Color(0xFFF7E7EA)
                        : AppColors.stroke,
                    isEating: status.phase == FastingPhase.eating,
                    configured: configured,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _windowTimeLabel(String value) {
    return Text(
      value,
      textAlign: TextAlign.center,
      maxLines: 1,
      style: TextStyle(
        color: AppColors.accentText,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        fontFamily: 'Roboto',
        height: 1,
      ),
    );
  }

  Widget _timeTick(String label, {required Color color}) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        fontFamily: 'Roboto',
        height: 1,
      ),
    );
  }

  TextStyle _labelStyle(Color accent) {
    return TextStyle(
      color: Color.alphaBlend(
        accent.withValues(alpha: 0.08),
        AppColors.textMuted,
      ),
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      fontFamily: 'Roboto',
    );
  }

  TextStyle _valueStyle(Color accent) {
    return TextStyle(
      color: accent.withValues(alpha: 0.92),
      fontSize: 22,
      fontWeight: FontWeight.w800,
      fontFamily: 'Roboto',
      height: 1.05,
    );
  }
}

class _HomeFastingTimelinePainter extends CustomPainter {
  const _HomeFastingTimelinePainter({
    required this.startMinutes,
    required this.endMinutes,
    required this.currentMinutes,
    required this.trackColor,
    required this.isEating,
    required this.configured,
  });

  static const int _visibleStart = 5 * 60;
  static const int _visibleEnd = 24 * 60;
  final Color trackColor;
  static const Color _eatingColor = Color(0xFF62B77C);

  final int startMinutes;
  final int endMinutes;
  final int currentMinutes;
  final bool isEating;
  final bool configured;

  static double xForMinutes(double width, int minutes) {
    final clipped = minutes.clamp(_visibleStart, _visibleEnd);
    return ((clipped - _visibleStart) / (_visibleEnd - _visibleStart)) * width;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    const trackHeight = 8.0;
    final trackY = size.height / 2;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, trackY - trackHeight / 2, size.width, trackHeight),
      const Radius.circular(8),
    );
    canvas.drawRRect(track, Paint()..color = trackColor);

    void drawEatingSegment(int start, int end) {
      final clippedStart = math.max(start, _visibleStart).toInt();
      final clippedEnd = math.min(end, _visibleEnd).toInt();
      if (clippedEnd <= clippedStart) return;
      final left = xForMinutes(size.width, clippedStart);
      final right = xForMinutes(size.width, clippedEnd);
      final rect = Rect.fromLTRB(
        left,
        trackY - trackHeight / 2,
        right,
        trackY + trackHeight / 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = _eatingColor,
      );
    }

    if (configured) {
      if (endMinutes >= startMinutes) {
        drawEatingSegment(startMinutes, endMinutes);
      } else {
        drawEatingSegment(startMinutes, _visibleEnd);
        drawEatingSegment(0, endMinutes);
      }
    }

    if (configured) {
      for (final minute in [startMinutes, endMinutes]) {
        final x = xForMinutes(size.width, minute);
        canvas.drawLine(
          Offset(x, trackY - 6),
          Offset(x, trackY + 6),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.95)
            ..strokeWidth = 1.5,
        );
      }
    }

    final dotX = xForMinutes(size.width, currentMinutes);
    final dotColor = isEating ? _eatingColor : const Color(0xFFE1A1AB);
    canvas.drawCircle(
      Offset(dotX, trackY),
      10,
      Paint()..color = dotColor.withValues(alpha: 0.22),
    );
    canvas.drawCircle(Offset(dotX, trackY), 8, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(dotX, trackY), 6, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(covariant _HomeFastingTimelinePainter oldDelegate) =>
      oldDelegate.trackColor != trackColor ||
      oldDelegate.startMinutes != startMinutes ||
      oldDelegate.endMinutes != endMinutes ||
      oldDelegate.currentMinutes != currentMinutes ||
      oldDelegate.isEating != isEating ||
      oldDelegate.configured != configured;
}

class _FastingHudShell extends StatelessWidget {
  const _FastingHudShell({
    required this.accent,
    required this.onTap,
    required this.child,
    required this.horizontalPadding,
  });

  final Color accent;
  final VoidCallback onTap;
  final Widget child;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            2,
            horizontalPadding,
            2,
          ),
          child: child,
        ),
      ),
    );
  }
}
