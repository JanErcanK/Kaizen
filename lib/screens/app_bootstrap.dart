import 'package:flutter/material.dart';

import '../services/progress_store.dart';
import 'onboarding/onboarding_flow.dart';
import 'root_shell.dart';

/// Chooses the initial screen without pushing a route that can be lost when
/// [MaterialApp] rebuilds (e.g. after [ProgressStore.markHomeOpened]).
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  var _showMainApp = !ProgressStore.needsOnboarding;

  void _onOnboardingCompleted() {
    setState(() => _showMainApp = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_showMainApp && ProgressStore.needsOnboarding) {
      return OnboardingFlow(onCompleted: _onOnboardingCompleted);
    }
    return const RootShell();
  }
}
