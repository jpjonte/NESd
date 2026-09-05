import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';

import '../robot.dart';

const _romInfo = RomInfo(
  file: FilesystemFile(
    path: '/test/roms/nestest.nes',
    name: '/test/roms/nestest.nes',
    type: FilesystemFileType.file,
  ),
);

const _reason = 'Invalid serialization version 9 for NESState';

Future<Robot> _openPickerWithUnreadableSlot(WidgetTester tester) async {
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
    });

  await r.pumpApp(storage: MemoryStorageFilesystem());

  // "NESd", container version 0, console type 0, NESState version 9: the
  // shape of a state written by a build with a newer format.
  await r.container.read(romManagerProvider).saveState(_romInfo, 3, [
    0x4e,
    0x45,
    0x53,
    0x64,
    0,
    0,
    9,
  ]);

  await r.mainMenu.openFirstRomTileContextMenu();
  await r.mainMenu.tapSaveStatesContextMenuEntry();

  return r;
}

void main() {
  testWidgets('an unreadable slot is shown as such', (tester) async {
    final r = await _openPickerWithUnreadableSlot(tester);

    r.saveStates.expectSaveStatesScreenFound();
    r.saveStates.expectSaveStatesFound(1);
    r.saveStates.expectUnreadableSaveStatesFound(1);
  });

  testWidgets('pressing an unreadable slot offers to delete it', (
    tester,
  ) async {
    final r = await _openPickerWithUnreadableSlot(tester);

    await r.saveStates.tapExistingSaveState();

    r.saveStates.expectUnreadableDialogFound(_reason);

    await r.saveStates.confirmDelete();

    r.saveStates.expectSaveStatesFound(0);
    expect(
      await r.container.read(romManagerProvider).loadState(_romInfo, 3),
      isNull,
    );
  });

  testWidgets('cancelling keeps the unreadable slot', (tester) async {
    final r = await _openPickerWithUnreadableSlot(tester);

    await r.saveStates.tapExistingSaveState();
    await r.go(find.text('Cancel'));

    r.saveStates.expectSaveStatesFound(1);
    expect(
      await r.container.read(romManagerProvider).loadState(_romInfo, 3),
      Uint8List.fromList([0x4e, 0x45, 0x53, 0x64, 0, 0, 9]),
    );
  });
}
