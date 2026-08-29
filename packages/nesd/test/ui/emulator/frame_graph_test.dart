import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/frame_graph.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';

import '../robot.dart';

Map<String, Object> _settings({required bool showDebugOverlay}) => {
  'showDebugOverlay': showDebugOverlay,
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

Future<void> _quitGame(Robot r) async {
  await r.emulator.tapMenu();
  await r.menuScreen.tapQuitGame();
  await r.waitUntil(() => r.container.read(nesStateProvider) == null);
}

void main() {
  testWidgets('the debug overlay shows the frame graph', (tester) async {
    final r = Robot(tester)..initSettings(_settings(showDebugOverlay: true));

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();

    expect(find.byType(FrameGraph), findsOneWidget);

    await _quitGame(r);
  });

  testWidgets('the frame graph is hidden with the debug overlay', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_settings(showDebugOverlay: false));

    await r.pumpApp();
    await r.mainMenu.tapFirstRomTile();
    r.emulator.expectEmulatorWidgetFound();

    expect(find.byType(FrameGraph), findsNothing);

    await _quitGame(r);
  });
}
