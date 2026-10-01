import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../../robot.dart';

void main() {
  testWidgets('the touch vibration switch toggles the setting', (tester) async {
    final r = Robot(tester)..initSettings({'showTouchControls': true});

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.openCategory(SettingsCategory.controls);

    expect(r.settings.touchVibration, isTrue);

    await r.settingsScreen.controls.tapTouchVibrationSwitch();

    expect(r.settings.touchVibration, isFalse);

    await r.settingsScreen.controls.tapTouchVibrationSwitch();

    expect(r.settings.touchVibration, isTrue);
  });

  testWidgets('the touch vibration switch is disabled without touch '
      'controls', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.openCategory(SettingsCategory.controls);

    await r.settingsScreen.controls.tapTouchVibrationSwitch();

    expect(r.settings.touchVibration, isTrue);
  });
}
