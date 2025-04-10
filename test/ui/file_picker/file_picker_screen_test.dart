import 'package:flutter_test/flutter_test.dart';

import '../robot.dart';

void main() {
  testWidgets('File picker screen shows two files and parent directory link', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings({
      'recentRoms': [
        {'path': '/test/roms/nestest.nes'},
      ],
      'lastRomPath': '/test/roms',
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
