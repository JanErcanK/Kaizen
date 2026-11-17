import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_extension.dart';
import '../services/home_weekly_summary_service.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import '../widgets/home_fasting_hud.dart';
import '../widgets/recovery_body_map.dart';
import 'category_detail_screen.dart';
import 'food_screen.dart';
import 'shopping_list_screen.dart';
import '../widgets/shopping_note_art.dart';
import 'running_screen.dart';
import 'social/friends_screen.dart';
import 'workout_hub_screen.dart';

const _homeDashboardPanelWidthFactor = 0.48;

class StartScreen extends StatefulWidget {
  const StartScreen({
    super.key,
    this.categoryTourKeys = const {},
    this.onStartIntro,
  });

  final Map<String, GlobalKey> categoryTourKeys;
  final VoidCallback? onStartIntro;

  static const List<_CategoryItem> categories = [
    _CategoryItem(
      id: 'workout',
      icon: Icons.fitness_center_outlined,
      infoDetail:
          'All strength and bodyweight workouts in one place — gym, calisthenics, '
          'stretch and morning routines. Search, filter and start.',
    ),
    _CategoryItem(
      id: 'running',
      icon: Icons.directions_run,
      infoDetail:
          'Plan routes or start a free run immediately and track distance, elevation and pace.',
    ),
    _CategoryItem(
      id: 'food',
      icon: Icons.restaurant_menu_outlined,
      infoDetail:
          'Search food and add it directly to your daily intake or create a meal and save it.',
    ),
    _CategoryItem(id: 'friends', icon: Icons.people_alt_outlined),
  ];

  static String categoryTitle(BuildContext context, String id) => switch (id) {
    'workout' => context.l10n.category_workout_title,
    '9min' => context.l10n.category_9min_title,
    'hercules_workout' => context.l10n.category_hercules_title,
    'only_stretch' => context.l10n.category_onlyStretch_title,
    'gym' => context.l10n.category_gym_title,
    'calisthenics' => context.l10n.category_calisthenics_title,
    'running' => context.l10n.category_running_title,
    'food' => context.l10n.category_food_title,
    'friends' => context.l10n.category_friends_title,
    _ => id,
  };

  static String categoryDescription(BuildContext context, String id) =>
      switch (id) {
        'workout' => context.l10n.category_workout_description,
        '9min' => context.l10n.category_9min_description,
        'hercules_workout' => context.l10n.category_hercules_description,
        'only_stretch' => context.l10n.category_onlyStretch_description,
        'gym' => context.l10n.category_gym_description,
        'calisthenics' => context.l10n.category_calisthenics_description,
        'running' => context.l10n.category_running_description,
        'food' => context.l10n.category_food_description,
        'friends' => context.l10n.category_friends_description,
        _ => '',
      };

  static _CategoryItem get workoutCategory =>
      categories.firstWhere((c) => c.id == 'workout');

  static _CategoryItem get runningCategory =>
      categories.firstWhere((c) => c.id == 'running');

  static _CategoryItem get foodCategory =>
      categories.firstWhere((c) => c.id == 'food');

  static _CategoryItem get friendsCategory =>
      categories.firstWhere((c) => c.id == 'friends');

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final _bodyExpandT = ValueNotifier<double>(0);

  @override
  void dispose() {
    _bodyExpandT.dispose();
    super.dispose();
  }

  Widget _buildCategoryTile(
    BuildContext context,
    _CategoryItem item, {
    bool fullWidth = false,
    bool centeredContent = false,
  }) {
    return KeyedSubtree(
      key: widget.categoryTourKeys[item.id],
      child: _CategoryCard(
        item: item,
        reserveInfoSpace: false,
        onTap: () => _openCategory(context, item),
        fullWidth: fullWidth,
        centeredContent: centeredContent,
        compact: true,
        shoppingTourKey: item.id == 'food'
            ? widget.categoryTourKeys['shopping']
            : null,
      ),
    );
  }

