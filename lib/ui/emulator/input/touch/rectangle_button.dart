import 'package:flutter/material.dart';
import 'package:nesd/ui/emulator/input/touch/align_touch_control.dart';
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
    return AlignTouchControl(
      alignment: Alignment(config.x, config.y),
      width: config.width,
      height: config.height,
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
