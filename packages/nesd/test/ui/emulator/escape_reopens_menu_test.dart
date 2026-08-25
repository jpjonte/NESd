import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/main_menu/main_screen.dart';
import 'package:nesd/ui/menu/menu_screen.dart';

import '../robot.dart';

const routeFade = Duration(milliseconds: 500);

Map<String, Object> settingsWithRecentRom() => {
  'recentRoms': [
    {
      'file': {
        'path': '/test/roms/nestest.nes',
        'name': '/test/roms/nestest.nes',
        'type': 'file',
      },
    },
  ],
};

Future<void> pressKey(Robot r, LogicalKeyboardKey key) async {
  await r.tester.sendKeyDownEvent(key);
  await r.pumpFrames(routeFade);
  await r.tester.sendKeyUpEvent(key);
  await r.pumpFrames(const Duration(milliseconds: 50));
}

Future<void> quitGame(Robot r) async {
  await r.menuScreen.tapQuitGame();
  await r.waitUntil(() => r.container.read(nesStateProvider) == null);
}

void main() {
  testWidgets('Escape reopens the menu after resuming the game with Enter', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(settingsWithRecentRom());

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();

    // Escape opens the in-game menu.
    await pressKey(r, LogicalKeyboardKey.escape);
    r.menuScreen.expectMenuScreenFound();

    // Enter activates the autofocused Resume button.
    await pressKey(r, LogicalKeyboardKey.enter);
    expect(find.byType(MenuScreen), findsNothing);
    r.emulator.expectEmulatorWidgetFound();

    // Escape must reopen the in-game menu, not quit to the main menu.
    await pressKey(r, LogicalKeyboardKey.escape);
    expect(find.byType(MainScreen), findsNothing);
    r.menuScreen.expectMenuScreenFound();

    // Quit the game so the emulator's timers are gone before teardown.
    await quitGame(r);
  });
}
