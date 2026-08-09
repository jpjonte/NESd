import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/tool_widgets.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/theme/dark.dart';
import 'package:nesd/ui/theme/light.dart';

/// One tool, filling one native window. Its own [MaterialApp] gives the
/// window a [Navigator], which the debugger's dialogs need.
class ToolWindow extends ConsumerWidget {
  const ToolWindow({required this.tool, super.key});

  final EmulatorTool tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      settingsControllerProvider.select((s) => s.themeMode),
    );

    final cartridgeInfo = ref.watch(
      nesStateProvider.select((nes) => nes?.cartridgeInfo),
    );

    return MaterialApp(
      title: tool.title,
      theme: nesdThemeLight,
      darkTheme: nesdThemeDark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: toolContentWidth(tool),
            child: _content(tool, cartridgeInfo),
          ),
        ),
      ),
    );
  }
}

Widget _content(EmulatorTool tool, CartridgeInfo? cartridgeInfo) =>
    switch (tool) {
      EmulatorTool.tileViewer ||
      EmulatorTool.cartridgeInfo ||
      EmulatorTool.apuDebug => SingleChildScrollView(
        child: emulatorToolWidget(tool, cartridgeInfo),
      ),
      EmulatorTool.debugger ||
      EmulatorTool.executionLog => emulatorToolWidget(tool, cartridgeInfo),
    };

// `EmulatorTool` on this branch's frozen base (main@bef1bd93) has no
// `contentWidth`/`minHeight` members; those were added later upstream by
// `#296 Register tool sizes in registry` (main commit 95c343b3), which
// this never-merging experiment branch does not and will not carry. Since
// `emulator_tool.dart` is out of scope for this task, the same per-tool
// values from that commit are reproduced here instead, next to the two
// places that need them (this file and windowed_tool_host.dart).

const _standardToolWidth = 512.0;

/// Content width for [tool], matching `CompactToolHost`'s per-tool widths
/// so a tool looks the same panned in a compact tab as it does filling its
/// own window.
double toolContentWidth(EmulatorTool tool) => switch (tool) {
  EmulatorTool.executionLog => executionLogWidth,
  EmulatorTool.tileViewer ||
  EmulatorTool.cartridgeInfo ||
  EmulatorTool.debugger ||
  EmulatorTool.apuDebug => _standardToolWidth,
};

/// Initial window content height for [tool].
double toolMinHeight(EmulatorTool tool) => switch (tool) {
  EmulatorTool.tileViewer => 480,
  EmulatorTool.cartridgeInfo => 372,
  EmulatorTool.apuDebug => 408,
  EmulatorTool.debugger => 400,
  EmulatorTool.executionLog => 400,
};
