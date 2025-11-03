import 'package:flutter_test/flutter_test.dart';

import '../robot.dart';

void main() {
  testWidgets('File picker screen shows two files and parent directory link', (
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
        'lastRomPath': {
          'path': '/test/roms',
          'name': '/test/roms',
          'type': 'directory',
        },
      });

    await r.pumpApp();
    r.mainMenu.expectMainMenuFound();

    await r.mainMenu.tapOpenRomButton();
    r.filePickerScreen.expectFilePickerScreenFound();
    r.filePickerScreen.expectFilesFound(2);

    await r.goBack();
    r.mainMenu.expectMainMenuFound();
  });
}
