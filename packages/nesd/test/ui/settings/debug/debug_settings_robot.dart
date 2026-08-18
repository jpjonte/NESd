import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/debug/debug_settings.dart';
import 'package:nesd/ui/settings/debug/log_level_dropdown.dart';
import 'package:nesd/ui/settings/debug/view_log_button.dart';

import '../../base_robot.dart';

class DebugSettingsRobot extends BaseRobot {
  DebugSettingsRobot(super.tester);

  void expectDebugSettingsFound() {
    expectOne(find.byType(DebugSettings));
  }

  void expectLogLevelDropdownFound() {
    expectOne(find.byType(LogLevelDropdown));
  }

  void expectViewLogButtonFound() {
    expectOne(find.byType(ViewLogButton));
  }
}
