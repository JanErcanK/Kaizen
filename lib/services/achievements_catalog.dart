import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'progress_store.dart';

enum AchievementGroup { level, streak, gym, calisthenics }

class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.group,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String id;
  final AchievementGroup group;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _AchievementTemplate {
  const _AchievementTemplate({
    required this.id,
    required this.group,
    required this.icon,
    required this.color,
  });

  final String id;
  final AchievementGroup group;
  final IconData icon;
  final Color color;
}

class AchievementsCatalog {
  static const List<int> levelMilestones = <int>[
    0,
    20,
    50,
    100,
    300,
    500,
    1000,
    2500,
    5000,
    7500,
    10000,
  ];

  static const List<_AchievementTemplate> _templates = <_AchievementTemplate>[
    _AchievementTemplate(
      id: 'level_0_rookie',
      group: AchievementGroup.level,
      icon: Icons.shield_outlined,
      color: Color(0xFF9AA0A6),
    ),
    _AchievementTemplate(
      id: 'level_20_student',
      group: AchievementGroup.level,
      icon: Icons.school_outlined,
      color: Color(0xFF7AA7FF),
    ),
    _AchievementTemplate(
      id: 'level_50_trainee',
      group: AchievementGroup.level,
      icon: Icons.fitness_center_outlined,
      color: Color(0xFF67E8F9),
    ),
    _AchievementTemplate(
      id: 'level_100_performer',
      group: AchievementGroup.level,
      icon: Icons.bolt_outlined,
      color: Color(0xFFFFD166),
    ),
    _AchievementTemplate(
      id: 'level_300_profi',
      group: AchievementGroup.level,
      icon: Icons.workspace_premium_outlined,
      color: Color(0xFFFFC857),
    ),
    _AchievementTemplate(
      id: 'level_500_athlet',
      group: AchievementGroup.level,
      icon: Icons.emoji_events_outlined,
      color: Color(0xFFB6FF00),
    ),
    _AchievementTemplate(
      id: 'level_1000_krieger',
      group: AchievementGroup.level,
      icon: Icons.military_tech_outlined,
      color: Color(0xFFFF6B6B),
    ),
    _AchievementTemplate(
      id: 'level_2500_elite',
      group: AchievementGroup.level,
      icon: Icons.stars_outlined,
      color: Color(0xFFB388FF),
    ),
    _AchievementTemplate(
      id: 'level_5000_champion',
      group: AchievementGroup.level,
      icon: Icons.verified_outlined,
      color: Color(0xFFFFD700),
    ),
    _AchievementTemplate(
      id: 'level_7500_goat',
      group: AchievementGroup.level,
      icon: Icons.whatshot_outlined,
      color: Color(0xFFFF8A65),
    ),
    _AchievementTemplate(
      id: 'level_10000_halbgott',
      group: AchievementGroup.level,
      icon: Icons.auto_awesome_outlined,
      color: Color(0xFF00E5FF),
    ),
    _AchievementTemplate(
      id: 'streak_30_discipline_month',
      group: AchievementGroup.streak,
      icon: Icons.calendar_month_outlined,
      color: Color(0xFFB6FF00),
    ),
    _AchievementTemplate(
      id: 'streak_100_discipline_medal',
      group: AchievementGroup.streak,
      icon: Icons.military_tech_outlined,
      color: Color(0xFFFFD166),
    ),
    _AchievementTemplate(
      id: 'streak_365_iron_discipline',
      group: AchievementGroup.streak,
      icon: Icons.shield_outlined,
      color: Color(0xFFE5E7EB),
    ),
    _AchievementTemplate(
      id: 'streak_500_warrior_mindset',
      group: AchievementGroup.streak,
      icon: Icons.sports_mma_outlined,
      color: Color(0xFFFF6B6B),
    ),
    _AchievementTemplate(
      id: 'streak_1000_demigod_mindset',
      group: AchievementGroup.streak,
      icon: Icons.auto_awesome_outlined,
      color: Color(0xFF00E5FF),
    ),
    _AchievementTemplate(
      id: 'gym_50_junior',
      group: AchievementGroup.gym,
      icon: Icons.fitness_center_outlined,
      color: Color(0xFF67E8F9),
    ),
    _AchievementTemplate(
      id: 'gym_100_profi',
      group: AchievementGroup.gym,
      icon: Icons.verified_outlined,
      color: Color(0xFFB6FF00),
    ),
    _AchievementTemplate(
      id: 'gym_500_bodybuilding_junior',
      group: AchievementGroup.gym,
      icon: Icons.sports_gymnastics_outlined,
      color: Color(0xFFFFD166),
    ),
    _AchievementTemplate(
      id: 'gym_1000_bodybuilder',
      group: AchievementGroup.gym,
      icon: Icons.emoji_events_outlined,
      color: Color(0xFFFFD700),
    ),
    _AchievementTemplate(
      id: 'cali_50_junior',
      group: AchievementGroup.calisthenics,
      icon: Icons.accessibility_new_outlined,
      color: Color(0xFF67E8F9),
    ),
    _AchievementTemplate(
      id: 'cali_100_profi',
      group: AchievementGroup.calisthenics,
      icon: Icons.verified_outlined,
      color: Color(0xFFB6FF00),
    ),
    _AchievementTemplate(
      id: 'cali_500_bodybuilding_junior',
      group: AchievementGroup.calisthenics,
      icon: Icons.sports_martial_arts_outlined,
      color: Color(0xFFFFD166),
    ),
    _AchievementTemplate(
      id: 'cali_1000_bodybuilder',
      group: AchievementGroup.calisthenics,
      icon: Icons.emoji_events_outlined,
      color: Color(0xFFFFD700),
    ),
  ];

