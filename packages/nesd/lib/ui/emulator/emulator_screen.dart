// ignore_for_file: implementation_imports, invalid_use_of_internal_member

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/_features.dart';
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
    if (isWindowingEnabled) {
      return const NesdScaffold(body: EmulatorWidget());
    }

    return NesdScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth >= dockedToolsMinWidth
            ? const Row(
                children: [
                  Expanded(child: EmulatorWidget()),
                  DockedToolHost(),
                ],
              )
            : const Stack(
                fit: StackFit.expand,
                children: [EmulatorWidget(), CompactToolHost()],
              ),
      ),
    );
  }
}
