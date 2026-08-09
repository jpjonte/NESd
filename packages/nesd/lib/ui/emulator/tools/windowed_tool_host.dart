// ignore_for_file: implementation_imports, invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:nesd/ui/emulator/tools/tool_window.dart';

/// Renders [child] unchanged; its only job is to keep one native window
/// alive per open tool.
class WindowedToolHost extends HookConsumerWidget {
  const WindowedToolHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = useRef(<EmulatorTool, WindowEntry>{});
    final registry = WindowRegistry.of(context);

    void sync(Set<EmulatorTool> open) {
      final current = entries.value.keys.toSet();

      for (final tool in open.difference(current)) {
        _open(registry, entries.value, tool, ref);
      }

      for (final tool in current.difference(open)) {
        _close(registry, entries.value, tool);
      }
    }

    useEffect(() {
      final open = ref.read(emulatorToolsControllerProvider);

      WidgetsBinding.instance.addPostFrameCallback((_) => sync(open));

      return null;
    }, const []);

    ref.listen(emulatorToolsControllerProvider, (_, next) => sync(next));

    return child;
  }
}

void _open(
  WindowRegistry registry,
  Map<EmulatorTool, WindowEntry> entries,
  EmulatorTool tool,
  WidgetRef ref,
) {
  final entry = WindowEntry(
    controller: WindowController(
      size: Size(toolContentWidth(tool), toolMinHeight(tool)),
      constraints: BoxConstraints(
        minWidth: toolContentWidth(tool),
        minHeight: 200,
      ),
      title: tool.title,
      delegate: _ToolWindowDelegate(
        onCloseRequested: () =>
            ref.read(emulatorToolsControllerProvider.notifier).close(tool),
      ),
    ),
    builder: (_) => ToolWindow(tool: tool),
  );

  entries[tool] = entry;

  registry.register(entry);
}

void _close(
  WindowRegistry registry,
  Map<EmulatorTool, WindowEntry> entries,
  EmulatorTool tool,
) {
  final entry = entries.remove(tool);

  if (entry == null) {
    return;
  }

  // Unregister first, then destroy: that order is the registry's
  // documented contract.
  registry.unregister(entry);

  entry.controller.destroy();
}

/// Routes a native close back through the controller, so closing has one
/// code path whether it starts at the window or at the menu.
class _ToolWindowDelegate with WindowControllerDelegate {
  _ToolWindowDelegate({required this.onCloseRequested});

  final VoidCallback onCloseRequested;

  @override
  void onWindowCloseRequested(WindowController controller) =>
      onCloseRequested();
}
