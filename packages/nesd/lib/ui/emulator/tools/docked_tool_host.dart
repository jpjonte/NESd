import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:nesd/ui/emulator/tools/tool_widgets.dart';

class DockedToolHost extends ConsumerWidget {
  const DockedToolHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openTools = ref.watch(emulatorToolsControllerProvider);

    if (openTools.isEmpty) {
      return const SizedBox.shrink();
    }

    final cartridgeInfo = ref.watch(
      nesStateProvider.select((nes) => nes?.cartridgeInfo),
    );

    final tools = EmulatorTool.values.where(openTools.contains).toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: dockedToolColumnWidth),
      child: Column(
        children: [for (final tool in tools) _docked(tool, cartridgeInfo)],
      ),
    );
  }

  Widget _docked(EmulatorTool tool, CartridgeInfo? cartridgeInfo) =>
      switch (tool) {
        EmulatorTool.debugger || EmulatorTool.executionLog => Expanded(
          child: emulatorToolWidget(tool, cartridgeInfo),
        ),
        EmulatorTool.apuDebug => Expanded(
          child: SingleChildScrollView(
            child: emulatorToolWidget(tool, cartridgeInfo),
          ),
        ),
        EmulatorTool.tileViewer ||
        EmulatorTool.cartridgeInfo => emulatorToolWidget(tool, cartridgeInfo),
      };
}
