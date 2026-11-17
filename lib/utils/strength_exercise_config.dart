import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../l10n/l10n_extension.dart';

class StrengthExerciseConfig {
  StrengthExerciseConfig._();

  static const int defaultSets = 3;
  static const int defaultReps = 10;
  static const int maxSets = 100;

  static bool isTimed(Map exercise) =>
      exercise['setSeconds'] is List &&
      (exercise['setSeconds'] as List).isNotEmpty;

  static List<int> setValues(Map exercise) {
    final timed = isTimed(exercise);
    final raw = timed ? exercise['setSeconds'] : exercise['setReps'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .take(maxSets)
          .map(
            (v) => _readInt(
              v,
              timed ? 30 : defaultReps,
            ).clamp(1, timed ? 3600 : 999),
          )
          .toList();
    }
    return List.filled(
      _readInt(exercise['sets'], defaultSets).clamp(1, maxSets),
      _readInt(exercise['reps'], defaultReps).clamp(1, 999),
    );
  }

  static int readSets(Map<String, dynamic> exercise) =>
      setValues(exercise).length;
  static List<int> readSetReps(Map<String, dynamic> exercise) =>
      isTimed(exercise) ? [] : setValues(exercise);
  static int readReps(Map<String, dynamic> exercise) =>
      isTimed(exercise) ? 0 : setValues(exercise).first;

  static String formatShort(Map<String, dynamic> exercise) {
    final values = setValues(exercise);
    final summary = values.every((v) => v == values.first)
        ? '${values.length} × ${values.first}'
        : values.join('–');
    return isTimed(exercise) ? '$summary s' : summary;
  }

  static Map<String, dynamic> applyDefaults(Map<String, dynamic> exercise) =>
      _withValues(exercise, setValues(exercise), isTimed(exercise));

  static Map<String, dynamic> _withValues(
    Map<String, dynamic> exercise,
    List<int> values,
    bool timed,
  ) {
    final result = Map<String, dynamic>.of(exercise)
      ..remove('setSeconds')
      ..remove('setReps')
      ..remove('reps');
    return {
      ...result,
      'sets': values.length,
      if (timed)
        'setSeconds': values
      else ...{
        'setReps': values,
        'reps': values.first,
      },
    };
  }

  static double readWeight(Map<String, dynamic> exercise) =>
      double.tryParse(exercise['weight']?.toString() ?? '') ?? 0;

  static Future<Map<String, dynamic>?> edit(
    BuildContext context, {
    required String exerciseName,
    required Map<String, dynamic> exercise,
  }) => showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.card,
    showDragHandle: true,
    builder: (_) => _SetEditor(name: exerciseName, exercise: exercise),
  );

  static int _readInt(Object? value, int fallback) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
}

class _SetEditor extends StatefulWidget {
  const _SetEditor({required this.name, required this.exercise});
  final String name;
  final Map<String, dynamic> exercise;
  @override
  State<_SetEditor> createState() => _SetEditorState();
}

class _SetEditorState extends State<_SetEditor> {
  final form = GlobalKey<FormState>();
  late final initiallyTimed = StrengthExerciseConfig.isTimed(widget.exercise);
  late bool timed = initiallyTimed;
  late final initial = StrengthExerciseConfig.setValues(widget.exercise);
  late final counts = TextEditingController(text: initial.length.toString());
  late final reps = TextEditingController(
    text: initiallyTimed ? '10' : initial.first.toString(),
  );
  late final seconds = TextEditingController(
    text: initiallyTimed ? initial.first.toString() : '30',
  );
  late final weight = TextEditingController(
    text: widget.exercise['weight']?.toString() ?? '',
  );
  late final overrides = <bool, Map<int, int>>{
    initiallyTimed: {
      for (var i = 0; i < initial.length; i++)
        if (initial[i] != initial.first) i: initial[i],
    },
    !initiallyTimed: {},
  };
  bool individual = false;

  @override
  void dispose() {
    for (final field in [counts, reps, seconds, weight]) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final de = Localizations.localeOf(context).languageCode == 'de';
    final label = timed
        ? (de ? 'Sekunden pro Satz' : 'Seconds per set')
        : context.l10n.strength_repsLabel;
    final controller = timed ? seconds : reps;
    final limit = timed ? 3600 : 999;
    final sets = (int.tryParse(counts.text) ?? 0).clamp(
      0,
      StrengthExerciseConfig.maxSets,
    );
    String? validate(String? v, int max) {
      final n = int.tryParse(v ?? '');
      return n != null && n >= 1 && n <= max ? null : '1–$max';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(context.l10n.strength_repsLabel),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.timer_outlined),
                      label: Text(de ? 'Zeit' : 'Time'),
                    ),
                  ],
                  selected: {timed},
                  onSelectionChanged: (s) => setState(() => timed = s.single),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: counts,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: context.l10n.strength_setsLabel,
                        ),
                        validator: (v) =>
                            validate(v, StrengthExerciseConfig.maxSets),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        key: ValueKey(timed),
                        controller: controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(labelText: label),
                        validator: (v) => validate(v, limit),
                        onChanged: (_) =>
                            setState(() => overrides[timed]!.clear()),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => setState(() => individual = !individual),
                  icon: Icon(
                    individual ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(
                    de ? 'Sätze einzeln anpassen' : 'Adjust individual sets',
                  ),
                ),
                if (individual)
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < sets; i++)
                        ActionChip(
                          label: Text(
                            'S${i + 1} · ${overrides[timed]![i] ?? controller.text}${timed ? ' s' : ''}',
                          ),
                          onPressed: () async {
                            var value =
                                (overrides[timed]![i]?.toString() ??
                                controller.text);
                            final next = await showDialog<int>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('${de ? 'Satz' : 'Set'} ${i + 1}'),
                                content: TextFormField(
                                  initialValue: value,
                                  autofocus: true,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(labelText: label),
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: (v) => validate(v, limit),
                                  onChanged: (v) => value = v,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(ctx.l10n.common_cancel),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      if (validate(value, limit) == null)
                                        Navigator.pop(ctx, int.parse(value));
                                    },
                                    child: Text(ctx.l10n.common_save),
                                  ),
                                ],
                              ),
                            );
                            if (next != null && mounted)
                              setState(() => overrides[timed]![i] = next);
                          },
                        ),
                    ],
                  ),
                TextFormField(
                  controller: weight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: de ? 'Gewicht (optional)' : 'Weight (optional)',
                    suffixText: 'kg',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    return n != null && n.isFinite && n >= 0 && n <= 5000
                        ? null
                        : '0–5000';
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (!form.currentState!.validate()) return;
                    final values = List.generate(
                      sets,
                      (i) => overrides[timed]![i] ?? int.parse(controller.text),
                    );
                    Navigator.pop(context, {
                      ...StrengthExerciseConfig._withValues(
                        widget.exercise,
                        values,
                        timed,
                      ),
                      'weight':
                          double.tryParse(weight.text.replaceAll(',', '.')) ??
                          0.0,
                    });
                  },
                  child: Text(context.l10n.common_save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