  Future<void> _openCategory(BuildContext context, _CategoryItem item) async {
    await ProgressStore.markCategoryOpened(item.id);
    if (!context.mounted) return;
    if (item.id == 'food') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const FoodScreen()));
      return;
    }
    if (item.id == 'friends') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const FriendsScreen()));
      return;
    }
    if (item.id == 'running') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const RunningScreen()));
      return;
    }
    if (item.id == 'workout') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const WorkoutHubScreen()));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryDetailScreen(
          title: StartScreen.categoryTitle(context, item.id),
          categoryId: item.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ValueListenableBuilder(
        valueListenable: ProgressStore.listenable(),
        builder: (context, box, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final l10n = context.l10n;
              final isGerman = l10n.localeName.startsWith('de');
              final profileName = ProgressStore.profileName.trim();
              final snapshot = HomeWeeklySummaryService.snapshot(l10n);
              final heroHeight = math.max(
                236.0,
                math.min(300.0, constraints.maxHeight * 0.35),
              );
              final categories = ValueListenableBuilder<double>(
                valueListenable: _bodyExpandT,
                builder: (context, progress, child) => Transform.translate(
                  offset: Offset(0, progress * 420),
                  child: Opacity(
                    opacity: (1 - progress).clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildCategoryTile(
                            context,
                            StartScreen.workoutCategory,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCategoryTile(
                            context,
                            StartScreen.runningCategory,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCategoryTile(
                            context,
                            StartScreen.foodCategory,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCategoryTile(
                            context,
                            StartScreen.friendsCategory,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              return Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: LayoutBuilder(
                        builder: (context, viewport) => SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: math.max(
                                  heroHeight +
                                      (profileName.isEmpty
                                          ? 0
                                          : RecoveryBodyCard
                                                .compactPanelTopWithHeading),
                                  viewport.maxHeight,
                                ),
                                child: RecoveryBodyCard(
                                  mannequinTourKey:
                                      widget.categoryTourKeys['mannequin'],
                                  compactSidePanelWidthFactor:
                                      _homeDashboardPanelWidthFactor,
                                  compactSidePanelHeight: heroHeight,
                                  compactDashboard: true,
                                  compactHeading: profileName.isEmpty
                                      ? null
                                      : Semantics(
                                          header: true,
                                          child: Text(
                                            profileName,
                                            key: const Key('home-profile-name'),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineLarge
                                                ?.copyWith(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.1,
                                                  letterSpacing: -0.8,
                                                ),
                                          ),
                                        ),
                                  compactSidePanel: _HomeDashboardMetricsCard(
                                    snapshot: snapshot,
                                    isGerman: isGerman,
                                    onWaterTap: snapshot.waterEnabled
                                        ? () => ProgressStore.addWaterGlass()
                                        : null,
                                    onWaterLongPress: snapshot.waterEnabled
                                        ? () => ProgressStore.removeWaterGlass()
                                        : null,
                                  ),
                                  onExpansionProgress: (t) {
                                    if ((_bodyExpandT.value - t).abs() >
                                        0.001) {
                                      _bodyExpandT.value = t;
                                    }
                                  },
                                  onStartIntro: ProgressStore.needsHomeIntro
                                      ? widget.onStartIntro
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (ProgressStore.fastingHudEnabled) ...[
                          const HomeFastingHud(compact: true),
                          const SizedBox(height: 6),
                        ],
                        _WeeklyStreakStrip(
                          days: ProgressStore.workoutStreakDays,
                          isGerman: isGerman,
                        ),
                        const SizedBox(height: 8),
                        ClipRect(child: categories),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem({required this.id, required this.icon, this.infoDetail});

  final String id;
  final IconData icon;
  final String? infoDetail;
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.item,
    required this.reserveInfoSpace,
    required this.onTap,
    this.fullWidth = false,
    this.centeredContent = false,
    this.compact = false,
    this.shoppingTourKey,
  });

  final _CategoryItem item;
  final bool reserveInfoSpace;
  final VoidCallback onTap;
  final bool fullWidth;
  final bool centeredContent;
  final bool compact;
  final Key? shoppingTourKey;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  Color _accentFor(String id) => switch (id) {
    'workout' => AppColors.workout,
    'running' => AppColors.running,
    'food' => AppColors.nutrition,
    _ => AppColors.primary,
  };

  String? _photoUrlFor(String id) => switch (id) {
    'workout' =>
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48'
          '?auto=format&fit=crop&w=600&q=70',
    'running' =>
      'https://images.unsplash.com/photo-1571008887538-b36bb32f4571'
          '?auto=format&fit=crop&w=600&q=70',
    'food' =>
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd'
          '?auto=format&fit=crop&w=600&q=70',
    'friends' =>
      'https://images.unsplash.com/photo-1529156069898-49953e39b3ac'
          '?auto=format&fit=crop&w=600&q=70',
    _ => null,
  };

  List<Color> _fallbackGradient(String id) => switch (id) {
    'workout' => [const Color(0xFF1A2408), const Color(0xFF0C1004)],
    'running' => [const Color(0xFF1E1530), const Color(0xFF0D0B18)],
    'food' => [const Color(0xFF0A1A2E), const Color(0xFF061018)],
    _ => [const Color(0xFF1C1C1E), const Color(0xFF111111)],
  };

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final accent = _accentFor(item.id);
    final photoUrl = _photoUrlFor(item.id);
    final fallback = _fallbackGradient(item.id);
    final title = StartScreen.categoryTitle(context, item.id);
    final compactTitle = widget.compact && item.id == 'food'
        ? (context.l10n.localeName.startsWith('de') ? 'Lebensmittel' : 'Food')
        : title;
    final description = StartScreen.categoryDescription(context, item.id);
    final cardHeight = widget.fullWidth
        ? 80.0
        : widget.compact
        ? 88.0
        : 120.0;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 90),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: SizedBox(
          height: cardHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Photo background ──
                if (photoUrl != null)
                  Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: fallback,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: fallback,
                      ),
                    ),
                  ),

                // ── Dark gradient overlay ──
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.38),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),

                // ── Accent border ──
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: accent.withValues(alpha: 0.22),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                // ── Content ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 50, 12),
                  child: widget.fullWidth
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Icon(item.icon, color: accent, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xAAFFFFFF),
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 11,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: widget.compact
                                    ? Colors.white.withValues(alpha: 0.20)
                                    : accent.withValues(alpha: 0.22),
                                shape: widget.compact
                                    ? BoxShape.circle
                                    : BoxShape.rectangle,
                                borderRadius: widget.compact
                                    ? null
                                    : BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.compact
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : accent.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Icon(
                                item.icon,
                                color: widget.compact ? Colors.white : accent,
                                size: 19,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  compactTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w800,
                                    fontSize: widget.compact ? 12.5 : 14,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (description.isNotEmpty && !widget.compact)
                                  Text(
                                    description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0x88FFFFFF),
                                      fontFamily: 'Roboto',
                                      fontSize: 10,
                                      height: 1.3,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),

                // ── Arrow button (always bottom-right) ──
                if (item.id != 'food')
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: widget.compact
                            ? const Color(0xFFA8D878)
                            : accent,
                        shape: widget.compact
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius: widget.compact
                            ? null
                            : BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF293743),
                        size: 17,
                      ),
                    ),
                  ),
                if (item.id == 'food')
                  Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: .25,
                      heightFactor: 1,
                      child: Semantics(
                        key: widget.shoppingTourKey,
                        button: true,
                        label: context.l10n.localeName.startsWith('de')
                            ? 'Einkaufszettel öffnen'
                            : 'Open shopping list',
                        child: Material(
                          color: Colors.white.withValues(alpha: .10),
                          child: InkWell(
                            key: const ValueKey('home-shopping-list'),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ShoppingListScreen(),
                              ),
                            ),
                            child: const ShoppingNoteArt(),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardSurface extends StatelessWidget {
  const _DashboardSurface({required this.child, this.fireFrame = false});

  final Widget child;
  final bool fireFrame;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: fireFrame
              ? const Color(0xFFFFB252).withValues(alpha: 0.85)
              : AppColors.stroke,
          width: fireFrame ? 1.3 : 1,
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x0D14251C),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
          if (fireFrame) ...[
            const BoxShadow(
              color: Color(0x16F45132),
              blurRadius: 13,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Color(0x14FFC247),
              blurRadius: 7,
              spreadRadius: 1,
            ),
          ],
        ],
      ),
      child: child,
    );
  }
}

