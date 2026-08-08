import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/menu/debug_tools_screen.dart';

import '../base_robot.dart';

class DebugToolsScreenRobot extends BaseRobot {
  DebugToolsScreenRobot(super.tester);

  void expectDebugToolsScreenFound() {
    expectOne(find.byType(DebugToolsScreen));
  }

  Future<void> tapTool(EmulatorTool tool) async {
    await go(find.byKey(Key('debugTool_${tool.name}')));
  }
}
