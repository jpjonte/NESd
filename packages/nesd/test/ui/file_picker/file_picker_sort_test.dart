import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/file_picker/file_sort_order.dart';
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
  testWidgets('the sort button cycles and stores the order', (tester) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();
    await r.mainMenu.tapOpenRomButton();

    r.filePickerScreen.expectSortLabel('Name ↑');
    expect(r.filePickerScreen.fileNames(), ['nestest.nes', 'z_fake.nes']);

    await r.filePickerScreen.tapSortButton();

    r.filePickerScreen.expectSortLabel('Name ↓');
    expect(r.settings.fileSortOrder, FileSortOrder.nameDescending);
    expect(r.filePickerScreen.fileNames(), ['z_fake.nes', 'nestest.nes']);
  });

  testWidgets('the sort action cycles the order and says so', (tester) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();
    await r.mainMenu.tapOpenRomButton();

    r.sendInputAction(sort);
    await r.fixAsync();

    r.filePickerScreen.expectSortLabel('Name ↓');
    expect([
      for (final toast in r.container.read(toastStateProvider)) toast.message,
    ], contains('Sorted by Name ↓'));
  });

  testWidgets('typing s in the filter does not sort', (tester) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();
    await r.mainMenu.tapOpenRomButton();
    await r.filePickerScreen.focusSearchBar();

    await r.pressKey(LogicalKeyboardKey.keyS);

    r.filePickerScreen.expectSortLabel('Name ↑');
  });

  testWidgets('the hint bar names the order', (tester) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();
    await r.mainMenu.tapOpenRomButton();
    await r.pressKey(LogicalKeyboardKey.arrowDown);

    expect(find.text('Favorite'), findsOneWidget);
    expect(find.text('Sort: Name ↑'), findsOneWidget);
    expect(find.text('Jump by letter'), findsOneWidget);
  });

  testWidgets('date orders hide the letter jump hint', (tester) async {
    final r = Robot(tester)
      ..initSettings({
        ..._romsDirectorySettings,
        'fileSortOrder': 'modifiedNewest',
      });

    await r.pumpApp();
    await r.mainMenu.tapOpenRomButton();
    await r.pressKey(LogicalKeyboardKey.arrowDown);

    expect(find.text('Sort: Modified ↓'), findsOneWidget);
    expect(find.text('Jump by letter'), findsNothing);
  });

  testWidgets('letter jump does nothing under a date order', (tester) async {
    final r = Robot(tester)
      ..initSettings({
        ..._romsDirectorySettings,
        'fileSortOrder': 'modifiedNewest',
      });

    await r.pumpApp();
    await r.mainMenu.tapOpenRomButton();
    await r.filePickerScreen.focusFile('nestest.nes');

    r.sendInputAction(nextTab);
    await r.fixAsync();

    r.filePickerScreen.expectFocusedFile('nestest.nes');
  });
}
