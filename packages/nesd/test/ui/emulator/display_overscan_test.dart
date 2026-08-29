import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';

import '../robot.dart';

void main() {
  const recentRoms = [
    {
      'file': {
        'path': '/test/roms/nestest.nes',
        'name': '/test/roms/nestest.nes',
        'type': 'file',
      },
    },
  ];

  const displayWidth = 293.0;

  Future<double> displayAspectRatio(
    WidgetTester tester,
    Map<String, Object> settings,
  ) async {
    final r = Robot(tester)
      ..initSettings({...settings, 'recentRoms': recentRoms});

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();
    await r.waitUntil(
      () => find.byKey(DisplayBuilder.screenKey).evaluate().isNotEmpty,
    );

    final size = tester.getSize(find.byKey(DisplayBuilder.screenKey));

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);

    return size.width / size.height;
  }

  testWidgets('the default 8px crop shortens the rendered screen', (
    tester,
  ) async {
    final aspectRatio = await displayAspectRatio(tester, const {});

    expect(aspectRatio, closeTo(displayWidth / 224, 0.001));
  });

  testWidgets('an uncropped screen renders the full 240 lines', (tester) async {
    final aspectRatio = await displayAspectRatio(tester, const {
      'overscan': {'top': 0, 'bottom': 0, 'left': 0, 'right': 0},
    });

    expect(aspectRatio, closeTo(displayWidth / 240, 0.001));
  });

  testWidgets('cropping the sides narrows the rendered screen', (tester) async {
    final aspectRatio = await displayAspectRatio(tester, const {
      'overscan': {'top': 0, 'bottom': 0, 'left': 8, 'right': 8},
    });

    // 240 wide stretched by 8/7 rounds to 274.
    expect(aspectRatio, closeTo(274 / 240, 0.001));
  });
}
