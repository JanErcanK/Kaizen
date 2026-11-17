import 'package:flutter/widgets.dart';

/// Stable logical tab IDs; the visual order is Chat, Home, Profile.
class AppTabNavigation {
  AppTabNavigation._();

  static const home = 0;
  static const profile = 1;
  static const chat = 2;
  static const visualOrder = [chat, home, profile];

  static final ValueNotifier<int> selectedTab = ValueNotifier<int>(0);

  /// When false, horizontal tab swiping is disabled (e.g. expanded mannequin).
  static final ValueNotifier<bool> tabSwipeEnabled = ValueNotifier<bool>(true);

  /// Return from a saved workout to Home, including nested workout routes.
  static void returnHome(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    selectedTab.value = home;
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
  }
}
