import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/app_controller.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';

import '../robot.dart';

void main() {
  testWidgets('Quit NESd saves the running game before it goes', (
    tester,
  ) async {
    var quit = false;

    final r = Robot(tester)
      ..initSettings({
        'autoSave': true,
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

    await r.pumpApp(
      overrides: [quitAppProvider.overrideWithValue(() => quit = true)],
    );

    await r.mainMenu.tapFirstRomTile();

    r.emulator.expectEmulatorWidgetFound();

    await r.pumpFrames(const Duration(seconds: 2));

    final romInfo = r.container.read(nesStateProvider)!.romInfo;

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitNesd();

    await r.waitUntil(() => quit);

    final state = await r.container
        .read(romManagerProvider)
        .loadState(romInfo, autoSaveSlot);

    expect(state, isNotNull, reason: 'the game should have been auto saved');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
