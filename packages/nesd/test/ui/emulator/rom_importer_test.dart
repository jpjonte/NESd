import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:nesd/ui/emulator/rom_importer.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/web_storage_filesystem.dart';

void main() {
  test('the native importer opens a dropped file in place', () async {
    final file = await NativeRomImporter().importDropped(
      XFile('/downloads/Some Game (USA).nes'),
    );

    expect(
      file,
      const FilesystemFile(
        path: '/downloads/Some Game (USA).nes',
        name: 'Some Game (USA).nes',
        type: FilesystemFileType.file,
      ),
    );
  });

  test('the web importer copies a dropped file into browser storage', () async {
    final storage = await WebStorageFilesystem.open(newIdbFactoryMemory());
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    final file = await WebRomImporter(
      storage: storage,
    ).importDropped(XFile.fromData(bytes, path: '/drops/game.zip'));

    expect(
      file,
      const FilesystemFile(
        path: '$webRomsDirectory/game.zip',
        name: 'game.zip',
        type: FilesystemFileType.file,
      ),
    );
    expect(await storage.read('$webRomsDirectory/game.zip'), bytes);
  });
}
