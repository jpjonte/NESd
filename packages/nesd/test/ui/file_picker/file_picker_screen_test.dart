import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';

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

  testWidgets('controller navigation moves focus out of the search bar', (
    tester,
  ) async {
    final r = Robot(tester)
      ..initSettings({
        'lastRomPath': {
          'path': '/test/roms',
          'name': '/test/roms',
          'type': 'directory',
        },
      });

    await r.pumpApp();

    await r.mainMenu.tapOpenRomButton();
    r.filePickerScreen.expectFilePickerScreenFound();

    await r.filePickerScreen.focusSearchBar();
    r.filePickerScreen.expectSearchBarFocused();

    r.sendInputAction(inputDown);
    await tester.pump();

    r.filePickerScreen.expectSearchBarNotFocused();
  });
}
