import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/touch/align_touch_control.dart';
import 'package:nesd/ui/emulator/input/touch/touch_controls.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';

class DPad extends HookConsumerWidget {
  const DPad({required this.config, super.key});

  final DPadConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionStream = ref.watch(actionStreamProvider);
    final position = useState(Offset.zero);

    final half = config.size / 2;

    final deadZone = config.deadZone * half;

    final left = Rect.fromLTWH(
      0,
      half - deadZone,
      half - deadZone,
      2 * deadZone,
    );

    final right = Rect.fromLTWH(
      half + deadZone,
      half - deadZone,
      half - deadZone,
      2 * deadZone,
    );

    final up = Rect.fromLTWH(half - deadZone, 0, 2 * deadZone, half - deadZone);

    final down = Rect.fromLTWH(
      half - deadZone,
      half + deadZone,
      2 * deadZone,
      half - deadZone,
    );

    void handleEdge(
      DPadConfig config,
      InputAction? action,
      Rect rect,
      Offset previous,
      Offset current,
    ) {
      if (action == null) {
        return;
      }

      final inside = rect.contains(current);

      if (inside != rect.contains(previous)) {
        actionStream.add(
          InputActionEvent(
            action: action,
            value: inside ? 1.0 : 0.0,
            bindingType: config.bindingType,
          ),
        );
      }
    }

    void updatePosition(Offset offset) {
      final previous = position.value;

      position.value = offset;

      handleEdge(config, config.leftAction, left, previous, position.value);
      handleEdge(config, config.rightAction, right, previous, position.value);
      handleEdge(config, config.upAction, up, previous, position.value);
      handleEdge(config, config.downAction, down, previous, position.value);
    }

    final borderRadius = Radius.circular(config.size * config.deadZone / 4);

    return AlignTouchControl(
      alignment: Alignment(config.x, config.y),
      width: config.size,
      height: config.size,
      child: GestureDetector(
        onPanStart: (details) => updatePosition(details.localPosition),
        onPanUpdate: (details) => updatePosition(details.localPosition),
        onPanEnd: (_) {
          position.value = Offset.zero;

          if (config.upAction case final action?) {
            actionStream.add(
              InputActionEvent(
                action: action,
                value: 0.0,
                bindingType: config.bindingType,
              ),
            );
          }

          if (config.downAction case final action?) {
            actionStream.add(
              InputActionEvent(
                action: action,
                value: 0.0,
                bindingType: config.bindingType,
              ),
            );
          }

          if (config.leftAction case final action?) {
            actionStream.add(
              InputActionEvent(
                action: action,
                value: 0.0,
                bindingType: config.bindingType,
              ),
            );
          }

          if (config.rightAction case final action?) {
            actionStream.add(
              InputActionEvent(
                action: action,
                value: 0.0,
                bindingType: config.bindingType,
              ),
            );
          }
        },
        child: SizedBox(
          width: config.size,
          height: config.size,
          child: Stack(
            children: [
              DPadSegment(
                rect: Rect.fromLTWH(
                  half - deadZone,
                  half - deadZone,
                  config.deadZone * config.size,
                  config.deadZone * config.size,
                ),
                color: touchInputColor,
              ),
              DPadSegment(
                rect: left,
                borderRadius: BorderRadius.only(
                  topLeft: borderRadius,
                  bottomLeft: borderRadius,
                ),
                color:
                    left.contains(position.value)
                        ? touchInputColorActive
                        : touchInputColor,
              ),
              DPadSegment(
                rect: right,
                borderRadius: BorderRadius.only(
                  topRight: borderRadius,
                  bottomRight: borderRadius,
                ),
                color:
                    right.contains(position.value)
                        ? touchInputColorActive
                        : touchInputColor,
              ),
              DPadSegment(
                rect: up,
                borderRadius: BorderRadius.only(
                  topLeft: borderRadius,
                  topRight: borderRadius,
                ),
                color:
                    up.contains(position.value)
                        ? touchInputColorActive
                        : touchInputColor,
              ),
              DPadSegment(
                rect: down,
                borderRadius: BorderRadius.only(
                  bottomLeft: borderRadius,
                  bottomRight: borderRadius,
                ),
                color:
                    down.contains(position.value)
                        ? touchInputColorActive
                        : touchInputColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DPadSegment extends StatelessWidget {
  const DPadSegment({
    required this.rect,
    required this.color,
    this.borderRadius,
    super.key,
  });

  final Rect rect;

  final BorderRadius? borderRadius;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: Container(
        width: rect.width,
        height: rect.height,
        decoration: BoxDecoration(borderRadius: borderRadius, color: color),
      ),
    );
  }
}
