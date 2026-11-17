import '../widgets/exercise_video_clip.dart';
import '../widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import '../widgets/workout_muscle_map.dart';

import '../data/strength_preset_workouts.dart';
import '../l10n/catalog_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../navigation/app_tab_navigation.dart';
import '../services/progress_store.dart';
import '../services/calorie_burn_service.dart';
import '../theme/app_colors.dart';
import '../utils/strength_exercise_config.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_header_logo.dart';
import '../widgets/exercise_stats_sheet.dart';
import '../widgets/preset_strength_workout_detail.dart';
import '../widgets/strength_workout_list.dart';
import 'root_shell.dart';
import '../data/gym_exercise_catalog.dart';
import '../models/social_models.dart';
import '../widgets/share_with_friends_sheet.dart';

typedef _GymExercise = GymCatalogExercise;
const _exercises = gymCatalogExercises;

String _displayGymName(_GymExercise ex) =>
    CatalogLocalizations.gymExerciseName(ex.name);

String _displayGymDescription(_GymExercise ex) =>
    CatalogLocalizations.gymDescription(ex.name);

String _displayMuscleGroup(String group) =>
    CatalogLocalizations.muscleGroup(group);

String _displayMuscleTag(String tag) => CatalogLocalizations.muscleTag(tag);

Map<String, dynamic> _gymExerciseToMap(_GymExercise ex) {
  return {
    'name': ex.name,
    'description': ex.description,
    'mainGroup': ex.mainGroup,
    'tags': ex.tags,
  };
}

List<Map<String, dynamic>> _resolveGymPreset(PresetWorkoutTemplate preset) {
  final catalog = {for (final e in _exercises) e.name: e};
  return [
    for (final name in preset.exerciseNames)
      if (catalog.containsKey(name))
        StrengthExerciseConfig.applyDefaults(_gymExerciseToMap(catalog[name]!)),
  ];
}

class GymScreen extends StatefulWidget {
  const GymScreen({super.key});

  @override
  State<GymScreen> createState() => _GymScreenState();
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class _GymScreenState extends State<GymScreen> {
  final Set<String> _selectedGroups = <String>{};

  static const List<String> _mainGroups = [
    'Alle',
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

  List<_GymExercise> get _filtered {
    if (_selectedGroups.isEmpty) return _exercises;
    return _exercises.where((e) {
      final hits = <String>{e.mainGroup, ...e.tags};
      // AND-filter: exercise must match ALL selected groups.
      return _selectedGroups.every(hits.contains);
    }).toList();
  }

  void _toggleGroup(String group) {
    if (group == 'Alle') {
      setState(() => _selectedGroups.clear());
      return;
    }
    setState(() {
      if (_selectedGroups.contains(group)) {
        _selectedGroups.remove(group);
      } else {
        _selectedGroups.add(group);
      }
    });
  }

  Future<void> _addToLastWorkout(_GymExercise ex) async {
    final lastId = ProgressStore.lastGymWorkoutId;
    if (lastId == null) return;
    if (ProgressStore.gymWorkoutById(lastId) == null) return;
    final configured = await StrengthExerciseConfig.edit(
      context,
      exerciseName: _displayGymName(ex),
      exercise: _exerciseToMap(ex),
    );
    if (configured == null) return;
    await ProgressStore.addExerciseToGymWorkout(
      workoutId: lastId,
      exercise: configured,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.gym_exerciseAdded),
        backgroundColor: AppColors.card,
      ),
    );
  }

  Map<String, dynamic> _exerciseToMap(_GymExercise ex) => _gymExerciseToMap(ex);

