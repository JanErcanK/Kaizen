import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../navigation/app_tab_navigation.dart';
import '../l10n/catalog_localizations.dart';
import '../services/calorie_burn_service.dart';
import '../services/progress_store.dart';
import '../services/workout_tts_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_header_logo.dart';
import 'root_shell.dart';

class WorkoutExercise {
  const WorkoutExercise({
    required this.name,
    required this.benefit,
    this.workSeconds = 30,
    this.assetPath,
    this.animationAssetPaths = const [],
  });

  final String name;
  final String benefit;
  final int workSeconds;
  final String? assetPath;

  /// Ordered frames cycled every second during the work phase while running.
  final List<String> animationAssetPaths;

  String get displayName => CatalogLocalizations.workoutExerciseName(name);

  String? get previewAssetPath =>
      animationAssetPaths.isNotEmpty ? animationAssetPaths.first : assetPath;
}

class WorkoutPlayerScreen extends StatefulWidget {
  const WorkoutPlayerScreen({
    super.key,
    required this.exercises,
    this.levelPoints = 1,
    this.workoutType,
    this.workoutName,
    this.prepSeconds = 10,
    this.restSeconds = 10,
    this.showInstructions = false,
  });

  final List<WorkoutExercise> exercises;
  final int levelPoints;
  final String? workoutType;
  final String? workoutName;
  final int prepSeconds;
  final int restSeconds;
  final bool showInstructions;

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

enum _WorkoutPhase { prep, work, rest, finished }

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen> {
  Timer? _timer;
  FlutterTts? _tts;
  bool _isRunning = true;
  bool _showControls = false;
  bool _completionCounted = false;
  int _elapsedSeconds = 0;
  int _exerciseIndex = 0;
  _WorkoutPhase _phase = _WorkoutPhase.prep;
  int _phaseRemaining = 0;
  bool _halbzeitAnnounced = false;
  bool _initialVoiceCueSent = false;

  /// Tracks which countdown values (3, 2, 1) have already been spoken for
  /// the current phase so we never double-announce them.
  final Set<int> _spokenCountdowns = {};
  int _animationFrameIndex = 0;
  AppLocalizations? _l10n;

  /// Timed circuits (9 Min, Morning Workout, Only Stretch, Wake-Up) use voice cues.
  bool get _voiceGuidanceWorkout {
    switch (widget.workoutType) {
      case 'nine_min':
      case 'hercules':
      case 'stretch':
      case 'wakeup_workout':
      case 'ligament_stability':
        return true;
      default:
        return false;
    }
  }

  bool get _shouldSpeak =>
      _voiceGuidanceWorkout && ProgressStore.workoutVoiceEnabled;

  /// Total timer counts up for timed circuit workouts (9 Min, Hercules, Stretch, Wake-Up).
  bool get _countUpTotalTimer {
    switch (widget.workoutType) {
      case 'nine_min':
      case 'hercules':
      case 'stretch':
      case 'wakeup_workout':
      case 'ligament_stability':
        return true;
      default:
        return false;
    }
  }

  int get _displayTotalSeconds =>
      _countUpTotalTimer ? _elapsedSeconds : _remainingTotalSeconds;

  @override
  void initState() {
    super.initState();
    _phaseRemaining = widget.prepSeconds;
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = context.l10n;
    unawaited(_ensureTtsAndInitialCue());
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_tts?.stop());
    super.dispose();
  }

  Future<void> _ensureTtsAndInitialCue() async {
    if (!_shouldSpeak || _initialVoiceCueSent) return;
    final l10n = _l10n;
    if (l10n == null) return;

    if (_tts == null) {
      await _initTtsEngine();
    }
    if (!mounted || _initialVoiceCueSent) return;

    _initialVoiceCueSent = true;
    await _speak(l10n.tts_getReady);
  }

  Future<void> _initTtsEngine() async {
    final tts = FlutterTts();
    _tts = tts;
    await WorkoutTtsService.configure(
      tts,
      appLocaleCode: ProgressStore.appLocaleCode,
      voiceGender: WorkoutTtsService.parseGender(
        ProgressStore.workoutVoiceGender,
      ),
    );
  }

