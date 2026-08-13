import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/tools/emulator_tools_controller.dart';

import '../robot.dart';

void main() {
  testWidgets('tools can be toggled from the in-game menu', (tester) async {
    final r = Robot(tester)
      ..initSettings({
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

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();

    await r.emulator.tapMenu();
    await r.menuScreen.tapTools();

    r.tools.expectToolsScreenFound();

    expect(r.container.read(emulatorToolsControllerProvider), isEmpty);

    await r.tools.tapTool(EmulatorTool.debugger);

    expect(r.container.read(emulatorToolsControllerProvider), {
      EmulatorTool.debugger,
    });

    await r.tools.tapTool(EmulatorTool.debugger);

    expect(r.container.read(emulatorToolsControllerProvider), isEmpty);

    await r.goBack();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });
}
