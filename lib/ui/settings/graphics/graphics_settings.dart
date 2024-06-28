import 'package:flutter/material.dart';
import 'package:nes/ui/settings/graphics/border_switch.dart';
import 'package:nes/ui/settings/graphics/scaling_dropdown.dart';
import 'package:nes/ui/settings/graphics/stretch_switch.dart';

class GraphicsSettings extends StatelessWidget {
  const GraphicsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        StretchSwitch(),
        BorderSwitch(),
        ScalingDropdown(),
      ],
    );
  }
}
