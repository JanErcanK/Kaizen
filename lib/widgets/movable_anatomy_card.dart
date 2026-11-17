import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps at least half of a card visible while freeing space for the model.
/// A hold starts moving; ordinary taps and immediate swipes stay with its content.
class MovableAnatomyCard extends StatefulWidget {
  const MovableAnatomyCard({
    super.key,
    required this.child,
    this.initialPosition,
    this.initialAlignment = Alignment.topLeft,
    this.insets = const EdgeInsets.all(12),
  });

  final Widget child;
  final Offset? initialPosition;
  final Alignment initialAlignment;
  final EdgeInsets insets;

  @override
  State<MovableAnatomyCard> createState() => _MovableAnatomyCardState();
}

class _MovableAnatomyCardState extends State<MovableAnatomyCard> {
  final _areaKey = GlobalKey();
  final _cardKey = GlobalKey();
  Offset? _position;
  Offset? _dragOrigin;

  void _start(LongPressStartDetails details) {
    final area = _areaKey.currentContext?.findRenderObject() as RenderBox?;
    final card = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (area == null || card == null) return;
    setState(() {
      _dragOrigin = card.localToGlobal(Offset.zero, ancestor: area);
    });
    HapticFeedback.selectionClick();
  }

  void _move(LongPressMoveUpdateDetails details) {
    final origin = _dragOrigin;
    final area = _areaKey.currentContext?.findRenderObject() as RenderBox?;
    final card = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (origin == null || area == null || card == null) return;
    setState(() {
      _position = _boundedPosition(
        origin + details.offsetFromOrigin,
        area.size,
        card.size,
        widget.insets,
      );
    });
  }

  void _stop() {
    if (_dragOrigin != null) setState(() => _dragOrigin = null);
  }

  @override
  Widget build(BuildContext context) {
    final german = Localizations.localeOf(context).languageCode == 'de';
    return CustomSingleChildLayout(
      key: _areaKey,
      delegate: _CardLayout(
        position: _position ?? widget.initialPosition,
        alignment: widget.initialAlignment,
        insets: widget.insets,
      ),
      child: MouseRegion(
        key: _cardKey,
        cursor: _dragOrigin == null
            ? SystemMouseCursors.grab
            : SystemMouseCursors.grabbing,
        child: Semantics(
          hint: german
              ? 'Gedrückt halten und ziehen, um die Karte zu verschieben'
              : 'Hold and drag to move the card',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: _start,
            onLongPressMoveUpdate: _move,
            onLongPressEnd: (_) => _stop(),
            onLongPressCancel: _stop,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

Offset _boundedPosition(
  Offset position,
  Size area,
  Size card,
  EdgeInsets insets,
) => Offset(
  position.dx.clamp(-card.width / 2, math.max(0, area.width - card.width / 2)),
  position.dy.clamp(
    -card.height / 2,
    math.max(0, area.height - card.height / 2),
  ),
);

class _CardLayout extends SingleChildLayoutDelegate {
  const _CardLayout({
    required this.position,
    required this.alignment,
    required this.insets,
  });

  final Offset? position;
  final Alignment alignment;
  final EdgeInsets insets;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          math.max(0, constraints.maxWidth - insets.horizontal),
          math.max(0, constraints.maxHeight - insets.vertical),
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) => _boundedPosition(
    position ??
        Offset(insets.left, insets.top) +
            alignment.alongOffset(
              Offset(
                size.width - insets.horizontal - childSize.width,
                size.height - insets.vertical - childSize.height,
              ),
            ),
    size,
    childSize,
    insets,
  );

  @override
  bool shouldRelayout(_CardLayout oldDelegate) =>
      position != oldDelegate.position ||
      alignment != oldDelegate.alignment ||
      insets != oldDelegate.insets;
}
