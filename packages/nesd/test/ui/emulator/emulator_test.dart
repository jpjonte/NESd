import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/emulator_widget.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';

import '../robot.dart';

void main() {
  testWidgets('Game can be started and quit, returning to main menu', (
    tester,
  ) async {
    final r = Robot(tester)
      ..initSettings({
        'showDebugOverlay': true,
        'openTools': ['debugger'],
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

    final romInfo = r.container.read(nesStateProvider)!.romInfo;
    final romManager = r.container.read(romManagerProvider);

    Uint8List? savedState;

    for (var attempt = 0; attempt < 40 && savedState == null; attempt++) {
      await r.fixAsync();
      savedState = await tester.runAsync<Uint8List?>(
        () => romManager.loadState(romInfo, 1),
      );
    }

    expect(savedState, isNotNull, reason: 'save state slot 1 never landed');

    await r.emulator.tapMenu();
    await r.menuScreen.tapSaveStates();
    r.saveStates.expectSaveStatesScreenFound();
    await r.waitUntil(() => find.byType(RomTile).evaluate().length == 2);
    r.saveStates.expectSaveStatesFound(2);

    final beforeReload = r.container.read(nesStateProvider);

    await r.saveStates.tapExistingSaveState();
    await r.waitUntil(() => r.container.read(nesStateProvider) != beforeReload);
    await r.pumpFrames(const Duration(milliseconds: 500));
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

  testWidgets('Menu button is not covered by the system status bar', (
    tester,
  ) async {
    final r = Robot(tester)
      ..initSettings({
        'recentRoms': [
          {
            'file': {
              'path': '/test/roms/nestest.nes',
              'name': '/test/roms/nestest.nes',
              'type': 'file',
            },
          },
        ],
      });

    tester.view.padding = const FakeViewPadding(top: 120);
    addTearDown(tester.view.reset);

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();

    final inset = tester.view.padding.top / tester.view.devicePixelRatio;
    final buttonTop = tester.getTopLeft(find.byKey(EmulatorWidget.menuKey)).dy;

    expect(buttonTop, greaterThanOrEqualTo(inset));

    // Quit the game so the emulator's timers are gone before teardown.
    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });
}
