import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/menu/tools_screen.dart';

import '../base_robot.dart';

class ToolsScreenRobot extends BaseRobot {
  ToolsScreenRobot(super.tester);

  void expectToolsScreenFound() {
    expectOne(find.byType(ToolsScreen));
  }

  Future<void> tapTool(EmulatorTool tool) async {
    await go(find.byKey(Key('tool_${tool.name}')));
  }
}
