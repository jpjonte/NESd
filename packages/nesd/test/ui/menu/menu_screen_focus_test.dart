import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/nesd_button.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/menu/menu_screen.dart';

import '../../helpers/focus.dart';
import '../robot.dart';

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

final _entries = find.descendant(
  of: find.byType(MenuScreen),
  matching: find.byType(NesdButton),
);

final _backButton = find.descendant(
  of: find.byType(MenuScreen),
  matching: find.byType(BackButton),
);

Future<Robot> _openMenu(WidgetTester tester) async {
  final r = Robot(tester)..initSettings(_rom);

  await r.pumpApp();
  await r.mainMenu.tapFirstRomTile();

  r.emulator.expectEmulatorWidgetFound();

  await r.emulator.tapMenu();

  return r;
}

Future<void> _quit(Robot r) async {
  await r.menuScreen.tapQuitGame();
  await r.waitUntil(() => r.container.read(nesStateProvider) == null);
}

void main() {
  testWidgets('moving up from the first entry wraps to the last', (
    tester,
  ) async {
    final r = await _openMenu(tester);

    expect(focusInside(tester, _entries.first), isTrue);

    r.sendInputAction(inputUp);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, _entries.last), isTrue);

    await _quit(r);
  });

  testWidgets('moving down from the last entry wraps to the first', (
    tester,
  ) async {
    final r = await _openMenu(tester);

    await r.menuScreen.expectAndFocus(_entries.last);

    r.sendInputAction(inputDown);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, _entries.first), isTrue);

    await _quit(r);
  });

  testWidgets('the back button never takes focus', (tester) async {
    final r = await _openMenu(tester);

    expect(_backButton, findsOneWidget);
    expect(focusInside(tester, _entries.first), isTrue);

    r.sendInputAction(inputUp);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, _backButton), isFalse);

    r.sendInputAction(previousInput);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, _backButton), isFalse);

    await _quit(r);
  });
}
