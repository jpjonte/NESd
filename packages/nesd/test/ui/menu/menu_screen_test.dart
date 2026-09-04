import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
import 'package:nesd/ui/emulator/rewind/rewind_timeline_overlay.dart';
import 'package:nesd/ui/menu/menu_screen.dart';

import '../robot.dart';

Robot _robot(WidgetTester tester, {bool rewind = true}) =>
    Robot(tester)..initSettings({
      'rewind': rewind,
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

Future<void> _startGame(Robot r) async {
  await r.pumpApp();
  await r.mainMenu.tapFirstRomTile();

  r.emulator.expectEmulatorWidgetFound();

  await r.pumpFrames(const Duration(seconds: 2));
}

RewindScrubState _scrubState(Robot r) =>
    r.container.read(rewindScrubControllerProvider);

Future<void> _quitGame(Robot r) async {
  if (_scrubState(r).open) {
    r.container.read(rewindScrubControllerProvider.notifier).cancel();

    await r.tester.pump();
  }

  await r.emulator.tapMenu();
  await r.menuScreen.tapQuitGame();
  await r.waitUntil(() => r.container.read(nesStateProvider) == null);
}

void main() {
  testWidgets('the rewind entry returns to the game and opens the timeline', (
    tester,
  ) async {
    final r = _robot(tester);

    await _startGame(r);
    await r.emulator.tapMenu();

    await tester.tap(find.byKey(MenuScreen.rewindTimelineKey));
    await tester.pump();

    await r.waitUntil(() => _scrubState(r).open, maxAttempts: 40);
    await tester.pump();

    expect(find.byType(MenuScreen), findsNothing);
    expect(find.byType(RewindTimelineOverlay), findsOneWidget);

    final commands = r.isolateHandles.last.sentCommands;
    final unpauseIndex = commands.lastIndexWhere((c) => c is UnpauseCommand);
    final scrubIndex = commands.lastIndexWhere(
      (c) => c is BeginRewindScrubCommand,
    );

    expect(unpauseIndex, greaterThanOrEqualTo(0));
    expect(scrubIndex, greaterThanOrEqualTo(0));
    expect(unpauseIndex, lessThan(scrubIndex));

    await _quitGame(r);
  });

  testWidgets('the rewind entry still opens the timeline when the game is '
      'paused', (tester) async {
    final r = _robot(tester);

    await _startGame(r);

    final nes = r.container.read(nesStateProvider)!..pause();

    await r.waitUntil(() => nes.paused);

    await r.emulator.tapMenu();

    await tester.tap(find.byKey(MenuScreen.rewindTimelineKey));
    await tester.pump();

    await r.waitUntil(() => _scrubState(r).open, maxAttempts: 40);
    await tester.pump();

    expect(find.byType(RewindTimelineOverlay), findsOneWidget);

    await _quitGame(r);
  });

  testWidgets('the rewind entry is hidden when rewind is off', (tester) async {
    final r = _robot(tester, rewind: false);

    await _startGame(r);
    await r.emulator.tapMenu();

    expect(find.byKey(MenuScreen.rewindTimelineKey), findsNothing);

    await r.menuScreen.tapResume();
    await _quitGame(r);
  });
}
