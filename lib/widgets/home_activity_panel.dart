import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/body_muscle_group.dart';
import '../services/home_weekly_summary_service.dart';

/// Daily readouts beside the mannequin, in the same order in both languages.
class HomeActivityPanel extends StatelessWidget {
  const HomeActivityPanel({
    super.key,
    required this.snapshot,
    required this.recovery,
    required this.isGerman,
    this.streakDays = 0,
    this.onWaterTap,
    this.onWaterLongPress,
    this.fastingCard,
  });

  final HomeHudSnapshot snapshot;
  final MuscleRecoverySnapshot recovery;
  final bool isGerman;
  final int streakDays;
  final VoidCallback? onWaterTap;
  final VoidCallback? onWaterLongPress;
  final Widget? fastingCard;

  static const cyan = Color(0xFF00CAE9);
  static const green = Color(0xFF20D9B0);

  @override
  Widget build(BuildContext context) {
    final locale = isGerman ? 'de' : 'en';
    final numbers = NumberFormat.decimalPattern(locale);
    final liters = NumberFormat('0.0', locale);
    final score = recovery.recoveryPercent;
    final recoveryColor = score >= 70
        ? green
        : score >= 40
        ? const Color(0xFFFFC66B)
        : const Color(0xFFFF886B);
    final recoveryStatus = score >= 90
        ? (isGerman ? 'Sehr gut erholt' : 'Well recovered')
        : score >= 70
        ? (isGerman ? 'Gute Erholung' : 'Good recovery')
        : score >= 40
        ? (isGerman ? 'In Erholung' : 'Recovering')
        : (isGerman ? 'Hohe Belastung' : 'High training load');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ReadoutCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Metric(
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFFFC86D),
                label: isGerman ? 'Verbrannt' : 'Burned',
                value: numbers.format(snapshot.burnedKcal),
                unit: 'kcal',
                goal: snapshot.burnGoalKcal,
                amount: snapshot.burnedKcal,
                goalLabel: '/ ${numbers.format(snapshot.burnGoalKcal)} kcal',
                tooltip: isGerman
                    ? 'Aktive Kalorien aus Training und Schritten. Richtziel: 500 kcal pro Tag.'
                    : 'Active calories from workouts and steps. Reference goal: 500 kcal per day.',
              ),
              const _ReadoutDivider(),
              _Metric(
                icon: Icons.restaurant_rounded,
                color: const Color(0xFFFFC86D),
                label: isGerman ? 'Eingenommen' : 'Intake',
                value: numbers.format(snapshot.eatenKcal),
                unit: 'kcal',
                goal: snapshot.calorieTarget,
                amount: snapshot.eatenKcal,
                goalLabel: snapshot.calorieTarget == null
                    ? (isGerman
                          ? 'Ziel im Profil setzen'
                          : 'Set goal in profile')
                    : '/ ${numbers.format(snapshot.calorieTarget)} kcal',
              ),
              const _ReadoutDivider(),
              _Metric(
                icon: Icons.directions_walk_rounded,
                color: cyan,
                label: isGerman ? 'Schritte' : 'Steps',
                value: numbers.format(snapshot.steps),
                goal: snapshot.stepsGoal,
                amount: snapshot.steps,
                goalLabel: '/ ${numbers.format(snapshot.stepsGoal)}',
              ),
            ],
          ),
        ),
        if (snapshot.waterEnabled) ...[
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: isGerman
                ? 'Ein Glas Wasser hinzufügen'
                : 'Add a glass of water',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onWaterTap,
              onLongPress: onWaterLongPress,
              child: _ReadoutCard(
                child: _Metric(
                  icon: Icons.water_drop_rounded,
                  color: cyan,
                  label: isGerman ? 'Wasser' : 'Hydration',
                  value: liters.format(snapshot.waterMl / 1000),
                  unit: 'L',
                  goal: snapshot.waterGoalMl,
                  amount: snapshot.waterMl,
                  goalLabel:
                      '/ ${liters.format(snapshot.waterGoalMl / 1000)} L',
                  tooltip: isGerman
                      ? 'Tippen: ein Glas hinzufügen. Gedrückt halten: ein Glas entfernen.'
                      : 'Tap to add a glass. Hold to remove a glass.',
                ),
              ),
            ),
          ),
        ],
        if (fastingCard != null) ...[
          const SizedBox(height: 8),
          _ReadoutCard(child: fastingCard!),
        ],
        const SizedBox(height: 8),
        Tooltip(
          message: isGerman
              ? 'Geschätzte Erholung aus 9 Muskelgruppen: Rot zählt 100 %, Gelb 40 % und leichtes Training 15 % Belastung je Gruppe. 100 minus die mittlere Belastung ergibt den Wert. ${recovery.heavilyTrainedGroups} Gruppen sind stark belastet. Kein Messwert für Muskelschäden.'
              : 'Estimated recovery across 9 muscle groups: red counts as 100%, yellow as 40%, and light training as 15% load per group. The score is 100 minus average load. ${recovery.heavilyTrainedGroups} groups are heavily trained. This does not measure muscle damage.',
          child: _ReadoutCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReadoutLabel(
                  icon: Icons.eco_rounded,
                  label: isGerman ? 'Erholung' : 'Recovery',
                  color: green,
                ),
                const SizedBox(height: 5),
                Text('$score%', style: _valueStyle(context)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 5,
                    backgroundColor: cyan.withValues(alpha: 0.12),
                    color: recoveryColor,
                    semanticsLabel: isGerman
                        ? 'Geschätzte Erholung'
                        : 'Estimated recovery',
                    semanticsValue: '$score%',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  recoveryStatus,
                  style: TextStyle(fontSize: 10, color: recoveryColor),
                ),
                Text(
                  isGerman
                      ? 'Trainingsbasierte Schätzung'
                      : 'Training-based estimate',
                  style: TextStyle(fontSize: 8, color: _muted(context)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _StreakCard(days: streakDays, isGerman: isGerman),
      ],
    );
  }
}

