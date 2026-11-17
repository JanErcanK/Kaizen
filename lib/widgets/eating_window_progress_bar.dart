import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../services/intermittent_fasting_service.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import 'eating_window_picker_dialog.dart';

/// Full-width eating-window progress strip for the home screen.
///
/// - Red while fasting (time until you may eat)
/// - Orange in the last 30 minutes before the window opens
/// - Green while eating (time left in the window)
class EatingWindowProgressBar extends StatefulWidget {
  const EatingWindowProgressBar({super.key});

  @override
  State<EatingWindowProgressBar> createState() =>
      _EatingWindowProgressBarState();
}

class _EatingWindowProgressBarState extends State<EatingWindowProgressBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
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
      builder: (context, _, child) {
        if (!ProgressStore.fastingHudEnabled) {
          return const SizedBox.shrink();
        }

        final l10n = context.l10n;
        if (!ProgressStore.eatingWindowConfigured) {
          return _BarShell(
            accent: AppColors.textMuted,
            progress: 0,
            onTap: _openPicker,
            label: l10n.fasting_windowLabel,
            value: l10n.fasting_configureTap,
          );
        }

        final status = IntermittentFastingService.currentStatus();
        final accent = IntermittentFastingService.phaseColor(status);
        final progress = IntermittentFastingService.phaseProgress(status);
        final isEating = status.phase == FastingPhase.eating;
        final label = isEating
            ? l10n.fasting_untilEatingEnd
            : l10n.fasting_untilEating;
        final value = IntermittentFastingService.formatDuration(
          status.remaining,
          includeSeconds: true,
        );

        return _BarShell(
          accent: accent,
          progress: progress,
          onTap: _openPicker,
          label: label,
          value: value,
        );
      },
    );
  }
}

class _BarShell extends StatelessWidget {
  const _BarShell({
    required this.accent,
    required this.progress,
    required this.onTap,
    required this.label,
    required this.value,
  });

  final Color accent;
  final double progress;
  final VoidCallback onTap;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent.withValues(alpha: 0.92),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      value,
                      style: TextStyle(
                        color: accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 12,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: accent.withValues(alpha: 0.14)),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: clamped,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accent.withValues(alpha: 0.72),
                                accent,
                              ],
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
        ),
      ),
    );
  }
}
