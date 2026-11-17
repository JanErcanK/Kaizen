import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../services/achievements_catalog.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_header_logo.dart';
import 'root_shell.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  void _showInfo(BuildContext context) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.stroke),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.achievements_levelingSystem,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: Icon(Icons.close, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.achievements_noXp,
                    style: TextStyle(color: AppColors.textMuted, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.achievements_levelPerWorkout,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _infoLine(
                    l10n.achievements_onlyStretch,
                    l10n.achievements_levelPlus(1),
                  ),
                  _infoLine(
                    l10n.achievements_nineMin,
                    l10n.achievements_levelPlus(2),
                  ),
                  _infoLine(
                    l10n.achievements_hercules,
                    l10n.achievements_levelPlus(3),
                  ),
                  _infoLine(
                    l10n.achievements_gymWorkout,
                    l10n.achievements_levelPlus(5),
                  ),
                  _infoLine(
                    l10n.achievements_caliWorkout,
                    l10n.achievements_levelPlus(5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.achievements_streakBonus,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _infoLine(
                    l10n.achievements_streak10,
                    l10n.achievements_levelPlus(1),
                  ),
                  _infoLine(
                    l10n.achievements_streak30,
                    l10n.achievements_levelPlus(30),
                  ),
                  _infoLine(
                    l10n.achievements_streak100,
                    l10n.achievements_levelPlus(50),
                  ),
                  _infoLine(
                    l10n.achievements_streak365,
                    l10n.achievements_levelPlus(300),
                  ),
                  _infoLine(
                    l10n.achievements_streak1000,
                    l10n.achievements_levelPlus(1000),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.achievements_gymCaliHint,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _infoLine(String left, String right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            right,
            style: TextStyle(
              color: AppColors.accentText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const AppHeaderLogo(),
        actions: [
          IconButton(
            tooltip: l10n.common_info,
            icon: Icon(Icons.info_outline, color: AppColors.textMuted),
            onPressed: () => _showInfo(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          RootShell.selectedTab.value = index;
        },
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: ProgressStore.listenable(),
        builder: (context, value, child) {
          final level = ProgressStore.userLevel;
          final rank = AchievementsCatalog.rankTitleForLevel(level, l10n);
          final remainingPercent =
              AchievementsCatalog.remainingPercentToNextMilestone(level);
          final nextMilestone = AchievementsCatalog.nextLevelMilestone(level);
          final earned = ProgressStore.earnedBadges;

          final all = AchievementsCatalog.allDefinitions(l10n);
          final milestones =
              all.where((d) => d.group == AchievementGroup.level).toList();
          final streaks =
              all.where((d) => d.group == AchievementGroup.streak).toList();
          final gym = all.where((d) => d.group == AchievementGroup.gym).toList();
          final cali = all
              .where((d) => d.group == AchievementGroup.calisthenics)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(
                  level: level,
                  rank: rank,
                  remainingPercent: remainingPercent,
                  nextMilestone: nextMilestone,
                ),
                const SizedBox(height: 16),
                _HorizontalSection(
                  title: l10n.achievements_milestones,
                  subtitle: l10n.achievements_earnedCount(
                    _earnedCount(milestones, earned),
                    milestones.length,
                  ),
                  items: milestones,
                  earned: earned,
                ),
                const SizedBox(height: 16),
                _HorizontalSection(
                  title: l10n.achievements_streaks,
                  subtitle: l10n.achievements_earnedCount(
                    _earnedCount(streaks, earned),
                    streaks.length,
                  ),
                  items: streaks,
                  earned: earned,
                ),
                const SizedBox(height: 16),
                _SpecializationsSection(
                  gym: gym,
                  calisthenics: cali,
                  earned: earned,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static int _earnedCount(List<AchievementDefinition> items, Set<String> earned) {
    var count = 0;
    for (final d in items) {
      if (earned.contains(d.id)) count++;
    }
    return count;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.level,
    required this.rank,
    required this.remainingPercent,
    required this.nextMilestone,
  });

  final int level;
  final String rank;
  final int remainingPercent;
  final int nextMilestone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final percentText = '${remainingPercent.clamp(0, 100)}%';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.achievements_coreLevel,
            style: TextStyle(
              color: AppColors.textMuted,
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.achievements_level(level),
            style: TextStyle(
              color: AppColors.accentText,
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w800,
              fontSize: 34,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.achievements_rank(rank),
            style: TextStyle(
              color: AppColors.textMuted,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _ProgressRing(
            remainingPercent: remainingPercent,
            centerTop: percentText,
            centerBottom: l10n.achievements_toNextMilestone,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.achievements_nextMilestone(nextMilestone),
            style: TextStyle(
              color: AppColors.textMuted,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.remainingPercent,
    required this.centerTop,
    required this.centerBottom,
  });

  final int remainingPercent;
  final String centerTop;
  final String centerBottom;

  @override
  Widget build(BuildContext context) {
    final value = (remainingPercent / 100.0).clamp(0.0, 1.0);
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 10,
              backgroundColor: AppColors.stroke.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.stroke.withValues(alpha: 0.35),
              ),
            ),
          ),
          SizedBox(
            width: 150,
            height: 150,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 10,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerTop,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'RobotoMono',
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                centerBottom,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: 'RobotoMono',
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HorizontalSection extends StatelessWidget {
  const _HorizontalSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.earned,
  });

  final String title;
  final String subtitle;
  final List<AchievementDefinition> items;
  final Set<String> earned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BadgeTimeline(
            items: items,
            earned: earned,
          ),
        ],
      ),
    );
  }
}

class _SpecializationsSection extends StatelessWidget {
  const _SpecializationsSection({
    required this.gym,
    required this.calisthenics,
    required this.earned,
  });

  final List<AchievementDefinition> gym;
  final List<AchievementDefinition> calisthenics;
  final Set<String> earned;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final earnedCount =
        AchievementsScreen._earnedCount(gym, earned) +
        AchievementsScreen._earnedCount(calisthenics, earned);
    final total = gym.length + calisthenics.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.achievements_specializations,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                l10n.achievements_earnedCount(earnedCount, total),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.achievements_gym,
            style: TextStyle(
              color: AppColors.textMuted,
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          _BadgeTimeline(items: gym, earned: earned),
          const SizedBox(height: 14),
          Text(
            l10n.achievements_calisthenics,
            style: TextStyle(
              color: AppColors.textMuted,
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          _BadgeTimeline(items: calisthenics, earned: earned),
        ],
      ),
    );
  }
}

class _BadgeTimeline extends StatefulWidget {
  const _BadgeTimeline({
    required this.items,
    required this.earned,
  });

  final List<AchievementDefinition> items;
  final Set<String> earned;

  @override
  State<_BadgeTimeline> createState() => _BadgeTimelineState();
}

class _BadgeTimelineState extends State<_BadgeTimeline> {
  final ScrollController _controller = ScrollController();
  bool _didCenter = false;

  static const double _tileWidth = 118;
  static const double _arrowWidth = 26;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _centerIndex() {
    var idx = 0;
    for (var i = 0; i < widget.items.length; i++) {
      if (widget.earned.contains(widget.items[i].id)) idx = i;
    }
    return idx;
  }

  void _maybeCenter(double viewportWidth) {
    if (_didCenter) return;
    _didCenter = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_controller.hasClients) return;
      final index = _centerIndex();
      final itemCenter = index * (_tileWidth + _arrowWidth) + (_tileWidth / 2);
      final target = (itemCenter - viewportWidth / 2).clamp(
        0.0,
        _controller.position.maxScrollExtent,
      );
      _controller.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maybeCenter(constraints.maxWidth);
        return SizedBox(
          height: 118,
          child: ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final def = widget.items[index];
              final isEarned = widget.earned.contains(def.id);
              return Row(
                children: [
                  SizedBox(
                    width: _tileWidth,
                    child: _BadgeTile(def: def, earned: isEarned),
                  ),
                  if (index != widget.items.length - 1)
                    SizedBox(
                      width: _arrowWidth,
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textMuted.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.def, required this.earned});

  final AchievementDefinition def;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final fg = earned ? def.color : AppColors.textMuted.withValues(alpha: 0.6);
    final opacity = earned ? 1.0 : 0.55;
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fg.withValues(alpha: earned ? 0.18 : 0.10),
                border: Border.all(
                  color: fg.withValues(alpha: earned ? 0.55 : 0.25),
                ),
              ),
              child: Icon(def.icon, color: fg, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              def.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: earned ? AppColors.textPrimary : AppColors.textMuted,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w800,
                fontSize: 11,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              def.subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMuted,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
