import 'package:flutter/material.dart';

/// Edge swipe from the left pops back to the app home (first route).
///
/// Only starts near the left screen edge so it does not fight TabBarView /
/// horizontal lists in the middle of the screen.
class HomeEdgeSwipeBack extends StatefulWidget {
  const HomeEdgeSwipeBack({
    super.key,
    required this.child,
    this.edgeWidth = 28,
    this.distanceThreshold = 72,
  });

  final Widget child;
  final double edgeWidth;
  final double distanceThreshold;

  @override
  State<HomeEdgeSwipeBack> createState() => _HomeEdgeSwipeBackState();
}

class _HomeEdgeSwipeBackState extends State<HomeEdgeSwipeBack> {
  double? _startX;
  double _dragDx = 0;

  void _goHome() {
    final nav = Navigator.of(context);
    if (!nav.canPop()) return;
    nav.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (details) {
        final x = details.globalPosition.dx;
        if (x <= widget.edgeWidth) {
          _startX = x;
          _dragDx = 0;
        } else {
          _startX = null;
        }
      },
      onHorizontalDragUpdate: (details) {
        if (_startX == null) return;
        _dragDx += details.delta.dx;
      },
      onHorizontalDragEnd: (_) {
        if (_startX != null && _dragDx >= widget.distanceThreshold) {
          _goHome();
        }
        _startX = null;
        _dragDx = 0;
      },
      onHorizontalDragCancel: () {
        _startX = null;
        _dragDx = 0;
      },
      child: widget.child,
    );
  }
}
