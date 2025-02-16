import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/touch/align_touch_control.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';

class JoyStick extends HookConsumerWidget {
  const JoyStick({required this.config, super.key});

  final JoyStickConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionStream = ref.watch(actionStreamProvider);
    final position = useState(Alignment.center);
    final active = useState(false);

    void handleEdge(double previous, double current, InputAction? action) {
      if (action == null) {
        return;
      }

      final inside = current > config.deadZone;

      if (previous <= config.deadZone != inside) {
        actionStream.add((action: action, value: inside ? 1.0 : 0.0));
      }
    }

    void updatePosition(Offset offset) {
      final radius = config.size / 2;

      final dx = offset.dx - radius;
      final dy = offset.dy - radius;

      final distance = Offset(dx, dy).distance;

      final previous = position.value;

      if (distance < radius) {
        position.value = Alignment(dx / radius, dy / radius);
      } else {
        position.value = Alignment(dx / distance, dy / distance);
      }

      handleEdge(-previous.x, -position.value.x, config.leftAction);
      handleEdge(previous.x, position.value.x, config.rightAction);
      handleEdge(-previous.y, -position.value.y, config.upAction);
      handleEdge(previous.y, position.value.y, config.downAction);
    }

    return AlignTouchControl(
      alignment: Alignment(config.x, config.y),
      width: config.size,
      height: config.size,
      child: GestureDetector(
        onPanStart: (details) {
          active.value = true;
          updatePosition(details.localPosition);
        },
        onPanUpdate: (details) => updatePosition(details.localPosition),
        onPanEnd: (_) {
          active.value = false;
          position.value = Alignment.center;

          if (config.upAction case final action?) {
            actionStream.add((action: action, value: 0.0));
          }

          if (config.downAction case final action?) {
            actionStream.add((action: action, value: 0.0));
          }

          if (config.leftAction case final action?) {
            actionStream.add((action: action, value: 0.0));
          }

          if (config.rightAction case final action?) {
            actionStream.add((action: action, value: 0.0));
          }
        },
        child: Container(
          width: config.size,
          height: config.size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x66FFFFFF),
          ),
          child: Align(
            alignment: position.value,
            child: Container(
              width: config.innerSize,
              height: config.innerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    active.value
                        ? const Color(0xFFFFFFFF)
                        : const Color(0x99FFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
