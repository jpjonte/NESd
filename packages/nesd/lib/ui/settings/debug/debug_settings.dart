import 'package:flutter/material.dart';
import 'package:nesd/ui/settings/debug/debug_overlay_switch.dart';
import 'package:nesd/ui/settings/debug/log_level_dropdown.dart';
import 'package:nesd/ui/settings/settings_tab.dart';

class DebugSettings extends StatelessWidget {
  const DebugSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsTab(
      index: 4,
      child: SingleChildScrollView(
        child: Column(children: [DebugOverlaySwitch(), LogLevelDropdown()]),
      ),
    );
  }
}
