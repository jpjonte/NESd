import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/debug/log_level_dropdown.dart';
import 'package:nesd/ui/settings/debug/view_log_button.dart';
import 'package:nesd/ui/settings/navigation/settings_category_content.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../../base_robot.dart';

class DebugSettingsRobot extends BaseRobot {
  DebugSettingsRobot(super.tester);

  void expectDebugSettingsFound() {
    expectOne(
      find.byWidgetPredicate(
        (w) =>
            w is SettingsCategoryContent &&
            w.category == SettingsCategory.advanced,
      ),
    );
  }

  void expectLogLevelDropdownFound() {
    expectOne(find.byType(LogLevelDropdown));
  }

  void expectViewLogButtonFound() {
    expectOne(find.byType(ViewLogButton));
  }
}
