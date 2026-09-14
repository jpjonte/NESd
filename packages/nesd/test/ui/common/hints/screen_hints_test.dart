import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tools/tool_focus_controller.dart';

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

Future<Robot> _startGame(
  WidgetTester tester, {
  List<String> openTools = const [],
}) async {
  final r = Robot(tester)..initSettings({..._rom, 'openTools': openTools});

  await r.pumpApp();
  await r.mainMenu.tapFirstRomTile();
  r.emulator.expectEmulatorWidgetFound();
  await r.pumpFrames(const Duration(seconds: 2));

  return r;
}

Future<void> _quitGame(Robot r) async {
  await r.emulator.tapMenu();
  await r.menuScreen.tapQuitGame();
  await r.waitUntil(() => r.container.read(nesStateProvider) == null);
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

  testWidgets('the tool host names how to switch tools and leave', (
    tester,
  ) async {
    final r = await _startGame(tester, openTools: ['display', 'audio']);

    await _useKeyboard(r);

    expect(find.text('Switch tool'), findsNothing);

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(r.container.read(toolFocusControllerProvider), isTrue);
    expect(find.text('Switch tool'), findsOneWidget);
    expect(find.text('Back to game'), findsOneWidget);

    r.container.read(toolFocusControllerProvider.notifier).exit();
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(find.text('Switch tool'), findsNothing);

    await _quitGame(r);
  });
}
