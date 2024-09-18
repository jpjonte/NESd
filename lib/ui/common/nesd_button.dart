import 'package:flutter/material.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';

class NesdButton extends StatelessWidget {
  const NesdButton({
    required this.child,
    this.autofocus = false,
    this.icon,
    this.onPressed,
    super.key,
  });

  final Widget child;
  final bool autofocus;
  final Icon? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FocusOnHover(
      child: SizedBox(
        width: 200,
        child: icon != null
            ? FilledButton.icon(
                autofocus: autofocus,
                onPressed: onPressed,
                icon: icon,
                label: child,
              )
            : FilledButton(
                autofocus: autofocus,
                onPressed: onPressed,
                child: child,
              ),
      ),
    );
  }
}
