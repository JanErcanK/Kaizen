import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../services/health_sleep_service.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';

class ProfileSleepCard extends StatefulWidget {
  const ProfileSleepCard({super.key});

  @override
  State<ProfileSleepCard> createState() => _ProfileSleepCardState();
}

class _ProfileSleepCardState extends State<ProfileSleepCard> {
  bool _syncing = false;
  String? _hint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshIfNeeded());
  }

  Future<void> _refreshIfNeeded() async {
    if (!HealthSleepService.isSupported) {
      setState(() {
        _hint = context.l10n.sleep_unavailableDevice;
      });
      return;
    }
    final result = await HealthSleepService.refreshLastNightSleepIfStale();
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() => _hint = null);
      return;
    }
    if (ProgressStore.lastNightSleepMinutes == null) {
      setState(() {
        _hint = result.message ?? context.l10n.sleep_connectHint;
      });
    }
  }

  Future<void> _connectOrRefresh() async {
    setState(() {
      _syncing = true;
      _hint = null;
    });
    final result = await HealthSleepService.refreshLastNightSleep();
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _syncing = false;
      if (!result.isSuccess) {
        _hint = result.message ?? l10n.sleep_loadFailed;
      }
    });
    if (result.isSuccess && mounted) {
      final duration = _formatDuration(l10n, result.minutes ?? 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sleep_loadedLastNight(duration))),
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

  String _formatDuration(AppLocalizations l10n, int minutes) {
    if (minutes <= 0) return '--';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return l10n.sleep_durationHoursMinutes(hours, mins);
    }
    if (hours > 0) return l10n.sleep_durationHours(hours);
    return l10n.sleep_durationMinutes(mins);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final supported = HealthSleepService.isSupported;

    return ValueListenableBuilder<int>(
      valueListenable: ProgressStore.listenable(),
      builder: (context, _, child) {
        final minutes = ProgressStore.lastNightSleepMinutes;
        final syncedAt = ProgressStore.lastNightSleepSyncedAt;
        final recent = ProgressStore.recentSleepMinutes();
        final maxMinutes = recent.fold<int>(
          0,
          (max, value) => value > max ? value : max,
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profile_sleepLastNight,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          minutes == null
                              ? '--'
                              : _formatDuration(l10n, minutes),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'Roboto',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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
                              minutes == null
                                  ? Icons.link_outlined
                                  : Icons.refresh,
                              size: 16,
                              color: AppColors.primary,
                            ),
                      label: Text(
                        minutes == null
                            ? l10n.steps_connect
                            : l10n.steps_refresh,
                        style: TextStyle(
                          color: AppColors.accentText,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < recent.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: _SleepBar(
                          minutes: recent[i],
                          maxMinutes: maxMinutes > 0 ? maxMinutes : 480,
                          isToday: i == recent.length - 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                supported
                    ? '${_sourceLabel(l10n)} · ${_formatSyncedAt(l10n, syncedAt)}'
                    : l10n.sleep_mobileOnly,
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
      },
    );
  }
}

class _SleepBar extends StatelessWidget {
  const _SleepBar({
    required this.minutes,
    required this.maxMinutes,
    required this.isToday,
  });

  final int minutes;
  final int maxMinutes;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final fraction = minutes <= 0 ? 0.0 : minutes / maxMinutes;
    final height = 8.0 + (48.0 * fraction.clamp(0.0, 1.0));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: minutes <= 0
                ? AppColors.stroke
                : (isToday ? AppColors.primary : AppColors.secondary)
                    .withValues(alpha: isToday ? 1 : 0.65),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

String formatSleepSummary(AppLocalizations l10n, int? minutes) {
  if (minutes == null || minutes <= 0) return l10n.home_statusSleepNone;
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours > 0 && mins > 0) {
    return l10n.home_statusSleepLastNight(hours, mins);
  }
  if (hours > 0) return l10n.home_statusSleepHours(hours);
  return l10n.home_statusSleepMinutes(mins);
}
