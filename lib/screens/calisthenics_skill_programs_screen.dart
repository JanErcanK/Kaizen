import '../widgets/app_back_button.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header_logo.dart';

class CalisthenicsSkillProgramsScreen extends StatelessWidget {
  const CalisthenicsSkillProgramsScreen({super.key, required this.skillName});

  final String skillName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        leadingWidth: 44,
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: const AppHeaderLogo(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            skillName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.cali_skillProgramsIntro,
            style: TextStyle(color: AppColors.textMuted, height: 1.3),
          ),
          const SizedBox(height: 16),
          _ProgramCard(
            title: l10n.cali_programBeginner,
            subtitle: l10n.cali_programBeginnerSub,
          ),
          const SizedBox(height: 10),
          _ProgramCard(
            title: l10n.cali_programIntermediate,
            subtitle: l10n.cali_programIntermediateSub,
          ),
          const SizedBox(height: 10),
          _ProgramCard(
            title: l10n.cali_programAdvanced,
            subtitle: l10n.cali_programAdvancedSub,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppColors.surfaceDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.cali_programPlaceholder,
              style: TextStyle(color: AppColors.textMuted, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.school_outlined, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
