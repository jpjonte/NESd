import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_list.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';

import '../robot.dart';

const _archive = '/roms/dirs.7z';

void main() {
  testWidgets('an archive shows its folders instead of a flat entry dump', (
    tester,
  ) async {
    await _openArchive(tester);

    expect(_tiles(), {'nested': true});
  });

  testWidgets('entering a folder inside an archive lists its contents', (
    tester,
  ) async {
    final r = await _openArchive(tester);

    await r.filePickerScreen.tapFile('nested');
    await r.fixAsync();

    expect(_tiles(), {'sub': true, 'scanline.nes': false});
  });

  testWidgets('the parent link walks back out of a folder', (tester) async {
    final r = await _openArchive(tester);

    await r.filePickerScreen.tapFile('nested');
    await r.fixAsync();
    await r.filePickerScreen.tapFile('sub');
    await r.fixAsync();

    expect(_tiles(), {'nestest.nes': false});

    await r.filePickerScreen.tapParentTile();
    await r.fixAsync();

    expect(_tiles(), {'sub': true, 'scanline.nes': false});

    await r.filePickerScreen.tapParentTile();
    await r.fixAsync();

    expect(_tiles(), {'nested': true});
  });

  testWidgets('cancelling inside a folder goes up instead of closing', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        _archive: File('test/fixtures/archive/dirs.7z').readAsBytesSync(),
      },
    );

    unawaited(
      r.container
          .read(nesControllerProvider)
          .startRom(
            const FilesystemFile(
              path: _archive,
              name: 'dirs.7z',
              type: FilesystemFileType.file,
            ),
          ),
    );

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == FilePickerRoute.name,
    );

    expect(_tiles(), {'nested': true});

    await r.filePickerScreen.tapFile('nested');
    await r.fixAsync();

    expect(_tiles(), {'sub': true, 'scanline.nes': false});

    r.sendInputAction(cancel);
    await r.fixAsync();

    r.filePickerScreen.expectFilePickerScreenFound();
    expect(_tiles(), {'nested': true});
  });

  testWidgets('a ROM picked inside a folder starts from its nested path', (
    tester,
  ) async {
    final r = await _openArchive(tester);

    await r.filePickerScreen.tapFile('nested');
    await r.fixAsync();
    await r.filePickerScreen.tapFile('scanline.nes');

    await r.waitUntil(() => r.container.read(nesStateProvider) != null);

    expect(
      r.container.read(nesStateProvider)!.romInfo.file.path,
      '$_archive:nested/scanline.nes',
    );

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });
}

Map<String, bool> _tiles() => {
  for (final element in find.byType(FileTile).evaluate())
    (element.widget as FileTile).file.name:
        (element.widget as FileTile).isDirectory,
};

Future<Robot> _openArchive(WidgetTester tester) async {
  final r = Robot(tester)
    ..initSettings({
      'lastRomPath': {'path': '/roms', 'name': '/roms', 'type': 'directory'},
    });

  await r.pumpApp(
    extraFiles: {
      _archive: File('test/fixtures/archive/dirs.7z').readAsBytesSync(),
    },
  );

  r.mainMenu.expectMainMenuFound();

  await r.mainMenu.tapOpenRomButton();
  await r.filePickerScreen.tapFile('dirs.7z');
  await r.fixAsync();

  return r;
}
