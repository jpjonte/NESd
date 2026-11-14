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
            width: tool.contentWidth,
            child: _content(tool, cartridgeInfo),
          ),
        ),
      ),
    );
  }
}

Widget _content(EmulatorTool tool, CartridgeInfo? cartridgeInfo) =>
    switch (tool) {
      EmulatorTool.display ||
      EmulatorTool.audio ||
      EmulatorTool.tileViewer ||
      EmulatorTool.cartridgeInfo ||
      EmulatorTool.apuDebug => SingleChildScrollView(
        child: emulatorToolWidget(tool, cartridgeInfo),
      ),
      EmulatorTool.debugger ||
      EmulatorTool.executionLog => emulatorToolWidget(tool, cartridgeInfo),
    };
