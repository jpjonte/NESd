import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tools/audio_tool.dart';
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

Future<Robot> start(
  WidgetTester tester,
  List<String> openTools, {
  Size logicalSize = const Size(1920, 1080),
}) async {
  final r = Robot(tester)..initSettings({..._rom, 'openTools': openTools});

  await r.pumpApp(logicalSize: logicalSize);
  await r.mainMenu.tapFirstRomTile();
  r.emulator.expectEmulatorWidgetFound();

  return r;
}

Future<void> quit(Robot r) async {
  await r.emulator.tapMenu();
  await r.menuScreen.tapQuitGame();
  await r.waitUntil(() => r.container.read(nesStateProvider) == null);
}

bool focusInside(WidgetTester tester, Finder ancestor) {
  final context = primaryFocus?.context;

  if (context == null || ancestor.evaluate().isEmpty) {
    return false;
  }

  return find
      .descendant(
        of: ancestor,
        matching: find.byElementPredicate((e) => identical(e, context)),
      )
      .evaluate()
      .isNotEmpty;
}

void main() {
  testWidgets('entering moves focus into the docked panel', (tester) async {
    final r = await start(tester, ['audio']);

    expect(focusInside(tester, find.byType(AudioToolWidget)), isFalse);

    r.container.read(toolFocusControllerProvider.notifier).enter();
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(AudioToolWidget)), isTrue);

    await quit(r);
  });

  testWidgets('exiting returns focus to the game', (tester) async {
    final r = await start(tester, ['audio']);

    final focus = r.container.read(toolFocusControllerProvider.notifier)
      ..enter();
    await r.pumpFrames(const Duration(milliseconds: 100));

    focus.exit();
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(AudioToolWidget)), isFalse);

    await quit(r);
  });

  testWidgets('focus never enters a pointer-only panel', (tester) async {
    final r = await start(tester, ['audio', 'debugger']);

    r.container.read(toolFocusControllerProvider.notifier).enter();
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(DebuggerWidget)), isFalse);
    expect(focusInside(tester, find.byType(AudioToolWidget)), isTrue);

    await quit(r);
  });
}
