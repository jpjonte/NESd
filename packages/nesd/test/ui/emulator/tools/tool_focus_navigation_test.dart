import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tools/audio_tool.dart';
import 'package:nesd/ui/emulator/tools/tool_focus_controller.dart';
import 'package:nesd/ui/main_menu/main_screen.dart';
import 'package:nesd/ui/menu/menu_screen.dart';
import 'package:nesd/ui/settings/settings.dart';

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

  testWidgets('the focus tools action enters and cancel leaves', (
    tester,
  ) async {
    final r = await start(tester, ['audio']);

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(r.container.read(toolFocusControllerProvider), isTrue);
    expect(focusInside(tester, find.byType(AudioToolWidget)), isTrue);

    r.sendInputAction(cancel);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(r.container.read(toolFocusControllerProvider), isFalse);
    expect(focusInside(tester, find.byType(AudioToolWidget)), isFalse);

    await quit(r);
  });

  testWidgets('holding focus tools does not thrash the mode', (tester) async {
    final r = await start(tester, ['audio']);

    r
      ..sendInputAction(focusTools)
      ..sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(r.container.read(toolFocusControllerProvider), isTrue);

    await quit(r);
  });

  testWidgets('menu decrease drives a slider while focused', (tester) async {
    final r = await start(tester, ['audio']);

    r.settings.volume = 0.5;
    await r.pumpFrames(const Duration(milliseconds: 50));

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    r.sendInputAction(menuDecrease);
    await r.pumpFrames(const Duration(milliseconds: 50));

    expect(r.container.read(settingsControllerProvider).volume, lessThan(0.5));

    await quit(r);
  });

  testWidgets('the d-pad stops reaching the game, and cancel restores it', (
    tester,
  ) async {
    final r = await start(tester, ['audio']);

    final actions = <String>[];

    final subscription = r.container
        .read(actionStreamProvider)
        .stream
        .listen((event) => actions.add(event.action.code));

    addTearDown(subscription.cancel);

    Future<void> pressDown() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await r.pumpFrames(const Duration(milliseconds: 50));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await r.pumpFrames(const Duration(milliseconds: 50));
    }

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    actions.clear();

    await pressDown();

    expect(actions, isNot(contains('controller1.down')));
    expect(focusInside(tester, find.byType(AudioToolWidget)), isTrue);

    r.sendInputAction(cancel);
    await r.pumpFrames(const Duration(milliseconds: 100));

    actions.clear();

    await pressDown();

    expect(actions, contains('controller1.down'));

    await quit(r);
  });

  testWidgets('open menu while focused opens the in-game menu', (tester) async {
    final r = await start(tester, ['audio']);

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    r.sendInputAction(openMenu);
    await r.pumpFrames(const Duration(milliseconds: 500));

    r.menuScreen.expectMenuScreenFound();
    expect(r.container.read(toolFocusControllerProvider), isFalse);

    await r.menuScreen.tapResume();
    await r.pumpFrames(const Duration(milliseconds: 500));

    expect(r.container.read(toolFocusControllerProvider), isFalse);
    expect(focusInside(tester, find.byType(AudioToolWidget)), isFalse);

    await quit(r);
  });

  testWidgets('focus tools is a no-op with only pointer-only tools', (
    tester,
  ) async {
    final r = await start(tester, ['debugger']);

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(r.container.read(toolFocusControllerProvider), isFalse);

    await quit(r);
  });

  testWidgets('escape exits the mode instead of quitting the game', (
    tester,
  ) async {
    final r = await start(tester, ['audio']);

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(r.container.read(toolFocusControllerProvider), isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await r.pumpFrames(const Duration(milliseconds: 500));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await r.pumpFrames(const Duration(milliseconds: 50));

    expect(find.byType(MainScreen), findsNothing);
    expect(find.byType(MenuScreen), findsNothing);
    expect(r.container.read(toolFocusControllerProvider), isFalse);
    r.emulator.expectEmulatorWidgetFound();

    await quit(r);
  });
}
