import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/execution_log/execution_log_widget.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:nesd/ui/emulator/tools/tool_widgets.dart';

const _dockedColumnMaxWidth = 512.0;

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

    final columnTools = EmulatorTool.values
        .where(
          (tool) =>
              tool != EmulatorTool.executionLog && openTools.contains(tool),
        )
        .toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (columnTools.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _dockedColumnMaxWidth),
            child: Column(
              children: [
                for (final tool in columnTools) _docked(tool, cartridgeInfo),
              ],
            ),
          ),
        if (openTools.contains(EmulatorTool.executionLog))
          const ExecutionLogWidget(),
      ],
    );
  }

  Widget _docked(EmulatorTool tool, CartridgeInfo? cartridgeInfo) =>
      switch (tool) {
        EmulatorTool.debugger => Expanded(
          child: emulatorToolWidget(tool, cartridgeInfo),
        ),
        EmulatorTool.apuDebug => Expanded(
          child: SingleChildScrollView(
            child: emulatorToolWidget(tool, cartridgeInfo),
          ),
        ),
        _ => emulatorToolWidget(tool, cartridgeInfo),
      };
}
