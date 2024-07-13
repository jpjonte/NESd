import 'package:flutter/material.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';

class NesdButton extends StatelessWidget {
  const NesdButton({
    required this.child,
    this.autofocus = false,
    this.onPressed,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return FocusOnHover(
      child: SizedBox(
        width: 200,
        child: FilledButton(
          autofocus: autofocus,
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}
