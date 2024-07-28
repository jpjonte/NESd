import 'package:flutter/material.dart';
import 'package:nesd/ui/emulator/input/touch/touch_button.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';

class RectangleButton extends StatelessWidget {
  const RectangleButton({
    required this.config,
    super.key,
  });

  final RectangleButtonConfig config;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(config.x, config.y),
      child: TouchButton(
        width: config.width,
        height: config.height,
        label: config.label,
        action: config.action,
        decorationBuilder: (color) => BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color,
        ),
      ),
    );
  }
}
