import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';

import '../robot.dart';

void main() {
  testWidgets('Game can be started and quit, returning to main menu', (
    tester,
  ) async {
    final r = Robot(tester)
      ..initSettings({
        'showDebugOverlay': true,
        'showDebugger': true,
        'showTouchControls': true,
        'recentRoms': [
          {
            'file': {
              'path': '/test/roms/nestest.nes',
              'name': '/test/roms/nestest.nes',
              'type': 'file',
            },
          },
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

    // Quit Game fires `NesController.stop()` unawaited, which now does
    // real async SRAM/thumbnail file IO before it stops the NES run loop
    // and clears `nesState`. A single `fixAsync` round trip isn't always
    // enough real time for that chain to drain, so poll until it settles
    // instead of guessing a fixed pump count.
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });
}
