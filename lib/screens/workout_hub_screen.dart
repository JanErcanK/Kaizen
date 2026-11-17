import '../widgets/exercise_video_clip.dart';
import '../widgets/app_back_button.dart';
import 'package:flutter/material.dart';

import '../data/calisthenics_exercise_catalog.dart';
import '../data/gym_exercise_catalog.dart';
import '../data/ligament_stability_workout_exercises.dart';
import '../data/strength_preset_workouts.dart';
import '../data/sport_catalog.dart';
import '../data/stretch_exercise_catalog.dart';
import 'stretch_catalog_screen.dart';
import '../l10n/catalog_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../navigation/app_tab_navigation.dart';
import '../services/calorie_burn_service.dart';
import '../services/muscle_exercise_filter.dart';
import '../services/on_the_go_workout_generator.dart';
import '../models/body_map_view_mode.dart';
import '../models/body_muscle_group.dart';
import '../widgets/workout_muscle_map.dart';
import '../widgets/anatomy_3d_view.dart';
import '../widgets/anatomy_webview.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import '../utils/strength_exercise_config.dart';
import '../widgets/exercise_set_stacks.dart';
import '../widgets/home_edge_swipe_back.dart';
import '../widgets/preset_strength_workout_detail.dart';
import 'calisthenics_screen.dart';
import 'category_detail_screen.dart';
import 'gym_screen.dart';
import 'morning_workout_detail_screen.dart';
import 'wakeup_workout_detail_screen.dart';
import 'timed_workout_detail_screen.dart';
import 'workout_timer_screen.dart';

class WorkoutHubScreen extends StatefulWidget {
  const WorkoutHubScreen({super.key});

  @override
  State<WorkoutHubScreen> createState() => _WorkoutHubScreenState();
}

