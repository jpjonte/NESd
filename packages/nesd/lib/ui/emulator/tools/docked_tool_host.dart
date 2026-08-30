import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/focus_child.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/input/intents.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:nesd/ui/emulator/tools/tool_focus_controller.dart';
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

    final focused = ref.watch(toolFocusControllerProvider);

    final navigable = tools.where((tool) => !tool.pointerOnly).toList();

    final activePanel = useState<EmulatorTool?>(null);

    final active = navigable.contains(activePanel.value)
        ? activePanel.value!
        : navigable.firstOrNull;

    void step(int delta) {
      if (navigable.isEmpty) {
        return;
      }

      final index = active == null ? 0 : navigable.indexOf(active);

      activePanel.value = navigable[(index + delta) % navigable.length];
    }

    return Actions(
      actions: {
        PreviousTabIntent: CallbackAction<PreviousTabIntent>(
          onInvoke: (_) => step(-1),
        ),
        NextTabIntent: CallbackAction<NextTabIntent>(onInvoke: (_) => step(1)),
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: dockedToolColumnWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final needed = tools.fold(0.0, (sum, tool) => sum + tool.minHeight);

            if (constraints.hasBoundedHeight &&
                needed <= constraints.maxHeight) {
              return Column(
                children: [
                  for (final tool in tools)
                    _filled(
                      tool,
                      cartridgeInfo,
                      focus: focused && tool == active,
                    ),
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
                      for (final tool in tools)
                        _pinned(
                          tool,
                          cartridgeInfo,
                          focus: focused && tool == active,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _panel(
    EmulatorTool tool,
    CartridgeInfo? cartridgeInfo, {
    required bool focus,
  }) => FocusChild(
    autofocus: focus,
    child: emulatorToolWidget(tool, cartridgeInfo),
  );

  Widget _filled(
    EmulatorTool tool,
    CartridgeInfo? cartridgeInfo, {
    required bool focus,
  }) => switch (tool) {
    EmulatorTool.debugger || EmulatorTool.executionLog => Expanded(
      child: _panel(tool, cartridgeInfo, focus: focus),
    ),
    EmulatorTool.display ||
    EmulatorTool.audio ||
    EmulatorTool.apuDebug => Expanded(
      child: SingleChildScrollView(
        child: _panel(tool, cartridgeInfo, focus: focus),
      ),
    ),
    EmulatorTool.tileViewer ||
    EmulatorTool.cartridgeInfo => _panel(tool, cartridgeInfo, focus: focus),
  };

  Widget _pinned(
    EmulatorTool tool,
    CartridgeInfo? cartridgeInfo, {
    required bool focus,
  }) => SizedBox(
    height: tool.minHeight,
    child: switch (tool) {
      EmulatorTool.display ||
      EmulatorTool.audio ||
      EmulatorTool.tileViewer ||
      EmulatorTool.cartridgeInfo ||
      EmulatorTool.apuDebug => SingleChildScrollView(
        child: _panel(tool, cartridgeInfo, focus: focus),
      ),
      EmulatorTool.debugger ||
      EmulatorTool.executionLog => _panel(tool, cartridgeInfo, focus: focus),
    },
  );
}
