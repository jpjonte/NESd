import 'package:flutter/material.dart';
import 'package:nesd/ui/emulator/input/touch/touch_button.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';

class CircleButton extends StatelessWidget {
  const CircleButton({
    required this.config,
    super.key,
  });

  final CircleButtonConfig config;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(config.x, config.y),
      child: TouchButton(
        width: config.size,
        height: config.size,
        label: config.label,
        action: config.action,
        decorationBuilder: (color) => BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
