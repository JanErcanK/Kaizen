import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../models/body_map_view_mode.dart';
import '../services/anatomy_tips.dart';
import '../theme/app_colors.dart';

class BodyMapTabIntroDialog {
  BodyMapTabIntroDialog._();

  static String title(AppLocalizations l10n, BodyMapViewMode mode) {
    final german = l10n.localeName.startsWith('de');
    return mode == BodyMapViewMode.skeleton
        ? (german ? 'Skelett & Knorpel' : 'Skeleton & cartilage')
        : mode.anatomyLabel(german);
  }

  static String legend(bool german, BodyMapViewMode mode) => switch (mode) {
    BodyMapViewMode.organs => german ? 'Gold: ausgewählt' : 'Gold: selected',
    BodyMapViewMode.connective =>
      german
          ? 'Rosa: Sehnen · Weiß: Bänder · Blauer Außenrand: am Training beteiligt · Grün: ausgewählt'
          : 'Pink: tendons · White: ligaments · Blue outline: involved in training · Green: selected',
    BodyMapViewMode.skeleton =>
      german
          ? 'Markiert: am Training beteiligt · Grün: ausgewählt'
          : 'Highlighted: involved in training · Green: selected',
    _ =>
      german
          ? 'Gelb bei Training · Rot bei hoher Belastung · Blaues Leuchten bei Nachbrennen · Grün bei Auswahl'
          : 'Yellow for training · Red for high load · Blue glow for afterburn · Green for selection',
  };

  static Future<void> show(BuildContext context, BodyMapViewMode mode) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = context.l10n;
    final german = l10n.localeName.startsWith('de');
    final tips = AnatomyTips.forMode(mode);
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * .82,
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          decoration: AppColors.surfaceDecoration(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title(l10n, mode),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                german
                    ? '10 praktische Tipps für deinen Alltag'
                    : '10 practical tips for everyday life',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                legend(german, mode),
                key: const ValueKey('anatomy-color-legend'),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  key: const ValueKey('anatomy-tips-list'),
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: tips.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 28, color: AppColors.stroke),
                  itemBuilder: (_, index) => _TipRow(
                    key: ValueKey('anatomy-tip-${tips[index].id}'),
                    number: index + 1,
                    tip: tips[index],
                    german: german,
                  ),
                ),
              ),
              Divider(height: 1, color: AppColors.stroke),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size(88, 44),
                    textStyle: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.common_close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({
    super.key,
    required this.number,
    required this.tip,
    required this.german,
  });

  final int number;
  final AnatomyTip tip;
  final bool german;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.softSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$number',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tip.title(german),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              tip.description(german),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
