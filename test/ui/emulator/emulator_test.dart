import 'package:flutter_test/flutter_test.dart';

import '../robot.dart';

void main() {
  testWidgets('Game can be started and quit, returning to main menu', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings({
      'showDebugOverlay': true,
      'showDebugger': true,
      'showTouchControls': true,
      'recentRoms': [
        {'path': '/test/roms/nestest.nes'},
      ],
      'wideTouchInputConfig': [
        {'x': 0.0, 'y': 0.0, 'type': 'rectangleButton'},
        {'x': 0.0, 'y': 0.0, 'type': 'circleButton'},
        {'x': 0.0, 'y': 0.0, 'type': 'joyStick'},
        {'x': 0.0, 'y': 0.0, 'type': 'dPad'},
      ],
    });

    await r.pumpApp();
    r.mainMenu.expectMainMenuFound();

    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();

    await r.emulator.tapMenu();
    r.menuScreen.expectMenuScreenFound();

    await r.menuScreen.tapResume();
    r.emulator.expectEmulatorWidgetFound();

    await r.emulator.tapMenu();
    await r.menuScreen.tapSaveStates();
    r.saveStates.expectSaveStatesScreenFound();
    r.saveStates.expectSaveStatesFound(1);

    await r.saveStates.tapNewSaveState();
    r.emulator.expectEmulatorWidgetFound();

    await r.emulator.tapMenu();
    await r.menuScreen.tapSaveStates();
    await r.fixAsync();
    r.saveStates.expectSaveStatesFound(2);

    await r.saveStates.tapExistingSaveState();
    r.emulator.expectEmulatorWidgetFound();

    await r.emulator.tapMenu();
    await r.menuScreen.tapResetGame();
    r.emulator.expectEmulatorWidgetFound();

    await r.emulator.tapMenu();
    await r.menuScreen.tapSettings();
    r.settingsScreen.expectSettingsScreenFound();

    await r.goBack();
    r.menuScreen.expectMenuScreenFound();

    await r.menuScreen.tapQuitGame();
    r.mainMenu.expectMainMenuFound();
  });
}
