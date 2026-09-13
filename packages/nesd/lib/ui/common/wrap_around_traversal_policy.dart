import 'package:flutter/widgets.dart';

class WrapAroundTraversalPolicy extends ReadingOrderTraversalPolicy {
  WrapAroundTraversalPolicy({required this.scope, super.requestFocusCallback});

  final FocusScopeNode scope;

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    if (super.inDirection(currentNode, direction)) {
      return true;
    }

    if (currentNode.nearestScope != scope) {
      return false;
    }

    final focused = scope.focusedChild;

    if (focused == null) {
      return false;
    }

    final target = _wrapTarget(focused, scope.traversalDescendants, direction);

    if (target == null) {
      return false;
    }

    invalidateScopeData(scope);

    requestFocusCallback(target, alignmentPolicy: _alignment(direction));

    return true;
  }

  FocusNode? _wrapTarget(
    FocusNode focused,
    Iterable<FocusNode> nodes,
    TraversalDirection direction,
  ) {
    final rect = focused.rect;
    final vertical = _isVertical(direction);
    final axis = vertical ? Axis.vertical : Axis.horizontal;

    bool behind(Rect other) => switch (direction) {
      TraversalDirection.down => other.center.dy < rect.top,
      TraversalDirection.up => other.center.dy > rect.bottom,
      TraversalDirection.right => other.center.dx < rect.left,
      TraversalDirection.left => other.center.dx > rect.right,
    };

    bool inBand(Rect other) => vertical
        ? other.left < rect.right && other.right > rect.left
        : other.top < rect.bottom && other.bottom > rect.top;

    var candidates = [
      for (final node in nodes)
        if (node != focused && behind(node.rect)) node,
    ];

    final scrollable = Scrollable.maybeOf(focused.context!, axis: axis);

    if (scrollable != null) {
      final inScrollable = [
        for (final node in candidates)
          if (Scrollable.maybeOf(node.context!, axis: axis) == scrollable) node,
      ];

      if (inScrollable.isNotEmpty) {
        candidates = inScrollable;
      }
    }

    final banded = [
      for (final node in candidates)
        if (inBand(node.rect)) node,
    ];

    if (banded.isNotEmpty) {
      candidates = banded;
    }

    if (candidates.isEmpty) {
      return null;
    }

    double position(FocusNode node) =>
        vertical ? node.rect.center.dy : node.rect.center.dx;

    final forward =
        direction == TraversalDirection.down ||
        direction == TraversalDirection.right;

    return candidates.reduce((a, b) {
      final aFirst = position(a) <= position(b);

      return aFirst == forward ? a : b;
    });
  }

  static bool _isVertical(TraversalDirection direction) =>
      direction == TraversalDirection.up ||
      direction == TraversalDirection.down;

  static ScrollPositionAlignmentPolicy _alignment(
    TraversalDirection direction,
  ) => switch (direction) {
    TraversalDirection.up ||
    TraversalDirection.left => ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    TraversalDirection.down ||
    TraversalDirection.right => ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
  };
}
