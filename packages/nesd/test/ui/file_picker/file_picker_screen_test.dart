import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/file_picker/file_picker_controller.dart';
import 'package:nesd/ui/file_picker/file_picker_screen.dart';
import 'package:nesd/ui/file_picker/file_picker_state.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../robot.dart';

const _romsDirectorySettings = {
  'lastRomPath': {
    'path': '/test/roms',
    'name': '/test/roms',
    'type': 'directory',
  },
};

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
    r.filePickerScreen.expectParentLinkFound();
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

  testWidgets('cancel navigates up and restores focus to the directory left', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp(extraFiles: {'/test/roms/sub/Game.nes': Uint8List(0)});

    await r.mainMenu.tapOpenRomButton();
    r.filePickerScreen.expectFilePickerScreenFound();

    await r.filePickerScreen.focusFile('sub');
    r.sendInputAction(confirm);

    await r.filePickerScreen.waitForDirectory('sub');
    await r.filePickerScreen.waitForFocusedFile('Game.nes');

    r.sendInputAction(cancel);

    await r.filePickerScreen.waitForDirectory('/test/roms');
    await r.filePickerScreen.waitForFocusedFile('sub');
    r.filePickerScreen.expectFilePickerScreenFound();
  });

  testWidgets('tapping the parent tile also restores focus', (tester) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();

    await r.mainMenu.tapOpenRomButton();
    r.filePickerScreen.expectFilePickerScreenFound();

    await r.filePickerScreen.tapParentTile();

    await r.filePickerScreen.waitForDirectory('/test');
    await r.filePickerScreen.waitForFocusedFile('roms');
  });

  testWidgets('cancel at the starting directory closes the picker', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();

    await r.mainMenu.tapOpenRomButton();
    r.filePickerScreen.expectFilePickerScreenFound();

    r.sendInputAction(cancel);
    await r.waitUntil(() => find.byType(FilePickerScreen).evaluate().isEmpty);

    r.mainMenu.expectMainMenuFound();
  });

  testWidgets('cancel closes the picker once it is back at the start', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp(extraFiles: {'/test/roms/sub/Game.nes': Uint8List(0)});

    await r.mainMenu.tapOpenRomButton();

    await r.filePickerScreen.focusFile('sub');
    r.sendInputAction(confirm);
    await r.filePickerScreen.waitForDirectory('sub');

    r.sendInputAction(cancel);
    await r.filePickerScreen.waitForDirectory('/test/roms');
    r.filePickerScreen.expectFilePickerScreenFound();

    r.sendInputAction(cancel);
    await r.waitUntil(() => find.byType(FilePickerScreen).evaluate().isEmpty);

    r.mainMenu.expectMainMenuFound();
  });

  testWidgets('cancel above the starting directory closes the picker', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();

    await r.mainMenu.tapOpenRomButton();

    await r.filePickerScreen.tapParentTile();
    await r.filePickerScreen.waitForDirectory('/test');

    r.sendInputAction(cancel);
    await r.waitUntil(() => find.byType(FilePickerScreen).evaluate().isEmpty);

    r.mainMenu.expectMainMenuFound();
  });

  testWidgets('choosing a directory moves where cancel closes', (tester) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp(extraFiles: {'/test/other/sub/Game.nes': Uint8List(0)});

    when(() => r.fileSystem.chooseDirectory('/test/roms')).thenAnswer(
      (_) async => const FilesystemFile(
        path: '/test/other',
        name: '/test/other',
        type: FilesystemFileType.directory,
      ),
    );

    await r.mainMenu.tapOpenRomButton();

    await r.filePickerScreen.tapDirectoryButton();
    await r.filePickerScreen.waitForDirectory('/test/other');

    await r.filePickerScreen.focusFile('sub');
    r.sendInputAction(confirm);
    await r.filePickerScreen.waitForDirectory('sub');

    r.sendInputAction(cancel);
    await r.filePickerScreen.waitForDirectory('/test/other');
    r.filePickerScreen.expectFilePickerScreenFound();
  });

  testWidgets('shoulder actions letter-skip through the file list', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    // Bio.txt is not an allowed extension: rendered disabled, skipped by
    // the jump.
    await r.pumpApp(
      extraFiles: {
        '/test/roms/Alpha.nes': Uint8List(0),
        '/test/roms/Aztec.nes': Uint8List(0),
        '/test/roms/Bio.txt': Uint8List(0),
        '/test/roms/Bobble.nes': Uint8List(0),
        '/test/roms/Castle.nes': Uint8List(0),
      },
    );

    await r.mainMenu.tapOpenRomButton();
    r.filePickerScreen.expectFilesFound(7);

    await r.filePickerScreen.focusFile('Alpha.nes');

    r.sendInputAction(nextTab);
    await r.filePickerScreen.waitForFocusedFile('Bobble.nes');
    r.filePickerScreen.expectIndicator('B');
    r.filePickerScreen.expectIndicator('4 / 7');

    r.sendInputAction(nextTab);
    await r.filePickerScreen.waitForFocusedFile('Castle.nes');

    r.sendInputAction(nextTab);
    await r.filePickerScreen.waitForFocusedFile('nestest.nes');

    r.sendInputAction(previousTab);
    await r.filePickerScreen.waitForFocusedFile('Castle.nes');

    r.sendInputAction(previousTab);
    await r.filePickerScreen.waitForFocusedFile('Bobble.nes');
  });

  testWidgets('letter skips scroll tiles that are outside the viewport', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/Alpha.nes': Uint8List(0),
        for (var i = 1; i <= 20; i++)
          '/test/roms/B${i.toString().padLeft(2, '0')}.nes': Uint8List(0),
        '/test/roms/Castle.nes': Uint8List(0),
      },
      logicalSize: const Size(1000, 600),
    );

    await r.mainMenu.tapOpenRomButton();
    r.filePickerScreen.expectFilePickerScreenFound();

    await r.filePickerScreen.focusFile('Alpha.nes');

    r.sendInputAction(nextTab);
    await r.filePickerScreen.waitForFocusedFile('B01.nes');

    r.sendInputAction(nextTab);
    await r.filePickerScreen.waitForFocusedFile('Castle.nes');
    r.filePickerScreen.expectFileTileVisible('Castle.nes');

    r.sendInputAction(previousTab);
    await r.filePickerScreen.waitForFocusedFile('B01.nes');
    r.filePickerScreen.expectFileTileVisible('B01.nes');
  });

  testWidgets('letter skip falls back to a page jump while filtering', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp(
      extraFiles: {
        for (var i = 1; i <= 20; i++)
          '/test/roms/B${i.toString().padLeft(2, '0')}.nes': Uint8List(0),
      },
      logicalSize: const Size(1000, 600),
    );

    await r.mainMenu.tapOpenRomButton();
    r.filePickerScreen.expectFilePickerScreenFound();

    await r.filePickerScreen.enterFilter('b');

    await r.waitUntil(() {
      final state = r.container.read(filePickerStateProvider);

      return state is FilePickerData && state.files.length == 20;
    });

    await r.filePickerScreen.focusFile('B01.nes');

    final page = r.filePickerScreen.visibleRowCount;

    expect(page, inInclusiveRange(2, 19), reason: 'page must be a real jump');

    r.sendInputAction(nextTab);

    final target = 'B${(page + 1).toString().padLeft(2, '0')}.nes';

    await r.filePickerScreen.waitForFocusedFile(target);

    r.sendInputAction(previousTab);
    await r.filePickerScreen.waitForFocusedFile('B01.nes');
  });

  testWidgets('the position indicator appears on focus and fades away', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();

    await r.mainMenu.tapOpenRomButton();
    r.filePickerScreen.expectFilesFound(2);

    await r.filePickerScreen.focusFile('nestest.nes');
    r.filePickerScreen.expectIndicator('1 / 2');

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    r.filePickerScreen.expectIndicatorHidden('1 / 2');
  });
}
