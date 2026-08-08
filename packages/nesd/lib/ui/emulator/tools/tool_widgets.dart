import 'package:flutter/material.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_debug_widget.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/emulator/execution_log/execution_log_widget.dart';
import 'package:nesd/ui/emulator/tile_debug.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';

Widget emulatorToolWidget(EmulatorTool tool, CartridgeInfo? cartridgeInfo) =>
    switch (tool) {
      EmulatorTool.tileViewer => const TileDebugWidget(),
      EmulatorTool.cartridgeInfo =>
        cartridgeInfo != null
            ? CartridgeInfoWidget(info: cartridgeInfo)
            : const SizedBox.shrink(),
      EmulatorTool.debugger => const DebuggerWidget(),
      EmulatorTool.apuDebug => const ApuDebugWidget(),
      EmulatorTool.executionLog => const ExecutionLogWidget(),
    };
