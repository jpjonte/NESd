import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/main_menu/main_screen.dart';
import 'package:nesd/ui/settings/settings.dart';

import '../robot.dart';

Map<String, Object> settingsWithTool(EmulatorTool tool) => {
  'openTools': [tool.name],
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

const routeFade = Duration(milliseconds: 500);

Future<void> pressKey(Robot r, LogicalKeyboardKey key) async {
  await r.tester.sendKeyDownEvent(key);
  await r.pumpFrames(routeFade);
  await r.tester.sendKeyUpEvent(key);
  await r.pumpFrames(const Duration(milliseconds: 50));
}

Future<void> hoverVolumeSlider(Robot r) async {
  final tester = r.tester;

  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);

  await mouse.addPointer(location: Offset.zero);

  addTearDown(mouse.removePointer);

  await mouse.moveTo(tester.getCenter(find.text('Volume')));
  await r.pumpFrames(const Duration(milliseconds: 50));
}

Future<void> quitGame(Robot r) async {
  await r.emulator.tapMenu();
  await r.menuScreen.tapQuitGame();
  await r.waitUntil(() => r.container.read(nesStateProvider) == null);
}

void main() {
  testWidgets('hovering a docked tool keeps game keys out of the tool', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(settingsWithTool(EmulatorTool.audio));

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();

    final actions = <InputAction>[];

    final subscription = r.container
        .read(actionStreamProvider)
        .stream
        .listen((event) => actions.add(event.action));

    addTearDown(subscription.cancel);

    await hoverVolumeSlider(r);

    // Z is bound to controller 1's A button.
    await pressKey(r, LogicalKeyboardKey.keyZ);

    expect(
      actions.map((action) => action.code),
      contains('controller1.a'),
      reason: 'the game must keep receiving input while a tool is hovered',
    );

    await quitGame(r);
  });

  testWidgets('escape opens the in-game menu while a tool is hovered', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(settingsWithTool(EmulatorTool.audio));

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();

    await hoverVolumeSlider(r);

    await pressKey(r, LogicalKeyboardKey.escape);

    expect(
      find.byType(MainScreen),
      findsNothing,
      reason: 'escape must not quit the game back to the main menu',
    );
    r.menuScreen.expectMenuScreenFound();

    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });

  testWidgets('a tool control still responds to the pointer', (tester) async {
    final r = Robot(tester)..initSettings(settingsWithTool(EmulatorTool.audio));

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();

    final settings = r.container.read(settingsControllerProvider);

    expect(settings.lowPassFilter, isFalse);

    await tester.tap(find.text('Low Pass Filter'));
    await r.pumpFrames(const Duration(milliseconds: 50));

    expect(
      r.container.read(settingsControllerProvider).lowPassFilter,
      isTrue,
      reason: 'tools stay operable with the mouse',
    );

    await quitGame(r);
  });

  testWidgets('a dialog opened from a tool still takes typing', (tester) async {
    final r = Robot(tester)
      ..initSettings(settingsWithTool(EmulatorTool.debugger));

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();

    await tester.tap(find.byTooltip('Go to address'));
    await r.pumpFrames(routeFade);

    tester.testTextInput.enterText('1234');
    await tester.pump();

    expect(find.text('1234'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await r.pumpFrames(routeFade);

    await quitGame(r);
  });

  testWidgets('the compact tool host keeps the keyboard on the game', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(settingsWithTool(EmulatorTool.audio));

    await r.pumpApp(logicalSize: const Size(800, 600));
    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();

    await hoverVolumeSlider(r);

    await pressKey(r, LogicalKeyboardKey.escape);

    expect(
      find.byType(MainScreen),
      findsNothing,
      reason: 'escape must not quit the game back to the main menu',
    );
    r.menuScreen.expectMenuScreenFound();

    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });
}
