import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/touch/touch_controls.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';
import 'package:nesd/ui/theme/base.dart';

enum TouchButtonShape { circle, rectangle }

class TouchButton extends HookConsumerWidget {
  const TouchButton({
    required this.width,
    required this.height,
    required this.label,
    required this.decorationBuilder,
    required this.config,
    this.action,
    super.key,
  });

  final double width;
  final double height;
  final String label;
  final Decoration Function(Color) decorationBuilder;
  final TouchInputConfig config;
  final InputAction? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = useState(false);
    final actionStream = ref.watch(actionStreamProvider);

    void up() {
      active.value = false;

      if (action case final action?) {
        actionStream.add(
          InputActionEvent(
            action: action,
            value: 0.0,
            bindingType: config.bindingType,
          ),
        );
      }
    }

    final color = active.value ? touchInputColorActive : touchInputColor;

    return GestureDetector(
      onTapDown: (_) {
        active.value = true;

        if (action case final action?) {
          actionStream.add(
            InputActionEvent(
              action: action,
              value: 1.0,
              bindingType: config.bindingType,
            ),
          );
        }
      },
      onTapCancel: up,
      onTapUp: (_) => up(),
      child: Container(
        width: width,
        height: height,
        decoration: decorationBuilder(color),
        child: Center(
          child: Text(
            label,
            style: baseTextStyle.copyWith(
              color: Colors.white,
              fontVariations: const [FontVariation.weight(700)],
            ),
          ),
        ),
      ),
    );
  }
}
