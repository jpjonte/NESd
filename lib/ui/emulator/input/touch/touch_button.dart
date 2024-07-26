import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/input/action.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';

enum TouchButtonShape { circle, rectangle }

class TouchButton extends HookConsumerWidget {
  const TouchButton({
    required this.width,
    required this.height,
    required this.label,
    required this.action,
    required this.decorationBuilder,
    super.key,
  });

  final double width;
  final double height;
  final String label;
  final NesAction action;
  final Decoration Function(Color) decorationBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = useState(false);
    final actionStream = ref.watch(actionStreamProvider);

    void up() {
      active.value = false;

      actionStream.add((action: action, value: 0.0));
    }

    final color =
        active.value ? const Color(0xFFFFFFFF) : const Color(0x99FFFFFF);

    return GestureDetector(
      onTapDown: (_) {
        active.value = true;

        actionStream.add((action: action, value: 1.0));
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
