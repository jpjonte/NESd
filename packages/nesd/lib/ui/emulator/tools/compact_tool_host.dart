import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:nesd/ui/emulator/tools/tool_widgets.dart';

class CompactToolHost extends HookConsumerWidget {
  const CompactToolHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openTools = ref.watch(emulatorToolsControllerProvider);
    final tools = ref.read(emulatorToolsControllerProvider.notifier);

    final selected = useState<EmulatorTool?>(null);

    if (openTools.isEmpty) {
      return const SizedBox.shrink();
    }

    final ordered = EmulatorTool.values.where(openTools.contains).toList();

    final active = ordered.contains(selected.value)
        ? selected.value!
        : ordered.first;

    final cartridgeInfo = ref.watch(
      nesStateProvider.select((nes) => nes?.cartridgeInfo),
    );

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final tool in ordered)
                        TextButton(
                          key: Key('compactTab_${tool.name}'),
                          onPressed: () => selected.value = tool,
                          child: Text(tool.title),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                key: const Key('compactToolClose'),
                icon: const Icon(Icons.close),
                tooltip: 'Close ${active.title}',
                onPressed: () => tools.close(active),
              ),
            ],
          ),
          Expanded(child: _body(active, cartridgeInfo)),
        ],
      ),
    );
  }

  Widget _body(EmulatorTool tool, CartridgeInfo? cartridgeInfo) {
    final content = emulatorToolWidget(tool, cartridgeInfo);

    return switch (tool) {
      EmulatorTool.debugger || EmulatorTool.executionLog => _panned(
        tool,
        Column(children: [Expanded(child: content)]),
      ),

      EmulatorTool.tileViewer ||
      EmulatorTool.cartridgeInfo ||
      EmulatorTool.apuDebug => _panned(
        tool,
        SingleChildScrollView(child: content),
      ),
    };
  }

  Widget _panned(EmulatorTool tool, Widget child) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(width: tool.contentWidth, child: child),
  );
}