  Future<void> _speak(String text) async {
    if (!_shouldSpeak) return;
    if (_tts == null) {
      await _initTtsEngine();
    }
    final tts = _tts;
    if (tts == null) return;
    try {
      await tts.stop();
      await tts.speak(text);
    } catch (_) {
      // TTS must never break the workout.
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!_isRunning || _phase == _WorkoutPhase.finished) return;
    if (_phaseRemaining <= 1) {
      _moveToNextPhase(consumedSeconds: 1);
    } else {
      setState(() {
        _phaseRemaining--;
        _elapsedSeconds++;
        if (_phase == _WorkoutPhase.work && _isRunning) {
          final frames = widget.exercises[_exerciseIndex].animationAssetPaths;
          if (frames.length > 1) {
            _animationFrameIndex = (_animationFrameIndex + 1) % frames.length;
          }
        }
      });
      if (_shouldSpeak && _phase == _WorkoutPhase.work && !_halbzeitAnnounced) {
        final workSec = widget.exercises[_exerciseIndex].workSeconds;
        final halfRemaining = workSec ~/ 2;
        if (workSec >= 2 &&
            halfRemaining >= 1 &&
            _phaseRemaining == halfRemaining) {
          _halbzeitAnnounced = true;
          unawaited(_speak(_l10n!.tts_halfway));
        }
      }
      // 3-2-1 countdown for the last 3 seconds of every exercise and rest phase
      if (_shouldSpeak &&
          (_phase == _WorkoutPhase.work || _phase == _WorkoutPhase.rest) &&
          _phaseRemaining >= 1 &&
          _phaseRemaining <= 3 &&
          !_spokenCountdowns.contains(_phaseRemaining)) {
        _spokenCountdowns.add(_phaseRemaining);
        unawaited(_speak('$_phaseRemaining'));
      }
    }
  }

  void _moveToNextPhase({required int consumedSeconds}) {
    setState(() {
      _elapsedSeconds += consumedSeconds;
      _spokenCountdowns.clear(); // reset countdown for every new phase
      if (_phase == _WorkoutPhase.prep) {
        _phase = _WorkoutPhase.work;
        _phaseRemaining = widget.exercises.first.workSeconds;
        _halbzeitAnnounced = false;
        _animationFrameIndex = 0;
        unawaited(_speak(_l10n!.tts_start));
        return;
      }
      if (_phase == _WorkoutPhase.work) {
        final isLastExercise = _exerciseIndex == widget.exercises.length - 1;
        if (isLastExercise) {
          _phase = _WorkoutPhase.finished;
          _phaseRemaining = 0;
          if (!_completionCounted) {
            _completionCounted = true;
            unawaited(_handleWorkoutFinished());
          }
          unawaited(_speak(_l10n!.tts_workoutComplete));
        } else {
          _phase = _WorkoutPhase.rest;
          _phaseRemaining = widget.restSeconds;
          final nextExercise = widget.exercises[_exerciseIndex + 1];
          unawaited(_speak(_l10n!.tts_pauseNext(nextExercise.displayName)));
        }
        return;
      }
      if (_phase == _WorkoutPhase.rest) {
        _exerciseIndex++;
        _phase = _WorkoutPhase.work;
        _phaseRemaining = widget.exercises[_exerciseIndex].workSeconds;
        _halbzeitAnnounced = false;
        _animationFrameIndex = 0;
        unawaited(_speak(_l10n!.tts_start));
      }
    });
  }

