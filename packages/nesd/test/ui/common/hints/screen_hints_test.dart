import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';

import '../../robot.dart';

const _rom = {
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

Future<Robot> _startGame(WidgetTester tester) async {
  final r = Robot(tester)..initSettings(_rom);

  await r.pumpApp();
  await r.mainMenu.tapFirstRomTile();
  r.emulator.expectEmulatorWidgetFound();
  await r.pumpFrames(const Duration(seconds: 2));

  return r;
}

Future<void> _useKeyboard(Robot r) => r.pressKey(LogicalKeyboardKey.shiftLeft);

void main() {
  testWidgets('the in-game menu names the bound keys once a key is used', (
    tester,
  ) async {
    final r = await _startGame(tester);

    await r.pressKey(LogicalKeyboardKey.escape);
    r.menuScreen.expectMenuScreenFound();

    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('Select'), findsOneWidget);
    expect(find.text('Back to game'), findsOneWidget);
    expect(find.text('Enter'), findsOneWidget);
    expect(find.text('Esc'), findsOneWidget);

    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });

  testWidgets('the in-game menu shows no hints after a touch', (tester) async {
    final r = await _startGame(tester);

    await r.emulator.tapMenu();
    r.menuScreen.expectMenuScreenFound();

    expect(find.text('Select'), findsNothing);
    expect(find.text('Back to game'), findsNothing);

    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });

  testWidgets('the file picker swaps in key hints when a key is pressed', (
    tester,
  ) async {
    final r = Robot(tester)
      ..initSettings({
        ..._rom,
        'lastRomPath': {
          'path': '/test/roms',
          'name': '/test/roms',
          'type': 'directory',
        },
      });

    await r.pumpApp();
    await r.mainMenu.tapOpenRomButton();
    r.filePickerScreen.expectFilePickerScreenFound();

    expect(find.text('Jump by letter'), findsNothing);

    await _useKeyboard(r);

    expect(find.text('Jump by letter'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Tab'), findsNWidgets(2));
  });

  testWidgets('settings names the category and adjust keys', (tester) async {
    final r = Robot(tester)..initSettings(_rom);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButtonAsync();
    r.settingsScreen.expectSettingsScreenFound();

    await _useKeyboard(r);

    expect(find.text('Switch category'), findsOneWidget);
    expect(find.text('Adjust'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.text('←'), findsOneWidget);
    expect(find.text('→'), findsOneWidget);
  });
}
