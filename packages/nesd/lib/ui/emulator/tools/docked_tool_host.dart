import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:nesd/ui/emulator/tools/tool_widgets.dart';

class DockedToolHost extends HookConsumerWidget {
  const DockedToolHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final needed = tools.fold(0.0, (sum, tool) => sum + tool.minHeight);

          if (constraints.hasBoundedHeight && needed <= constraints.maxHeight) {
            return Column(
              children: [
                for (final tool in tools) _filled(tool, cartridgeInfo),
              ],
            );
          }

          return Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    for (final tool in tools) _pinned(tool, cartridgeInfo),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filled(EmulatorTool tool, CartridgeInfo? cartridgeInfo) =>
      switch (tool) {
        EmulatorTool.debugger || EmulatorTool.executionLog => Expanded(
          child: emulatorToolWidget(tool, cartridgeInfo),
        ),
        EmulatorTool.display || EmulatorTool.apuDebug => Expanded(
          child: SingleChildScrollView(
            child: emulatorToolWidget(tool, cartridgeInfo),
          ),
        ),
        EmulatorTool.tileViewer ||
        EmulatorTool.cartridgeInfo => emulatorToolWidget(tool, cartridgeInfo),
      };

  Widget _pinned(EmulatorTool tool, CartridgeInfo? cartridgeInfo) => SizedBox(
    height: tool.minHeight,
    child: switch (tool) {
      EmulatorTool.display ||
      EmulatorTool.tileViewer ||
      EmulatorTool.cartridgeInfo ||
      EmulatorTool.apuDebug => SingleChildScrollView(
        child: emulatorToolWidget(tool, cartridgeInfo),
      ),
      EmulatorTool.debugger ||
      EmulatorTool.executionLog => emulatorToolWidget(tool, cartridgeInfo),
    },
  );
}
