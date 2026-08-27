import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/main_menu/main_menu.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';

import '../robot.dart';

void main() {
  testWidgets('a ROM passed at startup is started automatically', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      overrides: [
        initialRomProvider.overrideWith(
          () => InitialRom(initialValue: '/test/roms/nestest.nes'),
        ),
      ],
      settle: false,
    );

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
    );

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);

    for (var i = 0; i < 6; i++) {
      await r.fixAsync();
    }

    expect(r.container.read(nesStateProvider), isNull);
    expect(r.container.read(currentRouteProvider), MainRoute.name);
  });
}
