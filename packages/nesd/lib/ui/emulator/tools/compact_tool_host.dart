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
import 'package:nesd/ui/theme/dark.dart';

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

    final focused = ref.watch(toolFocusControllerProvider);

    final navigable = ordered.where((tool) => !tool.pointerOnly).toList();

    final candidates = focused ? navigable : ordered;

    final active = candidates.contains(selected.value)
        ? selected.value!
        : (candidates.isNotEmpty ? candidates.first : ordered.first);

    final cartridgeInfo = ref.watch(
      nesStateProvider.select((nes) => nes?.cartridgeInfo),
    );

    void step(int delta) {
      if (navigable.isEmpty) {
        return;
      }

      final index = navigable.contains(active) ? navigable.indexOf(active) : 0;

      selected.value = navigable[(index + delta) % navigable.length];
    }

    return Actions(
      actions: {
        PreviousTabIntent: CallbackAction<PreviousTabIntent>(
          onInvoke: (_) => step(-1),
        ),
        NextTabIntent: CallbackAction<NextTabIntent>(onInvoke: (_) => step(1)),
      },
      child: DecoratedBox(
        key: const Key('toolFocusIndicator'),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: focused
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: ColoredBox(
          color: Colors.black.withAlpha(200),
          // force dark theme so text is readable on the black background
          child: Theme(
            data: nesdThemeDark,
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  ExcludeFocus(
                    child: Row(
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
                  ),
                  Expanded(
                    child: FocusChild(
                      autofocus: focused,
                      key: ValueKey(active),
                      child: _body(active, cartridgeInfo),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

      EmulatorTool.display ||
      EmulatorTool.audio ||
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