class _HomeDashboardMetricsCard extends StatefulWidget {
  const _HomeDashboardMetricsCard({
    super.key,
    required this.snapshot,
    required this.isGerman,
    this.onWaterTap,
    this.onWaterLongPress,
  });

  final HomeHudSnapshot snapshot;
  final bool isGerman;
  final VoidCallback? onWaterTap;
  final VoidCallback? onWaterLongPress;

  @override
  State<_HomeDashboardMetricsCard> createState() =>
      _HomeDashboardMetricsCardState();
}

class _HomeDashboardMetricsCardState extends State<_HomeDashboardMetricsCard> {
  static const double _macroCardWidth = 190;
  static const double _macroCardHeight = 142;

  final GlobalKey _eatenRowKey = GlobalKey();
  OverlayEntry? _macroOverlay;

  void _dismissMacroBreakdown() {
    final overlay = _macroOverlay;
    if (overlay == null) return;
    _macroOverlay = null;
    overlay.remove();
    overlay.dispose();
  }

  void _showMacroBreakdown() {
    if (_macroOverlay != null) {
      _dismissMacroBreakdown();
      return;
    }

    final rowBox =
        _eatenRowKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (rowBox == null || overlayBox == null || !rowBox.hasSize) return;

    final origin = rowBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final rowSize = rowBox.size;
    final viewport = overlayBox.size;
    final cardWidth = math.min(_macroCardWidth, viewport.width - 24).toDouble();
    final preferredLeft = origin.dx + rowSize.width + 8;
    final left =
        (preferredLeft + cardWidth <= viewport.width - 12
                ? preferredLeft
                : math.max(12.0, viewport.width - cardWidth - 12))
            .toDouble();
    final safeTop = MediaQuery.paddingOf(context).top + 8;
    final maxTop = math
        .max(safeTop, viewport.height - _macroCardHeight - 12)
        .toDouble();
    final top = (origin.dy + rowSize.height / 2 - _macroCardHeight / 2)
        .clamp(safeTop, maxTop)
        .toDouble();

    _macroOverlay = OverlayEntry(
      builder: (overlayContext) => Positioned.fill(
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismissMacroBreakdown,
              child: const SizedBox.expand(),
            ),
            Positioned(
              left: left,
              top: top,
              width: cardWidth,
              child: Material(
                color: AppColors.card,
                surfaceTintColor: Colors.transparent,
                elevation: 9,
                shadowColor: Colors.black.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.stroke.withValues(alpha: 0.7),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
                  child: _buildMacroContent(overlayContext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    overlay.insert(_macroOverlay!);
  }

  Widget _buildMacroContent(BuildContext context) {
    final l10n = context.l10n;
    final number = NumberFormat('0.#', widget.isGerman ? 'de' : 'en');
    final macros = <({String label, double grams, Color color})>[
      (
        label: l10n.profile_protein,
        grams: widget.snapshot.proteinG,
        color: AppColors.nutrition,
      ),
      (
        label: l10n.profile_carbs,
        grams: widget.snapshot.carbsG,
        color: const Color(0xFFE53935),
      ),
      (
        label: l10n.profile_fats,
        grams: widget.snapshot.fatsG,
        color: const Color(0xFFF0C94B),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isGerman ? 'Makros heute' : 'Today’s macros',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        for (final macro in macros)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: macro.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    macro.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${number.format(macro.grams)} g',
                  style: TextStyle(
                    color: macro.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _dismissMacroBreakdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final isGerman = widget.isGerman;
    final locale = isGerman ? 'de' : 'en';
    final number = NumberFormat.decimalPattern(locale);
    final liters = NumberFormat('0.0', locale);
    final calorieGoal = snapshot.calorieTarget ?? 2200;
    final rows = <_DashboardMetricData>[
      _DashboardMetricData(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF9D25),
        label: isGerman ? 'Verbrannt' : 'Burned',
        value: number.format(snapshot.burnedKcal),
        goal: '/ ${number.format(snapshot.burnGoalKcal)} kcal',
        ratio: snapshot.burnGoalKcal <= 0
            ? 0
            : snapshot.burnedKcal / snapshot.burnGoalKcal,
      ),
      _DashboardMetricData(
        icon: Icons.restaurant_rounded,
        color: const Color(0xFF70A935),
        label: isGerman ? 'Eingenommen' : 'Consumed',
        value: number.format(snapshot.eatenKcal),
        goal: '/ ${number.format(calorieGoal)} kcal',
        ratio: calorieGoal <= 0 ? 0 : snapshot.eatenKcal / calorieGoal,
      ),
      _DashboardMetricData(
        icon: Icons.directions_run_rounded,
        color: const Color(0xFF239BF1),
        label: isGerman ? 'Schritte' : 'Steps',
        value: number.format(snapshot.steps),
        goal: '/ ${number.format(snapshot.stepsGoal)}',
        ratio: snapshot.stepsGoal <= 0
            ? 0
            : snapshot.steps / snapshot.stepsGoal,
      ),
      if (snapshot.waterEnabled)
        _DashboardMetricData(
          icon: Icons.water_drop_rounded,
          color: const Color(0xFF21C6BE),
          label: isGerman ? 'Wasser' : 'Water',
          value: liters.format(snapshot.waterMl / 1000),
          goal: '/ ${liters.format(snapshot.waterGoalMl / 1000)} L',
          ratio: snapshot.waterGoalMl <= 0
              ? 0
              : snapshot.waterMl / snapshot.waterGoalMl,
        ),
    ];

    return _DashboardSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              Expanded(
                child: _DashboardMetricRow(
                  key: index == 1 ? _eatenRowKey : null,
                  data: rows[index],
                  onTap: switch (index) {
                    1 => _showMacroBreakdown,
                    3 => widget.onWaterTap,
                    _ => null,
                  },
                  onLongPress: index == 3 ? widget.onWaterLongPress : null,
                ),
              ),
              if (index < rows.length - 1)
                Divider(height: 1, color: AppColors.stroke),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardMetricData {
  const _DashboardMetricData({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.goal,
    required this.ratio,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String goal;
  final double ratio;
}

class _DashboardMetricRow extends StatelessWidget {
  const _DashboardMetricRow({
    super.key,
    required this.data,
    this.onTap,
    this.onLongPress,
  });

  final _DashboardMetricData data;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Icon(data.icon, color: data.color, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.goal,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9.5,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: data.ratio.clamp(0.0, 1.0),
                  strokeWidth: 3.5,
                  strokeCap: StrokeCap.round,
                  color: AppColors.primary,
                  backgroundColor: AppColors.stroke,
                ),
              ),
              Text(
                '${(data.ratio.clamp(0.0, 1.0) * 100).round()}%',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: content,
        ),
      ),
    );
  }
}

class _WeeklyStreakStrip extends StatelessWidget {
  const _WeeklyStreakStrip({required this.days, required this.isGerman});

  final int days;
  final bool isGerman;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary;
    const daysDe = ['M', 'D', 'M', 'D', 'F', 'S', 'S'];
    const daysEn = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final letters = isGerman ? daysDe : daysEn;
    final dayUnit = isGerman
        ? (days == 1 ? 'Tag' : 'Tage')
        : (days == 1 ? 'day' : 'days');

    return _DashboardSurface(
      fireFrame: days >= 7,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        child: SizedBox(
          height: 45,
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (days / 7).clamp(0.0, 1.0),
                      strokeWidth: 4,
                      color: accent,
                      backgroundColor: AppColors.stroke,
                    ),
                    if (days >= 3)
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFFF45132),
                            Color(0xFFFF9D27),
                            Color(0xFFFFD84D),
                          ],
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 23,
                        ),
                      )
                    else
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: accent,
                        size: 23,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$days $dayUnit',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Streak',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 34, color: AppColors.stroke),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final active = index < days.clamp(0, 7);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active ? accent : AppColors.stroke,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          letters[index],
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 8,
                            height: 1,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Friends Banner ───────────────────────────────────────────────────────────

class _FriendsBanner extends StatelessWidget {
  const _FriendsBanner({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0D2B5E), Color(0xFF1A4080)],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF4A9FE0).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: Color(0xFF4A9FE0),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontFamily: 'Roboto',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
