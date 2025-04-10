import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/controls/controls_settings.dart';
import 'package:nesd/ui/settings/controls/show_touch_controls_switch.dart';
import 'package:nesd/ui/settings/controls/touch_editor_button.dart';

import '../../base_robot.dart';

class ControlsSettingsRobot extends BaseRobot {
  ControlsSettingsRobot(super.tester);

  void expectControlsSettingsFound() {
    expectOne(find.byType(ControlsSettings));
  }

  Future<void> tapShowTouchControlsSwitch() async {
    await go(find.byType(ShowTouchControlsSwitch));
  }

  Future<void> tapTouchEditorButton() async {
    await go(find.byType(TouchEditorButton));
  }
}
