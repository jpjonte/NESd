import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/file_picker/file_list.dart';

import '../../helpers/focus.dart';
import '../robot.dart';

const _romsDirectory = {
  'lastRomPath': {
    'path': '/test/roms',
    'name': '/test/roms',
    'type': 'directory',
  },
};

Future<Robot> _openPicker(WidgetTester tester) async {
  final r = Robot(tester)..initSettings(_romsDirectory);

  await r.pumpApp();
  await r.mainMenu.tapOpenRomButton();

  r.filePickerScreen.expectFilePickerScreenFound();

  return r;
}

void main() {
  testWidgets('moving down from the last file wraps to the top of the list', (
    tester,
  ) async {
    final r = await _openPicker(tester);

    await r.filePickerScreen.focusFile('z_fake.nes');

    r.sendInputAction(inputDown);
    await r.pumpFrames(const Duration(milliseconds: 100));

    expect(focusInside(tester, find.byType(ParentTile)), isTrue);
  });
}
