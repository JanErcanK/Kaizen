import 'package:flutter/material.dart';

/// The workout search back control, shared across every route.
/// The visible tile is narrow; its surrounding touch target stays generous.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        padding: const EdgeInsets.only(right: 12),
        icon: const AppBackIcon(),
      ),
    );
  }
}

/// Also used by Flutter-owned routes (for example software licenses).
class AppBackIcon extends StatelessWidget {
  const AppBackIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: 34,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: light ? const Color(0xFFF2F2F7) : const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.arrow_back_rounded,
        size: 19,
        color: light ? const Color(0xFF8E8E93) : const Color(0xFF98989D),
      ),
    );
  }
}