  Future<int?> _promptMood(BuildContext context) async {
    final l10n = context.l10n;
    return showDialog<int?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Widget moodButton(int value, IconData icon, String label) {
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(ctx).pop(value),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: AppColors.textPrimary, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return AlertDialog(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.transparent,
          title: Text(
            l10n.mood_title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Row(
            children: [
              moodButton(
                1,
                Icons.sentiment_very_dissatisfied,
                l10n.mood_veryBad,
              ),
              moodButton(2, Icons.sentiment_dissatisfied, l10n.mood_bad),
              moodButton(3, Icons.sentiment_neutral, l10n.mood_neutral),
              moodButton(4, Icons.sentiment_satisfied, l10n.mood_good),
              moodButton(5, Icons.sentiment_very_satisfied, l10n.mood_veryGood),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(
                l10n.common_skip,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleWorkoutFinished() async {
    final type = widget.workoutType?.trim();
    if (type == null || type.isEmpty) {
      // Fallback path; still keep streak/level behavior.
      await ProgressStore.markWorkoutCompletedToday();
      await ProgressStore.addUserLevel(widget.levelPoints);
      if (mounted) AppTabNavigation.returnHome(context);
      return;
    }
    if (!mounted) return;
    final mood = await _promptMood(context);
    if (!mounted) return;
    final burn = CalorieBurnService.timedCircuitWorkout(
      exercises: widget.exercises
          .map(
            (e) => TimedExerciseInput(
              name: e.name,
              workSeconds: e.workSeconds,
              assetPath: e.assetPath,
            ),
          )
          .toList(),
      prepSeconds: widget.prepSeconds,
      restSeconds: widget.restSeconds,
    );
    await ProgressStore.applyWorkoutRewards(
      workoutType: type,
      mood: mood,
      caloriesBurned: burn.totalKcal,
      durationSeconds: burn.durationSeconds,
      workoutName: widget.workoutName,
      calorieBreakdown: CalorieBurnService.breakdownToMaps(burn.breakdown),
    );
    if (!mounted) return;
    AppTabNavigation.returnHome(context);
  }

  void _togglePauseResume() {
    if (_phase == _WorkoutPhase.finished) return;
    setState(() => _isRunning = !_isRunning);
  }

  void _skipForward() {
    if (_phase == _WorkoutPhase.finished) return;
    _moveToNextPhase(consumedSeconds: _phaseRemaining);
  }

  void _goBack() {
    if (_phase == _WorkoutPhase.finished) return;
    setState(() {
      if (_phase == _WorkoutPhase.work && _exerciseIndex > 0) {
        _exerciseIndex--;
        _phase = _WorkoutPhase.work;
        _phaseRemaining = widget.exercises[_exerciseIndex].workSeconds;
        _halbzeitAnnounced = false;
        _animationFrameIndex = 0;
        return;
      }
      if (_phase == _WorkoutPhase.rest) {
        _phase = _WorkoutPhase.work;
        _phaseRemaining = widget.exercises[_exerciseIndex].workSeconds;
        _halbzeitAnnounced = false;
        _animationFrameIndex = 0;
        return;
      }
      _phase = _WorkoutPhase.prep;
      _phaseRemaining = widget.prepSeconds;
      _exerciseIndex = 0;
      _elapsedSeconds = 0;
    });
  }

  String _formatClock(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }

  int get _totalWorkoutSeconds {
    final work = widget.exercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.workSeconds,
    );
    final rests = (widget.exercises.length - 1) * widget.restSeconds;
    return work + rests + widget.prepSeconds;
  }

  int get _remainingTotalSeconds {
    final remaining = _totalWorkoutSeconds - _elapsedSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  String _phaseLabel(AppLocalizations l10n) {
    switch (_phase) {
      case _WorkoutPhase.prep:
        return l10n.workout_phaseGetReady;
      case _WorkoutPhase.work:
        return l10n.workout_phaseWork;
      case _WorkoutPhase.rest:
        return l10n.workout_phaseRest;
      case _WorkoutPhase.finished:
        return l10n.workout_phaseComplete;
    }
  }

  WorkoutExercise get _displayExercise {
    if (_phase == _WorkoutPhase.rest) {
      final nextIndex = _exerciseIndex + 1;
      if (nextIndex >= 0 && nextIndex < widget.exercises.length) {
        return widget.exercises[nextIndex];
      }
    }
    return widget.exercises[_exerciseIndex];
  }

  String? _imagePathFor(WorkoutExercise exercise) {
    final frames = exercise.animationAssetPaths;
    if (_phase == _WorkoutPhase.work && _isRunning && frames.length > 1) {
      return frames[_animationFrameIndex % frames.length];
    }
    return exercise.previewAssetPath;
  }

  void _handleScreenTap() {
    if (_phase == _WorkoutPhase.finished || _showControls) return;
    setState(() {
      _showControls = true;
      _isRunning = false;
    });
  }

  void _goToProgress() {
    RootShell.selectedTab.value = 1;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isFinished = _phase == _WorkoutPhase.finished;
    final current = widget.exercises[_exerciseIndex];
    final display = isFinished ? current : _displayExercise;
    final imagePath = (!isFinished) ? _imagePathFor(display) : null;
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            RootShell.selectedTab.value = 1;
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleScreenTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: widget.showInstructions
                    ? _instructionContent(display, imagePath, isFinished, l10n)
                    : Column(
                        children: [
                          const AppHeaderLogo(),
                          const Spacer(flex: 2),
                          Text(
                            _phaseLabel(l10n),
                            style: TextStyle(
                              color: AppColors.textMuted,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (!isFinished) ...[
                            Text(
                              _formatClock(_displayTotalSeconds),
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_phaseRemaining',
                              style: TextStyle(
                                color: AppColors.accentText,
                                fontSize: 96,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Center(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: imagePath == null
                                  ? (isFinished
                                        ? GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: _goToProgress,
                                            child: Icon(
                                              Icons.check_circle,
                                              color: AppColors.primary,
                                              size: 220,
                                            ),
                                          )
                                        : Icon(
                                            Icons.accessibility_new,
                                            color: AppColors.textPrimary,
                                            size: 220,
                                          ))
                                  : Image.asset(
                                      imagePath,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.accessibility_new,
                                              color: AppColors.textPrimary,
                                              size: 220,
                                            );
                                          },
                                    ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            display.displayName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 44,
                              letterSpacing: 0.6,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isFinished
                                ? l10n.workout_finishedMessage(
                                    widget.exercises.length,
                                  )
                                : l10n.workout_setProgress(
                                    _exerciseIndex + 1,
                                    widget.exercises.length,
                                  ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.accentText,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          if (isFinished) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.workout_tapCheckHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.9,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                          const Spacer(flex: 1),
                        ],
                      ),
              ),
              if (_showControls && !isFinished)
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: 0.45)),
                ),
              if (_showControls && !isFinished)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _bigControl(icon: Icons.skip_previous, onTap: _goBack),
                      const SizedBox(width: 18),
                      _bigControl(
                        icon: _isRunning ? Icons.pause : Icons.play_arrow,
                        onTap: () {
                          _togglePauseResume();
                          if (_isRunning) {
                            setState(() => _showControls = false);
                          }
                        },
                        isPrimary: true,
                      ),
                      const SizedBox(width: 18),
                      _bigControl(icon: Icons.skip_next, onTap: _skipForward),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _instructionContent(
    WorkoutExercise exercise,
    String? imagePath,
    bool finished,
    AppLocalizations l10n,
  ) => SingleChildScrollView(
    child: Column(
      children: [
        const AppHeaderLogo(),
        const SizedBox(height: 16),
        Text(_phaseLabel(l10n), style: TextStyle(color: AppColors.textMuted)),
        if (!finished) ...[
          Text(
            _formatClock(_displayTotalSeconds),
            style: TextStyle(color: AppColors.textMuted),
          ),
          Text(
            '$_phaseRemaining',
            style: TextStyle(
              color: AppColors.accentText,
              fontSize: 72,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (finished)
          IconButton(
            onPressed: _goToProgress,
            tooltip: l10n.workout_tapCheckHint,
            iconSize: 96,
            icon: Icon(Icons.check_circle, color: AppColors.primary),
          )
        else if (imagePath != null)
          Image.asset(imagePath, height: 150, fit: BoxFit.contain)
        else
          Icon(Icons.self_improvement, size: 80, color: AppColors.primary),
        const SizedBox(height: 12),
        Text(
          exercise.displayName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          finished
              ? l10n.workout_finishedMessage(widget.exercises.length)
              : CatalogLocalizations.workoutExerciseBenefit(exercise.benefit),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        if (!finished)
          Text(
            l10n.workout_setProgress(
              _exerciseIndex + 1,
              widget.exercises.length,
            ),
            style: TextStyle(color: AppColors.accentText),
          ),
      ],
    ),
  );

  Widget _bigControl({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: 76,
      height: 76,
      child: FloatingActionButton(
        heroTag: '${icon.codePoint}_$isPrimary',
        backgroundColor: isPrimary
            ? AppColors.actionBackground
            : AppColors.card,
        foregroundColor: isPrimary ? AppColors.onAction : AppColors.textPrimary,
        onPressed: onTap,
        child: Icon(icon, size: 36),
      ),
    );
  }
}
