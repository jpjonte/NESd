import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';

enum TouchButtonShape { circle, rectangle }

class TouchButton extends HookConsumerWidget {
  const TouchButton({
    required this.width,
    required this.height,
    required this.label,
    required this.decorationBuilder,
    this.action,
    super.key,
  });

  final double width;
  final double height;
  final String label;
  final InputAction? action;
  final Decoration Function(Color) decorationBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = useState(false);
    final actionStream = ref.watch(actionStreamProvider);

    void up() {
      active.value = false;

      if (action case final action?) {
        actionStream.add((action: action, value: 0.0));
      }
    }

    final color =
        active.value ? const Color(0xFFFFFFFF) : const Color(0x99FFFFFF);

    return GestureDetector(
      onTapDown: (_) {
        active.value = true;

        if (action case final action?) {
          actionStream.add((action: action, value: 1.0));
        }
      },
      onTapCancel: up,
      onTapUp: (_) => up(),
      child: Container(
        width: width,
        height: height,
        decoration: decorationBuilder(color),
        child: Center(child: Text(label)),
      ),
    );
  }
}