  static String rankTitleForLevel(int level, AppLocalizations l10n) {
    if (level >= 10000) return l10n.rank_halbgott;
    if (level >= 7500) return l10n.rank_goat;
    if (level >= 5000) return l10n.rank_champion;
    if (level >= 2500) return l10n.rank_elite;
    if (level >= 1000) return l10n.rank_krieger;
    if (level >= 500) return l10n.rank_athlet;
    if (level >= 300) return l10n.rank_profi;
    if (level >= 100) return l10n.rank_performer;
    if (level >= 50) return l10n.rank_trainee;
    if (level >= 20) return l10n.rank_student;
    return l10n.rank_rookie;
  }

  static (String title, String subtitle) badgeText(
    String id,
    AppLocalizations l10n,
  ) {
    switch (id) {
      case 'level_0_rookie':
        return (l10n.badge_level0_title, l10n.badge_level0_subtitle);
      case 'level_20_student':
        return (l10n.badge_level20_title, l10n.badge_level20_subtitle);
      case 'level_50_trainee':
        return (l10n.badge_level50_title, l10n.badge_level50_subtitle);
      case 'level_100_performer':
        return (l10n.badge_level100_title, l10n.badge_level100_subtitle);
      case 'level_300_profi':
        return (l10n.badge_level300_title, l10n.badge_level300_subtitle);
      case 'level_500_athlet':
        return (l10n.badge_level500_title, l10n.badge_level500_subtitle);
      case 'level_1000_krieger':
        return (l10n.badge_level1000_title, l10n.badge_level1000_subtitle);
      case 'level_2500_elite':
        return (l10n.badge_level2500_title, l10n.badge_level2500_subtitle);
      case 'level_5000_champion':
        return (l10n.badge_level5000_title, l10n.badge_level5000_subtitle);
      case 'level_7500_goat':
        return (l10n.badge_level7500_title, l10n.badge_level7500_subtitle);
      case 'level_10000_halbgott':
        return (l10n.badge_level10000_title, l10n.badge_level10000_subtitle);
      case 'streak_30_discipline_month':
        return (l10n.badge_streak30_title, l10n.badge_streak30_subtitle);
      case 'streak_100_discipline_medal':
        return (l10n.badge_streak100_title, l10n.badge_streak100_subtitle);
      case 'streak_365_iron_discipline':
        return (l10n.badge_streak365_title, l10n.badge_streak365_subtitle);
      case 'streak_500_warrior_mindset':
        return (l10n.badge_streak500_title, l10n.badge_streak500_subtitle);
      case 'streak_1000_demigod_mindset':
        return (l10n.badge_streak1000_title, l10n.badge_streak1000_subtitle);
      case 'gym_50_junior':
        return (l10n.badge_gym50_title, l10n.badge_gym50_subtitle);
      case 'gym_100_profi':
        return (l10n.badge_gym100_title, l10n.badge_gym100_subtitle);
      case 'gym_500_bodybuilding_junior':
        return (l10n.badge_gym500_title, l10n.badge_gym500_subtitle);
      case 'gym_1000_bodybuilder':
        return (l10n.badge_gym1000_title, l10n.badge_gym1000_subtitle);
      case 'cali_50_junior':
        return (l10n.badge_cali50_title, l10n.badge_cali50_subtitle);
      case 'cali_100_profi':
        return (l10n.badge_cali100_title, l10n.badge_cali100_subtitle);
      case 'cali_500_bodybuilding_junior':
        return (l10n.badge_cali500_title, l10n.badge_cali500_subtitle);
      case 'cali_1000_bodybuilder':
        return (l10n.badge_cali1000_title, l10n.badge_cali1000_subtitle);
      default:
        return ('', '');
    }
  }

  static int previousLevelMilestone(int level) {
    var prev = 0;
    for (final m in levelMilestones) {
      if (m <= level) {
        prev = m;
      } else {
        break;
      }
    }
    return prev;
  }

  static int nextLevelMilestone(int level) {
    for (final m in levelMilestones) {
      if (m > level) return m;
    }
    return levelMilestones.last;
  }

  /// Returns remaining percent (0..100) needed to reach the next milestone.
  static int remainingPercentToNextMilestone(int level) {
    final next = nextLevelMilestone(level);
    final prev = previousLevelMilestone(level);
    if (next <= prev) return 0;
    final progress = ((level - prev) / (next - prev)).clamp(0.0, 1.0);
    final remaining = (1.0 - progress) * 100.0;
    return remaining.round().clamp(0, 100);
  }

  static List<AchievementDefinition> allDefinitions(AppLocalizations l10n) {
    return _templates.map((template) {
      final text = badgeText(template.id, l10n);
      return AchievementDefinition(
        id: template.id,
        group: template.group,
        title: text.$1,
        subtitle: text.$2,
        icon: template.icon,
        color: template.color,
      );
    }).toList();
  }

  static List<AchievementDefinition> earnedDefinitions(AppLocalizations l10n) {
    final earned = ProgressStore.earnedBadges;
    final all = allDefinitions(l10n);
    return all.where((d) => earned.contains(d.id)).toList();
  }
}
