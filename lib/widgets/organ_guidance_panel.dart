import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/catalog_localizations.dart';
import '../screens/food_screen.dart';
import '../services/organ_guidance.dart';
import '../theme/app_colors.dart';
import 'shopping_food_button.dart';

class OrganGuidancePanel extends StatelessWidget {
  const OrganGuidancePanel({
    super.key,
    required this.organId,
    this.prioritizeActions = false,
  });
  final String organId;
  final bool prioritizeActions;

  @override
  Widget build(BuildContext context) {
    final de = Localizations.localeOf(context).languageCode == 'de';
    final guidance = OrganGuidance.forOrgan(organId);
    final tips = de ? guidance.tipsDe : guidance.tipsEn;
    Widget tip(String text) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '• $text',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          height: 1.45,
        ),
      ),
    );
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            de ? 'Was du tun kannst' : 'What you can do',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final text in prioritizeActions ? tips.take(1) : tips) tip(text),
          const SizedBox(height: 16),
          Text(
            de ? 'Ideen für deinen Teller' : 'Ideas for your plate',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final name in guidance.foods)
            Padding(
              key: ValueKey('organ-food-$name'),
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CatalogLocalizations.foodName(name),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final action in CatalogFoodAction.values)
                        OutlinedButton.icon(
                          onPressed: () => showCatalogFoodDetails(
                            context,
                            name,
                            action: action,
                            grams: OrganGuidance.portion(name),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            textStyle: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                            ),
                          ),
                          icon: Icon(
                            action == CatalogFoodAction.today
                                ? Icons.today_outlined
                                : Icons.restaurant_menu,
                            size: 16,
                          ),
                          label: Text(
                            action == CatalogFoodAction.today
                                ? (de ? 'Heute' : 'Today')
                                : (de ? 'Gericht' : 'Dish'),
                          ),
                        ),
                      ShoppingFoodButton(
                        name: CatalogLocalizations.foodName(name),
                        compact: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          if (prioritizeActions) ...[
            Text(
              de ? 'Weitere Alltagstipps' : 'More everyday tips',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            for (final text in tips.skip(1)) tip(text),
            const SizedBox(height: 12),
          ],
          Text(
            de
                ? 'Alltagstipps und Ernährungsideen; die Ansicht misst keine Organfunktion.'
                : 'Everyday tips and food ideas; this view does not measure organ function.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              de ? 'Quellen' : 'Sources',
              style: const TextStyle(fontSize: 12),
            ),
            children: [
              for (final source in guidance.sources.entries)
                TextButton(
                  onPressed: () async {
                    final opened = await launchUrl(
                      Uri.parse(source.value),
                      mode: LaunchMode.externalApplication,
                    );
                    if (!opened && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            de
                                ? 'Quelle konnte nicht geöffnet werden.'
                                : 'Could not open source.',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(source.key, style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
