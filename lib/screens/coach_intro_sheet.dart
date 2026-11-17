import 'package:flutter/material.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';

class CoachIntroSheet extends StatefulWidget {
  const CoachIntroSheet({super.key});
  @override
  State<CoachIntroSheet> createState() => _CoachIntroSheetState();
}

class _CoachIntroSheetState extends State<CoachIntroSheet> {
  int _step = 0;
  bool _personal = ProgressStore.chatSettings['shareFitnessContext'] == true;
  bool _saving = false;
  String t(String de, String en) =>
      Localizations.localeOf(context).languageCode == 'de' ? de : en;

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await ProgressStore.saveChatSettings({
        ...ProgressStore.chatSettings,
        'coachIntroSeen': true,
        'shareFitnessContext': _personal,
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('Bitte erneut versuchen.', 'Please try again.')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gold = _step == 2;
    final light = Theme.of(context).brightness == Brightness.light;
    final palette = AppColors.paletteFor(light);
    final accent = gold ? const Color(0xFF8A5800) : palette.accentText;
    final name = ProgressStore.profileName.trim();
    final titles = [
      t(
        name.isEmpty
            ? 'Dein Essen. Einfach erfasst.'
            : '$name, mach ein Foto von deinem Essen.',
        name.isEmpty
            ? 'Your food. Simply tracked.'
            : '$name, take a photo of your meal.',
      ),
      t('Dein Coach kennt deinen Alltag.', 'Your coach, your routine.'),
      t('Vom Video zu deinem Workout.', 'From video to your workout.'),
    ];
    final bodies = [
      t(
        'Lade ein Foto deiner Mahlzeit hoch. Dein Coach schätzt Portionen, Kalorien, Makros und Mikronährstoffe und hilft dir beim Eintragen. Mengen und versteckte Zutaten kannst du korrigieren — die Werte bleiben Schätzungen.',
        'Upload a meal photo. Your coach estimates portions, calories, macros and micronutrients and helps you log it. You can correct quantities and hidden ingredients — the values remain estimates.',
      ),
      t(
        'Mit deiner Datenfreigabe wertet dein Coach bis zu acht Wochen Training aus und schlägt konkrete nächste Schritte vor. Er berücksichtigt deine Ziele, Übungsentwicklung und verfügbare Ernährungs- und Gesundheitsdaten. Besprich Änderungen im Chat und speichere passende Vorschläge.',
        'With data sharing enabled, your coach analyzes up to eight weeks of training and suggests practical next steps. It considers your goals, exercise trends and available nutrition and health data. Discuss changes in chat and save suitable proposals.',
      ),
      t(
        'Teile Inhalte mit Kaizen und starte direkt einen neuen Coach-Chat. Aus Videobildern erkennt die KI Übungen und schlägt ein Workout vor. Erst du entscheidest, ob du es speicherst oder ändern lässt.\n\nBei Social-Media-Links wird häufig nur die Adresse geteilt. Füge dann die Videodatei oder Screenshots hinzu. Aktuell: Android, Videos bis 3 Minuten, visuelle Analyse ohne Ton.',
        'Share content to Kaizen to start a new coach chat. AI identifies exercises from video images and proposes a workout. You decide whether to save it or request changes.\n\nSocial apps often share only a link. Add the video file or screenshots in that case. Currently: Android, videos up to 3 minutes, visual analysis without audio.',
      ),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? (gold ? accent : palette.accent)
                            : palette.stroke,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Flexible(
              child: SingleChildScrollView(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gold
                          ? [
                              const Color(0xFFFFE6A3),
                              const Color(0xFFFFF9E8),
                              const Color(0xFFF2CE77),
                            ]
                          : [
                              light
                                  ? (_step == 0
                                        ? palette.actionBackground
                                        : palette.selectedBackground)
                                  : palette.softSurface,
                              palette.surface,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: accent.withValues(alpha: .2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        [
                          Icons.add_a_photo_outlined,
                          Icons.favorite_outline,
                          Icons.auto_awesome,
                        ][_step],
                        size: 44,
                        color: accent,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        gold
                            ? t('NEU · VIDEO-WORKOUTS', 'NEW · VIDEO WORKOUTS')
                            : t('DEIN KAIZEN COACH', 'YOUR KAIZEN COACH'),
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        titles[_step],
                        style: TextStyle(
                          color: accent,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        bodies[_step],
                        style: TextStyle(
                          color: gold ? const Color(0xFF493717) : palette.text,
                          height: 1.5,
                        ),
                      ),
                      if (_step == 1) ...[
                        const SizedBox(height: 16),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            t(
                              'Mit meinen Fitnessdaten personalisieren',
                              'Personalize with my fitness data',
                            ),
                          ),
                          value: _personal,
                          onChanged: (v) => setState(() => _personal = v),
                        ),
                        Text(
                          t(
                            'Dabei gehen Profil, Trainings- und Ernährungsdaten sowie gespeicherte Coach-Notizen bei Anfragen an deinen gewählten KI-Anbieter. Details werden bei Bedarf nachgeladen. In den KI-Einstellungen jederzeit abschaltbar.',
                            'Requests send your profile, fitness and nutrition data and saved coach notes to your selected AI provider. Details are fetched when needed. You can disable this in AI settings.',
                          ),
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('coach-intro-next'),
              style: FilledButton.styleFrom(
                backgroundColor: gold ? accent : palette.actionBackground,
                foregroundColor: gold ? Colors.white : palette.onAction,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: _saving
                  ? null
                  : () {
                      if (_step < 2) {
                        setState(() => _step++);
                      } else {
                        _finish();
                      }
                    },
              child: Text(
                _step == 2
                    ? t('Los geht’s', 'Let’s go')
                    : t('Weiter', 'Continue'),
              ),
            ),
            if (_step > 0)
              TextButton(
                onPressed: _saving ? null : () => setState(() => _step--),
                child: Text(t('Zurück', 'Back')),
              ),
          ],
        ),
      ),
    );
  }
}
