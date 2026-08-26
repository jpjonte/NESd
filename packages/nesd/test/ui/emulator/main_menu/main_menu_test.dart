import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../robot.dart';

void main() {
  testWidgets('App starts with main menu and logo', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();

    r.mainMenu.expectMainMenuFound();
    r.mainMenu.expectLogoFound();
    r.mainMenu.expectNoAboutButton();
  });

  testWidgets('App starts with main menu and has a list of recent games', (
    tester,
  ) async {
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
    r.mainMenu.expectMainMenuFound();
    r.mainMenu.expectPaginatedGridFound();
  });

  testWidgets('Save states can be opened from a recent ROM context menu '
      'without a running game', (tester) async {
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
    await r.mainMenu.openFirstRomTileContextMenu();
    await r.mainMenu.tapSaveStatesContextMenuEntry();
    r.saveStates.expectSaveStatesScreenFound();
  });

  testWidgets('Main menu buttons share one row on wide screens', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(logicalSize: const Size(1280, 720));

    r.mainMenu.expectMenuButtonsOnOneRow();
  });

  testWidgets(
    'Main menu buttons stack in one column when the row does not fit',
    (tester) async {
      final r = Robot(tester);

      await r.pumpApp(logicalSize: const Size(560, 720));

      r.mainMenu.expectMenuButtonsInOneColumn();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets('Recent ROM grid shows two rows on a 1280x720 screen', (
    tester,
  ) async {
    final r = Robot(tester)
      ..initSettings({
        'recentRoms': [
          for (var i = 0; i < 12; i++)
            {
              'file': {
                'path': '/test/roms/rom$i.nes',
                'name': 'rom$i.nes',
                'type': 'file',
              },
            },
        ],
      });

    await r.pumpApp(logicalSize: const Size(1280, 720));

    r.mainMenu.expectPaginatedGridFound();
    r.mainMenu.expectRomTileCount(8);
  });

  testWidgets('Main menu buttons sit directly below a short ROM grid', (
    tester,
  ) async {
    final r = Robot(tester)
      ..initSettings({
        'recentRoms': [
          for (var i = 0; i < 4; i++)
            {
              'file': {
                'path': '/test/roms/rom$i.nes',
                'name': 'rom$i.nes',
                'type': 'file',
              },
            },
        ],
      });

    await r.pumpApp(logicalSize: const Size(1280, 720));

    r.mainMenu.expectMenuButtonsDirectlyBelowGrid();
  });
}
