import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/ui/common/focus_child.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/emulator/emulator_widget.dart';
import 'package:nesd/ui/emulator/tools/compact_tool_host.dart';
import 'package:nesd/ui/emulator/tools/docked_tool_host.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/tool_focus_controller.dart';

@RoutePage()
class EmulatorScreen extends ConsumerWidget {
  const EmulatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsFocused = ref.watch(toolFocusControllerProvider);

    final game = FocusChild(
      autofocus: !toolsFocused,
      child: const EmulatorWidget(),
    );

    final body = LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= dockedToolsMinWidth
          ? Row(
              children: [
                Expanded(child: game),
                ExcludeFocus(
                  excluding: !toolsFocused,
                  child: FocusChild(
                    autofocus: toolsFocused,
                    child: const DockedToolHost(),
                  ),
                ),
              ],
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                game,
                ExcludeFocus(
                  excluding: !toolsFocused,
                  child: const CompactToolHost(),
                ),
              ],
            ),
    );

    return NesdScaffold(
      body: Actions(
        actions: {
          if (toolsFocused)
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) =>
                  ref.read(toolFocusControllerProvider.notifier).exit(),
            ),
        },
        child: body,
      ),
    );
  }
}
