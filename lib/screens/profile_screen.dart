import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../models/training_schedule.dart';
import '../services/progress_store.dart';
import '../data/strength_preset_workouts.dart';
import '../services/achievements_catalog.dart';
import '../services/health_steps_service.dart';
import '../services/launcher_icon_service.dart';
import '../widgets/app_back_button.dart';
import '../services/training_notification_service.dart';
import '../services/workout_tts_service.dart';
import '../theme/app_colors.dart';
import '../widgets/weekly_training_schedule_editor.dart';
import '../navigation/app_tab_navigation.dart';
import '../widgets/daily_nutrients_panel.dart';
import '../widgets/profile_health_card.dart';
import '../widgets/sources_licenses_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'profile_gallery_screen.dart';
import 'achievements_screen.dart';
import 'social/friends_connect_screen.dart';
import 'social/inbox_screen.dart';
import '../services/social/social_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onStartTour, this.tourKeys = const {}});

  final VoidCallback? onStartTour;
  final Map<String, GlobalKey> tourKeys;

  static const String _fontFamily = 'Roboto';

  Future<void> _editWeight(BuildContext context) async {
    var weightText = ProgressStore.currentWeightKg?.toStringAsFixed(1) ?? '';
    final saved = await showDialog<double?>(
      context: context,
      builder: (context) {
        final dialogL10n = context.l10n;
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            dialogL10n.profile_updateWeight,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextFormField(
            initialValue: weightText,
            onChanged: (value) => weightText = value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: _fontFamily,
            ),
            decoration: InputDecoration(
              labelText: dialogL10n.profile_weightKgLabel,
              labelStyle: TextStyle(
                color: AppColors.textMuted,
                fontFamily: _fontFamily,
              ),
              hintText: dialogL10n.profile_weightHint,
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
                dialogL10n.common_cancel,
                style: TextStyle(fontFamily: _fontFamily),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.actionBackground,
                foregroundColor: AppColors.onAction,
              ),
              onPressed: () {
                final raw = weightText.trim().replaceAll(',', '.');
                final value = double.tryParse(raw);
                if (value == null || !value.isFinite || value <= 0) return;
                Navigator.of(context).pop(value);
              },
              child: Text(
                dialogL10n.common_save,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (saved != null) {
      await ProgressStore.setWeightForToday(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return SafeArea(
      child: ValueListenableBuilder<int>(
        valueListenable: ProgressStore.listenable(),
        builder: (context, _, child) {
          final metrics = _NutritionMetrics.fromStore();
          return _ProfileScrollHost(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: Row(
                    children: [
                      const Spacer(),
                      ValueListenableBuilder<int>(
                        valueListenable: SocialService.instance.listenable,
                        builder: (context, _, __) {
                          final pending =
                              SocialService.instance.pendingInboxCount;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const InboxScreen(),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.inbox_outlined,
                                  color: AppColors.textPrimary,
                                  size: 20,
                                ),
                                tooltip: l10n.social_inboxTitle,
                              ),
                              if (pending > 0)
                                Positioned(
                                  right: 3,
                                  top: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.actionBackground,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      pending > 9 ? '9+' : '$pending',
                                      style: TextStyle(
                                        color: AppColors.onAction,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.08,
                          ),
                        ),
                        onPressed: () => _openSettings(context),
                        icon: Icon(
                          Icons.settings_outlined,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        tooltip: l10n.profile_settingsTooltip,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: tourKeys['leveling'],
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                    decoration: AppColors.surfaceDecoration(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: _ProfileHeader(
                      metrics: metrics,
                      metabolicKey: tourKeys['metabolic'],
                      onEditAvatar: () => _editAvatar(context),
                      summary: l10n.profile_biometricSummary(
                        _displayCm(ProgressStore.profileHeightCm),
                        _displayKg(ProgressStore.currentWeightKg, l10n),
                        ProgressStore.profileAge?.toString() ?? '--',
                        _genderLabel(l10n, ProgressStore.profileGender),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: tourKeys['calendar'],
                  child: _WorkoutCalendarCard(),
                ),
                const SizedBox(height: 20),
                KeyedSubtree(
                  key: tourKeys['gallery'],
                  child: _GalleryEntry(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProfileGalleryScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: tourKeys['health'],
                  child: const ProfileHealthCard(),
                ),
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: tourKeys['weight'],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        key: const ValueKey('profile-add-weight-row'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ProgressStore.currentWeightKg == null
                                  ? '-- ${l10n.analytics_unitKg}'
                                  : '${ProgressStore.currentWeightKg!.toStringAsFixed(1)} ${l10n.analytics_unitKg}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: _fontFamily,
                                  ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filled(
                              key: const ValueKey('profile-add-weight'),
                              tooltip: ProgressStore.useGerman
                                  ? 'Gewicht hinzufügen'
                                  : 'Add weight',
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.actionBackground,
                                foregroundColor: AppColors.onAction,
                              ),
                              onPressed: () => _editWeight(context),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    key: const ValueKey('profile-edit'),
                    onPressed: () => _showEditDialog(context),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      l10n.profile_editProfile,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.textMuted,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.stroke),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 640),
            child: ValueListenableBuilder<int>(
              valueListenable: ProgressStore.listenable(),
              builder: (context, tick, child) {
                final l10n = context.l10n;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 48),
                          Expanded(
                            child: Text(
                              l10n.profile_settings,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: Icon(Icons.close, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── SECTION 1: Feature toggles ──────────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                                child: Text(
                                  l10n.profile_settingsSectionFeatures,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Roboto',
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              Material(
                                color: Color.alphaBlend(
                                  AppColors.primary.withValues(alpha: 0.035),
                                  AppColors.card,
                                ),
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: AppColors.textMuted.withValues(
                                      alpha: 0.45,
                                    ),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Intervallfasten
                                    SwitchListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      title: Text(
                                        l10n.profile_fastingHud,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        l10n.profile_fastingHudSubtitle,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      value: ProgressStore.fastingHudEnabled,
                                      activeThumbColor: AppColors.primary,
                                      onChanged: (enabled) async {
                                        await ProgressStore.setFastingHudEnabled(
                                          enabled,
                                        );
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      color: AppColors.stroke.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    // Wasser tracken
                                    SwitchListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      title: Text(
                                        l10n.profile_waterTracking,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        l10n.profile_waterTrackingSubtitle,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      value: ProgressStore.waterTrackingEnabled,
                                      activeThumbColor: AppColors.primary,
                                      onChanged: (enabled) async {
                                        await ProgressStore.setWaterTrackingEnabled(
                                          enabled,
                                        );
                                      },
                                    ),
                                    if (ProgressStore.waterTrackingEnabled) ...[
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          4,
                                          16,
                                          0,
                                        ),
                                        child: Text(
                                          l10n.profile_waterGoal,
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          2,
                                          16,
                                          0,
                                        ),
                                        child: Text(
                                          l10n.profile_waterGoalHint(
                                            (ProgressStore
                                                        .recommendedWaterGoalMl /
                                                    1000)
                                                .toStringAsFixed(1),
                                          ),
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                            fontFamily: 'Roboto',
                                          ),
                                        ),
                                      ),
                                      Slider(
                                        value: ProgressStore.waterGoalMl
                                            .toDouble()
                                            .clamp(1000, 5000),
                                        min: 1000,
                                        max: 5000,
                                        divisions: 16,
                                        label:
                                            '${(ProgressStore.waterGoalMl / 1000).toStringAsFixed(2)} L',
                                        activeColor: AppColors.primary,
                                        onChanged: (v) {
                                          unawaited(
                                            ProgressStore.setWaterGoalMl(
                                              v.round(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                    Divider(
                                      height: 1,
                                      color: AppColors.stroke.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    // One connection for all health categories.
                                    ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      leading: Icon(
                                        Icons.bedtime_outlined,
                                        color: AppColors.primary,
                                      ),
                                      title: Text(
                                        ProgressStore.useGerman
                                            ? 'Gesundheitsdaten'
                                            : 'Health data',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        ProgressStore.useGerman
                                            ? 'Apple Health / Health Connect verbinden'
                                            : 'Connect Apple Health / Health Connect',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      onTap: () async {
                                        Navigator.of(ctx).pop();
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => Scaffold(
                                              appBar: AppBar(
                                                leading: const AppBackButton(),
                                                leadingWidth: 48,
                                                title: Text(
                                                  ProgressStore.useGerman
                                                      ? 'Gesundheitsdaten'
                                                      : 'Health data',
                                                ),
                                              ),
                                              body: const SafeArea(
                                                child: SingleChildScrollView(
                                                  padding: EdgeInsets.all(16),
                                                  child: ProfileHealthCard(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      color: AppColors.stroke.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    // Schritte
                                    ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      leading: Icon(
                                        Icons.directions_walk_outlined,
                                        color: AppColors.primary,
                                      ),
                                      title: Text(
                                        l10n.profile_syncSteps,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        l10n.profile_syncStepsSubtitle,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      onTap: () async {
                                        Navigator.of(ctx).pop();
                                        final result =
                                            await HealthStepsService.refreshTodaySteps();
                                        if (!context.mounted) return;
                                        final message = result.isSuccess
                                            ? l10n.steps_loadedToday(
                                                result.steps ?? 0,
                                              )
                                            : (result.message ??
                                                  l10n.steps_loadFailed);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(message)),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── SECTION 2: App & System ─────────────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                                child: Text(
                                  l10n.profile_settingsSectionSystem,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Roboto',
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              Material(
                                color: Color.alphaBlend(
                                  AppColors.primary.withValues(alpha: 0.035),
                                  AppColors.card,
                                ),
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: AppColors.textMuted.withValues(
                                      alpha: 0.45,
                                    ),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    if (Platform.isAndroid) ...[
                                      ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                        leading: Icon(
                                          Icons.add_to_home_screen_rounded,
                                          color: AppColors.textMuted,
                                        ),
                                        title: Text(l10n.profile_pinLevelIcon),
                                        subtitle: Text(l10n.profile_pinLevelIconHint),
                                        onTap: () async {
                                          final requested =
                                              await LauncherIconService.pinLevelIcon();
                                          if (requested || !context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(l10n.profile_pinLevelIconUnavailable)),
                                          );
                                        },
                                      ),
                                      Divider(height: 1, color: AppColors.stroke.withValues(alpha: 0.4)),
                                    ],
                                    ListTile(
                                      key: const Key(
                                        'settings-sources-licenses',
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      leading: Icon(
                                        Icons.library_books_outlined,
                                        color: AppColors.textMuted,
                                      ),
                                      title: Text(
                                        l10n.localeName.startsWith('de')
                                            ? 'Quellen & Lizenzen'
                                            : 'Sources & licenses',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        l10n.localeName.startsWith('de')
                                            ? 'Anatomie, Gesundheitstipps und Software'
                                            : 'Anatomy, health tips and software',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.chevron_right,
                                        color: AppColors.textMuted,
                                      ),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const SourcesLicensesScreen(),
                                        ),
                                      ),
                                    ),
                                    Divider(
                                      height: 1,
                                      color: AppColors.stroke.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    // Helles Design
                                    SwitchListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      title: Text(
                                        l10n.profile_lightMode,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        l10n.profile_lightModeSubtitle,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      value: ProgressStore.useLightTheme,
                                      activeThumbColor: AppColors.primary,
                                      onChanged: (v) {
                                        unawaited(
                                          ProgressStore.setUseLightTheme(v),
                                        );
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      color: AppColors.stroke.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    // Sprache
                                    SwitchListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      title: Text(
                                        l10n.settings_languageTitle,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        l10n.settings_languageSubtitle,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      value: ProgressStore.useGerman,
                                      activeThumbColor: AppColors.primary,
                                      onChanged: (v) {
                                        unawaited(
                                          ProgressStore.setUseGerman(v),
                                        );
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      color: AppColors.stroke.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    // Freunde verbinden
                                    ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      leading: Icon(
                                        Icons.group_add_outlined,
                                        color: AppColors.primary,
                                      ),
                                      title: Text(
                                        l10n.social_connectTitle,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        l10n.social_connectSubtitle,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.chevron_right,
                                        color: AppColors.textMuted,
                                      ),
                                      onTap: () {
                                        Navigator.of(ctx).pop();
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const FriendsConnectScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      color: AppColors.stroke.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    // App Tour
                                    ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      leading: Icon(
                                        Icons.explore_outlined,
                                        color: AppColors.primary,
                                      ),
                                      title: Text(
                                        l10n.profile_appTour,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        l10n.profile_appTourSubtitle,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.of(ctx).pop();
                                        onStartTour?.call();
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      color: AppColors.stroke.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    // Workout Stimme
                                    SwitchListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      title: Text(
                                        l10n.profile_workoutVoice,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        l10n.profile_workoutVoiceSubtitle,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      value: ProgressStore.workoutVoiceEnabled,
                                      activeThumbColor: AppColors.primary,
                                      onChanged: (v) {
                                        unawaited(
                                          ProgressStore.setWorkoutVoiceEnabled(
                                            v,
                                          ),
                                        );
                                      },
                                    ),
                                    ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      enabled:
                                          ProgressStore.workoutVoiceEnabled,
                                      title: Text(
                                        l10n.profile_workoutVoiceGenderTitle,
                                        style: TextStyle(
                                          color:
                                              ProgressStore.workoutVoiceEnabled
                                              ? AppColors.textPrimary
                                              : AppColors.textMuted,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        l10n.profile_workoutVoiceGenderSubtitle,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _workoutVoiceGenderLabel(
                                              l10n,
                                              ProgressStore.workoutVoiceGender,
                                            ),
                                            style: TextStyle(
                                              color: AppColors.accentText,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Roboto',
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            color: AppColors.textMuted,
                                          ),
                                        ],
                                      ),
                                      onTap: ProgressStore.workoutVoiceEnabled
                                          ? () => _showWorkoutVoiceGenderPicker(
                                              context,
                                            )
                                          : null,
                                    ),
                                    Divider(
                                      height: 1,
                                      color: AppColors.stroke.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    // Trainings-Erinnerungen
                                    SwitchListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      title: Text(
                                        l10n.profile_trainingReminders,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        l10n.profile_trainingRemindersSubtitle,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      value: ProgressStore
                                          .trainingNotificationsEnabled,
                                      activeThumbColor: AppColors.primary,
                                      onChanged: (enabled) async {
                                        final sheetL10n = context.l10n;
                                        await ProgressStore.setTrainingNotificationsEnabled(
                                          enabled,
                                        );
                                        if (enabled)
                                          await TrainingNotificationService.requestPermission();
                                        await TrainingNotificationService.syncFromStore(
                                          l10n: sheetL10n,
                                        );
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      color: AppColors.stroke.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  static String _workoutVoiceGenderLabel(AppLocalizations l10n, String gender) {
    return switch (gender) {
      'male' => l10n.profile_workoutVoiceMale,
      'system' => l10n.profile_workoutVoiceSystem,
      _ => l10n.profile_workoutVoiceFemale,
    };
  }

  Future<void> _showWorkoutVoiceGenderPicker(BuildContext context) async {
    final l10n = context.l10n;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: ValueListenableBuilder<int>(
              valueListenable: ProgressStore.listenable(),
              builder: (context, _, __) {
                final current = ProgressStore.workoutVoiceGender;
                Widget option(String value, String label) {
                  final selected = current == value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    trailing: selected
                        ? Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () async {
                      await ProgressStore.setWorkoutVoiceGender(value);
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop(value);
                    },
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.stroke,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.profile_workoutVoiceGenderTitle,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    option('female', l10n.profile_workoutVoiceFemale),
                    option('male', l10n.profile_workoutVoiceMale),
                    option('system', l10n.profile_workoutVoiceSystem),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        unawaited(
                          WorkoutTtsService.previewVoice(
                            appLocaleCode: ProgressStore.appLocaleCode,
                            voiceGender: WorkoutTtsService.parseGender(
                              ProgressStore.workoutVoiceGender,
                            ),
                            sampleText: l10n.tts_getReady,
                          ),
                        );
                      },
                      icon: const Icon(Icons.volume_up_outlined),
                      label: Text(l10n.profile_workoutVoicePreview),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    if (selected == null || !context.mounted) return;
  }

  static String _displayKg(double? value, AppLocalizations l10n) {
    if (value == null) return '--';
    final formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$formatted ${l10n.analytics_unitKg}';
  }

  static String _displayCm(double? value) {
    if (value == null) return '--';
    return value == value.roundToDouble()
        ? '${value.toStringAsFixed(0)} cm'
        : '${value.toStringAsFixed(1)} cm';
  }

  static String _genderLabel(AppLocalizations l10n, String? value) {
    return switch (value) {
      'female' => l10n.gender_female,
      'male' => l10n.gender_male,
      _ => '--',
    };
  }

  static String _monthLabel(AppLocalizations l10n, DateTime date) {
    final month = switch (date.month) {
      1 => l10n.month_january,
      2 => l10n.month_february,
      3 => l10n.month_march,
      4 => l10n.month_april,
      5 => l10n.month_may,
      6 => l10n.month_june,
      7 => l10n.month_july,
      8 => l10n.month_august,
      9 => l10n.month_september,
      10 => l10n.month_october,
      11 => l10n.month_november,
      12 => l10n.month_december,
      _ => '',
    };
    return '$month ${date.year}';
  }

  static String _workoutTypeLabel(AppLocalizations l10n, String type) {
    return switch (type) {
      'nine_min' => l10n.calendar_workoutType9min,
      'hercules' => l10n.calendar_workoutTypeHercules,
      'stretch' => l10n.calendar_workoutTypeStretch,
      'gym' => l10n.calendar_workoutTypeGym,
      'calisthenics' => l10n.calendar_workoutTypeCalisthenics,
      'run' => l10n.calendar_workoutTypeRun,
      'legacy' => l10n.calendar_workoutTypeLegacy,
      _ => type,
    };
  }

  static String? _resolveWorkoutEventName(
    AppLocalizations l10n,
    Map<String, dynamic> event,
  ) {
    final stored = event['workoutName']?.toString().trim();
    if (stored != null && stored.isNotEmpty) return stored;

    final workoutId = event['workoutId']?.toString().trim();
    if (workoutId != null && workoutId.isNotEmpty) {
      final gymName = ProgressStore.gymWorkoutById(
        workoutId,
      )?['name']?.toString().trim();
      if (gymName != null && gymName.isNotEmpty) return gymName;

      final caliName = ProgressStore.calisthenicsWorkoutById(
        workoutId,
      )?['name']?.toString().trim();
      if (caliName != null && caliName.isNotEmpty) return caliName;

      if (workoutId.startsWith('gym_') || workoutId.startsWith('cali_')) {
        return presetWorkoutLocalizedName(workoutId, l10n);
      }
    }

    return switch ((event['type'] ?? '').toString()) {
      'nine_min' => l10n.categoryDetail_heading9min,
      'hercules' => l10n.categoryDetail_headingHercules,
      'stretch' => l10n.categoryDetail_headingStretch,
      _ => null,
    };
  }

  static String _workoutEventTitle(
    AppLocalizations l10n,
    Map<String, dynamic> event,
  ) {
    final type = (event['type'] ?? '').toString();
    final typeLabel = _workoutTypeLabel(l10n, type);
    final name = _resolveWorkoutEventName(l10n, event);
    if (name == null || name.isEmpty || name == typeLabel) {
      return typeLabel;
    }
    return '$typeLabel · $name';
  }

  static List<String> _weekdayLabels(AppLocalizations l10n) {
    return [
      l10n.weekday_mon,
      l10n.weekday_tue,
      l10n.weekday_wed,
      l10n.weekday_thu,
      l10n.weekday_fri,
      l10n.weekday_sat,
      l10n.weekday_sun,
    ];
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final rootContext = context;
    final nameController = TextEditingController(
      text: ProgressStore.profileName,
    );
    final ageController = TextEditingController(
      text: ProgressStore.profileAge?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: _rawNumber(ProgressStore.profileHeightCm),
    );
    final weightController = TextEditingController(
      text: _rawNumber(ProgressStore.currentWeightKg),
    );
    final bodyFatController = TextEditingController(
      text: _rawNumber(ProgressStore.profileBodyFatPercent),
    );
    final muscleMassController = TextEditingController(
      text: _rawNumber(ProgressStore.profileMuscleMassKg),
    );
    final boneMassController = TextEditingController(
      text: _rawNumber(ProgressStore.profileBoneMassKg),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _ProfileEditDialog(
          rootContext: rootContext,
          dialogContext: dialogContext,
          nameController: nameController,
          ageController: ageController,
          heightController: heightController,
          weightController: weightController,
          bodyFatController: bodyFatController,
          muscleMassController: muscleMassController,
          boneMassController: boneMassController,
          parseAndValidate: _parseAndValidateProfileValues,
          persist: _persistProfileValues,
        );
      },
    );
  }

  _ValidationResult<_ProfileValues> _parseAndValidateProfileValues(
    AppLocalizations l10n, {
    required String name,
    required String ageText,
    required String heightText,
    required String weightText,
    required String bodyFatText,
    required String muscleMassText,
    required String boneMassText,
    required String gender,
    required String activityLevel,
    required String goal,
  }) {
    final age = _parseInt(ageText);
    final height = _parseDouble(heightText);
    final weight = _parseDouble(weightText);
    final bodyFat = _parseDouble(bodyFatText);
    final muscleMass = _parseDouble(muscleMassText);
    final boneMass = _parseDouble(boneMassText);

    if (name.isEmpty) {
      return _ValidationResult(error: l10n.validation_nameRequired);
    }
    if (age == null) {
      return _ValidationResult(error: l10n.validation_ageRequired);
    }
    if (height == null) {
      return _ValidationResult(error: l10n.validation_heightRequired);
    }
    if (weight == null) {
      return _ValidationResult(error: l10n.validation_weightRequired);
    }
    if (age < 10 || age > 120) {
      return _ValidationResult(error: l10n.validation_ageInvalid);
    }
    if (height < 100 || height > 260) {
      return _ValidationResult(error: l10n.validation_heightInvalid);
    }
    if (weight < 25 || weight > 400) {
      return _ValidationResult(error: l10n.validation_weightInvalid);
    }
    if (bodyFat != null && (bodyFat <= 0 || bodyFat >= 80)) {
      return _ValidationResult(error: l10n.validation_bodyFatInvalid);
    }
    if (muscleMass != null && (muscleMass <= 0 || muscleMass > 200)) {
      return _ValidationResult(error: l10n.validation_muscleMassInvalid);
    }
    if (boneMass != null && (boneMass <= 0 || boneMass > 30)) {
      return _ValidationResult(error: l10n.validation_boneWeightInvalid);
    }

    return _ValidationResult(
      values: _ProfileValues(
        name: name,
        age: age,
        heightCm: height,
        weightKg: weight,
        bodyFatPercent: bodyFat,
        muscleMassKg: muscleMass,
        boneMassKg: boneMass,
        gender: gender,
        activityLevel: activityLevel,
        goal: goal,
      ),
    );
  }

  Future<void> _persistProfileValues(_ProfileValues values) async {
    await ProgressStore.batch(() async {
      await ProgressStore.setProfileName(values.name);
      await ProgressStore.setProfileAge(values.age);
      await ProgressStore.setProfileHeightCm(values.heightCm);
      await ProgressStore.setProfileGender(values.gender);
      await ProgressStore.setProfileBodyFatPercent(values.bodyFatPercent);
      await ProgressStore.setProfileMuscleMassKg(values.muscleMassKg);
      await ProgressStore.setProfileBoneMassKg(values.boneMassKg);
      await ProgressStore.setProfileActivityLevel(values.activityLevel);
      await ProgressStore.setProfileGoal(values.goal);
      if (values.weightKg != null) {
        await ProgressStore.setWeightForToday(values.weightKg!);
      }
    });
  }

  static String _rawNumber(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  static int? _parseInt(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  static double? _parseDouble(String raw) {
    final trimmed = raw.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  Future<void> _editAvatar(BuildContext context) async {
    final l10n = context.l10n;
    if (!(Platform.isAndroid || Platform.isIOS)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.avatar_mobileOnly)));
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) {
        final sheetL10n = context.l10n;
        final hasAvatar = ProgressStore.profileAvatarPath != null;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.textPrimary,
                  ),
                  title: Text(
                    sheetL10n.avatar_takePhoto,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () => Navigator.of(context).pop('camera'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.textPrimary,
                  ),
                  title: Text(
                    sheetL10n.avatar_pickGallery,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () => Navigator.of(context).pop('gallery'),
                ),
                if (hasAvatar)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      sheetL10n.avatar_remove,
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () => Navigator.of(context).pop('remove'),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return;
    if (action == 'remove') {
      final existing = ProgressStore.profileAvatarPath;
      await ProgressStore.setProfileAvatarPath(null);
      if (existing != null) {
        try {
          final file = File(existing);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
      return;
    }

    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = action == 'camera'
          ? await picker.pickImage(source: ImageSource.camera, imageQuality: 85)
          : await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 85,
            );
    } on PlatformException catch (e) {
      if (!context.mounted) return;
      final msg = (e.message ?? e.code).trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.isEmpty
                ? l10n.start_cameraGalleryError
                : l10n.start_cameraGalleryErrorWithDetail(msg),
          ),
        ),
      );
      return;
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.start_cameraGalleryErrorWithDetail('$e'))),
      );
      return;
    }
    if (picked == null) return;

    final savedPath = await _persistAvatarFile(picked);
    if (savedPath == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.avatar_saveFailed)));
      return;
    }
    await ProgressStore.setProfileAvatarPath(savedPath);
  }

  Future<String?> _persistAvatarFile(XFile picked) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final avatarDir = Directory('${dir.path}/Kaizen/avatars');
      if (!avatarDir.existsSync()) {
        avatarDir.createSync(recursive: true);
      }
      final ext = picked.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final target = File('${avatarDir.path}/profile_avatar.$ext');
      await File(picked.path).copy(target.path);
      return target.path;
    } catch (_) {
      return null;
    }
  }
}

class _GalleryEntry extends StatelessWidget {
  const _GalleryEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: AppColors.surfaceDecoration(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.profile_gallery,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled ? 1 : 0.35,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(icon, size: 22, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _WorkoutCalendarCard extends StatefulWidget {
  const _WorkoutCalendarCard();

  @override
  State<_WorkoutCalendarCard> createState() => _WorkoutCalendarCardState();
}

class _WorkoutCalendarCardState extends State<_WorkoutCalendarCard> {
  // Center on "now" and allow swiping back in time.
  static const int _centerPage = 600;
  late final PageController _controller = PageController(
    initialPage: _centerPage,
  );

  DateTime _monthForPage(int page) {
    final now = DateTime.now();
    final delta = page - _centerPage;
    return DateTime(now.year, now.month + delta, 1);
  }

  int _daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  int _leadingBlankDays(DateTime month) {
    // Monday-first calendar: Mon=0 .. Sun=6
    final weekday = DateTime(
      month.year,
      month.month,
      1,
    ).weekday; // Mon=1..Sun=7
    return (weekday - 1) % 7;
  }

  static const double _calendarCrossSpacing = 5;
  static const double _calendarMainSpacing = 5;
  static const double _calendarCellAspectRatio = 0.78;

  int _rowCountForMonth(DateTime month) {
    final days = _daysInMonth(month);
    final leading = _leadingBlankDays(month);
    return (leading + days + 6) ~/ 7;
  }

  /// Height for [rows] week rows; cells scale with card width.
  double _calendarGridHeight(double gridWidth, int rows) {
    final cellWidth = (gridWidth - 6 * _calendarCrossSpacing) / 7;
    final cellHeight = cellWidth / _calendarCellAspectRatio;
    return rows * cellHeight + (rows - 1) * _calendarMainSpacing;
  }

  Color _colorForWorkoutType(String type) {
    return switch (type) {
      'nine_min' => AppColors.secondary,
      'hercules' => AppColors.workout,
      'stretch' => const Color(0xFFB388FF), // matches Home card
      'gym' => AppColors.tertiary,
      'calisthenics' => const Color(0xFF00D1B2), // matches Home card
      'run' => const Color(0xFFFFC857),
      'legacy' => AppColors.textMuted,
      _ => AppColors.textMuted,
    };
  }

  Widget _workoutTypeDot(String type) {
    final color = _colorForWorkoutType(type);
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context, {
    required DateTime day,
    required List<Map<String, dynamic>> dayEvents,
  }) {
    final today = _dateOnly(DateTime.now());
    final dateOnly = _dateOnly(day);
    final isToday = dateOnly == today;
    final isFuture = dateOnly.isAfter(today);
    final hasWorkouts = dayEvents.isNotEmpty;

    final dayNumberColor = isToday
        ? (hasWorkouts ? AppColors.textPrimary : AppColors.primary)
        : isFuture
        ? AppColors.textMuted.withValues(alpha: 0.55)
        : hasWorkouts
        ? AppColors.textPrimary
        : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDayDetails(context, day),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
          decoration: AppColors.calendarDayDecoration(
            context,
            isToday: isToday,
            hasWorkouts: hasWorkouts,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isToday && !hasWorkouts)
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.selectedBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: AppColors.onSelected,
                      fontFamily: ProfileScreen._fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.0,
                    ),
                  ),
                )
              else
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: dayNumberColor,
                    fontFamily: ProfileScreen._fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.0,
                  ),
                ),
              const Spacer(flex: 1),
              if (hasWorkouts)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _workoutMarkersForDay(dayEvents, day),
                )
              else if (isToday)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Keeps day cells compact: 1–2 workouts show type dots; 3+ → one dot + "+N".
  Widget _workoutMarkersForDay(
    List<Map<String, dynamic>> dayEvents,
    DateTime day,
  ) {
    if (dayEvents.isEmpty) return const SizedBox.shrink();

    final types = <String>[];
    for (final e in dayEvents) {
      final type = (e['type'] ?? '').toString();
      if (type.isNotEmpty) types.add(type);
    }
    if (types.isEmpty) return const SizedBox.shrink();

    final count = dayEvents.length;
    if (count >= 3) {
      final seed = day.year * 10000 + day.month * 100 + day.day;
      final picked = types[seed % types.length];
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _workoutTypeDot(picked),
          const SizedBox(width: 3),
          Text(
            '+${count - 1}',
            style: TextStyle(
              color: AppColors.textMuted,
              fontFamily: ProfileScreen._fontFamily,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      );
    }

    final uniqueTypes = types.toSet().toList();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 3,
      runSpacing: 2,
      children: [for (final t in uniqueTypes) _workoutTypeDot(t)],
    );
  }

  String _labelForWorkoutType(AppLocalizations l10n, String type) {
    return ProfileScreen._workoutTypeLabel(l10n, type);
  }

  String _monthLabel(AppLocalizations l10n, DateTime date) {
    return ProfileScreen._monthLabel(l10n, date);
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Map<DateTime, List<Map<String, dynamic>>> _eventsByDayInMonth(
    DateTime month,
  ) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final map = <DateTime, List<Map<String, dynamic>>>{};
    for (final e in ProgressStore.workoutEvents) {
      final at = DateTime.tryParse(e['recordedAt']?.toString() ?? '');
      if (at == null) continue;
      if (at.isBefore(start) || !at.isBefore(end)) continue;
      final day = _dateOnly(at);
      (map[day] ??= <Map<String, dynamic>>[]).add(e);
    }
    for (
      var day = start;
      day.isBefore(end);
      day = day.add(const Duration(days: 1))
    ) {
      final dateOnly = _dateOnly(day);
      if ((map[dateOnly] ?? const []).isNotEmpty) continue;
      if (ProgressStore.isWorkoutCompletedOn(dateOnly)) {
        map[dateOnly] = ProgressStore.workoutSessionsForDay(dateOnly);
      }
    }
    for (final list in map.values) {
      list.sort(
        (a, b) => (a['recordedAt'] ?? '').toString().compareTo(
          (b['recordedAt'] ?? '').toString(),
        ),
      );
    }
    return map;
  }

  Future<void> _open30DaySummary(BuildContext context) async {
    const days = 30;
    final avg = ProgressStore.foodAverageDailyNutrientsLastDays(days);
    final events = ProgressStore.workoutEventsLastDays(days);
    var totalWorkoutBurn = 0;
    for (final e in events) {
      totalWorkoutBurn += ProgressStore.workoutEventBurnKcal(e);
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final l10n = ctx.l10n;
        return AlertDialog(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.transparent,
          title: Text(
            l10n.calendar_30DaySummary,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: ProfileScreen._fontFamily,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 400,
            height: MediaQuery.sizeOf(ctx).height * 0.72,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.calendar_nutritionAvg,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: ProfileScreen._fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DailyNutrientsPanel(totals: avg),
                  const SizedBox(height: 18),
                  Text(
                    l10n.calendar_workouts,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: ProfileScreen._fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.calendar_workoutsInLastDays(events.length, days) +
                        (totalWorkoutBurn > 0
                            ? l10n.calendar_kcalBurnedSuffix(totalWorkoutBurn)
                            : ''),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: ProfileScreen._fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (events.isEmpty)
                    Text(
                      l10n.calendar_noWorkoutsPeriod,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontFamily: ProfileScreen._fontFamily,
                        fontSize: 12,
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (var index = 0; index < events.length; index++) ...[
                          Builder(
                            builder: (_) {
                              final e = events[index];
                              final at = DateTime.tryParse(
                                e['recordedAt']?.toString() ?? '',
                              );
                              final type = (e['type'] ?? '').toString();
                              final workoutTitle =
                                  ProfileScreen._workoutEventTitle(l10n, e);
                              final burnKcal =
                                  ProgressStore.workoutEventBurnKcal(e);
                              final dateLabel = at == null
                                  ? '--.--.----'
                                  : '${_two(at.day)}.${_two(at.month)}.${at.year}';
                              final timeLabel = at == null
                                  ? '--:--'
                                  : '${_two(at.hour)}:${_two(at.minute)}';
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _colorForWorkoutType(type),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '$workoutTitle  •  $dateLabel  •  $timeLabel'
                                        '${burnKcal > 0 ? '  •  $burnKcal ${l10n.food_macroKcal}' : ''}',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: ProfileScreen._fontFamily,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (index < events.length - 1)
                            Divider(color: AppColors.stroke, height: 1),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                l10n.common_ok,
                style: TextStyle(
                  color: AppColors.accentText,
                  fontFamily: ProfileScreen._fontFamily,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openDayDetails(BuildContext context, DateTime day) async {
    final today = _dateOnly(DateTime.now());
    if (_dateOnly(day) == today && ProgressStore.stepsForDay(day) == null) {
      await HealthStepsService.refreshTodaySteps(
        requestPermissionIfNeeded: false,
      );
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _DayDetailsDialog(
        initialDay: _dateOnly(day),
        colorForWorkoutType: _colorForWorkoutType,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<int>(
      valueListenable: ProgressStore.listenable(),
      builder: (context, _, __) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: AppColors.themedCardDecoration(
            context,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final page =
                      (_controller.hasClients && _controller.page != null)
                      ? _controller.page!.round()
                      : _centerPage;
                  final month = _monthForPage(page);
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          _monthLabel(l10n, month),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontFamily: ProfileScreen._fontFamily,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      _CalendarNavButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () {
                          if (!_controller.hasClients) return;
                          _controller.previousPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      _CalendarNavButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: page >= _centerPage
                            ? null
                            : () {
                                if (!_controller.hasClients) return;
                                _controller.nextPage(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildCalendarBody(context, l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarBody(BuildContext context, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final page = _controller.hasClients
                ? (_controller.page ?? _centerPage.toDouble()).round()
                : _centerPage;
            final visibleMonth = _monthForPage(page);
            final visibleRows = _rowCountForMonth(visibleMonth);
            final gridHeight = _calendarGridHeight(gridWidth, visibleRows);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (final label in ProfileScreen._weekdayLabels(l10n))
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.75),
                            fontFamily: ProfileScreen._fontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: gridHeight,
                    child: PageView.builder(
                      controller: _controller,
                      itemBuilder: (context, page) {
                        final month = _monthForPage(page);
                        final days = _daysInMonth(month);
                        final leading = _leadingBlankDays(month);
                        final rowCount = _rowCountForMonth(month);
                        final eventsByDay = _eventsByDayInMonth(month);
                        final totalCells = rowCount * 7;

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: _calendarMainSpacing,
                                crossAxisSpacing: _calendarCrossSpacing,
                                childAspectRatio: _calendarCellAspectRatio,
                              ),
                          itemCount: totalCells,
                          itemBuilder: (context, index) {
                            final dayNumber = index - leading + 1;
                            if (dayNumber < 1 || dayNumber > days) {
                              return const SizedBox.shrink();
                            }
                            final day = DateTime(
                              month.year,
                              month.month,
                              dayNumber,
                            );
                            final dayEvents =
                                eventsByDay[_dateOnly(day)] ?? const [];

                            return _buildDayCell(
                              context,
                              day: day,
                              dayEvents: dayEvents,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    InkWell(
                      onTap: () => _open30DaySummary(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.stroke),
                        ),
                        child: Icon(
                          Icons.list_alt_outlined,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DayDetailsDialog extends StatefulWidget {
  const _DayDetailsDialog({
    required this.initialDay,
    required this.colorForWorkoutType,
  });

  final DateTime initialDay;
  final Color Function(String type) colorForWorkoutType;

  @override
  State<_DayDetailsDialog> createState() => _DayDetailsDialogState();
}

class _DayDetailsDialogState extends State<_DayDetailsDialog> {
  static const _center = 4000;
  static const _count = 8000;
  late final PageController _pages = PageController(initialPage: _center);
  late DateTime _day = widget.initialDay;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  DateTime _dayAt(int page) {
    return DateTime(
      widget.initialDay.year,
      widget.initialDay.month,
      widget.initialDay.day + (page - _center),
    );
  }

  String _titleFor(DateTime day) =>
      '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year}';

  Future<void> _go(int delta) async {
    final current = _pages.page?.round() ?? _center;
    final next = (current + delta).clamp(0, _count - 1);
    await _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _onPage(int page) async {
    final day = _dayAt(page);
    setState(() => _day = day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today && ProgressStore.stepsForDay(day) == null) {
      await HealthStepsService.refreshTodaySteps(
        requestPermissionIfNeeded: false,
      );
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.88;
    return Dialog(
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 420,
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _go(-1),
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _titleFor(_day),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: ProfileScreen._fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _go(1),
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _count,
                onPageChanged: _onPage,
                itemBuilder: (context, page) {
                  return _DayDetailsBody(
                    day: _dayAt(page),
                    colorForWorkoutType: widget.colorForWorkoutType,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDetailsBody extends StatelessWidget {
  const _DayDetailsBody({required this.day, required this.colorForWorkoutType});

  final DateTime day;
  final Color Function(String type) colorForWorkoutType;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<int>(
      valueListenable: ProgressStore.listenable(),
      builder: (context, _, __) {
        final events = ProgressStore.workoutSessionsForDay(day);
        final intake = ProgressStore.foodIntakeForDay(day);
        final nutrients = ProgressStore.foodNutrientsForDay(day);
        final workoutBurn = ProgressStore.workoutBurnKcalForDay(day);
        final stepsCount = ProgressStore.stepsForDay(day);
        final stepsBurn = ProgressStore.stepsBurnKcalForDay(day);
        final totalBurn = workoutBurn + stepsBurn;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DaySectionHeader(
                label: l10n.calendar_workouts,
                icon: Icons.fitness_center_rounded,
                accent: AppColors.workout,
              ),
              if (events.isEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 12,
                    bottom: 4,
                  ),
                  child: Text(
                    l10n.calendar_noWorkoutsDay,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: ProfileScreen._fontFamily,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12),
                  child: Column(
                    children: [
                      for (var index = 0; index < events.length; index++)
                        _DayWorkoutTile(
                          event: events[index],
                          accent: colorForWorkoutType(
                            (events[index]['type'] ?? '').toString(),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              _DaySectionHeader(
                label: l10n.calendar_consumption,
                icon: Icons.local_fire_department_rounded,
                accent: AppColors.burn,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 12),
                child: _DayBurnSummary(
                  totalKcal: totalBurn,
                  workoutKcal: workoutBurn,
                  stepsKcal: stepsBurn,
                  stepsCount: stepsCount,
                ),
              ),
              const SizedBox(height: 18),
              _DaySectionHeader(
                label: l10n.calendar_nutrition,
                icon: Icons.restaurant_outlined,
                accent: AppColors.nutrition,
              ),
              // Meals eaten first, then the full nutrient breakdown below —
              // matches the order you actually think in (what did I eat,
              // then how does that add up).
              if (intake.isEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 12,
                    bottom: 4,
                  ),
                  child: Text(
                    l10n.calendar_noMealsDay,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: ProfileScreen._fontFamily,
                      fontSize: 12,
                    ),
                  ),
                )
              else ...[
                for (final entry in intake) ...[
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: _DayFoodEntry(entry: entry),
                  ),
                  const SizedBox(height: 6),
                ],
                const SizedBox(height: 8),
              ],
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 12),
                child: DailyNutrientsPanel(totals: nutrients),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayWorkoutTile extends StatelessWidget {
  const _DayWorkoutTile({required this.event, required this.accent});

  final Map<String, dynamic> event;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final at = DateTime.tryParse(event['recordedAt']?.toString() ?? '');
    final workoutTitle = ProfileScreen._workoutEventTitle(l10n, event);
    final moodRaw = event['mood'];
    final mood = moodRaw is int
        ? moodRaw
        : int.tryParse(moodRaw?.toString() ?? '');
    final burnKcal = ProgressStore.workoutEventBurnKcal(event);
    final timeLabel = at == null
        ? '--:--'
        : '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    final moodIcon = switch (mood) {
      1 => Icons.sentiment_very_dissatisfied,
      2 => Icons.sentiment_dissatisfied,
      3 => Icons.sentiment_neutral,
      4 => Icons.sentiment_satisfied,
      5 => Icons.sentiment_very_satisfied,
      _ => null,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.fitness_center_rounded, size: 16, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workoutTitle,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: ProfileScreen._fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      timeLabel,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontFamily: ProfileScreen._fontFamily,
                        fontSize: 11,
                      ),
                    ),
                    if (burnKcal > 0) ...[
                      Text(
                        ' · ',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '$burnKcal ${l10n.food_macroKcal}',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: ProfileScreen._fontFamily,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (moodIcon != null)
            Icon(moodIcon, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.metrics,
    required this.metabolicKey,
    required this.summary,
    required this.onEditAvatar,
  });
  final Key? metabolicKey;
  final String summary;

  final _NutritionMetrics metrics;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    final name = ProgressStore.profileName;
    final avatarPath = ProgressStore.profileAvatarPath;
    final avatarFile = avatarPath == null ? null : File(avatarPath);
    final hasAvatar = avatarFile != null && avatarFile.existsSync();
    final streakDays = ProgressStore.workoutStreakDays;
    return Center(
      child: Column(
        children: [
          SizedBox(
            height: 92,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -22,
                        right: -22,
                        top: -22,
                        bottom: -22,
                        child: IgnorePointer(
                          child: _StreakFlameAura(streakDays: streakDays),
                        ),
                      ),
                      InkWell(
                        onTap: onEditAvatar,
                        borderRadius: BorderRadius.circular(999),
                        child: _ProfileAvatarFrame(
                          streakDays: streakDays,
                          child: ClipOval(
                            child: hasAvatar
                                ? Image.file(
                                    avatarFile,
                                    fit: BoxFit.cover,
                                    width: 76,
                                    height: 76,
                                  )
                                : Container(
                                    width: 76,
                                    height: 76,
                                    color: AppColors.card,
                                    child: Icon(
                                      Icons.person,
                                      color: AppColors.textMuted,
                                      size: 38,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.actionBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.edit,
                            color: AppColors.onAction,
                            size: 12,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AchievementsScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: AppColors.surfaceDecoration(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Icon(
                                Icons.emoji_events_outlined,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _HighestBadgesList(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AchievementsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.stroke),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: _MetabolicCard(key: metabolicKey, metrics: metrics),
                ),
                VerticalDivider(
                  width: 20,
                  thickness: 1,
                  color: AppColors.stroke,
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'Roboto',
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.25,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${_rankTitle(context.l10n)}  ·  ${context.l10n.achievements_level(ProgressStore.userLevel)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.accentText,
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            letterSpacing: 0.65,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        summary,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _rankTitle(AppLocalizations l10n) {
    final title = AchievementsCatalog.rankTitleForLevel(
      ProgressStore.userLevel,
      l10n,
    );
    return title.toUpperCase();
  }
}

class _HighestBadgesList extends StatelessWidget {
  const _HighestBadgesList({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final earned = ProgressStore.earnedBadges;
    final all = AchievementsCatalog.allDefinitions(context.l10n);

    AchievementDefinition? highestFor(AchievementGroup group) {
      AchievementDefinition? result;
      for (final d in all.where((d) => d.group == group)) {
        if (earned.contains(d.id)) result = d;
      }
      return result;
    }

    final topLevel = highestFor(AchievementGroup.level);
    final topStreak = highestFor(AchievementGroup.streak);
    final topGym = highestFor(AchievementGroup.gym);
    final topCali = highestFor(AchievementGroup.calisthenics);

    final shown = <AchievementDefinition>[
      if (topLevel != null) topLevel,
      if (topStreak != null) topStreak,
      if (topGym != null) topGym,
      if (topCali != null) topCali,
    ];

    if (shown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final d in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: d.color.withValues(alpha: 0.18),
                          border: Border.all(
                            color: d.color.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Icon(d.icon, size: 13, color: d.color),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        d.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatarFrame extends StatelessWidget {
  const _ProfileAvatarFrame({required this.streakDays, required this.child});

  final int streakDays;
  final Widget child;

  static const _fireColors = [
    Color(0xFFFF6A00),
    Color(0xFFFFD000),
    Color(0xFFFF2D00),
    Color(0xFFFF6A00),
  ];

  @override
  Widget build(BuildContext context) {
    const size = 82.0;
    if (streakDays < 3) {
      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: child,
      );
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(colors: _fireColors),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withValues(alpha: 0.42),
            blurRadius: 14,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: const Color(0xFFFFD000).withValues(alpha: 0.22),
            blurRadius: 22,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
        ),
        child: child,
      ),
    );
  }
}

class _StreakFlameAura extends StatelessWidget {
  const _StreakFlameAura({required this.streakDays});

  final int streakDays;

  double get _intensity {
    final d = streakDays;
    if (d < 3) return 0;
    if (d < 7) return 0.38;
    if (d < 14) return 0.48;
    if (d < 30) return 0.58;
    if (d < 100) return 0.78;
    if (d < 365) return 0.9;
    return 1.0;
  }

  double get _scale {
    final d = streakDays;
    if (d < 3) return 0;
    if (d < 7) return 1.05;
    if (d < 14) return 1.15;
    if (d < 30) return 1.25;
    if (d < 100) return 1.72;
    if (d < 365) return 1.9;
    if (d < 1000) return 2.1;
    return 2.35;
  }

  bool get _largeFlames => streakDays >= 30;

  double get _flameIconSize => (_largeFlames ? 22.0 : 18.0) * _scale;

  double get _flameOrbitRadius => 92.0 * _scale / (_largeFlames ? 2.12 : 2.5);

  @override
  Widget build(BuildContext context) {
    final intensity = _intensity;
    if (intensity <= 0) return const SizedBox.shrink();

    final baseSize = 92.0 * _scale;
    final glow =
        Color.lerp(
          const Color(0xFFFF6A00),
          const Color(0xFFFFD000),
          (intensity - 0.38).clamp(0.0, 1.0),
        ) ??
        const Color(0xFFFFB000);

    return Center(
      child: SizedBox(
        width: baseSize,
        height: baseSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft glow ring
            Container(
              width: baseSize,
              height: baseSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.45 * intensity),
                    blurRadius: 26 * _scale,
                    spreadRadius: 2 * _scale,
                  ),
                  BoxShadow(
                    color: const Color(
                      0xFFFF2D00,
                    ).withValues(alpha: 0.18 * intensity),
                    blurRadius: 44 * _scale,
                    spreadRadius: 1 * _scale,
                  ),
                ],
              ),
            ),
            // Flames (small ring of icons)
            for (final angle in const [0, 60, 120, 180, 240, 300])
              Transform.rotate(
                angle: angle * 3.1415926535 / 180.0,
                child: Transform.translate(
                  offset: Offset(0, -_flameOrbitRadius),
                  child: Icon(
                    Icons.local_fire_department,
                    size: _flameIconSize,
                    color: glow.withValues(alpha: 0.65 * intensity),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetabolicCard extends StatelessWidget {
  const _MetabolicCard({super.key, required this.metrics});

  final _NutritionMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = ProgressStore.todayFoodTotals;
    final goalKcal = metrics.calories ?? 0;
    final kcalProgress = goalKcal > 0
        ? (today.kcal / goalKcal).clamp(0.0, 1.0)
        : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profile_dailyCalorieGoal,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text.rich(
          TextSpan(
            text: _NutritionMetrics.formatCalories(today.kcal),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            children: [
              TextSpan(
                text: ' / ${metrics.calorieNumberLabel} ${l10n.food_macroKcal}',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (goalKcal > 0) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: kcalProgress,
              backgroundColor: AppColors.stroke.withValues(alpha: 0.45),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _MacroBar(
          label: l10n.profile_macroProteinShort,
          todayG: today.p,
          goalG: metrics.proteinGrams,
          color: AppColors.nutrition,
          unitLabel: l10n.analytics_unitG,
        ),
        const SizedBox(height: 5),
        _MacroBar(
          label: l10n.food_macroCarbs,
          todayG: today.c,
          goalG: metrics.carbsGrams,
          color: const Color(0xFFE53935),
          unitLabel: l10n.analytics_unitG,
        ),
        const SizedBox(height: 5),
        _MacroBar(
          label: l10n.profile_macroFatShort,
          todayG: today.f,
          goalG: metrics.fatGrams,
          color: const Color(0xFFF0C94B),
          unitLabel: l10n.analytics_unitG,
        ),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.todayG,
    required this.goalG,
    required this.color,
    required this.unitLabel,
  });

  final String label;
  final double todayG;
  final int? goalG;
  final Color color;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final goal = (goalG ?? 0).toDouble();
    final progress = goal > 0 ? (todayG / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 4,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${todayG.toStringAsFixed(0)} / ${goalG ?? '--'} $unitLabel',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 3,
            value: progress,
            backgroundColor: AppColors.stroke.withValues(alpha: 0.45),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─── Day-detail section header ────────────────────────────────────────────
class _DaySectionHeader extends StatelessWidget {
  const _DaySectionHeader({
    required this.label,
    required this.icon,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: ProfileScreen._fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Day-detail burn summary (workouts + steps) ───────────────────────────
class _DayBurnSummary extends StatelessWidget {
  const _DayBurnSummary({
    required this.totalKcal,
    required this.workoutKcal,
    required this.stepsKcal,
    required this.stepsCount,
  });

  final int totalKcal;
  final int workoutKcal;
  final int stepsKcal;
  final int? stepsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$totalKcal',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: ProfileScreen._fontFamily,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.profile_kcalBurned,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: ProfileScreen._fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BurnChip(
                  icon: Icons.fitness_center_rounded,
                  value: '$workoutKcal kcal',
                  label: l10n.calendar_workouts,
                  color: AppColors.burn,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BurnChip(
                  icon: Icons.directions_walk_rounded,
                  value: stepsCount != null
                      ? '${stepsCount!.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')} Schr.'
                      : '– Schr.',
                  label: '$stepsKcal kcal',
                  color: const Color(0xFF43B86B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BurnChip extends StatelessWidget {
  const _BurnChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: ProfileScreen._fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: ProfileScreen._fontFamily,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Day-detail food summary (kcal + small P/C/F bar chart) ───────────────
class _DayMacroSummary extends StatelessWidget {
  const _DayMacroSummary({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });

  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatsG;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The bar widths are scaled to the largest macro of the day so the chart
    // is always readable, even on very low-calorie days.
    final maxG = [
      proteinG,
      carbsG,
      fatsG,
    ].fold<double>(0, (m, v) => v > m ? v : m);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$kcal',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: ProfileScreen._fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.food_macroKcal,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: ProfileScreen._fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                l10n.profile_macroSummary(
                  proteinG.toStringAsFixed(0),
                  carbsG.toStringAsFixed(0),
                  fatsG.toStringAsFixed(0),
                ),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: ProfileScreen._fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DayMacroBar(
            label: l10n.profile_macroProteinShort,
            grams: proteinG,
            maxG: maxG,
            color: AppColors.primary,
            unitLabel: l10n.analytics_unitG,
          ),
          const SizedBox(height: 4),
          _DayMacroBar(
            label: l10n.food_macroCarbs,
            grams: carbsG,
            maxG: maxG,
            color: AppColors.secondary,
            unitLabel: l10n.analytics_unitG,
          ),
          const SizedBox(height: 4),
          _DayMacroBar(
            label: l10n.profile_macroFatShort,
            grams: fatsG,
            maxG: maxG,
            color: const Color(0xFFFFA58A),
            unitLabel: l10n.analytics_unitG,
          ),
        ],
      ),
    );
  }
}

class _DayMacroBar extends StatelessWidget {
  const _DayMacroBar({
    required this.label,
    required this.grams,
    required this.maxG,
    required this.color,
    required this.unitLabel,
  });

  final String label;
  final double grams;
  final double maxG;
  final Color color;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final value = maxG > 0 ? (grams / maxG).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontFamily: ProfileScreen._fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: value,
              backgroundColor: AppColors.stroke.withValues(alpha: 0.45),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${grams.toStringAsFixed(0)} $unitLabel',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: ProfileScreen._fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DayFoodEntry extends StatelessWidget {
  const _DayFoodEntry({required this.entry});

  final Map<String, dynamic> entry;

  Future<void> _delete(BuildContext context) async {
    final l10n = context.l10n;
    final german = Localizations.localeOf(context).languageCode == 'de';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          german ? 'Ernährungseintrag löschen?' : 'Delete food log entry?',
        ),
        content: Text(
          '${entry['name']}\n\n${german ? 'Dieser Eintrag wird aus dem Tagesprotokoll entfernt.' : 'This entry will be removed from the daily log.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ProgressStore.removeFoodIntake(entry['id'].toString());
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            german
                ? 'Eintrag konnte nicht gelöscht werden.'
                : 'Could not delete entry.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kind = entry['kind']?.toString() ?? 'food';
    final name = entry['name']?.toString() ?? '';
    final at = DateTime.tryParse(entry['recordedAt']?.toString() ?? '');
    final time = at == null
        ? '--:--'
        : '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    final p = (entry['proteinG'] as num?)?.toDouble() ?? 0;
    final c = (entry['carbsG'] as num?)?.toDouble() ?? 0;
    final f = (entry['fatsG'] as num?)?.toDouble() ?? 0;
    final kcal = (p * 4 + c * 4 + f * 9).round();
    final isDish = kind == 'dish';
    final grams = entry['grams'];
    final subtitle = isDish
        ? l10n.profile_dishEntry(time)
        : (grams is num
              ? l10n.profile_foodEntryGrams(grams.toStringAsFixed(0), time)
              : time);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stroke.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(
            isDish ? Icons.restaurant_menu : Icons.lunch_dining_outlined,
            size: 14,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: ProfileScreen._fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: ProfileScreen._fontFamily,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$kcal ${l10n.food_macroKcal}',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: ProfileScreen._fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            key: ValueKey('delete-food-${entry['id']}'),
            tooltip: l10n.common_delete,
            onPressed: entry['id'] == null ? null : () => _delete(context),
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Edit Dialog ──────────────────────────────────────────────────────

typedef _ParseFn =
    _ValidationResult<_ProfileValues> Function(
      AppLocalizations l10n, {
      required String name,
      required String ageText,
      required String heightText,
      required String weightText,
      required String bodyFatText,
      required String muscleMassText,
      required String boneMassText,
      required String gender,
      required String activityLevel,
      required String goal,
    });

typedef _PersistFn = Future<void> Function(_ProfileValues values);

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({
    required this.rootContext,
    required this.dialogContext,
    required this.nameController,
    required this.ageController,
    required this.heightController,
    required this.weightController,
    required this.bodyFatController,
    required this.muscleMassController,
    required this.boneMassController,
    required this.parseAndValidate,
    required this.persist,
  });

  final BuildContext rootContext;
  final BuildContext dialogContext;
  final TextEditingController nameController;
  final TextEditingController ageController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController bodyFatController;
  final TextEditingController muscleMassController;
  final TextEditingController boneMassController;
  final _ParseFn parseAndValidate;
  final _PersistFn persist;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  late String _gender = ProgressStore.profileGender ?? 'male';
  late String _activityLevel = ProgressStore.profileActivityLevel;
  late String _goal = ProgressStore.profileGoal;
  late WeeklyTrainingSchedule _weeklySchedule =
      ProgressStore.weeklyTrainingSchedule;

  Future<void> _save() async {
    final l10n = context.l10n;
    final result = widget.parseAndValidate(
      l10n,
      name: widget.nameController.text.trim(),
      ageText: widget.ageController.text,
      heightText: widget.heightController.text,
      weightText: widget.weightController.text,
      bodyFatText: widget.bodyFatController.text,
      muscleMassText: widget.muscleMassController.text,
      boneMassText: widget.boneMassController.text,
      gender: _gender,
      activityLevel: _activityLevel,
      goal: _goal,
    );
    if (!mounted || !widget.rootContext.mounted) return;
    if (result.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!widget.rootContext.mounted) return;
        ScaffoldMessenger.of(
          widget.rootContext,
        ).showSnackBar(SnackBar(content: Text(result.error!)));
      });
      return;
    }
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!widget.rootContext.mounted) return;
      await widget.persist(result.values!);
      await ProgressStore.setWeeklyTrainingSchedule(
        _weeklySchedule.withoutLegacyActivities(),
      );
      await TrainingNotificationService.syncFromStore(
        l10n: widget.rootContext.l10n,
      );
      if (!widget.rootContext.mounted) return;
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(content: Text(widget.rootContext.l10n.profile_updated)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      title: Text(
        l10n.profile_editTitle,
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InputField(
                label: l10n.profile_nameLabel,
                controller: widget.nameController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InputField(
                      label: l10n.profile_ageLabel,
                      isRequired: true,
                      controller: widget.ageController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InputField(
                      label: l10n.profile_heightLabel,
                      isRequired: true,
                      controller: widget.heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InputField(
                      label: l10n.profile_weightLabel,
                      isRequired: true,
                      controller: widget.weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InputField(
                      label: l10n.profile_bodyFatLabel,
                      controller: widget.bodyFatController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InputField(
                      label: l10n.profile_muscleMassLabel,
                      controller: widget.muscleMassController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InputField(
                      label: l10n.profile_boneWeightLabel,
                      controller: widget.boneMassController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _MiniChoiceRow(
                label: l10n.profile_genderLabel,
                options: [
                  _OptionItem('male', l10n.gender_male),
                  _OptionItem('female', l10n.gender_female),
                ],
                value: _gender,
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 14),
              _MiniChoiceRow(
                label: l10n.profile_activityLabel,
                options: [
                  _OptionItem('sedentary', l10n.activity_sedentary),
                  _OptionItem('light', l10n.activity_light),
                  _OptionItem('moderate', l10n.activity_moderate),
                  _OptionItem('high', l10n.activity_high),
                  _OptionItem('athlete', l10n.activity_athlete),
                ],
                value: _activityLevel,
                onChanged: (v) => setState(() => _activityLevel = v),
              ),
              const SizedBox(height: 14),
              _MiniChoiceRow(
                label: l10n.profile_goalLabel,
                options: [
                  _OptionItem('lose', l10n.goal_lose),
                  _OptionItem('maintain', l10n.goal_maintain),
                  _OptionItem('gain', l10n.goal_gain),
                ],
                value: _goal,
                onChanged: (v) => setState(() => _goal = v),
              ),
              const SizedBox(height: 16),
              WeeklyTrainingScheduleSummary(
                schedule: _weeklySchedule,
                onTap: () async {
                  final edited = await showWeeklyScheduleEditorDialog(
                    context: context,
                    schedule: _weeklySchedule,
                  );
                  if (edited == null) return;
                  if (!mounted) return;
                  setState(() => _weeklySchedule = edited);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.actionBackground,
            foregroundColor: AppColors.onAction,
          ),
          onPressed: _save,
          child: Text(l10n.common_save),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.isRequired = false,
    this.keyboardType,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final bool isRequired;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: TextStyle(color: AppColors.textMuted),
                  children: [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.accentText),
                    ),
                  ],
                ),
              )
            : null,
        labelText: isRequired ? null : label,
        labelStyle: TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.background,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _MiniChoiceRow extends StatelessWidget {
  const _MiniChoiceRow({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<_OptionItem> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(option.label),
                selected: option.value == value,
                onSelected: (_) => onChanged(option.value),
                backgroundColor: AppColors.background,
                selectedColor: AppColors.selectedBackground,
                side: BorderSide(color: AppColors.stroke),
                labelStyle: TextStyle(
                  color: option.value == value
                      ? AppColors.onSelected
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProfileValues {
  const _ProfileValues({
    required this.name,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.bodyFatPercent,
    required this.muscleMassKg,
    required this.boneMassKg,
    required this.gender,
    required this.activityLevel,
    required this.goal,
  });

  final String name;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final double? bodyFatPercent;
  final double? muscleMassKg;
  final double? boneMassKg;
  final String gender;
  final String activityLevel;
  final String goal;
}

class _ValidationResult<T> {
  const _ValidationResult({this.values, this.error});

  final T? values;
  final String? error;
}

class _OptionItem {
  const _OptionItem(this.value, this.label);

  final String value;
  final String label;
}

class _NutritionMetrics {
  const _NutritionMetrics({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.waterLiters,
  });

  final int? calories;
  final int? proteinGrams;
  final int? carbsGrams;
  final int? fatGrams;
  final double? waterLiters;

  String get caloriesLabel => calories == null ? '-- kcal' : '$calories kcal';
  String get calorieNumberLabel =>
      calories == null ? '--' : formatCalories(calories!);

  static String formatCalories(int value) => _formatCalories(value);
  String get proteinLabel => proteinGrams == null ? '-- g' : '$proteinGrams g';
  String get carbsLabel => carbsGrams == null ? '-- g' : '$carbsGrams g';
  String get fatLabel => fatGrams == null ? '-- g' : '$fatGrams g';
  String get waterLabel =>
      waterLiters == null ? '-- l' : '${waterLiters!.toStringAsFixed(1)} l';
  String get proteinShareLabel => '${(proteinShare * 100).round()}%';
  String get carbShareLabel => '${(carbShare * 100).round()}%';
  String get fatShareLabel => '${(fatShare * 100).round()}%';
  String get goalLabel {
    final goal = ProgressStore.profileGoal;
    return switch (goal) {
      'lose' => 'cut',
      'gain' => 'bulk',
      _ => 'maintain',
    };
  }

  String get levelLabel {
    return 'LEVEL ${ProgressStore.userLevel}';
  }

  String get performanceLabel {
    final streak = ProgressStore.workoutStreakDays;
    if (streak >= 30) return 'Top 2%';
    if (streak >= 14) return 'Top 5%';
    if (streak >= 7) return 'Top 10%';
    return 'Rising';
  }

  double get proteinShare {
    final total = _macroCalories;
    if (total <= 0 || proteinGrams == null) return 0;
    return ((proteinGrams! * 4) / total).clamp(0.0, 1.0);
  }

  double get carbShare {
    final total = _macroCalories;
    if (total <= 0 || carbsGrams == null) return 0;
    return ((carbsGrams! * 4) / total).clamp(0.0, 1.0);
  }

  double get fatShare {
    final total = _macroCalories;
    if (total <= 0 || fatGrams == null) return 0;
    return ((fatGrams! * 9) / total).clamp(0.0, 1.0);
  }

  double get _macroCalories {
    final protein = proteinGrams ?? 0;
    final carbs = carbsGrams ?? 0;
    final fat = fatGrams ?? 0;
    return protein * 4 + carbs * 4 + fat * 9;
  }

  static String _formatCalories(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buffer.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  factory _NutritionMetrics.fromStore() {
    final age = ProgressStore.profileAge;
    final heightCm = ProgressStore.profileHeightCm;
    final weightKg = ProgressStore.currentWeightKg;
    final gender = ProgressStore.profileGender;
    final activityLevel = ProgressStore.profileActivityLevel;
    final goal = ProgressStore.profileGoal;

    final water = _estimateWater(
      weightKg: weightKg,
      activityLevel: activityLevel,
    );

    if (age == null || heightCm == null || weightKg == null || gender == null) {
      return _NutritionMetrics(
        calories: null,
        proteinGrams: null,
        carbsGrams: null,
        fatGrams: null,
        waterLiters: water,
      );
    }

    final bmrBase = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    final bmr = gender == 'female' ? bmrBase - 161 : bmrBase + 5;
    final activity = switch (activityLevel) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'high' => 1.725,
      'athlete' => 1.9,
      _ => 1.55,
    };

    final goalAdjustment = switch (goal) {
      'lose' => -450,
      'gain' => 300,
      _ => 0,
    };

    final dailyCalories = (bmr * activity + goalAdjustment).round();
    final proteinFactor = switch (goal) {
      'lose' => 2.2,
      'gain' => 2.0,
      _ => 1.8,
    };
    final fatFactor = switch (goal) {
      'lose' => 0.8,
      'gain' => 1.0,
      _ => 0.9,
    };

    final proteinGrams = (weightKg * proteinFactor).round();
    final fatGrams = (weightKg * fatFactor).round();
    final remainingCalories =
        dailyCalories - (proteinGrams * 4) - (fatGrams * 9);
    final carbsGrams = remainingCalories > 0
        ? (remainingCalories / 4).round()
        : 0;

    return _NutritionMetrics(
      calories: dailyCalories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      waterLiters: water,
    );
  }

  static double? _estimateWater({
    required double? weightKg,
    required String activityLevel,
  }) {
    if (weightKg == null) return null;
    final baseLiters = weightKg * 0.035;
    final activityBonus = switch (activityLevel) {
      'sedentary' => 0.0,
      'light' => 0.2,
      'high' => 0.5,
      'athlete' => 0.7,
      _ => 0.35,
    };
    return baseLiters + activityBonus;
  }
}

/// Opens Profile at the top on both tab taps and horizontal swipes.
class _ProfileScrollHost extends StatefulWidget {
  const _ProfileScrollHost({required this.child});

  final Widget child;

  @override
  State<_ProfileScrollHost> createState() => _ProfileScrollHostState();
}

class _ProfileScrollHostState extends State<_ProfileScrollHost> {
  static const _profileTabIndex = 1;

  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  );

  @override
  void initState() {
    super.initState();
    AppTabNavigation.selectedTab.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToDefaultView());
  }

  @override
  void dispose() {
    AppTabNavigation.selectedTab.removeListener(_onTabChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (AppTabNavigation.selectedTab.value == _profileTabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToDefaultView());
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  void _jumpToDefaultView({int attempt = 0}) {
    if (!mounted || AppTabNavigation.selectedTab.value != _profileTabIndex) {
      return;
    }
    if (!_scrollController.hasClients) {
      if (attempt < 12) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _jumpToDefaultView(attempt: attempt + 1),
        );
      }
      return;
    }

    if (_scrollController.offset != 0) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
      child: widget.child,
    );
  }
}
