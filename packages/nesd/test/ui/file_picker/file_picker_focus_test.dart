import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/file_picker/file_list.dart';
import 'package:nesd/ui/file_picker/file_picker_screen.dart';

import '../../helpers/focus.dart';
import '../robot.dart';

const _romsDirectory = {
  'lastRomPath': {
    'path': '/test/roms',
    'name': '/test/roms',
    'type': 'directory',
  },
};

final _manyRoms = {
  for (var i = 0; i < 60; i++)
    '/test/roms/file_${i.toString().padLeft(2, '0')}.nes': Uint8List(0),
};

const _lastFile = 'z_fake.nes';

Future<Robot> _openPicker(
  WidgetTester tester, {
  Map<String, Uint8List> extraFiles = const {},
}) async {
  final r = Robot(tester)..initSettings(_romsDirectory);

  await r.pumpApp(extraFiles: extraFiles);
  await r.mainMenu.tapOpenRomButton();

  r.filePickerScreen.expectFilePickerScreenFound();

  return r;
}

Future<void> _send(Robot r, InputAction action) async {
  r.sendInputAction(action);
  await r.pumpFrames(const Duration(milliseconds: 100));
}

void main() {
  group('short list', () {
    testWidgets('moving down from the last file wraps to the top of the list', (
      tester,
    ) async {
      final r = await _openPicker(tester);

      await r.filePickerScreen.focusFile(_lastFile);

      await _send(r, inputDown);

      expect(focusInside(tester, find.byType(ParentTile)), isTrue);
    });

    testWidgets('moving up after wrapping leaves the list', (tester) async {
      final r = await _openPicker(tester);

      await r.filePickerScreen.focusFile('nestest.nes');

      await _send(r, inputDown);
      r.filePickerScreen.expectFocusedFile(_lastFile);

      await _send(r, inputDown);
      expect(focusInside(tester, find.byType(ParentTile)), isTrue);

      await _send(r, inputUp);
      r.filePickerScreen.expectSearchBarFocused();
    });

    testWidgets('left and right keep the focused file', (tester) async {
      final r = await _openPicker(tester);

      await r.filePickerScreen.focusFile('nestest.nes');

      await _send(r, inputLeft);
      r.filePickerScreen.expectFocusedFile('nestest.nes');

      await _send(r, inputRight);
      r.filePickerScreen.expectFocusedFile('nestest.nes');
    });
  });

  group('long list', () {
    testWidgets('moving down from the last file wraps to the top of the list', (
      tester,
    ) async {
      final r = await _openPicker(tester, extraFiles: _manyRoms);

      await r.filePickerScreen.scrollToFile(_lastFile);
      await r.filePickerScreen.focusFile(_lastFile);

      await _send(r, inputDown);

      expect(focusInside(tester, find.byType(ParentTile)), isTrue);
      r.filePickerScreen.expectFileTileVisible('file_00.nes');
    });

    testWidgets('next input from the last file wraps to the top of the list', (
      tester,
    ) async {
      final r = await _openPicker(tester, extraFiles: _manyRoms);

      await r.filePickerScreen.scrollToFile(_lastFile);
      await r.filePickerScreen.focusFile(_lastFile);

      await _send(r, nextInput);

      expect(focusInside(tester, find.byType(ParentTile)), isTrue);
    });

    testWidgets('moving up from the directory button wraps to the last file', (
      tester,
    ) async {
      final r = await _openPicker(tester, extraFiles: _manyRoms);

      focusInto(tester, find.byType(DirectoryPickerButton));
      await r.pumpFrames(const Duration(milliseconds: 100));

      await _send(r, inputUp);

      await r.filePickerScreen.waitForFocusedFile(_lastFile);
      r.filePickerScreen.expectFileTileVisible(_lastFile);
    });

    testWidgets(
      'previous input from the directory button wraps to the last file',
      (tester) async {
        final r = await _openPicker(tester, extraFiles: _manyRoms);

        focusInto(tester, find.byType(DirectoryPickerButton));
        await r.pumpFrames(const Duration(milliseconds: 100));

        await _send(r, previousInput);

        await r.filePickerScreen.waitForFocusedFile(_lastFile);
      },
    );

    testWidgets('moving up after wrapping leaves the list', (tester) async {
      final r = await _openPicker(tester, extraFiles: _manyRoms);

      await r.filePickerScreen.scrollToFile(_lastFile);
      await r.filePickerScreen.focusFile('nestest.nes');

      await _send(r, inputDown);
      r.filePickerScreen.expectFocusedFile(_lastFile);

      await _send(r, inputDown);
      expect(focusInside(tester, find.byType(ParentTile)), isTrue);

      await _send(r, inputUp);
      r.filePickerScreen.expectSearchBarFocused();
    });
  });
}
