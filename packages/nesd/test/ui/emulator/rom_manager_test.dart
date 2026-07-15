import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

void main() {
  late Directory tempDir;
  late RomManager manager;

  const romInfo = RomInfo(
    file: FilesystemFile(
      path: '/roms/test.nes',
      name: 'test.nes',
      type: FilesystemFileType.file,
    ),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nesd_rom_manager');
    manager = RomManager(baseDirectory: tempDir.path);
  });

  tearDown(() => tempDir.delete(recursive: true));

  group('RomManager', () {
    test('saveState writes asynchronously and loadState reads back', () async {
      await manager.saveState(romInfo, 3, [1, 2, 3]);

      expect(manager.loadState(romInfo, 3), [1, 2, 3]);
    });

    test('save writes SRAM asynchronously and load reads back', () async {
      await manager.save(romInfo, Uint8List.fromList([9, 8, 7]));

      expect(manager.load(romInfo), [9, 8, 7]);
    });
  });
}
