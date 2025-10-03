import 'package:flutter_test/flutter_test.dart';

import '../../../robot.dart';

void main() {
  testWidgets('Touch editor screen can be opened', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    r.settings.showTouchControls = true;
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.tapControlsTab();
    await r.settingsScreen.controls.tapTouchEditorButton();
  });
}
