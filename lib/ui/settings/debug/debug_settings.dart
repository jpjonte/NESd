import 'package:flutter/material.dart';
import 'package:nes/ui/settings/debug/cartridge_switch.dart';
import 'package:nes/ui/settings/debug/debug_tile_switch.dart';

class DebugSettings extends StatelessWidget {
  const DebugSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        DebugTileSwitch(),
        CartridgeSwitch(),
      ],
    );
  }
}
