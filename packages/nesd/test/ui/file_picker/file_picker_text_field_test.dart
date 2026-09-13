import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/focus.dart';
import '../robot.dart';

const _romsDirectorySettings = {
  'lastRomPath': {
    'path': '/test/roms',
    'name': '/test/roms',
    'type': 'directory',
  },
};

void main() {
  testWidgets(
    'Enter in the filter field leaves the picker on the same screen',
    (tester) async {
      final r = Robot(tester)..initSettings(_romsDirectorySettings);

      await r.pumpApp();

      await r.mainMenu.tapOpenRomButton();
      r.filePickerScreen.expectFilePickerScreenFound();

      final field = find.byType(TextField);

      await tester.tap(field);
      await tester.pump();

      await tester.enterText(field, 'nes');
      await tester.pump();

      await r.pressKey(LogicalKeyboardKey.enter);

      r.filePickerScreen.expectFilePickerScreenFound();
      expect(tester.widget<TextField>(field).controller!.text, 'nes');

      await r.pressKey(LogicalKeyboardKey.arrowDown);

      expect(focusInside(tester, field), isFalse);
    },
  );
}
