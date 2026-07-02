import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/emulator/emulator_widget.dart';
import 'package:nesd/ui/emulator/execution_log/execution_log_widget.dart';
import 'package:nesd/ui/emulator/tile_debug.dart';
import 'package:nesd/ui/settings/settings.dart';

@RoutePage()
class EmulatorScreen extends HookConsumerWidget {
  const EmulatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debuggerState = ref.watch(debuggerStateProvider);

    final showTiles = ref.watch(
      settingsControllerProvider.select((s) => s.showTiles),
    );
    final showDebugger = ref.watch(
      settingsControllerProvider.select((s) => s.showDebugger),
    );

    // TEMPORARY: the cartridge-info panel read the full Cartridge from the NES,
    // which now lives in the emulator isolate. Will be reconnected; until then
    // only tiles/debugger occupy the side column.
    return NesdScaffold(
      body: Row(
        children: [
          const Expanded(child: EmulatorWidget()),
          if (showTiles || showDebugger)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 512),
              child: Column(
                children: [
                  if (showTiles) const TileDebugWidget(),
                  if (showDebugger) const DebuggerWidget(),
                ],
              ),
            ),
          if (debuggerState.executionLogOpen) const ExecutionLogWidget(),
        ],
      ),
    );
  }
}
