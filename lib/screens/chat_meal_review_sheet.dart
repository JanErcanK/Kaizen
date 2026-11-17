import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/ai_chat.dart';
import '../services/progress_store.dart';

class ChatMealReviewSheet extends StatefulWidget {
  const ChatMealReviewSheet({
    super.key,
    required this.message,
    required this.onSaved,
  });
  final ChatMessage message;
  final Future<void> Function() onSaved;
  @override
  State<ChatMealReviewSheet> createState() => _ChatMealReviewSheetState();
}

class _ChatMealReviewSheetState extends State<ChatMealReviewSheet> {
  late List<MealFood> _foods;
  late DateTime _day;
  bool _saving = false;
  String? _error;
  String t(String de, String en) =>
      Localizations.localeOf(context).languageCode == 'de' ? de : en;
  @override
  void initState() {
    super.initState();
    _foods = [...widget.message.meal!.foods];
    _day = widget.message.createdAt;
  }

  Future<void> _edit(int index) async {
    final food = _foods[index];
    final controllers = [
      food.name,
      '${food.grams}',
      '${food.proteinG}',
      '${food.carbsG}',
      '${food.fatsG}',
    ].map((text) => TextEditingController(text: text)).toList();
    String? error;
    final updated = await showDialog<MealFood>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(t('Portion bearbeiten', 'Edit portion')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < controllers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: controllers[i],
                      keyboardType: i == 0
                          ? TextInputType.text
                          : const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                      onChanged: i == 1
                          ? (raw) {
                              final amount = double.tryParse(
                                raw.replaceAll(',', '.'),
                              );
                              if (amount != null &&
                                  amount > 0 &&
                                  amount.isFinite) {
                                final scaled = food.scaledTo(amount);
                                controllers[2].text = scaled.proteinG
                                    .toStringAsFixed(1);
                                controllers[3].text = scaled.carbsG
                                    .toStringAsFixed(1);
                                controllers[4].text = scaled.fatsG
                                    .toStringAsFixed(1);
                              }
                            }
                          : null,
                      decoration: InputDecoration(
                        labelText: [
                          t('Lebensmittel', 'Food'),
                          t('Menge (g)', 'Amount (g)'),
                          t('Eiweiß (g)', 'Protein (g)'),
                          t('Kohlenhydrate (g)', 'Carbs (g)'),
                          t('Fett (g)', 'Fat (g)'),
                        ][i],
                      ),
                    ),
                  ),
                Text(
                  t(
                    'Makros gelten für die gesamte Portion. Bei Mengenänderung werden sie proportional angepasst.',
                    'Macros are for the whole portion. Changing the amount scales them proportionally.',
                  ),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('Abbrechen', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                double n(int i) =>
                    double.tryParse(controllers[i].text.replaceAll(',', '.')) ??
                    double.nan;
                final next = MealFood(
                  name: controllers[0].text.trim(),
                  grams: n(1),
                  proteinG: n(2),
                  carbsG: n(3),
                  fatsG: n(4),
                );
                if (!next.isValid) {
                  setLocal(
                    () => error = t(
                      'Bitte gültige Mengen und Makros eingeben.',
                      'Enter valid amounts and macros.',
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, next);
              },
              child: Text(t('Übernehmen', 'Apply')),
            ),
          ],
        ),
      ),
    );
    // Controllers stay alive through the dialog's reverse transition.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final controller in controllers) {
      controller.dispose();
    }
    if (mounted && updated != null) setState(() => _foods[index] = updated);
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final meal = MealDraft(
      name: widget.message.meal!.name,
      foods: _foods,
      assumptions: widget.message.meal!.assumptions,
    );
    try {
      await ProgressStore.confirmChatMeal(
        sourceId: widget.message.id,
        meal: meal,
        at: _day,
      );
      widget.message.meal = meal;
      widget.message.loggedAt = _day;
      await widget.onSaved();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = t(
            'Speichern fehlgeschlagen. Du kannst es erneut versuchen; es entstehen keine doppelten Einträge.',
            'Saving failed. You can try again; entries will not be duplicated.',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.message.meal!;
    final totals = MealDraft(
      name: draft.name,
      foods: _foods,
      assumptions: draft.assumptions,
    ).totals;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t('Mahlzeit prüfen', 'Review meal'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                t(
                  'KI-Schätzung · Bitte Mengen und Zutaten prüfen.',
                  'AI estimate · Check portions and ingredients.',
                ),
              ),
              if (draft.assumptions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(draft.assumptions),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(
                  DateFormat.yMMMd(
                    Localizations.localeOf(context).languageCode,
                  ).format(_day),
                ),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: _saving
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _day,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (mounted && date != null) {
                          setState(() => _day = date);
                        }
                      },
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _foods.length,
                itemBuilder: (context, i) {
                  final food = _foods[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${food.name} · ${food.grams.toStringAsFixed(0)} g',
                    ),
                    subtitle: Text(
                      '${food.nutrients.kcal} kcal · P ${food.proteinG.toStringAsFixed(1)} · C ${food.carbsG.toStringAsFixed(1)} · F ${food.fatsG.toStringAsFixed(1)} g',
                    ),
                    onTap: _saving ? null : () => _edit(i),
                    trailing: IconButton(
                      tooltip: t('Entfernen', 'Remove'),
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _saving
                          ? null
                          : () => setState(() => _foods.removeAt(i)),
                    ),
                  );
                },
              ),
              const Divider(),
              Text(
                '${totals.kcal} kcal',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                '${t("Eiweiß", "Protein")} ${totals.proteinG.toStringAsFixed(1)} g · '
                '${t("Kohlenhydrate", "Carbs")} ${totals.carbsG.toStringAsFixed(1)} g · '
                '${t("Fett", "Fat")} ${totals.fatsG.toStringAsFixed(1)} g',
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('confirm-chat-meal'),
                onPressed: _saving || _foods.isEmpty ? null : _confirm,
                icon: const Icon(Icons.check),
                label: Text(
                  _saving
                      ? t('Wird eingetragen …', 'Saving …')
                      : t('Bestätigen & eintragen', 'Confirm & log'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
