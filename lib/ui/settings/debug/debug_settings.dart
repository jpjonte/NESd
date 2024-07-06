import 'package:flutter/material.dart';
import 'package:nes/ui/settings/debug/cartridge_switch.dart';
import 'package:nes/ui/settings/debug/debug_tile_switch.dart';
import 'package:nes/ui/settings/settings_tab.dart';

class DebugSettings extends StatelessWidget {
  const DebugSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsTab(
      index: 4,
      child: ListView(
        children: const [
          DebugTileSwitch(),
          CartridgeSwitch(),
        ],
      ),
    );
  }
}
