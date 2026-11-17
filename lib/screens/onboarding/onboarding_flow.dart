import '../../widgets/app_back_button.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n_extension.dart';
import '../../models/training_schedule.dart';
import '../../services/morning_workout_service.dart';
import '../../services/nutrition_calculator.dart';
import '../../services/progress_store.dart';
import '../../services/training_notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header_logo.dart';
import '../../widgets/weekly_training_schedule_editor.dart';

enum OnboardingMode { biometrics, setup }

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    this.onCompleted,
    this.mode = OnboardingMode.biometrics,
  });

  final VoidCallback? onCompleted;
  final OnboardingMode mode;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  var _step = 0;
  String? _gender;
  var _goal = 'maintain';
  var _notificationsEnabled = false;
  var _isFinishing = false;
  var _schedule = WeeklyTrainingSchedule.empty();

  int get _stepCount => widget.mode == OnboardingMode.setup ? 2 : 3;

  bool get _isScheduleStep => widget.mode == OnboardingMode.setup && _step == 0;

  bool get _isNotificationsStep =>
      widget.mode == OnboardingMode.setup && _step == 1;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  late final AnimationController _macroAnimCtrl;
  DailyNutritionTargets? _targets;

  @override
  void initState() {
    super.initState();
    _gender = null;
    if (widget.mode == OnboardingMode.setup) {
      _schedule = ProgressStore.weeklyTrainingSchedule;
      _notificationsEnabled = ProgressStore.trainingNotificationsEnabled;
    }
    _macroAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _macroAnimCtrl.dispose();
    super.dispose();
  }

  bool _validateProfileStep() {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final height = double.tryParse(
      _heightController.text.trim().replaceAll(',', '.'),
    );
    final weight = double.tryParse(
      _weightController.text.trim().replaceAll(',', '.'),
    );
    if (name.isEmpty ||
        _gender == null ||
        age == null ||
        height == null ||
        weight == null ||
        age < 10 ||
        age > 120 ||
        height < 100 ||
        height > 260 ||
        weight < 25 ||
        weight > 400) {
      return false;
    }
    return true;
  }

  void _computeTargets() {
    final age = int.parse(_ageController.text.trim());
    final height = double.parse(
      _heightController.text.trim().replaceAll(',', '.'),
    );
    final weight = double.parse(
      _weightController.text.trim().replaceAll(',', '.'),
    );
    _targets = NutritionCalculator.calculate(
      age: age,
      heightCm: height,
      weightKg: weight,
      gender: _gender!,
      goal: _goal,
    );
  }

  Future<void> _next() async {
    if (widget.mode == OnboardingMode.biometrics) {
      if (_step == 0 && !_validateProfileStep()) return;
      if (_step == 1) {
        _computeTargets();
        _macroAnimCtrl.forward(from: 0);
      }
    }
    if (_step < _stepCount - 1) {
      setState(() => _step++);
      return;
    }
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    try {
      await _finish();
      widget.onCompleted?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFinishing = false);
      final isDe = Localizations.localeOf(context).languageCode == 'de';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDe
                ? 'Speichern fehlgeschlagen. Bitte erneut versuchen.'
                : 'Could not save. Please try again.',
          ),
        ),
      );
    }
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  Future<void> _finish() async {
    if (widget.mode == OnboardingMode.setup) {
      await _finishSetup();
      return;
    }
    await _finishBiometrics();
  }

  Future<void> _finishBiometrics() async {
    final name = _nameController.text.trim();
    final age = int.parse(_ageController.text.trim());
    final height = double.parse(
      _heightController.text.trim().replaceAll(',', '.'),
    );
    final weight = double.parse(
      _weightController.text.trim().replaceAll(',', '.'),
    );
    final morningOrder = MorningWorkoutService.defaultExerciseOrder();

    await ProgressStore.batch(() async {
      await ProgressStore.setProfileName(name);
      await ProgressStore.setProfileAge(age);
      await ProgressStore.setProfileHeightCm(height);
      await ProgressStore.setProfileGender(_gender!);
      await ProgressStore.setProfileGoal(_goal);
      await ProgressStore.setWeightForToday(weight);
      await ProgressStore.setMorningWorkoutExerciseOrder(morningOrder);
      await ProgressStore.setHasCompletedOnboarding(true);
      await ProgressStore.setHasCompletedHomeIntro(false);
    });
  }

  Future<void> _finishSetup() async {
    final l10n = context.l10n;
    await ProgressStore.batch(() async {
      await ProgressStore.setWeeklyTrainingSchedule(_schedule);
      await ProgressStore.setTrainingNotificationsEnabled(
        _notificationsEnabled,
      );
      await ProgressStore.setHasCompletedHomeIntro(true);
    });

    try {
      if (_notificationsEnabled) {
        await TrainingNotificationService.requestPermission();
      }
      await TrainingNotificationService.syncFromStore(l10n: l10n);
    } catch (_) {
      // Setup data is saved; notification setup must not block entry.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    if (_step > 0)
                      AppBackButton(onPressed: _back)
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Column(
                        children: [
                          const AppHeaderLogo(),
                          const SizedBox(height: 10),
                          _StepDots(current: _step, total: _stepCount),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final offset = Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: offset, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(context),
                  ),
                ),
              ),
              _BottomBar(
                primaryLabel: _step == _stepCount - 1
                    ? l10n.onboarding_finish
                    : l10n.onboarding_next,
                onPrimary: _canContinue() && !_isFinishing ? _next : null,
                isLoading: _isFinishing,
                secondaryLabel: _isScheduleStep
                    ? l10n.onboarding_skipSchedule
                    : _isNotificationsStep
                    ? l10n.onboarding_skipNotifications
                    : null,
                onSecondary: _isScheduleStep
                    ? () => setState(() => _step++)
                    : _isNotificationsStep
                    ? () async {
                        setState(() => _notificationsEnabled = false);
                        await _next();
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canContinue() {
    if (widget.mode == OnboardingMode.biometrics && _step == 0) {
      return _validateProfileStep();
    }
    return true;
  }

  Widget _buildScheduleStep(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            title: context.l10n.onboarding_stepScheduleTitle,
            subtitle: context.l10n.onboarding_stepScheduleSubtitle,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              context.l10n.onboarding_stepScheduleLaterHint,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Roboto',
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          WeeklyTrainingScheduleEditor(
            schedule: _schedule,
            onChanged: (s) => setState(() => _schedule = s),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    if (widget.mode == OnboardingMode.setup) {
      return switch (_step) {
        0 => _buildScheduleStep(context),
        1 => _NotificationsStep(
          enabled: _notificationsEnabled,
          onChanged: (v) => setState(() => _notificationsEnabled = v),
        ),
        _ => const SizedBox.shrink(),
      };
    }
    return switch (_step) {
      0 => _ProfileStep(
        nameController: _nameController,
        ageController: _ageController,
        heightController: _heightController,
        weightController: _weightController,
        gender: _gender,
        onGenderChanged: (g) => setState(() => _gender = g),
      ),
      1 => _GoalStep(
        goal: _goal,
        onGoalChanged: (g) => setState(() => _goal = g),
      ),
      2 => _MacroRevealStep(targets: _targets, animation: _macroAnimCtrl),
      _ => const SizedBox.shrink(),
    };
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i <= current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : AppColors.stroke.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            height: 1.45,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.isLoading = false,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (secondaryLabel != null && onSecondary != null)
            TextButton(
              onPressed: onSecondary,
              child: Text(
                secondaryLabel!,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onPrimary,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.actionBackground,
                disabledBackgroundColor: AppColors.softSurface,
                foregroundColor: AppColors.onAction,
                disabledForegroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.onAction,
                      ),
                    )
                  : Text(
                      primaryLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Roboto',
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.nameController,
    required this.ageController,
    required this.heightController,
    required this.weightController,
    required this.gender,
    required this.onGenderChanged,
  });

  final TextEditingController nameController;
  final TextEditingController ageController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final String? gender;
  final ValueChanged<String> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            title: l10n.onboarding_stepProfileTitle,
            subtitle: l10n.onboarding_stepProfileSubtitle,
          ),
          const SizedBox(height: 20),
          _OnboardingField(
            label: l10n.profile_nameLabel,
            controller: nameController,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OnboardingField(
                  label: l10n.profile_ageLabel,
                  controller: ageController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OnboardingField(
                  label: l10n.profile_heightLabel,
                  controller: heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _OnboardingField(
            label: l10n.profile_weightLabel,
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.profile_genderLabel,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _GenderChoiceChip(
                  label: l10n.gender_male,
                  selected: gender == 'male',
                  onTap: () => onGenderChanged('male'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GenderChoiceChip(
                  label: l10n.gender_female,
                  selected: gender == 'female',
                  onTap: () => onGenderChanged('female'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.goal, required this.onGoalChanged});

  final String goal;
  final ValueChanged<String> onGoalChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            title: l10n.onboarding_stepGoalTitle,
            subtitle: l10n.onboarding_stepGoalSubtitle,
          ),
          const SizedBox(height: 24),
          _GoalCard(
            label: l10n.goal_maintain,
            hint: l10n.onboarding_stepGoalSubtitle,
            icon: Icons.balance_rounded,
            selected: goal == 'maintain',
            onTap: () => onGoalChanged('maintain'),
          ),
          const SizedBox(height: 10),
          _GoalCard(
            label: l10n.goal_gain,
            hint: l10n.goal_gain,
            icon: Icons.fitness_center_rounded,
            selected: goal == 'gain',
            onTap: () => onGoalChanged('gain'),
          ),
          const SizedBox(height: 10),
          _GoalCard(
            label: l10n.goal_lose,
            hint: l10n.goal_lose,
            icon: Icons.local_fire_department_outlined,
            selected: goal == 'lose',
            onTap: () => onGoalChanged('lose'),
          ),
        ],
      ),
    );
  }
}

class _MacroRevealStep extends StatefulWidget {
  const _MacroRevealStep({required this.targets, required this.animation});

  final DailyNutritionTargets? targets;
  final AnimationController animation;

  @override
  State<_MacroRevealStep> createState() => _MacroRevealStepState();
}

class _MacroRevealStepState extends State<_MacroRevealStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.animation.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = widget.targets;
    final cards = [
      _MacroCard(
        label: l10n.profile_kcalGoal,
        value: t?.calories.toString() ?? '—',
        unit: 'kcal',
        delay: 0.0,
        animation: widget.animation,
      ),
      _MacroCard(
        label: l10n.profile_protein,
        value: t?.proteinGrams.toString() ?? '—',
        unit: 'g',
        delay: 0.15,
        animation: widget.animation,
      ),
      _MacroCard(
        label: l10n.profile_carbs,
        value: t?.carbsGrams.toString() ?? '—',
        unit: 'g',
        delay: 0.3,
        animation: widget.animation,
      ),
      _MacroCard(
        label: l10n.profile_fats,
        value: t?.fatGrams.toString() ?? '—',
        unit: 'g',
        delay: 0.45,
        animation: widget.animation,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            title: l10n.onboarding_stepMacrosTitle,
            subtitle: l10n.onboarding_stepMacrosSubtitle,
          ),
          const SizedBox(height: 24),
          ...cards,
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.delay,
    required this.animation,
  });

  final String label;
  final String value;
  final String unit;
  final double delay;
  final AnimationController animation;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(
        delay,
        (delay + 0.55).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        return Transform.translate(
          offset: Offset(0, (1 - t) * 36),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: AppColors.surfaceDecoration(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: AppColors.accentText,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                fontFamily: 'RobotoMono',
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsStep extends StatelessWidget {
  const _NotificationsStep({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            title: l10n.onboarding_stepNotificationsTitle,
            subtitle: l10n.onboarding_stepNotificationsSubtitle,
          ),
          const SizedBox(height: 32),
          Center(
            child: Icon(
              Icons.notifications_active_outlined,
              size: 72,
              color: AppColors.primary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 28),
          Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            child: SwitchListTile(
              value: enabled,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
              title: Text(
                l10n.onboarding_enableNotifications,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Roboto',
                ),
              ),
              subtitle: Text(
                l10n.onboarding_stepNotificationsSubtitle,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingField extends StatelessWidget {
  const _OnboardingField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textMuted, fontFamily: 'Roboto'),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _GenderChoiceChip extends StatelessWidget {
  const _GenderChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.stroke,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accentText : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.label,
    required this.hint,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.stroke,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: AppColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
