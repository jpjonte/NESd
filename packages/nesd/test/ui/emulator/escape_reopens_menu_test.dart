import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/emulator_widget.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
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

  testWidgets('Unbound Escape does nothing in game', (tester) async {
    final r = Robot(tester)..initSettings(settingsWithRecentRom());

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();

    r.settings.bindings = r.settings.bindings
        .where((binding) => binding.action != openMenu)
        .toList();
    await r.pumpFrames(const Duration(milliseconds: 50));

    // Escape must be swallowed, not fall through to the default
    // DismissIntent shortcut that would pop back to the main menu.
    await pressKey(r, LogicalKeyboardKey.escape);
    expect(find.byType(MainScreen), findsNothing);
    expect(find.byType(MenuScreen), findsNothing);
    r.emulator.expectEmulatorWidgetFound();

    // Quit the game so the emulator's timers are gone before teardown.
    await r.emulator.tapMenu();
    await quitGame(r);
  });

  testWidgets('Escape opens the menu while the menu button has focus', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(settingsWithRecentRom());

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();

    final icon = tester.element(
      find.descendant(
        of: find.byKey(EmulatorWidget.menuKey),
        matching: find.byType(Icon),
      ),
    );

    Focus.of(icon).requestFocus();
    await r.pumpFrames(const Duration(milliseconds: 50));

    await pressKey(r, LogicalKeyboardKey.escape);
    expect(find.byType(MainScreen), findsNothing);
    r.menuScreen.expectMenuScreenFound();

    // Quit the game so the emulator's timers are gone before teardown.
    await quitGame(r);
  });
}
