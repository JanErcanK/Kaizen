import 'package:flutter/material.dart';

import '../data/stretch_exercise_catalog.dart';
import '../theme/app_colors.dart';
import 'workout_player_screen.dart';

void startStretching(BuildContext context, List<StretchExercise> exercises) {
  final de = Localizations.localeOf(context).languageCode == 'de';
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WorkoutPlayerScreen(
        showInstructions: true,
        workoutType: 'stretch',
        workoutName: de ? 'Dehnen & Mobilität' : 'Stretching & mobility',
        exercises: [
          for (final e in exercises)
            WorkoutExercise(
              name: e.name(de),
              benefit:
                  '${e.instructions(de)} ${de ? 'Bei einseitigen Übungen anschließend die Seite wechseln.' : 'For one-sided exercises, repeat on the other side afterwards.'}',
              workSeconds: 30,
            ),
        ],
      ),
    ),
  );
}

class StretchCatalogScreen extends StatefulWidget {
  const StretchCatalogScreen({super.key, this.initialQuery = ''});
  final String initialQuery;

  @override
  State<StretchCatalogScreen> createState() => _StretchCatalogScreenState();
}

class _StretchCatalogScreenState extends State<StretchCatalogScreen> {
  late final _search = TextEditingController(text: widget.initialQuery);
  final _selected = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final de = Localizations.localeOf(context).languageCode == 'de';
    final matches = stretchExercises
        .where((e) => e.matches(_search.text))
        .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(de ? 'Dehnen & Mobilität' : 'Stretching & mobility'),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: de
                    ? '${stretchExercises.length} Übungen durchsuchen'
                    : 'Search ${stretchExercises.length} exercises',
                suffixIcon: IconButton(
                  tooltip: de ? 'Suche leeren' : 'Clear search',
                  onPressed: () => setState(_search.clear),
                  icon: const Icon(Icons.clear),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              de
                  ? 'Kurz aufwärmen. Sanft und ohne Federn bewegen; Dehnungen 10–30 Sekunden schmerzfrei halten. Einseitige Übungen auf beiden Seiten ausführen.'
                  : 'Warm up first. Move gently without bouncing; hold stretches comfortably for 10–30 seconds. Repeat one-sided exercises on both sides.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: matches.isEmpty
                ? Center(
                    child: Text(
                      de ? 'Keine passenden Übungen' : 'No matching exercises',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: matches.length + 1,
                    itemBuilder: (context, index) {
                      if (index == matches.length) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            de
                                ? 'Übungsauswahl: Free Exercise DB (Unlicense), ergänzt und neu beschrieben. Empfehlungen nach Körperregion.'
                                : 'Exercise selection: Free Exercise DB (Unlicense), supplemented with rewritten guidance. Suggestions are based on body region.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }
                      final exercise = matches[index];
                      return Card(
                        color: AppColors.card,
                        child: ExpansionTile(
                          key: ValueKey('stretch-${exercise.id}'),
                          title: Text(exercise.name(de)),
                          leading: Checkbox(
                            value: _selected.contains(exercise.id),
                            onChanged: (value) => setState(() {
                              if (value == true) {
                                _selected.add(exercise.id);
                              } else {
                                _selected.remove(exercise.id);
                              }
                            }),
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            12,
                          ),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exercise.instructions(de)),
                            TextButton.icon(
                              onPressed: () =>
                                  startStretching(context, [exercise]),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(
                                de ? '30 Sekunden starten' : 'Start 30 seconds',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => startStretching(
                    context,
                    stretchExercises
                        .where((e) => _selected.contains(e.id))
                        .toList(),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    de
                        ? '${_selected.length} Übungen starten'
                        : 'Start ${_selected.length} exercises',
                  ),
                ),
              ),
            ),
    );
  }
}
