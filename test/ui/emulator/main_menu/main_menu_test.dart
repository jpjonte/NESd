import 'package:flutter_test/flutter_test.dart';

import '../../robot.dart';

void main() {
  testWidgets('App starts with main menu and logo', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();

    r.mainMenu.expectMainMenuFound();
    r.mainMenu.expectLogoFound();
  });

  testWidgets('App starts with main menu, has a list of recent games, '
      'and about dialog can be opened', (tester) async {
    final r = Robot(tester)..initSettings({
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

    await r.mainMenu.tapAboutButton();
    r.mainMenu.expectAboutDialogFound();
  });
}
