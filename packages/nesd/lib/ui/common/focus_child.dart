import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nesd/ui/common/focus_first_descendant.dart';
import 'package:nesd/ui/common/wrap_around_traversal_policy.dart';

class FocusChild extends HookWidget {
  const FocusChild({
    required this.child,
    required this.autofocus,
    this.wrapAround = false,
    this.wrapTraversal = true,
    super.key,
  });

  final Widget child;

  final bool autofocus;

  /// whether directional (arrow) moves wrap around at the edges
  final bool wrapAround;

  /// whether next/previous (tab order) moves wrap around at the edges
  final bool wrapTraversal;

  @override
  Widget build(BuildContext context) {
    final focusScopeNode = useFocusScopeNode(skipTraversal: true)
      ..traversalEdgeBehavior = wrapTraversal
          ? TraversalEdgeBehavior.closedLoop
          : TraversalEdgeBehavior.stop;

    final policy = useMemoized(
      () =>
          wrapAround ? WrapAroundTraversalPolicy(scope: focusScopeNode) : null,
      [wrapAround, focusScopeNode],
    );

    useEffect(() {
      if (autofocus) {
        scheduleMicrotask(() => focusFirstDescendant(focusScopeNode));
      }

      return null;
    }, [autofocus]);

    return FocusScope(
      node: focusScopeNode,
      child: policy == null
          ? child
          : FocusTraversalGroup(policy: policy, child: child),
    );
  }
}
