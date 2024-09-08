import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';

// ignore: avoid_positional_boolean_parameters
typedef FocusedBuilder = Widget Function(BuildContext context, bool focused);

class CustomButton extends HookWidget {
  const CustomButton({
    required this.onPressed,
    required this.builder,
    this.onLongPress,
    super.key,
  });

  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final FocusedBuilder builder;

  @override
  Widget build(BuildContext context) {
    final active = useState(false);

    return Actions(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) => onPressed(),
        ),
      },
      child: FocusOnHover(
        cursor: SystemMouseCursors.click,
        onFocusChange: (hasFocus) => active.value = hasFocus,
        child: Focus(
          child: GestureDetector(
            onTap: onPressed,
            onLongPress: onLongPress,
            child: builder(context, active.value),
          ),
        ),
      ),
    );
  }
}
