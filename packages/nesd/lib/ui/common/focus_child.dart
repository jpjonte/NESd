import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nesd/ui/common/focus_first_descendant.dart';

class FocusChild extends HookWidget {
  const FocusChild({
    required this.child,
    required this.autofocus,
    this.wrapAround = false,
    super.key,
  });

  final Widget child;

  final bool autofocus;

  final bool wrapAround;

  @override
  Widget build(BuildContext context) {
    final focusScopeNode = useFocusScopeNode(skipTraversal: true)
      ..directionalTraversalEdgeBehavior = wrapAround
          ? TraversalEdgeBehavior.closedLoop
          : TraversalEdgeBehavior.stop;

    useEffect(() {
      if (autofocus) {
        scheduleMicrotask(() => focusFirstDescendant(focusScopeNode));
      }

      return null;
    }, [autofocus]);

    return FocusScope(node: focusScopeNode, child: child);
  }
}
