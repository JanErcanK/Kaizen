import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const double barHeight = 68;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isHome = selectedIndex == 0;
    final isProfile = selectedIndex == 1;

    return Material(
      color: AppColors.card,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight,
          child: Row(
            children: [
              Expanded(
                child: _NavPillItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  selected: selectedIndex == 2,
                  onTap: () => onDestinationSelected(2),
                ),
              ),
              Expanded(
                child: _NavPillItem(
                  icon: Icons.home_rounded,
                  label: l10n.nav_home,
                  selected: isHome,
                  onTap: () => onDestinationSelected(0),
                ),
              ),
              Expanded(
                child: _NavPillItem(
                  icon: Icons.person_outline_rounded,
                  label: l10n.nav_profile,
                  selected: isProfile,
                  onTap: () => onDestinationSelected(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavPillItem extends StatelessWidget {
  const _NavPillItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Roboto',
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? AppColors.accentText : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
