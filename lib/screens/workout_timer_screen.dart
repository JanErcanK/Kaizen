import '../widgets/app_back_button.dart';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n_extension.dart';
import '../navigation/app_tab_navigation.dart';
import '../services/calorie_burn_service.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';

class WorkoutTimerScreen extends StatefulWidget {
  const WorkoutTimerScreen({super.key});

  @override
  State<WorkoutTimerScreen> createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen>
    with WidgetsBindingObserver {
  Duration _workDuration = const Duration(seconds: 30);
  Duration _restDuration = const Duration(seconds: 15);
  Duration _remaining = Duration.zero;
  Duration _phaseDuration = Duration.zero;
  int _setCount = 3;
  int _currentSet = 1;
  _TimerPhase _phase = _TimerPhase.work;
  DateTime? _phaseEndsAt;
  Timer? _ticker;
  bool _hasStarted = false;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isComplete = false;
  bool _workoutSaved = false;
  bool _isSaving = false;

  bool get _isGerman => context.l10n.localeName.startsWith('de');

  int get _plannedSeconds =>
      _workDuration.inSeconds * _setCount +
      _restDuration.inSeconds * (_setCount - 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRunning) {
      _tick();
    }
  }

  Future<void> _pickDuration({required bool work}) async {
    final initial = work ? _workDuration : _restDuration;
    var selected = initial;
    final value = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      work
                          ? (_isGerman ? 'Satzdauer' : 'Set duration')
                          : (_isGerman ? 'Pausenzeit' : 'Rest duration'),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(_isGerman ? 'Abbrechen' : 'Cancel'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(selected),
                    child: Text(_isGerman ? 'Übernehmen' : 'Set'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.ms,
                initialTimerDuration: initial,
                minuteInterval: 1,
                secondInterval: 5,
                onTimerDurationChanged: (duration) => selected = duration,
              ),
            ],
          ),
        ),
      ),
    );
    if (value == null || !mounted) return;
    setState(() {
      if (work) {
        _workDuration = value;
      } else {
        _restDuration = value;
      }
    });
  }

  void _startOrResume() {
    if (_isRunning || _isComplete) return;
    if (_isPaused) {
      setState(() {
        _isPaused = false;
        _isRunning = true;
        _phaseEndsAt = DateTime.now().add(_remaining);
      });
      _playBell();
      _startTicker();
      return;
    }
    if (_workDuration.inSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isGerman
                ? 'Die Satzdauer muss mindestens eine Sekunde betragen.'
                : 'Set duration must be at least one second.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _hasStarted = true;
      _isRunning = true;
      _isPaused = false;
      _phase = _TimerPhase.work;
      _currentSet = 1;
      _phaseDuration = _workDuration;
      _remaining = _workDuration;
      _phaseEndsAt = DateTime.now().add(_workDuration);
    });
    _playBell();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _tick() {
    if (!_isRunning) return;
    final now = DateTime.now();
    var crossedBoundary = false;
    while (_phaseEndsAt != null && !now.isBefore(_phaseEndsAt!)) {
      crossedBoundary = true;
      final previousEnd = _phaseEndsAt!;
      if (_phase == _TimerPhase.work && _currentSet == _setCount) {
        _complete();
        return;
      }
      if (_phase == _TimerPhase.work && _restDuration > Duration.zero) {
        _phase = _TimerPhase.rest;
        _phaseDuration = _restDuration;
        _remaining = _restDuration;
        _phaseEndsAt = previousEnd.add(_restDuration);
      } else {
        if (_phase == _TimerPhase.rest || _restDuration == Duration.zero) {
          _currentSet++;
        }
        _phase = _TimerPhase.work;
        _phaseDuration = _workDuration;
        _remaining = _workDuration;
        _phaseEndsAt = previousEnd.add(_workDuration);
      }
    }
    final deadline = _phaseEndsAt;
    if (deadline == null) return;
    setState(() => _remaining = deadline.difference(now));
    if (crossedBoundary) _playBell();
  }

  void _pause() {
    final deadline = _phaseEndsAt;
    if (!_isRunning || deadline == null) return;
    _ticker?.cancel();
    setState(() {
      _remaining = deadline.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;
      _isRunning = false;
      _isPaused = true;
      _phaseEndsAt = null;
    });
  }

  void _complete() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isComplete = true;
      _phaseEndsAt = null;
      _remaining = Duration.zero;
    });
    _playBell();
  }

  int get _activeTrainingSeconds => _workDuration.inSeconds * _setCount;

  int _estimatedCalories(int intensity) {
    return CalorieBurnService.timerWorkoutSession(
      durationSeconds: _activeTrainingSeconds,
      intensity: intensity,
    ).totalKcal;
  }

  Future<void> _saveCompletedWorkout(int intensity) async {
    if (_workoutSaved || _isSaving) return;
    setState(() => _isSaving = true);
    final name = _isGerman ? 'Workout-Timer' : 'Workout Timer';
    final burn = CalorieBurnService.timerWorkoutSession(
      durationSeconds: _activeTrainingSeconds,
      intensity: intensity,
    );
    try {
      await ProgressStore.applyWorkoutRewards(
        workoutType: 'sport',
        workoutName: name,
        workoutCategory: 'timer',
        workoutId: 'timer_${DateTime.now().microsecondsSinceEpoch}',
        workoutIntensity: intensity,
        durationSeconds: burn.durationSeconds,
        caloriesBurned: burn.totalKcal,
        calorieBreakdown: CalorieBurnService.breakdownToMaps(burn.breakdown),
      );
      if (!mounted) return;
      setState(() => _workoutSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isGerman
                ? 'Im Kalender gespeichert · ${burn.totalKcal} kcal'
                : 'Saved to calendar · ${burn.totalKcal} kcal',
          ),
        ),
      );
      AppTabNavigation.returnHome(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _hasStarted = false;
      _isRunning = false;
      _isPaused = false;
      _isComplete = false;
      _workoutSaved = false;
      _phase = _TimerPhase.work;
      _phaseEndsAt = null;
      _remaining = Duration.zero;
      _phaseDuration = Duration.zero;
      _currentSet = 1;
    });
  }

  void _playBell() {
    unawaited(SystemSound.play(SystemSoundType.alert));
    unawaited(HapticFeedback.mediumImpact());
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final hours = seconds ~/ 3600;
    final minutes = (seconds ~/ 60).remainder(60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$remainder';
    return '${seconds ~/ 60}:$remainder';
  }

  @override
  Widget build(BuildContext context) {
    final active = _isRunning || _isPaused;
    return PopScope(
      canPop: !_isRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isRunning) unawaited(_confirmLeave());
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: const AppBackButton(),
          leadingWidth: 44,
          backgroundColor: AppColors.background,
          title: Text(_isGerman ? 'Workout-Timer' : 'Workout Timer'),
          actions: [
            if (active)
              IconButton(
                tooltip: _isGerman ? 'Timer zurücksetzen' : 'Reset timer',
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
        body: _isComplete
            ? _buildComplete()
            : _hasStarted
            ? _buildRunning()
            : _buildSetup(),
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          _isGerman ? 'Timer verlassen?' : 'Leave timer?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          _isGerman
              ? 'Der laufende Timer wird beendet.'
              : 'The running timer will stop.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_isGerman ? 'Weiter trainieren' : 'Keep training'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_isGerman ? 'Verlassen' : 'Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      _ticker?.cancel();
      Navigator.of(context).pop();
    }
  }

  Widget _buildSetup() {
    final isGerman = _isGerman;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        // Keep the controls at their established height after removing the intro.
        const SizedBox(height: 110),
        const SizedBox(height: 16),
        _settingTile(
          icon: Icons.fitness_center_rounded,
          title: isGerman ? 'Zeit pro Satz' : 'Set duration',
          value: _formatDuration(_workDuration),
          onTap: () => _pickDuration(work: true),
        ),
        const SizedBox(height: 10),
        _setCountTile(),
        const SizedBox(height: 10),
        _settingTile(
          icon: Icons.hourglass_bottom_rounded,
          title: isGerman ? 'Pausenzeit' : 'Rest duration',
          value: _formatDuration(_restDuration),
          onTap: () => _pickDuration(work: false),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: AppColors.surfaceDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, color: AppColors.primary, size: 19),
              const SizedBox(width: 9),
              Text(
                isGerman ? 'Gesamtdauer' : 'Total duration',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const Spacer(),
              Text(
                _formatDuration(Duration(seconds: _plannedSeconds)),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: _startOrResume,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.actionBackground,
              foregroundColor: AppColors.onAction,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: Text(
              isGerman ? 'Workout starten' : 'Start workout',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _setCountTile() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 8, 9),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              _isGerman ? 'Anzahl der Sätze' : 'Number of sets',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: _setCount > 1 ? () => setState(() => _setCount--) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: AppColors.textMuted,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$_setCount',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: _setCount < 99
                ? () => setState(() => _setCount++)
                : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildRunning() {
    final isWork = _phase == _TimerPhase.work;
    final color = isWork ? AppColors.primary : const Color(0xFF57C9A4);
    final progress = _phaseDuration.inMilliseconds == 0
        ? 0.0
        : (_remaining.inMilliseconds / _phaseDuration.inMilliseconds).clamp(
            0.0,
            1.0,
          );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isWork
                  ? (_isGerman
                        ? 'SATZ $_currentSet VON $_setCount'
                        : 'SET $_currentSet OF $_setCount')
                  : (_isGerman ? 'PAUSE' : 'REST'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 15,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.stroke,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isWork
                            ? Icons.fitness_center_rounded
                            : Icons.self_improvement_rounded,
                        size: 24,
                        color: color,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _formatDuration(_remaining),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        isWork
                            ? (_isGerman ? 'Satzzeit' : 'Set time')
                            : (_isGerman ? 'Pausenzeit' : 'Rest time'),
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isPaused
                  ? (_isGerman ? 'PAUSIERT' : 'PAUSED')
                  : (_isGerman ? 'Workout läuft' : 'Workout in progress'),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(_isGerman ? 'Beenden' : 'Stop'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.stroke),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isRunning ? _pause : _startOrResume,
                    icon: Icon(
                      _isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      _isRunning
                          ? (_isGerman ? 'Pause' : 'Pause')
                          : (_isGerman ? 'Weiter' : 'Resume'),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.actionBackground,
                      foregroundColor: AppColors.onAction,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplete() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.16),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.primary,
                  size: 54,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isGerman ? 'Workout abgeschlossen' : 'Workout complete',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_setCount ${_isGerman ? 'Sätze' : 'sets'} · ${_formatDuration(Duration(seconds: _activeTrainingSeconds))} ${_isGerman ? 'Trainingszeit' : 'training time'}',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 15),
            ),
            const SizedBox(height: 24),
            Text(
              _isGerman
                  ? 'Wie intensiv war dein Workout?'
                  : 'How intense was your workout?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _intensityButton(
              intensity: 1,
              title: _isGerman ? 'Leicht' : 'Light',
              description: _isGerman ? 'Ruhiges Tempo' : 'Relaxed pace',
              icon: Icons.spa_outlined,
            ),
            const SizedBox(height: 8),
            _intensityButton(
              intensity: 2,
              title: _isGerman ? 'Mittel' : 'Moderate',
              description: _isGerman
                  ? 'Wie lockeres Laufen'
                  : 'Like an easy run',
              icon: Icons.directions_run_rounded,
            ),
            const SizedBox(height: 8),
            _intensityButton(
              intensity: 3,
              title: _isGerman ? 'Intensiv' : 'Intense',
              description: _isGerman
                  ? 'Wie schnelles Laufen'
                  : 'Like a fast run',
              icon: Icons.local_fire_department_outlined,
            ),
            if (_isSaving) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_workoutSaved) ...[
              const SizedBox(height: 10),
              Text(
                _isGerman ? 'Im Kalender gespeichert' : 'Saved to calendar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accentText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _workoutSaved
                  ? () => Navigator.of(context).pop()
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.actionBackground,
                foregroundColor: AppColors.onAction,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _isGerman ? 'Fertig' : 'Done',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intensityButton({
    required int intensity,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return OutlinedButton(
      onPressed: _isSaving || _workoutSaved
          ? null
          : () => _saveCompletedWorkout(intensity),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.stroke),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  description,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${_estimatedCalories(intensity)} kcal',
            style: TextStyle(
              color: AppColors.accentText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

enum _TimerPhase { work, rest }