class _WorkoutHubScreenState extends State<WorkoutHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    ProgressStore.pruneEmptyStrengthWorkouts();
  }

  List<_WorkoutHubEntry> _allEntries(BuildContext context) {
    final l10n = context.l10n;
    return [
      _WorkoutHubEntry.special(
        id: 'stretch_catalog',
        name: l10n.localeName.startsWith('de')
            ? 'Dehnübungen & Mobilität'
            : 'Stretching & mobility',
        subtitle: l10n.localeName.startsWith('de')
            ? '${stretchExercises.length} Übungen durchsuchen und starten'
            : 'Browse and start ${stretchExercises.length} exercises',
        kind: 'stretch',
      ),
      if (_query.isNotEmpty)
        for (final exercise in stretchExercises.where((e) => e.matches(_query)))
          _WorkoutHubEntry.special(
            id: 'stretch:${exercise.id}',
            name: exercise.name(l10n.localeName.startsWith('de')),
            subtitle: l10n.localeName.startsWith('de')
                ? 'Dehnen & Mobilität'
                : 'Stretching & mobility',
            kind: 'stretch',
          ),
      _WorkoutHubEntry.special(
        id: '9min',
        name: l10n.category_9min_title,
        subtitle: l10n.category_9min_description,
        kind: 'stretch',
      ),
      _WorkoutHubEntry.special(
        id: 'only_stretch',
        name: l10n.category_onlyStretch_title,
        subtitle: l10n.category_onlyStretch_description,
        kind: 'stretch',
      ),
      _WorkoutHubEntry.special(
        id: 'wakeup_workout',
        name: l10n.category_wakeup_title,
        subtitle: l10n.category_wakeup_description,
        kind: 'stretch',
      ),
      _WorkoutHubEntry.special(
        id: 'ligament_stability',
        name: 'Bänder Stabilität',
        subtitle: l10n.localeName.startsWith('de')
            ? 'Stabilität, Balance & Mobilität · 20 Übungen'
            : 'Stability, balance & mobility · 20 exercises',
        kind: 'stretch',
      ),
      ...ProgressStore.gymWorkouts
          .where((w) => ((w['exercises'] as List?)?.isNotEmpty ?? false))
          .map(
            (w) => _WorkoutHubEntry.workout(
              id: w['id']?.toString() ?? '',
              name: w['name']?.toString() ?? 'Workout',
              subtitle: '${((w['exercises'] as List?)?.length ?? 0)} Übungen',
              kind: 'gym',
              workout: w,
            ),
          ),
      ...ProgressStore.calisthenicsWorkouts
          .where((w) => ((w['exercises'] as List?)?.isNotEmpty ?? false))
          .map(
            (w) => _WorkoutHubEntry.workout(
              id: w['id']?.toString() ?? '',
              name: w['name']?.toString() ?? 'Workout',
              subtitle: '${((w['exercises'] as List?)?.length ?? 0)} Übungen',
              kind: 'calisthenics',
              workout: w,
            ),
          ),
      ...gymPresetWorkouts.map(
        (p) => _WorkoutHubEntry.preset(
          id: p.id,
          name: p.localizedName(l10n),
          subtitle: l10n.workoutHub_kindGym,
          kind: p.kind,
        ),
      ),
      ...calisthenicsPresetWorkouts.map(
        (p) => _WorkoutHubEntry.preset(
          id: p.id,
          name: p.localizedName(l10n),
          subtitle: l10n.workoutHub_kindCalisthenics,
          kind: p.kind,
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(String text) {
    if (_query.isEmpty) return true;
    return text.toLowerCase().contains(_query.toLowerCase());
  }

  bool _matchesEntry(_WorkoutHubEntry entry) {
    if (entry.id.startsWith('stretch:')) return true;
    if (!_matchesQuery(entry.name)) return false;
    return true;
  }

  Widget _sectionHeading(String title) => Text(
    title,
    style: TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 18,
      letterSpacing: -0.4,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final favorites = ProgressStore.favoriteWorkoutIds;

    return HomeEdgeSwipeBack(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          toolbarHeight: 0,
          automaticallyImplyLeading: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: ValueListenableBuilder<int>(
          valueListenable: ProgressStore.listenable(),
          builder: (context, _, _) {
            final entries =
                _allEntries(
                  context,
                ).where(_matchesEntry).toList(growable: false)..sort((a, b) {
                  final aFav = favorites.contains(a.id);
                  final bFav = favorites.contains(b.id);
                  if (aFav != bFav) return aFav ? -1 : 1;
                  return a.name.compareTo(b.name);
                });
            final myEntries = entries
                .where((entry) => entry.workout != null)
                .toList();
            final existingEntries =
                entries.where((entry) => entry.workout == null).toList()
                  ..sort((a, b) {
                    final pinA = _existingPinRank(a.id);
                    final pinB = _existingPinRank(b.id);
                    if (pinA != pinB) return pinA.compareTo(pinB);
                    final aFav = favorites.contains(a.id);
                    final bFav = favorites.contains(b.id);
                    if (aFav != bFav) return aFav ? -1 : 1;
                    return a.name.compareTo(b.name);
                  });

            // Search sits outside CustomScrollView — pinned SliverPersistentHeader
            // crashed on Windows (layoutExtent 72 > paintExtent 68 → white screen).
            return Column(
              children: [
                _HubSearchBar(
                  controller: _searchController,
                  hintText: l10n.workoutHub_searchHint,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _HubActionCard(
                                      label: l10n.localeName.startsWith('de')
                                          ? 'Sport eintragen'
                                          : 'Log a sport',
                                      icon: Icons.sports_basketball_outlined,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const SportActivityScreen(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _HubActionCard(
                                      label: l10n.localeName.startsWith('de')
                                          ? 'Timer verwenden'
                                          : 'Use a timer',
                                      icon: Icons.timer_outlined,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const WorkoutTimerScreen(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const CreateNewWorkoutScreen(),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(color: AppColors.stroke),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 20),
                                  label: Text(
                                    l10n.gym_createNewWorkout,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _HubActionCard(
                                label: 'Workout on the go',
                                subtitle: l10n.localeName.startsWith('de')
                                    ? 'Direkt loslegen. In deinem Tempo.'
                                    : 'Start moving. At your own pace.',
                                icon: Icons.bolt_rounded,
                                primary: true,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const WorkoutOnTheGoScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      if (entries.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              l10n.workoutHub_empty,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      if (myEntries.isNotEmpty) ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          sliver: SliverToBoxAdapter(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 640,
                                ),
                                child: _sectionHeading(
                                  l10n.workoutHub_myWorkouts,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildHubEntry(
                                context,
                                myEntries[index],
                                favorites,
                              ),
                              childCount: myEntries.length,
                            ),
                          ),
                        ),
                      ],
                      if (existingEntries.isNotEmpty) ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          sliver: SliverToBoxAdapter(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 640,
                                ),
                                child: _sectionHeading(
                                  l10n.localeName.startsWith('de')
                                      ? 'Workouts entdecken'
                                      : 'Discover workouts',
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Column(
                                children: [
                                  if (index > 0 &&
                                      _existingPinRank(
                                            existingEntries[index - 1].id,
                                          ) <
                                          2 &&
                                      _existingPinRank(
                                            existingEntries[index].id,
                                          ) >=
                                          2)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Divider(
                                        key: const ValueKey(
                                          'timed-workouts-divider',
                                        ),
                                        height: 1,
                                        thickness: 1,
                                        color: AppColors.stroke,
                                      ),
                                    ),
                                  _buildHubEntry(
                                    context,
                                    existingEntries[index],
                                    favorites,
                                  ),
                                ],
                              ),
                              childCount: existingEntries.length,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Keep the two timed routines ahead of the remaining workouts.
  int _existingPinRank(String id) {
    if (id == '9min') return 0;
    if (id == 'wakeup_workout') return 1;
    return 3;
  }

  Widget _buildHubEntry(
    BuildContext context,
    _WorkoutHubEntry entry,
    Set<String> favorites,
  ) {
    return _HubWorkoutTile(
      entry: entry,
      favorite: favorites.contains(entry.id),
      onRename: _isCustomWorkout(entry)
          ? () => _renameCustomWorkout(context, entry)
          : null,
      onDelete: _isCustomWorkout(entry)
          ? () => _confirmDeleteCustomWorkout(context, entry)
          : null,
      onTap: () {
        if (entry.id == 'stretch_catalog' || entry.id.startsWith('stretch:')) {
          final exercise = entry.id.startsWith('stretch:')
              ? stretchExercises.firstWhere(
                  (e) => 'stretch:${e.id}' == entry.id,
                )
              : null;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  StretchCatalogScreen(initialQuery: exercise?.nameDe ?? ''),
            ),
          );
          return;
        }
        if (entry.kind == 'stretch') {
          if (entry.id == 'ligament_stability') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TimedWorkoutDetailScreen(
                  title: entry.name,
                  exercises: ligamentStabilityWorkoutExercises,
                  workoutType: entry.id,
                  showInstructions: true,
                ),
              ),
            );
            return;
          }
          if (entry.id == 'hercules_workout') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MorningWorkoutDetailScreen(),
              ),
            );
            return;
          }
          if (entry.id == 'wakeup_workout') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WakeupWorkoutDetailScreen(),
              ),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  CategoryDetailScreen(title: entry.name, categoryId: entry.id),
            ),
          );
          return;
        }
        if (entry.isPreset) {
          final preset = findPresetWorkoutById(entry.id);
          if (preset == null) return;
          final exercises = resolvePresetWorkoutExercises(preset);
          final l10n = context.l10n;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PresetStrengthWorkoutDetailScreen(
                name: preset.localizedName(l10n),
                presetId: preset.id,
                workoutType: preset.kind,
                initialExercises: exercises,
              ),
            ),
          );
          return;
        }
        if (entry.kind == 'gym') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GymWorkoutDetailScreen(workoutId: entry.id),
            ),
          );
          return;
        }
        if (entry.kind == 'sport') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SportWorkoutDetailScreen(event: entry.workout!),
            ),
          );
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                CalisthenicsWorkoutDetailScreen(workoutId: entry.id),
          ),
        );
      },
    );
  }

  bool _isCustomWorkout(_WorkoutHubEntry entry) =>
      entry.kind == 'gym' || entry.kind == 'calisthenics';

  Future<void> _renameCustomWorkout(
    BuildContext context,
    _WorkoutHubEntry entry,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: entry.name);
    final nextName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.strength_renameWorkoutTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: l10n.common_name,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.stroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.common_cancel,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.actionBackground,
              foregroundColor: AppColors.onAction,
            ),
            child: Text(l10n.common_save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!context.mounted || nextName == null || nextName.trim().isEmpty) {
      return;
    }

    if (entry.kind == 'gym') {
      await ProgressStore.renameGymWorkout(
        workoutId: entry.id,
        newName: nextName,
      );
    } else {
      await ProgressStore.renameCalisthenicsWorkout(
        workoutId: entry.id,
        newName: nextName,
      );
    }
  }

  Future<void> _confirmDeleteCustomWorkout(
    BuildContext context,
    _WorkoutHubEntry entry,
  ) async {
    final l10n = context.l10n;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.strength_deleteWorkoutTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          l10n.strength_deleteWorkoutBody,
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.common_cancel,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.common_delete,
              style: TextStyle(
                color: Colors.red.shade400,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;

    if (ProgressStore.isFavoriteWorkout(entry.id)) {
      await ProgressStore.toggleFavoriteWorkout(entry.id);
    }
    if (entry.kind == 'gym') {
      await ProgressStore.deleteGymWorkout(entry.id);
    } else {
      await ProgressStore.deleteCalisthenicsWorkout(entry.id);
    }
  }
}

