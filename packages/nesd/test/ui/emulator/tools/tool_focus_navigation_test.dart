import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/debugger/debugger_widget.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tools/audio_tool.dart';
import 'package:nesd/ui/emulator/tools/display_tool.dart';
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
  // widen back to a docked width first: in the compact layout the tool
  // host is a full-screen Stack overlay that covers the emulator's own
  // menu button whenever any tool is open (see compact_tool_host_test.dart)
  r.tester.view.physicalSize =
      const Size(1920, 1080) * r.tester.view.devicePixelRatio;
  addTearDown(r.tester.view.resetPhysicalSize);
  await r.tester.pump();

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
  Color dockedIndicatorColor(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.byKey(const Key('toolFocusIndicator')),
    );

    final border = (box.decoration as BoxDecoration).border! as Border;

    return border.left.color;
  }

  Color compactIndicatorColor(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.byKey(const Key('toolFocusIndicator')),
    );

    final border = (box.decoration as BoxDecoration).border! as Border;

    return border.top.color;
  }

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

  testWidgets('next tab moves focus to the next navigable panel', (
    tester,
  ) async {
    final r = await start(tester, ['display', 'audio']);

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(DisplayToolWidget)), isTrue);

    r.sendInputAction(nextTab);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(AudioToolWidget)), isTrue);

    // wraps back around
    r.sendInputAction(nextTab);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(DisplayToolWidget)), isTrue);

    await quit(r);
  });

  testWidgets('tab cycling skips pointer-only panels', (tester) async {
    final r = await start(tester, ['display', 'debugger', 'audio']);

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    r.sendInputAction(nextTab);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(AudioToolWidget)), isTrue);
    expect(focusInside(tester, find.byType(DebuggerWidget)), isFalse);

    r.sendInputAction(nextTab);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(DisplayToolWidget)), isTrue);
    expect(focusInside(tester, find.byType(DebuggerWidget)), isFalse);

    await quit(r);
  });

  testWidgets('previous tab wraps backward and skips pointer-only panels', (
    tester,
  ) async {
    final r = await start(tester, ['display', 'debugger', 'audio']);

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(DisplayToolWidget)), isTrue);

    r.sendInputAction(previousTab);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(AudioToolWidget)), isTrue);
    expect(focusInside(tester, find.byType(DebuggerWidget)), isFalse);

    await quit(r);
  });

  testWidgets('the compact host takes focus and switches tabs', (tester) async {
    final r = await start(tester, [
      'display',
      'audio',
    ], logicalSize: const Size(800, 600));

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(DisplayToolWidget)), isTrue);

    r.sendInputAction(nextTab);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(AudioToolWidget)), isTrue);

    await quit(r);
  });

  testWidgets(
    'the compact tab row and close button refuse programmatic focus',
    (tester) async {
      final r = await start(tester, [
        'audio',
      ], logicalSize: const Size(800, 600));

      r.sendInputAction(focusTools);
      await r.pumpFrames(const Duration(milliseconds: 100));

      expect(focusInside(tester, find.byType(AudioToolWidget)), isTrue);

      final tabNode = Focus.of(
        tester.element(
          find
              .descendant(
                of: find.byKey(const Key('compactTab_audio')),
                matching: find.byType(Text),
              )
              .first,
        ),
      )..requestFocus();
      await r.pumpFrames(const Duration(milliseconds: 50));

      expect(tabNode.hasFocus, isFalse);
      expect(focusInside(tester, find.byType(AudioToolWidget)), isTrue);

      final closeNode = Focus.of(
        tester.element(
          find
              .descendant(
                of: find.byKey(const Key('compactToolClose')),
                matching: find.byType(Icon),
              )
              .first,
        ),
      )..requestFocus();
      await r.pumpFrames(const Duration(milliseconds: 50));

      expect(closeNode.hasFocus, isFalse);
      expect(focusInside(tester, find.byType(AudioToolWidget)), isTrue);

      await quit(r);
    },
  );

  testWidgets('compact tab cycling skips pointer-only panels', (tester) async {
    final r = await start(tester, [
      'display',
      'debugger',
      'audio',
    ], logicalSize: const Size(800, 600));

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    r.sendInputAction(nextTab);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(AudioToolWidget)), isTrue);
    expect(focusInside(tester, find.byType(DebuggerWidget)), isFalse);

    r.sendInputAction(nextTab);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(DisplayToolWidget)), isTrue);
    expect(focusInside(tester, find.byType(DebuggerWidget)), isFalse);

    await quit(r);
  });

  testWidgets('compact previous tab wraps backward past a pointer-only panel', (
    tester,
  ) async {
    final r = await start(tester, [
      'display',
      'debugger',
      'audio',
    ], logicalSize: const Size(800, 600));

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(DisplayToolWidget)), isTrue);

    r.sendInputAction(previousTab);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(AudioToolWidget)), isTrue);
    expect(focusInside(tester, find.byType(DebuggerWidget)), isFalse);

    await quit(r);
  });

  testWidgets('entering focus redirects away from a pointer-only compact tab', (
    tester,
  ) async {
    final r = await start(tester, [
      'display',
      'debugger',
    ], logicalSize: const Size(800, 600));

    await tester.tap(find.byKey(const Key('compactTab_debugger')));
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(find.byType(DebuggerWidget), findsOneWidget);

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(DisplayToolWidget)), isTrue);
    expect(find.byType(DebuggerWidget), findsNothing);

    await quit(r);
  });

  testWidgets('the docked column marks itself while focused', (tester) async {
    final r = await start(tester, ['audio']);

    expect(dockedIndicatorColor(tester), Colors.transparent);

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(dockedIndicatorColor(tester), isNot(Colors.transparent));

    r.sendInputAction(cancel);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(dockedIndicatorColor(tester), Colors.transparent);

    await quit(r);
  });

  testWidgets('the compact column marks itself while focused', (tester) async {
    final r = await start(tester, ['audio'], logicalSize: const Size(800, 600));

    expect(compactIndicatorColor(tester), Colors.transparent);

    r.sendInputAction(focusTools);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(compactIndicatorColor(tester), isNot(Colors.transparent));

    r.sendInputAction(cancel);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(compactIndicatorColor(tester), Colors.transparent);

    await quit(r);
  });
}
