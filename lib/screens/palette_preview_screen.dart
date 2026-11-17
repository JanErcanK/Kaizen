import 'package:flutter/material.dart';

import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header_logo.dart';

class PalettePreviewScreen extends StatelessWidget {
  const PalettePreviewScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeaderLogo(),
              const SizedBox(height: 16),
              Text('Kaizen Color System', style: textStyle),
              const SizedBox(height: 16),
              _PaletteTile(
                name: 'Primary',
                hex: ProgressStore.useLightTheme ? '#6FAE00' : '#CCFF00',
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              _PaletteTile(
                name: 'Secondary',
                hex: '#BFE4FA',
                color: AppColors.secondary,
              ),
              const SizedBox(height: 12),
              const _PaletteTile(
                name: 'Tertiary',
                hex: '#FF3D00',
                color: AppColors.tertiary,
              ),
              const SizedBox(height: 12),
              _PaletteTile(
                name: 'Neutral',
                hex: ProgressStore.useLightTheme ? '#FAFAFA' : '#0A0A0A',
                color: AppColors.background,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.actionBackground,
                    foregroundColor: AppColors.onAction,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onContinue,
                  child: const Text('Continue to Start Screen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.name,
    required this.hex,
    required this.color,
  });

  final String name;
  final String hex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.stroke),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(hex, style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
