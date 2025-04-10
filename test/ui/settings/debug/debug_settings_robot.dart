import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/debug/debug_settings.dart';

import '../../base_robot.dart';

class DebugSettingsRobot extends BaseRobot {
  DebugSettingsRobot(super.tester);

  void expectDebugSettingsFound() {
    expectOne(find.byType(DebugSettings));
  }
}
