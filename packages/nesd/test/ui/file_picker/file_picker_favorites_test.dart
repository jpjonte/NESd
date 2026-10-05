import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../robot.dart';

const _romsDirectorySettings = {
  'lastRomPath': {
    'path': '/test/roms',
    'name': '/test/roms',
    'type': 'directory',
  },
};

void main() {
  testWidgets('clicking the star stores the game by its hash', (tester) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();
    await r.mainMenu.tapOpenRomButton();

    await r.filePickerScreen.tapStar('nestest.nes');
    await r.waitUntil(() => r.settings.favoriteRoms.isNotEmpty);

    expect(r.settings.favoriteRoms.single.romHash, isNotNull);
    r.filePickerScreen.expectStarred('nestest.nes', starred: true);
  });

  testWidgets('secondary action toggles the focused row', (tester) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();
    await r.mainMenu.tapOpenRomButton();
    await r.filePickerScreen.focusFile('nestest.nes');

    r.sendInputAction(secondaryAction);
    await r.waitUntil(() => r.settings.favoriteRoms.isNotEmpty);

    r.filePickerScreen.expectStarred('nestest.nes', starred: true);

    r.sendInputAction(secondaryAction);
    await r.waitUntil(() => r.settings.favoriteRoms.isEmpty);

    r.filePickerScreen.expectStarred('nestest.nes', starred: false);
  });

  testWidgets('an unreadable file is not starred', (tester) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();
    await r.mainMenu.tapOpenRomButton();

    await r.filePickerScreen.tapStar('z_fake.nes');
    await r.fixAsync();

    expect(r.settings.favoriteRoms, isEmpty);
    expect([
      for (final toast in r.container.read(toastStateProvider)) toast.message,
    ], contains('Could not read z_fake.nes'));
    r.filePickerScreen.expectStarred('z_fake.nes', starred: false);
  });

  testWidgets('shift+tab jumps by letter without starring', (tester) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();
    await r.mainMenu.tapOpenRomButton();
    await r.filePickerScreen.focusFile('nestest.nes');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await r.pressKey(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await r.fixAsync();

    expect(r.settings.favoriteRoms, isEmpty);
    expect(r.filePickerScreen.focusedFileName, isNot('nestest.nes'));

    await r.filePickerScreen.focusFile('nestest.nes');
    await r.pressKey(LogicalKeyboardKey.shift);
    await r.waitUntil(() => r.settings.favoriteRoms.isNotEmpty);
  });
}
