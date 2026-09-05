import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/controls/gamepad_slots.dart';
import 'package:nesd/ui/settings/controls/show_touch_controls_switch.dart';
import 'package:nesd/ui/settings/controls/touch_editor_button.dart';
import 'package:nesd/ui/settings/navigation/settings_category_content.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../../base_robot.dart';

class ControlsSettingsRobot extends BaseRobot {
  ControlsSettingsRobot(super.tester);

  void expectControlsSettingsFound() {
    expectOne(
      find.byWidgetPredicate(
        (w) =>
            w is SettingsCategoryContent &&
            w.category == SettingsCategory.controls,
      ),
    );
  }

  Future<void> tapShowTouchControlsSwitch() async {
    await go(find.byType(ShowTouchControlsSwitch));
  }

  Future<void> tapTouchEditorButton() async {
    await go(find.byType(TouchEditorButton));
  }

  void expectGamepadSlotsFound() {
    expectOne(find.byType(GamepadSlotsSection));
  }
}
