import 'package:flutter/material.dart';

import '../services/progress_store.dart';
import '../theme/app_colors.dart';

/// Compact, shared segmented navigation for category screen headers.
class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.controller,
    required this.labels,
    required this.accent,
    this.softSelection = false,
  });

  final TabController controller;
  final List<String> labels;
  final Color accent;
  final bool softSelection;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: ProgressStore.useLightTheme
          ? const Color(0xFFF2F2F7)
          : const Color(0xFF2C2C2E),
      borderRadius: BorderRadius.circular(14),
    ),
    child: TabBar(
      controller: controller,
      indicator: BoxDecoration(
        color: softSelection
            ? Color.alphaBlend(accent.withValues(alpha: 0.12), AppColors.card)
            : AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: softSelection ? 0.06 : 0.28),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      labelColor: accent,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      tabs: [
        for (final label in labels)
          Tab(
            height: softSelection ? 40 : 36,
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
          ),
      ],
    ),
  );
}
