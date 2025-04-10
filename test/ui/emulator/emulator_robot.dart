import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/emulator/emulator_widget.dart';

import '../base_robot.dart';

class EmulatorRobot extends BaseRobot {
  EmulatorRobot(super.tester);

  void expectEmulatorWidgetFound() {
    expectOne(find.byType(EmulatorWidget));
  }

  Future<void> tapMenu() async {
    await goAsync(find.byKey(DisplayWidget.menuKey));
  }
}
