import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../navigation/app_tab_navigation.dart';
import '../services/progress_store.dart';
import '../services/coach_share_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_tour.dart';
import 'onboarding/onboarding_flow.dart';
import 'profile_screen.dart';
import 'start_screen.dart';
import 'chat_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  static ValueNotifier<int> get selectedTab => AppTabNavigation.selectedTab;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  bool _pageChangeFromTab = false;
  bool _homeIntroRunning = false;
  bool _tourActive = false;
  late final Map<String, GlobalKey> _tourKeys;
  late final AppTourController _tourController;
  late final PageController _pageController;
  bool _shareNavigationScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (CoachShareService.pending.value.isNotEmpty) {
      AppTabNavigation.selectedTab.value = AppTabNavigation.chat;
    }
    _pageController = PageController(
      initialPage: AppTabNavigation.visualOrder.indexOf(
        AppTabNavigation.selectedTab.value,
      ),
    );
    AppTabNavigation.selectedTab.addListener(_onSelectedTabChanged);
    _tourKeys = {
      'mannequin': GlobalKey(),
      'workout': GlobalKey(),
      'running': GlobalKey(),
      'food': GlobalKey(),
      'shopping': GlobalKey(),
      'friends': GlobalKey(),
      'metabolic': GlobalKey(),
      'gallery': GlobalKey(),
      'calendar': GlobalKey(),
      'weight': GlobalKey(),
      'leveling': GlobalKey(),
      'health': GlobalKey(),
    };
    _tourController = AppTourController(keys: _tourKeys)
      ..onFinished = _markAppTourCompleted
      ..navigateToTab = _navigateTourTab
      ..addListener(_onTourActivityChanged);
    ProgressStore.markHomeOpened();
    CoachShareService.pending.addListener(_onSharedInput);
    unawaited(CoachShareService.start());
    WidgetsBinding.instance.addPostFrameCallback((_) => _onSharedInput());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CoachShareService.pending.removeListener(_onSharedInput);
    AppTabNavigation.selectedTab.removeListener(_onSelectedTabChanged);
    _pageController.dispose();
    _tourController.dispose();
    super.dispose();
  }

  void _onSharedInput() {
    if (!mounted || CoachShareService.pending.value.isEmpty) return;
    if (_shareNavigationScheduled) return;
    _shareNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shareNavigationScheduled = false;
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
      AppTabNavigation.selectedTab.value = AppTabNavigation.chat;
      // The notifier may already say Chat before PageView attaches. Explicitly
      // synchronize the visible page even when the value did not change.
      if (_pageController.hasClients) {
        _pageChangeFromTab = true;
        _pageController.jumpToPage(
          AppTabNavigation.visualOrder.indexOf(AppTabNavigation.chat),
        );
        _pageChangeFromTab = false;
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(CoachShareService.refresh());
    }
  }

  void _onTourActivityChanged() {
    if (!mounted || _tourActive == _tourController.isActive) return;
    // Step changes only rebuild the overlay, keeping charts and the WebView
    // intact while the tour moves between targets.
    setState(() => _tourActive = _tourController.isActive);
  }

  Future<void> _navigateTourTab(int tab) async {
    _pageChangeFromTab = true;
    AppTabNavigation.selectedTab.value = tab;
    await WidgetsBinding.instance.endOfFrame;
    try {
      if (!mounted || !_pageController.hasClients) return;
      final target = AppTabNavigation.visualOrder.indexOf(tab);
      if (MediaQuery.disableAnimationsOf(context)) {
        _pageController.jumpToPage(target);
      } else if ((_pageController.page! - target).abs() > .001) {
        await _pageController.animateToPage(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
        );
      }
    } finally {
      _pageChangeFromTab = false;
    }
  }

  void _onSelectedTabChanged() {
    // Clear focus history before moving away from an input. Otherwise popping
    // a Home dialog can restore the kept-alive Chat field and its keyboard.
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_pageController.hasClients || _pageChangeFromTab) return;
    final target = AppTabNavigation.visualOrder.indexOf(
      AppTabNavigation.selectedTab.value,
    );
    final current = _pageController.page?.round() ?? target;
    if (current == target) return;
    if (_tourController.isActive) {
      _pageController.jumpToPage(target);
      return;
    }
    _pageChangeFromTab = true;
    _pageController
        .animateToPage(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          _pageChangeFromTab = false;
          if (mounted) _onSelectedTabChanged();
        });
  }

  void _onPageChanged(int index) {
    if (_pageChangeFromTab) return;
    final tab = AppTabNavigation.visualOrder[index];
    if (AppTabNavigation.selectedTab.value != tab) {
      AppTabNavigation.selectedTab.value = tab;
    }
  }

  ScrollPhysics _tabPagePhysics(bool tourActive) {
    if (tourActive || !AppTabNavigation.tabSwipeEnabled.value) {
      return const NeverScrollableScrollPhysics();
    }
    return const PageScrollPhysics();
  }

  Future<void> _markAppTourCompleted() async {
    await ProgressStore.setHasCompletedAppTour(true);
    await ProgressStore.setHasSeenInstallHint(true);
  }

  Future<void> _startAppTour() async {
    if (_tourController.isActive || _homeIntroRunning) return;
    await _tourController.start(context.l10n);
  }

  Future<void> _startHomeIntro() async {
    if (_homeIntroRunning || _tourController.isActive) return;
    if (!ProgressStore.needsHomeIntro) return;
    _homeIntroRunning = true;

    final previousFinished = _tourController.onFinished;
    final tourDone = Completer<void>();
    _tourController.onFinished = () {
      unawaited(_markAppTourCompleted());
      if (!tourDone.isCompleted) tourDone.complete();
    };

    try {
      await _tourController.start(context.l10n);
      await tourDone.future;
      if (!mounted) return;

      AppTabNavigation.selectedTab.value = 0;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => OnboardingFlow(
            mode: OnboardingMode.setup,
            onCompleted: () {
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ),
      );
      if (!mounted) return;
      if (ProgressStore.needsHomeIntro) {
        await ProgressStore.setHasCompletedHomeIntro(true);
      }
    } finally {
      _tourController.onFinished = previousFinished;
      _homeIntroRunning = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTabNavigation.tabSwipeEnabled,
      builder: (context, tabSwipeEnabled, _) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.background,
              // Each page gets its own RepaintBoundary so sliding between
              // tabs composites two cached layers instead of re-painting
              // the mannequin / charts on every transition frame.
              body: PageView(
                controller: _pageController,
                physics: _tabPagePhysics(_tourController.isActive),
                onPageChanged: _onPageChanged,
                children: [
                  _TabFocus(
                    tab: AppTabNavigation.chat,
                    child: ValueListenableBuilder<int>(
                      valueListenable: AppTabNavigation.selectedTab,
                      builder: (_, tab, _) => RepaintBoundary(
                        child: ChatScreen(
                          isActive: tab == AppTabNavigation.chat,
                        ),
                      ),
                    ),
                  ),
                  _TabFocus(
                    tab: AppTabNavigation.home,
                    child: RepaintBoundary(
                      child: StartScreen(
                        categoryTourKeys: _tourKeys,
                        onStartIntro: _tourController.isActive
                            ? null
                            : _startHomeIntro,
                      ),
                    ),
                  ),
                  _TabFocus(
                    tab: AppTabNavigation.profile,
                    child: RepaintBoundary(
                      child: ProfileScreen(
                        onStartTour: _startAppTour,
                        tourKeys: _tourKeys,
                      ),
                    ),
                  ),
                ],
              ),
              // Scoped to just the nav bar: switching tabs used to rebuild
              // the whole PageView (both screens) via an outer listener
              // that only this widget actually needed.
              bottomNavigationBar: ValueListenableBuilder<int>(
                valueListenable: AppTabNavigation.selectedTab,
                builder: (context, selectedIndex, _) => AppBottomNavBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    if (_tourController.isActive) return;
                    AppTabNavigation.selectedTab.value = index;
                  },
                ),
              ),
            ),
            if (_tourController.isActive)
              Positioned.fill(
                child: AppTourOverlay(controller: _tourController),
              ),
          ],
        );
      },
    );
  }
}

/// Off-screen pages stay alive for drafts and scroll position, but cannot
/// receive restored focus, traversal or text input while another tab is open.
class _TabFocus extends StatelessWidget {
  const _TabFocus({required this.tab, required this.child});
  final int tab;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: AppTabNavigation.selectedTab,
    child: child,
    builder: (_, selected, child) =>
        ExcludeFocus(excluding: selected != tab, child: child!),
  );
}
