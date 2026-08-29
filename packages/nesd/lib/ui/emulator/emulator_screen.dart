import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/emulator/emulator_widget.dart';
import 'package:nesd/ui/emulator/tools/compact_tool_host.dart';
import 'package:nesd/ui/emulator/tools/docked_tool_host.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';

@RoutePage()
class EmulatorScreen extends StatelessWidget {
  const EmulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NesdScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth >= dockedToolsMinWidth
            ? const Row(
                children: [
                  Expanded(child: EmulatorWidget()),
                  ExcludeFocus(child: DockedToolHost()),
                ],
              )
            : const Stack(
                fit: StackFit.expand,
                children: [
                  EmulatorWidget(),
                  ExcludeFocus(child: CompactToolHost()),
                ],
              ),
      ),
    );
  }
}