class _HubSearchBar extends StatelessWidget {
  const _HubSearchBar({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onBack,
    this.trailing,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isLight = ProgressStore.useLightTheme;
    final fill = isLight ? const Color(0xFFF2F2F7) : const Color(0xFF2C2C2E);
    final iconColor = isLight
        ? const Color(0xFF8E8E93)
        : const Color(0xFF98989D);

    return Material(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
        child: Row(
          children: [
            if (onBack != null) ...[
              AppBackButton(onPressed: onBack),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: iconColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: iconColor,
                      size: 22,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 40,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

Color _workoutSectionAccent(BuildContext context) => AppColors.primary;

class _HubActionCard extends StatelessWidget {
  const _HubActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.primary = false,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? AppColors.onAction : AppColors.textPrimary;
    return Material(
      color: primary ? AppColors.actionBackground : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: primary ? BorderSide.none : BorderSide(color: AppColors.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(primary ? 20 : 16),
          child: primary
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: foreground, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                color: foreground.withValues(alpha: 0.76),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: foreground,
                      size: 20,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: AppColors.primary, size: 23),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

IconData _workoutEntryIcon(String kind) {
  return switch (kind) {
    'stretch' => Icons.self_improvement_rounded,
    'gym' => Icons.fitness_center_rounded,
    'calisthenics' => Icons.accessibility_new_rounded,
    'sport' => Icons.sports_rounded,
    _ => Icons.fitness_center_rounded,
  };
}

class _HubWorkoutTile extends StatelessWidget {
  const _HubWorkoutTile({
    required this.entry,
    required this.favorite,
    this.onRename,
    this.onDelete,
    required this.onTap,
  });

  final _WorkoutHubEntry entry;
  final bool favorite;
  final Future<void> Function()? onRename;
  final Future<void> Function()? onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _workoutSectionAccent(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 15, 10, 15),
              decoration: AppColors.surfaceDecoration(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _workoutEntryIcon(entry.kind),
                      color: accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                entry.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                            if (favorite) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.star_rounded, color: accent, size: 15),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          entry.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.workout != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          ProgressStore.toggleFavoriteWorkout(entry.id),
                      icon: Icon(
                        favorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: favorite ? accent : AppColors.textMuted,
                      ),
                    ),
                  if (onRename != null && onDelete != null)
                    PopupMenuButton<String>(
                      tooltip: context.l10n.localeName.startsWith('de')
                          ? 'Workout-Optionen'
                          : 'Workout options',
                      color: AppColors.card,
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: AppColors.textMuted,
                      ),
                      onSelected: (action) async {
                        if (action == 'rename') await onRename!();
                        if (action == 'delete') await onDelete!();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'rename',
                          child: Text(
                            context.l10n.strength_renameWorkoutTitle,
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(
                            context.l10n.strength_deleteWorkoutMenu,
                            style: TextStyle(color: Colors.red.shade400),
                          ),
                        ),
                      ],
                    ),
                  if (entry.workout == null)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkoutHubEntry {
  const _WorkoutHubEntry({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.kind,
    required this.workout,
    this.isPreset = false,
  });

  const _WorkoutHubEntry.special({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.kind,
  }) : workout = null,
       isPreset = false;

  const _WorkoutHubEntry.workout({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.kind,
    required this.workout,
  }) : isPreset = false;

  const _WorkoutHubEntry.preset({
    required String name,
    required String id,
    required String subtitle,
    required String kind,
  }) : this(
         id: id,
         name: name,
         subtitle: subtitle,
         kind: kind,
         workout: null,
         isPreset: true,
       );

  final String id;
  final String name;
  final String subtitle;
  final String kind;
  final Map<String, dynamic>? workout;
  final bool isPreset;
}

class SportActivityScreen extends StatefulWidget {
  const SportActivityScreen({super.key});

  @override
  State<SportActivityScreen> createState() => _SportActivityScreenState();
}

class _SportActivityScreenState extends State<SportActivityScreen> {
  final _sportController = TextEditingController();
  final _minutesController = TextEditingController(text: '30');
  String _query = '';
  bool _saving = false;

  @override
  void dispose() {
    _sportController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final sport = _sportController.text.trim();
    final minutes = int.tryParse(_minutesController.text.trim());
    if (sport.isEmpty || minutes == null || minutes <= 0 || minutes > 1440) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.localeName.startsWith('de')
                ? 'Bitte Sportart und eine gültige Dauer eingeben.'
                : 'Enter a sport and a valid duration.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final burn = CalorieBurnService.sportSession(
      sportName: sport,
      durationSeconds: minutes * 60,
    );
    await ProgressStore.applyWorkoutRewards(
      workoutType: 'sport',
      workoutName: sport,
      durationSeconds: burn.durationSeconds,
      caloriesBurned: burn.totalKcal,
      calorieBreakdown: CalorieBurnService.breakdownToMaps(burn.breakdown),
    );
    if (!mounted) return;
    AppTabNavigation.returnHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final isGerman = context.l10n.localeName.startsWith('de');
    final matches = sportCatalog
        .where((sport) => sport.matches(_query))
        .map((sport) => sport.label(isGerman))
        .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        leadingWidth: 44,
        backgroundColor: AppColors.background,
        title: Text(isGerman ? 'Sport eintragen' : 'Log a sport'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            isGerman
                ? 'Suche eine Sportart oder gib eine eigene ein.'
                : 'Search for a sport or enter your own.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _sportController,
            onChanged: (value) => setState(() => _query = value.trim()),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: isGerman ? 'Sportart' : 'Sport',
              prefixIcon: const Icon(Icons.search_rounded),
              border: const OutlineInputBorder(),
            ),
          ),
          if (matches.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final sport in matches)
                      ChoiceChip(
                        label: Text(sport),
                        selected: _sportController.text == sport,
                        onSelected: (_) {
                          _sportController.text = sport;
                          setState(() => _query = sport);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: _minutesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isGerman ? 'Dauer in Minuten' : 'Duration in minutes',
              prefixIcon: const Icon(Icons.schedule_rounded),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(isGerman ? 'Als Workout speichern' : 'Save workout'),
          ),
          const SizedBox(height: 10),
          Text(
            isGerman
                ? 'Der Kalorienverbrauch ist ein Richtwert aus Dauer, Sportart und deinem erfassten Körpergewicht.'
                : 'Calories are an estimate based on duration, sport and your recorded body weight.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class SportWorkoutDetailScreen extends StatelessWidget {
  const SportWorkoutDetailScreen({super.key, required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final isGerman = context.l10n.localeName.startsWith('de');
    final name = event['workoutName']?.toString() ?? 'Sport';
    final seconds = (event['durationSeconds'] as num?)?.toInt() ?? 0;
    final kcal = (event['caloriesBurned'] as num?)?.toInt() ?? 0;
    final recordedAt = DateTime.tryParse(event['recordedAt']?.toString() ?? '');
    final rawExercises = event['exercises'];
    final exercises = rawExercises is List
        ? rawExercises
              .whereType<Map>()
              .map((raw) => Map<String, dynamic>.from(raw))
              .toList()
        : const <Map<String, dynamic>>[];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        leadingWidth: 44,
        backgroundColor: AppColors.background,
        title: Text(name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${CalorieBurnService.formatDuration(seconds)} · $kcal kcal',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
            ),
            if (recordedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                MaterialLocalizations.of(context).formatMediumDate(recordedAt),
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              isGerman
                  ? 'Kalorienverbrauch als Schätzwert anhand der durchschnittlichen Intensität und deines Körpergewichts.'
                  : 'Estimated calories based on average intensity and your body weight.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            if (exercises.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                isGerman ? 'Übungen' : 'Exercises',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: exercises.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, position) {
                    if (position == 0)
                      return WorkoutMuscleMap(exercises: exercises);
                    final index = position - 1;
                    final exercise = exercises[index];
                    final exerciseName =
                        exercise['name']?.toString() ??
                        (isGerman ? 'Übung' : 'Exercise');
                    final sets = (exercise['sets'] as num?)?.toInt() ?? 1;
                    final reps = (exercise['reps'] as num?)?.toInt() ?? 1;
                    final tags = exercise['tags'] is List
                        ? (exercise['tags'] as List)
                              .map((tag) => tag.toString())
                              .toSet()
                        : <String>{};
                    final primary = exercise['mainGroup']?.toString();
                    if (primary != null && primary.isNotEmpty) {
                      tags.add(primary);
                    }
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppColors.surfaceDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  CatalogLocalizations.anyExerciseName(
                                    exerciseName,
                                  ),
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '$sets × $reps',
                                style: TextStyle(
                                  color: AppColors.accentText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          if (tags.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              tags.join(' · '),
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Shared exercise catalog helpers ─────────────────────────────────────────

List<Map<String, dynamic>> _catalogExercises() {
  final list = <Map<String, dynamic>>[
    for (final e in gymCatalogExercises)
      {
        'kind': 'gym',
        'name': e.name,
        'description': e.description,
        'mainGroup': e.mainGroup,
        'tags': e.tags,
      },
    for (final e in calisthenicsCatalogExercises)
      {
        'kind': 'calisthenics',
        'name': e.name,
        'description': e.description,
        'mainGroup': e.mainGroup,
        'tags': e.tags,
      },
  ];
  list.sort(
    (a, b) => (a['name']?.toString() ?? '').toLowerCase().compareTo(
      (b['name']?.toString() ?? '').toLowerCase(),
    ),
  );
  return list;
}

const List<String> _muscleOptions = [
  'Brust',
  'Schultern',
  'Rücken',
  'Trizeps',
  'Bizeps',
  'Bauch',
  'Beine',
  'Nacken',
  'Unterarme',
];

List<Map<String, dynamic>> _filterCatalog({
  required List<Map<String, dynamic>> all,
  required String query,
  required Set<String> kinds,
  required Set<String> muscles,
}) {
  return all.where((exercise) {
    final kind = exercise['kind']?.toString() ?? '';
    if (kinds.isNotEmpty && !kinds.contains(kind)) return false;
    if (query.isNotEmpty) {
      final name = exercise['name']?.toString() ?? '';
      if (!CatalogLocalizations.matchesExerciseQuery(name, query)) {
        return false;
      }
    }
    if (muscles.isEmpty) return true;
    final hits = <String>{
      exercise['mainGroup']?.toString() ?? '',
      ...((exercise['tags'] as List?) ?? const []).map((e) => e.toString()),
    };
    return muscles.any(hits.contains);
  }).toList();
}

// ─── Create New Workout ──────────────────────────────────────────────────────

class CreateNewWorkoutScreen extends StatefulWidget {
  const CreateNewWorkoutScreen({super.key});

  @override
  State<CreateNewWorkoutScreen> createState() => _CreateNewWorkoutScreenState();
}

class _CreateNewWorkoutScreenState extends State<CreateNewWorkoutScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _selected = [];
  final Set<String> _kinds = <String>{};
  final Set<String> _muscles = <String>{};
  String _query = '';
  late final List<Map<String, dynamic>> _allExercises = _catalogExercises();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editSelected(int index) async {
    final ex = _selected[index];
    final next = await StrengthExerciseConfig.edit(
      context,
      exerciseName: CatalogLocalizations.anyExerciseName(
        ex['name']?.toString() ?? '',
      ),
      exercise: ex,
    );
    if (next == null || !mounted) return;
    setState(() {
      _selected[index] = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final matches = _filterCatalog(
      all: _allExercises,
      query: _query,
      kinds: _kinds,
      muscles: _muscles,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        leadingWidth: 44,
        backgroundColor: AppColors.background,
        title: Text(context.l10n.gym_createNewWorkout),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selected.isEmpty
            ? null
            : () async {
                final id = await ProgressStore.createGymWorkout(
                  context.l10n.gym_defaultWorkoutName,
                );
                await ProgressStore.setGymWorkoutExercises(
                  workoutId: id,
                  exercises: _selected
                      .map(StrengthExerciseConfig.applyDefaults)
                      .toList(),
                );
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => GymWorkoutDetailScreen(workoutId: id),
                  ),
                );
              },
        label: Text(context.l10n.common_save),
        icon: const Icon(Icons.check_rounded),
      ),
      body: Column(
        children: [
          _HubSearchBar(
            controller: _searchController,
            hintText: context.l10n.workoutHub_searchHint,
            onChanged: (value) => setState(() => _query = value.trim()),
            trailing: _ExerciseFilterButton(
              activeKinds: _kinds,
              activeMuscles: _muscles,
              muscleOptions: _muscleOptions,
              onApply: (nextKinds, nextMuscles) {
                setState(() {
                  _kinds
                    ..clear()
                    ..addAll(nextKinds);
                  _muscles
                    ..clear()
                    ..addAll(nextMuscles);
                });
              },
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (_selected.isNotEmpty)
                  ..._selectedExerciseSlivers(
                    selected: _selected,
                    sectionTitle: context.l10n.workoutHub_myWorkouts,
                    onEdit: _editSelected,
                    onRemove: (i) => setState(() => _selected.removeAt(i)),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final exercise = matches[index];
                      return _CatalogExerciseTile(
                        exercise: exercise,
                        onAdd: () async {
                          final plan = await StrengthExerciseConfig.edit(
                            context,
                            exerciseName: CatalogLocalizations.anyExerciseName(
                              exercise['name'] as String,
                            ),
                            exercise: exercise,
                          );
                          if (mounted && plan != null)
                            setState(() => _selected.add(plan));
                        },
                      );
                    }, childCount: matches.length),
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

// ─── Workout on the go (starts immediately) ──────────────────────────────────

class WorkoutOnTheGoScreen extends StatefulWidget {
  const WorkoutOnTheGoScreen({super.key, this.webViewFactory});

  final AnatomyWebViewFactory? webViewFactory;

  @override
  State<WorkoutOnTheGoScreen> createState() => _WorkoutOnTheGoScreenState();
}

class _WorkoutOnTheGoScreenState extends State<WorkoutOnTheGoScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _selected = [];
  final Set<String> _kinds = <String>{};
  final Set<String> _muscles = <String>{};
  late final List<Map<String, dynamic>> _allExercises = _catalogExercises();
  Set<String> _regions = {};
  final Anatomy3DController _anatomyController = Anatomy3DController();
  bool _focusSearch = false;
  bool _front = true;
  bool _review = false;
  bool _starting = false;
  String _query = '';
  String? _workoutId;

  void _generateWorkout() {
    final plan = OnTheGoWorkoutGenerator.generate(
      catalog: _allExercises,
      regions: _regions,
    );
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      final existing = _selected
          .map(OnTheGoWorkoutGenerator.exerciseKey)
          .toSet();
      _selected.addAll(
        plan.where((e) => existing.add(OnTheGoWorkoutGenerator.exerciseKey(e))),
      );
      _query = '';
      _kinds.clear();
      _muscles.clear();
      _review = true;
      _focusSearch = false;
    });
  }

  void _addExercise(Map<String, dynamic> exercise) {
    final key = OnTheGoWorkoutGenerator.exerciseKey(exercise);
    if (_selected.any((e) => OnTheGoWorkoutGenerator.exerciseKey(e) == key)) {
      return;
    }
    setState(
      () => _selected.add(StrengthExerciseConfig.applyDefaults(exercise)),
    );
  }

  Future<void> _editSelected(Map<String, dynamic> exercise) async {
    final next = await StrengthExerciseConfig.edit(
      context,
      exerciseName: CatalogLocalizations.anyExerciseName(
        exercise['name'] as String,
      ),
      exercise: exercise,
    );
    if (next == null || !mounted) return;
    final index = _selected.indexOf(exercise);
    if (index < 0) return;
    setState(() {
      _selected[index] = next;
    });
  }

  Future<void> _startWorkout() async {
    if (_starting || _selected.isEmpty) return;
    setState(() => _starting = true);
    try {
      _workoutId ??= await ProgressStore.createGymWorkout('Workout on the go');
      await ProgressStore.setGymWorkoutExercises(
        workoutId: _workoutId!,
        exercises: _selected.map(StrengthExerciseConfig.applyDefaults).toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GymWorkoutDetailScreen(workoutId: _workoutId!),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _starting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.onTheGo_saveFailed)));
    }
  }

  void _returnToFigure() {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _review = false;
      _query = '';
      _front = true;
    });
  }

  void _openExercises({bool focusSearch = false}) {
    setState(() {
      _focusSearch = focusSearch;
      _review = true;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _anatomyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_review && !_starting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_starting) _returnToFigure();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: AppBackButton(
            onPressed: _starting ? () {} : (_review ? _returnToFigure : null),
          ),
          leadingWidth: 44,
          backgroundColor: AppColors.background,
          title: const Text('Workout on the go'),
        ),
        body: SafeArea(
          top: false,
          child: AbsorbPointer(
            absorbing: _starting,
            child: _review ? _reviewPage(context) : _musclePage(context),
          ),
        ),
      ),
    );
  }

  Widget _musclePage(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            key: const ValueKey('on-the-go-direct-search'),
            readOnly: true,
            onTap: () => _openExercises(focusSearch: true),
            decoration: InputDecoration(
              hintText: l10n.onTheGo_search,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Anatomy3DView(
                  mode: BodyMapViewMode.recovery,
                  expanded: true,
                  controller: _anatomyController,
                  webViewFactory: widget.webViewFactory,
                  selectedSegments: _regions,
                  snapshot: const MuscleRecoverySnapshot(
                    recovery: {},
                    afterburn: {},
                    trainedThisWeek: {},
                  ),
                  onMuscleSelected: (slug) {
                    setState(() {
                      final next = {..._regions};
                      if (!next.add(slug)) next.remove(slug);
                      _regions = next;
                    });
                  },
                ),
              ),
              Positioned(
                bottom: 16,
                right: 8,
                child: FilledButton.tonalIcon(
                  key: const ValueKey('on-the-go-flip'),
                  onPressed: () {
                    _anatomyController.toggleFrontBack();
                    setState(() => _front = !_front);
                  },
                  icon: const Icon(Icons.flip_camera_android_outlined),
                  label: Text(
                    _front ? l10n.home_bodyBack : l10n.home_bodyFront,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_regions.isEmpty)
          Text(l10n.onTheGo_select)
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final slug in _regions)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      label: Text(
                        CatalogLocalizations.muscleTag(
                          MuscleExerciseFilter.selectionLabel(slug),
                        ),
                      ),
                      onDeleted: () => setState(
                        () => _regions = {..._regions}..remove(slug),
                      ),
                    ),
                  ),
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('on-the-go-generate'),
              onPressed: _regions.isEmpty ? null : _generateWorkout,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(l10n.onTheGo_generate),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('on-the-go-add'),
              onPressed: () => _openExercises(),
              icon: const Icon(Icons.playlist_add_rounded),
              label: Text(
                '${l10n.localeName.startsWith('de') ? 'Zum Workout hinzufügen' : 'Add to workout'}'
                '${_selected.isEmpty ? '' : ' (${_selected.length})'}',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewPage(BuildContext context) {
    final l10n = context.l10n;
    final selectedKeys = _selected
        .map(OnTheGoWorkoutGenerator.exerciseKey)
        .toSet();
    final matches =
        _filterCatalog(
          all: _allExercises,
          query: _query,
          kinds: _kinds,
          muscles: _muscles,
        ).where(
          (exercise) =>
              !selectedKeys.contains(
                OnTheGoWorkoutGenerator.exerciseKey(exercise),
              ) &&
              (_regions.isEmpty ||
                  _regions.any(
                    (region) =>
                        OnTheGoWorkoutGenerator.matches(exercise, region),
                  )),
        );
    final unique = <String, Map<String, dynamic>>{};
    for (final exercise in matches) {
      unique.putIfAbsent(
        OnTheGoWorkoutGenerator.exerciseKey(exercise),
        () => exercise,
      );
    }
    final suggestions = unique.values.toList();
    final burn = CalorieBurnService.strengthSession(exercises: _selected);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _regions
                      .map(
                        (slug) => CatalogLocalizations.muscleTag(
                          MuscleExerciseFilter.selectionLabel(slug),
                        ),
                      )
                      .join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              IconButton(
                onPressed: _returnToFigure,
                tooltip: l10n.workoutHub_filterMuscles,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Workout (${_selected.length})',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(
                      child: _selected.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  l10n.onTheGo_empty,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              key: const ValueKey('on-the-go-plan'),
                              padding: const EdgeInsets.fromLTRB(12, 0, 6, 12),
                              itemCount: _selected.length,
                              itemBuilder: (_, index) {
                                final exercise = _selected[index];
                                return _planExerciseCard(
                                  exercise,
                                  selected: true,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(width: 1, color: AppColors.stroke),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        l10n.onTheGo_moreExercises,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 12, 8),
                      child: TextField(
                        autofocus: _focusSearch,
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _query = value.trim()),
                        decoration: InputDecoration(
                          hintText: l10n.onTheGo_search,
                          isDense: true,
                          suffixIcon: _ExerciseFilterButton(
                            activeKinds: _kinds,
                            activeMuscles: _muscles,
                            muscleOptions: _muscleOptions,
                            onApply: (kinds, muscles) => setState(() {
                              _kinds
                                ..clear()
                                ..addAll(kinds);
                              _muscles
                                ..clear()
                                ..addAll(muscles);
                            }),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: suggestions.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  l10n.onTheGo_noMatches,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              key: const ValueKey('on-the-go-suggestions'),
                              padding: const EdgeInsets.fromLTRB(6, 0, 12, 12),
                              itemCount: suggestions.length,
                              itemBuilder: (_, index) => _planExerciseCard(
                                suggestions[index],
                                selected: false,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${burn.totalKcal} kcal · ${CalorieBurnService.formatDuration(burn.durationSeconds)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              FilledButton.icon(
                key: const ValueKey('on-the-go-start'),
                onPressed: _starting || _selected.isEmpty
                    ? null
                    : _startWorkout,
                icon: _starting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.workoutHub_startWorkout),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _planExerciseCard(
    Map<String, dynamic> exercise, {
    required bool selected,
  }) {
    final l10n = context.l10n;
    final name = CatalogLocalizations.anyExerciseName(
      exercise['name'] as String,
    );
    final kind = exercise['kind'] == 'gym'
        ? l10n.workoutHub_kindGym
        : l10n.workoutHub_kindCalisthenics;
    final group = CatalogLocalizations.muscleGroup(
      exercise['mainGroup'] as String,
    );
    return Container(
      key: ValueKey(
        '${selected ? 'plan' : 'suggestion'}-${OnTheGoWorkoutGenerator.exerciseKey(exercise)}',
      ),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$kind · $group',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          if (exercise['onTheGoComplement'] == true) ...[
            const SizedBox(height: 4),
            Text(
              l10n.onTheGo_complement,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
          const SizedBox(height: 4),
          if (selected)
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () => _editSelected(exercise),
                    child: Text(StrengthExerciseConfig.formatShort(exercise)),
                  ),
                ),
                IconButton(
                  tooltip: l10n.common_delete,
                  onPressed: () => setState(() => _selected.remove(exercise)),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: l10n.common_add,
                onPressed: () => _addExercise(exercise),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ),
        ],
      ),
    );
  }
}

List<Widget> _selectedExerciseSlivers({
  required List<Map<String, dynamic>> selected,
  required Future<void> Function(int index) onEdit,
  required void Function(int index) onRemove,
  String? sectionTitle,
}) {
  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Text(
          sectionTitle ?? 'Workout',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
    for (var i = 0; i < selected.length; i++)
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        sliver: SliverToBoxAdapter(
          child: _SelectedExerciseCard(
            exercise: selected[i],
            onEdit: () => onEdit(i),
            onRemove: () => onRemove(i),
          ),
        ),
      ),
  ];
}

class _SelectedExerciseCard extends StatelessWidget {
  const _SelectedExerciseCard({
    required this.exercise,
    required this.onEdit,
    required this.onRemove,
  });

  final Map<String, dynamic> exercise;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final rawName = exercise['name']?.toString() ?? '';
    final name = CatalogLocalizations.anyExerciseName(rawName);
    final kind = exercise['kind']?.toString() ?? '';
    final description = CatalogLocalizations.anyExerciseDescription(
      rawName,
      kind: kind,
    );
    final line = CalorieBurnService.strengthExerciseLine(exercise);
    final setReps = StrengthExerciseConfig.setValues(exercise);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        StrengthExerciseConfig.formatShort(exercise),
                        style: TextStyle(
                          color: AppColors.accentText,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.strength_exerciseKcalDuration(
                      '${line.kcal}',
                      CalorieBurnService.formatDuration(line.seconds),
                    ),
                    style: TextStyle(
                      color: AppColors.accentText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  ExerciseVideoClip(exercise: exercise),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ExerciseSetStacks(
            setReps: setReps,
            timed: StrengthExerciseConfig.isTimed(exercise),
            onTap: onEdit,
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _CatalogExerciseTile extends StatelessWidget {
  const _CatalogExerciseTile({required this.exercise, required this.onAdd});

  final Map<String, dynamic> exercise;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final rawName = exercise['name']?.toString() ?? '';
    final kind = exercise['kind']?.toString() ?? '';
    final mainGroup = exercise['mainGroup']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppColors.surfaceDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CatalogLocalizations.anyExerciseName(rawName),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${kind == 'gym' ? context.l10n.workoutHub_kindGym : context.l10n.workoutHub_kindCalisthenics} · ${CatalogLocalizations.muscleGroup(mainGroup)}',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseFilterButton extends StatelessWidget {
  const _ExerciseFilterButton({
    required this.activeKinds,
    required this.activeMuscles,
    required this.muscleOptions,
    required this.onApply,
  });

  final Set<String> activeKinds;
  final Set<String> activeMuscles;
  final List<String> muscleOptions;
  final void Function(Set<String> nextKinds, Set<String> nextMuscles) onApply;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      color: AppColors.card,
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 280),
      offset: const Offset(0, 52),
      itemBuilder: (popupContext) {
        final nextKinds = activeKinds.toSet();
        final nextMuscles = activeMuscles.toSet();
        return [
          PopupMenuItem<void>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: StatefulBuilder(
              builder: (context, setPopupState) {
                Widget compactSwitch(String label, String key) {
                  final selected = nextKinds.contains(key);
                  return InkWell(
                    onTap: () => setPopupState(() {
                      if (selected) {
                        nextKinds.remove(key);
                      } else {
                        nextKinds.add(key);
                      }
                    }),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: selected,
                            onChanged: (_) => setPopupState(() {
                              if (selected) {
                                nextKinds.remove(key);
                              } else {
                                nextKinds.add(key);
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SizedBox(
                  width: 260,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.workoutHub_filterKind,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        compactSwitch(context.l10n.workoutHub_kindGym, 'gym'),
                        compactSwitch(
                          context.l10n.workoutHub_kindCalisthenics,
                          'calisthenics',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.workoutHub_filterMuscles,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final muscle in muscleOptions)
                              FilterChip(
                                label: Text(
                                  CatalogLocalizations.muscleGroup(muscle),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                selected: nextMuscles.contains(muscle),
                                onSelected: (_) => setPopupState(() {
                                  if (nextMuscles.contains(muscle)) {
                                    nextMuscles.remove(muscle);
                                  } else {
                                    nextMuscles.add(muscle);
                                  }
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              onApply(nextKinds, nextMuscles);
                              Navigator.of(context).pop();
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(
                              context.l10n.workoutHub_filterApply,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ];
      },
      child: Container(
        height: 52,
        width: 52,
        decoration: AppColors.surfaceDecoration(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.tune_rounded,
          color: activeKinds.isNotEmpty || activeMuscles.isNotEmpty
              ? AppColors.primary
              : AppColors.textPrimary,
        ),
      ),
    );
  }
}
