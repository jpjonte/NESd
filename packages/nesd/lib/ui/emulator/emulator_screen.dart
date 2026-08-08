import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nesd/ui/common/nesd_scaffold.dart';
import 'package:nesd/ui/emulator/emulator_widget.dart';
import 'package:nesd/ui/emulator/tools/docked_tool_host.dart';

@RoutePage()
class EmulatorScreen extends StatelessWidget {
  const EmulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NesdScaffold(
      body: Row(
        children: [
          Expanded(child: EmulatorWidget()),
          DockedToolHost(),
        ],
      ),
    );
  }
}