bool _light(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light;
Color _muted(BuildContext context) =>
    _light(context) ? const Color(0xFF466474) : const Color(0xFF9AB5C5);
TextStyle _valueStyle(BuildContext context) => TextStyle(
  color: _light(context) ? const Color(0xFF153344) : const Color(0xFFF1F8FC),
  fontSize: 21,
  height: 1.1,
  fontWeight: FontWeight.w600,
);

class _ReadoutCard extends StatelessWidget {
  const _ReadoutCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: _light(context) ? Colors.white : const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: _light(context)
            ? const Color(0xFFE7ECEF)
            : const Color(0xFF343434),
      ),
      boxShadow: _light(context)
          ? const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ]
          : null,
    ),
    child: child,
  );
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.days, required this.isGerman});

  final int days;
  final bool isGerman;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF8BCB20);
    final today = DateTime.now().weekday;
    const dayLettersDe = ['M', 'D', 'M', 'D', 'F', 'S', 'S'];
    const dayLettersEn = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final letters = isGerman ? dayLettersDe : dayLettersEn;

    return _ReadoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: (days / 7).clamp(0.0, 1.0),
                        strokeWidth: 3,
                        strokeCap: StrokeCap.round,
                        color: accent,
                        backgroundColor: accent.withValues(alpha: 0.13),
                        // A progress bar's semantics value must be a number or
                        // a percentage; the day count belongs in the label.
                        semanticsLabel: isGerman
                            ? 'Trainingsserie: $days Tage'
                            : 'Workout streak: $days days',
                        semanticsValue:
                            '${((days / 7).clamp(0.0, 1.0) * 100).round()}%',
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$days',
                          style: TextStyle(
                            color: accent,
                            fontSize: 15,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isGerman ? 'TAGE' : 'DAYS',
                          style: TextStyle(
                            color: _muted(context),
                            fontSize: 5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'STREAK',
                      style: TextStyle(
                        color: _muted(context),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      days > 0
                          ? (isGerman ? 'Weiter so!' : 'Keep it up!')
                          : (isGerman ? 'Leg los!' : 'Get started!'),
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = index + 1;
              final active = days > 0 && day <= today;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? accent : accent.withValues(alpha: 0.16),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    letters[index],
                    style: TextStyle(
                      color: active
                          ? _muted(context)
                          : _muted(context).withValues(alpha: 0.55),
                      fontSize: 7,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ReadoutLabel extends StatelessWidget {
  const _ReadoutLabel({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: _muted(context),
          ),
        ),
      ),
    ],
  );
}

class _ReadoutDivider extends StatelessWidget {
  const _ReadoutDivider();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Divider(
      height: 1,
      color: HomeActivityPanel.cyan.withValues(alpha: 0.10),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.goal,
    required this.amount,
    required this.goalLabel,
    this.unit = '',
    this.tooltip,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;
  final int? goal;
  final int amount;
  final String goalLabel;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final hasGoal = goal != null && goal! > 0;
    final ratio = hasGoal ? amount / goal! : 0.0;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReadoutLabel(icon: icon, label: label, color: color),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        text: value,
                        children: [
                          if (unit.isNotEmpty)
                            TextSpan(
                              text: ' $unit',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                      style: _valueStyle(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    goalLabel,
                    style: TextStyle(fontSize: 9, color: _muted(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            SizedBox(
              width: 32,
              height: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                      color: HomeActivityPanel.cyan,
                      backgroundColor: HomeActivityPanel.cyan.withValues(
                        alpha: 0.12,
                      ),
                      semanticsLabel: label,
                      // Never null: a progress bar's semantics value is
                      // required, and the ring reads 0 when there is no goal.
                      semanticsValue:
                          '${(ratio.clamp(0.0, 1.0) * 100).round()}%',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        hasGoal ? '${(ratio * 100).round()}%' : '—',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _muted(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
    return tooltip == null
        ? content
        : Tooltip(message: tooltip!, child: content);
  }
}
