import 'package:flutter/material.dart';
import 'package:nesd/ui/settings/graphics/border_switch.dart';
import 'package:nesd/ui/settings/graphics/renderer_selector.dart';
import 'package:nesd/ui/settings/graphics/scaling_dropdown.dart';
import 'package:nesd/ui/settings/graphics/stretch_switch.dart';
import 'package:nesd/ui/settings/settings_tab.dart';

class GraphicsSettings extends StatelessWidget {
  const GraphicsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsTab(
      index: 1,
      child: SingleChildScrollView(
        child: Column(
          children: [
            RendererSelector(),
            StretchSwitch(),
            BorderSwitch(),
            ScalingDropdown(),
          ],
        ),
      ),
    );
  }
}
