import 'package:flutter/material.dart';
import 'package:nesd/ui/emulator/input/touch/align_touch_control.dart';
import 'package:nesd/ui/emulator/input/touch/touch_button.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';

class CircleButton extends StatelessWidget {
  const CircleButton({required this.config, super.key});

  final CircleButtonConfig config;

  @override
  Widget build(BuildContext context) {
    return AlignTouchControl(
      alignment: Alignment(config.x, config.y),
      width: config.size,
      height: config.size,
      child: TouchButton(
        width: config.size,
        height: config.size,
        label: config.label,
        action: config.action,
        config: config,
        decorationBuilder: (color) =>
            BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
