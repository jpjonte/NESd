import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_debug_widget.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/emulator/emulator_widget.dart';
import 'package:nesd/ui/emulator/execution_log/execution_log_widget.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tile_debug.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';
import 'package:nesd/ui/settings/settings.dart';

@RoutePage()
class EmulatorScreen extends HookConsumerWidget {
  const EmulatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nes = ref.watch(nesStateProvider);

    final executionLogOpen = ref.watch(
      emulatorToolsControllerProvider.select(
        (tools) => tools.contains(EmulatorTool.executionLog),
      ),
    );

    final showTiles = ref.watch(
      settingsControllerProvider.select((s) => s.showTiles),
    );
    final showCartridgeInfo = ref.watch(
      settingsControllerProvider.select((s) => s.showCartridgeInfo),
    );
    final showDebugger = ref.watch(
      settingsControllerProvider.select((s) => s.showDebugger),
    );
    final showApuDebug = ref.watch(
      settingsControllerProvider.select((s) => s.showApuDebug),
    );

    final cartridgeInfo = nes?.cartridgeInfo;

    return NesdScaffold(
      body: Row(
        children: [
          const Expanded(child: EmulatorWidget()),
          if (showTiles || showCartridgeInfo || showDebugger || showApuDebug)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 512),
              child: Column(
                children: [
                  if (showTiles) const TileDebugWidget(),
                  if (cartridgeInfo != null && showCartridgeInfo)
                    CartridgeInfoWidget(info: cartridgeInfo),
                  if (showDebugger) const DebuggerWidget(),
                  if (showApuDebug)
                    const Expanded(
                      child: SingleChildScrollView(child: ApuDebugWidget()),
                    ),
                ],
              ),
            ),
          if (executionLogOpen) const ExecutionLogWidget(),
        ],
      ),
    );
  }
}
