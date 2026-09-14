import 'package:flutter/material.dart';
import 'package:nesd/ui/common/hints/input_hint_bar.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';

const _focusedHints = [
  InputHint(actions: [previousTab, nextTab], label: 'Switch tool'),
  InputHint(actions: [cancel, openMenu, focusTools], label: 'Back to game'),
];

const _unfocusedHints = [
  InputHint(actions: [focusTools], label: 'Focus tools'),
];

class ToolHostHints extends StatelessWidget {
  const ToolHostHints({required this.focused, super.key});

  final bool focused;

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      child: InputHintBar(
        hints: focused ? _focusedHints : _unfocusedHints,
        padding: const EdgeInsets.all(4),
      ),
    );
  }
}