  Future<void> _openAddExerciseSheet(_GymExercise ex) async {
    final lastId = ProgressStore.lastGymWorkoutId;
    final last = lastId == null ? null : ProgressStore.gymWorkoutById(lastId);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final l10n = ctx.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayGymName(ex),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                if (last != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.history, color: AppColors.secondary),
                    title: Text(
                      l10n.gym_addToLastWorkout,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      (last['name'] ?? '').toString(),
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await _addToLastWorkout(ex);
                    },
                  )
                else
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.history, color: AppColors.textMuted),
                    title: Text(
                      l10n.gym_addToLastWorkout,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      l10n.gym_noWorkoutYet,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.playlist_add, color: AppColors.secondary),
                  title: Text(
                    l10n.gym_addWorkout,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _openChooseWorkoutSheet(ex);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openChooseWorkoutSheet(_GymExercise ex) async {
    final workouts = ProgressStore.gymWorkouts;
    String? selectedId = workouts.isNotEmpty
        ? workouts.first['id']?.toString()
        : null;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final l10n = ctx.l10n;
            final currentWorkouts = ProgressStore.gymWorkouts;
            if (selectedId == null && currentWorkouts.isNotEmpty) {
              selectedId = currentWorkouts.first['id']?.toString();
            }
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.gym_addToWorkoutTitle,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (currentWorkouts.isEmpty)
                      Text(
                        l10n.gym_noWorkoutsCreated,
                        style: TextStyle(color: AppColors.textMuted),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.stroke),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedId,
                            isExpanded: true,
                            dropdownColor: AppColors.card,
                            items: currentWorkouts.map((w) {
                              final id = w['id']?.toString() ?? '';
                              final name =
                                  (w['name'] ?? l10n.strength_workoutFallback)
                                      .toString();
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setSheetState(() => selectedId = v),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(color: AppColors.stroke),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final id = await _promptCreateWorkout(ctx);
                              if (id == null) return;
                              setSheetState(() => selectedId = id);
                            },
                            child: Text(l10n.gym_createNewWorkout),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.actionBackground,
                              foregroundColor: AppColors.onAction,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                currentWorkouts.isEmpty || selectedId == null
                                ? null
                                : () async {
                                    final id = selectedId!;
                                    final configured =
                                        await StrengthExerciseConfig.edit(
                                          context,
                                          exerciseName: _displayGymName(ex),
                                          exercise: _exerciseToMap(ex),
                                        );
                                    if (configured == null) return;
                                    await ProgressStore.addExerciseToGymWorkout(
                                      workoutId: id,
                                      exercise: configured,
                                    );
                                    if (!ctx.mounted) return;
                                    Navigator.of(ctx).pop();
                                  },
                            child: Text(l10n.common_add),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _promptCreateWorkout(BuildContext sheetContext) async {
    final l10n = sheetContext.l10n;
    final controller = TextEditingController(text: l10n.gym_defaultWorkoutName);
    final id = await showDialog<String?>(
      context: sheetContext,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.transparent,
          title: Text(
            l10n.gym_newWorkout,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.common_name,
              hintStyle: TextStyle(color: AppColors.textMuted),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.stroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(
                l10n.common_cancel,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () async {
                final created = await ProgressStore.createGymWorkout(
                  controller.text,
                );
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop(created);
              },
              child: Text(
                l10n.common_create,
                style: TextStyle(
                  color: AppColors.accentText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          automaticallyImplyLeading: false,
          centerTitle: true,
          toolbarHeight: 52,
          title: const AppHeaderLogo(),
        ),
        bottomNavigationBar: _compactNavBar(context),
        body: Column(
          children: [
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: TabBar(
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.2,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
                tabs: [
                  Tab(text: l10n.gym_tabExercises),
                  Tab(text: l10n.gym_tabWorkouts),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _GymExercisesTab(
                    mainGroups: _mainGroups,
                    selectedGroups: _selectedGroups,
                    onToggleGroup: _toggleGroup,
                    exercises: _filtered,
                    totalCount: _filtered.length,
                    onAddTap: _openAddExerciseSheet,
                  ),
                  const _GymWorkoutsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GymExercisesTab extends StatelessWidget {
  const _GymExercisesTab({
    required this.mainGroups,
    required this.selectedGroups,
    required this.onToggleGroup,
    required this.exercises,
    required this.totalCount,
    required this.onAddTap,
  });

  final List<String> mainGroups;
  final Set<String> selectedGroups;
  final void Function(String) onToggleGroup;
  final List<_GymExercise> exercises;
  final int totalCount;
  final void Function(_GymExercise) onAddTap;

  bool _isTagHighlighted({
    required String tag,
    required Set<String> selectedGroups,
  }) {
    if (selectedGroups.isEmpty) return false;
    final t = tag.toLowerCase();
    for (final s in selectedGroups) {
      final sel = s.toLowerCase();
      if (sel.isEmpty) continue;
      if (t.contains(sel) || sel.contains(t)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sticky filter chips (Wrap, no horizontal scroll)
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: mainGroups.map((group) {
              final selected = group == 'Alle'
                  ? selectedGroups.isEmpty
                  : selectedGroups.contains(group);
              return GestureDetector(
                onTap: () => onToggleGroup(group),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.selectedBackground
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.stroke,
                    ),
                  ),
                  child: Text(
                    group == 'Alle'
                        ? l10n.food_macroAll
                        : _displayMuscleGroup(group),
                    style: TextStyle(
                      color: selected
                          ? AppColors.onSelected
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: exercises.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.category_gym_title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.strength_exerciseCount('$totalCount'),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final ex = exercises[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppColors.surfaceDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _displayGymName(ex),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => onAddTap(ex),
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: AppColors.primary,
                            ),
                            tooltip: l10n.strength_addToWorkoutTooltip,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _displayGymDescription(ex),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ex.tags.map((tag) {
                          final highlighted = _isTagHighlighted(
                            tag: tag,
                            selectedGroups: selectedGroups,
                          );
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: highlighted
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: highlighted
                                    ? AppColors.primary.withValues(alpha: 0.35)
                                    : AppColors.stroke,
                              ),
                            ),
                            child: Text(
                              _displayMuscleTag(tag),
                              style: TextStyle(
                                color: highlighted
                                    ? AppColors.accentText
                                    : AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GymWorkoutsTab extends StatelessWidget {
  const _GymWorkoutsTab();

  Future<void> _openRenameDialog(
    BuildContext context,
    Map<String, dynamic> w,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: (w['name'] ?? '').toString(),
    );
    final newName = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
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
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.common_name,
              hintStyle: TextStyle(color: AppColors.textMuted),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.stroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(
                l10n.common_cancel,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: Text(
                l10n.common_save,
                style: TextStyle(
                  color: AppColors.accentText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
    controller.dispose();
    final id = w['id']?.toString();
    if (id == null) return;
    if (newName == null) return;
    await ProgressStore.renameGymWorkout(workoutId: id, newName: newName);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Map<String, dynamic> w,
  ) async {
    final l10n = context.l10n;
    final id = w['id']?.toString();
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
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
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                l10n.common_cancel,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                l10n.common_delete,
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    await ProgressStore.deleteGymWorkout(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder(
      valueListenable: ProgressStore.listenable(),
      builder: (context, tick, child) {
        final workouts = ProgressStore.gymWorkouts;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            strengthWorkoutSectionTitle(l10n.strength_sectionMyWorkouts),
            if (workouts.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.gym_noWorkoutsCreated,
                  style: TextStyle(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              for (final w in workouts) _customWorkoutTile(context, w),
            ],
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.actionBackground,
                foregroundColor: AppColors.onAction,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await ProgressStore.createGymWorkout(
                  l10n.gym_defaultWorkoutName,
                );
              },
              child: Text(l10n.gym_createNewWorkout),
            ),
            const SizedBox(height: 28),
            strengthWorkoutSectionTitle(l10n.strength_sectionPresetWorkouts),
            for (final preset in gymPresetWorkouts) ...[
              Builder(
                builder: (_) {
                  final exercises = _resolveGymPreset(preset);
                  final burn = CalorieBurnService.strengthSession(
                    exercises: exercises,
                  );
                  return presetWorkoutListTile(
                    context: context,
                    name: preset.localizedName(context.l10n),
                    exerciseCount: exercises.length,
                    burn: burn,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PresetStrengthWorkoutDetailScreen(
                            name: preset.localizedName(context.l10n),
                            presetId: preset.id,
                            workoutType: 'gym',
                            initialExercises: exercises,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _customWorkoutTile(BuildContext context, Map<String, dynamic> w) {
    final id = w['id']?.toString() ?? '';
    final name = (w['name'] ?? 'Workout').toString();
    final rawExercises = w['exercises'];
    final count = rawExercises is List ? rawExercises.length : 0;
    final exercises = rawExercises is List
        ? rawExercises
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : const <Map<String, dynamic>>[];
    final burn = CalorieBurnService.strengthSession(exercises: exercises);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GymWorkoutDetailScreen(workoutId: id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppColors.surfaceDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    strengthWorkoutSubtitle(
                      context: context,
                      exerciseCount: count,
                      burn: burn,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: AppColors.card,
                icon: Icon(Icons.more_horiz, color: AppColors.textMuted),
                onSelected: (value) async {
                  if (value == 'rename') {
                    await _openRenameDialog(context, w);
                  } else if (value == 'share') {
                    await showShareWithFriendsSheet(
                      context: context,
                      type: ShareContentType.gymWorkout,
                      payload: Map<String, dynamic>.from(w),
                    );
                  } else if (value == 'delete') {
                    await _confirmDelete(context, w);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem<String>(
                    value: 'rename',
                    child: Text(
                      ctx.l10n.strength_renameWorkoutTitle,
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'share',
                    child: Text(
                      ctx.l10n.social_shareAction,
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      ctx.l10n.strength_deleteWorkoutMenu,
                      style: TextStyle(color: Colors.red.shade300),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GymWorkoutDetailScreen extends StatelessWidget {
  const GymWorkoutDetailScreen({super.key, required this.workoutId});

  final String workoutId;

  List<Map<String, dynamic>> _readExercises(Map<String, dynamic> workout) {
    final raw = workout['exercises'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder(
      valueListenable: ProgressStore.listenable(),
      builder: (context, tick, child) {
        final workout = ProgressStore.gymWorkoutById(workoutId);
        if (workout == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              leading: const AppBackButton(),
              leadingWidth: 44,
              backgroundColor: AppColors.background,
              title: Text(
                l10n.strength_workoutFallback,
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            body: Center(
              child: Text(
                l10n.gym_workoutNotFound,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          );
        }

        final name = (workout['name'] ?? l10n.strength_workoutFallback)
            .toString();
        final exercises = _readExercises(workout);
        final burn = CalorieBurnService.strengthSession(exercises: exercises);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: const AppBackButton(),
            leadingWidth: 44,
            backgroundColor: AppColors.background,
            title: Text(
              name,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              IconButton(
                tooltip: l10n.strength_workoutComplete,
                icon: Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                ),
                onPressed: () async {
                  final mood = await _promptMood(context);
                  final burn = CalorieBurnService.strengthSession(
                    exercises: exercises,
                  );
                  await ProgressStore.applyWorkoutRewards(
                    workoutType: 'gym',
                    mood: mood,
                    caloriesBurned: burn.totalKcal,
                    durationSeconds: burn.durationSeconds,
                    workoutName: name,
                    workoutId: workoutId,
                    exercises: exercises,
                    calorieBreakdown: CalorieBurnService.breakdownToMaps(
                      burn.breakdown,
                    ),
                  );
                  // Log lift entries for every exercise
                  for (final ex in exercises) {
                    final rawName = (ex['name'] ?? '').toString();
                    final exName = CatalogLocalizations.anyExerciseName(
                      rawName,
                    );
                    final w = StrengthExerciseConfig.readWeight(ex);
                    if (w > 0 && !StrengthExerciseConfig.isTimed(ex)) {
                      await ProgressStore.addLiftEntry(
                        exerciseName: exName,
                        sets: StrengthExerciseConfig.readSets(ex),
                        reps: StrengthExerciseConfig.readReps(ex),
                        weight: w,
                      );
                    }
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.strength_workoutCompleteSnack('${burn.totalKcal}'),
                      ),
                      backgroundColor: AppColors.card,
                    ),
                  );
                  AppTabNavigation.returnHome(context);
                },
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (exercises.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.strength_estimatedBurn,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${burn.totalKcal} kcal · ${CalorieBurnService.formatDuration(burn.durationSeconds)}',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: ReorderableListView.builder(
                  header: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: WorkoutMuscleMap(exercises: exercises),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: exercises.length,
                  onReorder: (oldIndex, newIndex) async {
                    var target = newIndex;
                    if (target > oldIndex) target -= 1;
                    final next = exercises.toList();
                    final item = next.removeAt(oldIndex);
                    next.insert(target, item);
                    await ProgressStore.setGymWorkoutExercises(
                      workoutId: workoutId,
                      exercises: next,
                    );
                  },
                  itemBuilder: (context, index) {
                    final ex = exercises[index];
                    final rawName =
                        (ex['name'] ?? l10n.strength_exerciseFallback)
                            .toString();
                    final exName = CatalogLocalizations.anyExerciseName(
                      rawName,
                    );
                    final exDesc = CatalogLocalizations.anyExerciseDescription(
                      rawName,
                      kind: 'gym',
                    );
                    final tagsRaw = ex['tags'];
                    final tags = tagsRaw is List
                        ? tagsRaw.map((e) => e.toString()).toList()
                        : const <String>[];
                    final line = burn.breakdown.length > index
                        ? burn.breakdown[index]
                        : CalorieBurnService.strengthExerciseLine(ex);

                    return Material(
                      key: ValueKey(
                        'ex_${workoutId}_${index}_${exName.hashCode}',
                      ),
                      color: Colors.transparent,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: AppColors.surfaceDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left 3/4 → stats popup
                                Expanded(
                                  flex: 3,
                                  child: InkWell(
                                    onTap: () => ExerciseStatsSheet.show(
                                      context,
                                      exName,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        14,
                                        4,
                                        14,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  exName,
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l10n.strength_exerciseKcalDuration(
                                              '${line.kcal}',
                                              CalorieBurnService.formatDuration(
                                                line.seconds,
                                              ),
                                            ),
                                            style: TextStyle(
                                              color: AppColors.accentText,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          ExerciseVideoClip(exercise: ex),
                                          if (exDesc.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              exDesc,
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 13,
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                          if (tags.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children: tags.map((t) {
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 9,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    border: Border.all(
                                                      color: AppColors.primary
                                                          .withValues(
                                                            alpha: 0.35,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _displayMuscleTag(t),
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.accentText,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Right 1/4 → edit sets/reps/weight
                                InkWell(
                                  onTap: () async {
                                    final updated =
                                        await StrengthExerciseConfig.edit(
                                          context,
                                          exerciseName: exName,
                                          exercise: ex,
                                        );
                                    if (updated == null) return;
                                    final next = exercises.toList();
                                    next[index] = updated;
                                    await ProgressStore.setGymWorkoutExercises(
                                      workoutId: workoutId,
                                      exercises: next,
                                    );
                                  },
                                  child: Container(
                                    width: 70,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: AppColors.stroke,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          StrengthExerciseConfig.formatShort(
                                            ex,
                                          ),
                                          style: TextStyle(
                                            color: AppColors.accentText,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        if (StrengthExerciseConfig.readWeight(
                                              ex,
                                            ) >
                                            0)
                                          Text(
                                            '${StrengthExerciseConfig.readWeight(ex).toStringAsFixed(StrengthExerciseConfig.readWeight(ex) % 1 == 0 ? 0 : 1)} kg',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          )
                                        else
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 14,
                                            color: AppColors.textMuted,
                                          ),
                                        const SizedBox(height: 6),
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: Icon(
                                            Icons.drag_handle,
                                            color: AppColors.textMuted,
                                            size: 20,
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
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<int?> _promptMood(BuildContext context) async {
  final l10n = context.l10n;
  return showDialog<int?>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      Widget moodButton(int value, IconData icon, String label) {
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(ctx).pop(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.textPrimary, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.mood_title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Row(
          children: [
            moodButton(1, Icons.sentiment_very_dissatisfied, l10n.mood_veryBad),
            moodButton(2, Icons.sentiment_dissatisfied, l10n.mood_bad),
            moodButton(3, Icons.sentiment_neutral, l10n.mood_neutral),
            moodButton(4, Icons.sentiment_satisfied, l10n.mood_good),
            moodButton(5, Icons.sentiment_very_satisfied, l10n.mood_veryGood),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(
              l10n.common_skip,
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );
}

// ─── Nav bar (shared style) ───────────────────────────────────────────────────

Widget _compactNavBar(BuildContext context) {
  return AppBottomNavBar(
    selectedIndex: 0,
    onDestinationSelected: (index) {
      if (index == 0) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
        RootShell.selectedTab.value = 1;
      }
    },
  );
}
