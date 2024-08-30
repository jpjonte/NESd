import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FocusOnHover extends HookWidget {
  const FocusOnHover({
    required this.child,
    this.cursor,
    this.focusNode,
    this.onKeyEvent,
    this.onFocusChange,
    super.key,
  });

  final Widget child;
  final MouseCursor? cursor;
  final FocusNode? focusNode;
  final FocusOnKeyEventCallback? onKeyEvent;
  final ValueChanged<bool>? onFocusChange;

  @override
  Widget build(BuildContext context) {
    final focusNode = this.focusNode ?? useFocusNode();

    return Focus(
      focusNode: focusNode,
      onKeyEvent: onKeyEvent,
      skipTraversal: true,
      onFocusChange: onFocusChange,
      child: MouseRegion(
        cursor: cursor ?? MouseCursor.defer,
        onHover: (_) {
          if (!focusNode.hasFocus) {
            focusNode.descendants
                .where((d) => d.canRequestFocus)
                .firstOrNull
                ?.requestFocus();
          }
        },
        child: child,
      ),
    );
  }
}
