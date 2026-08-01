import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:path/path.dart' as p;

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

  Future<void> saveThumbnail(int size) => manager.saveThumbnail(
    romInfo,
    width: size,
    height: size,
    pixels: Uint8List(size * size * 4),
  );

  group('RomManager', () {
    test('saveState writes asynchronously and loadState reads back', () async {
      await manager.saveState(romInfo, 3, [1, 2, 3]);

      expect(manager.loadState(romInfo, 3), [1, 2, 3]);
    });

    test('save writes SRAM asynchronously and load reads back', () async {
      await manager.save(romInfo, Uint8List.fromList([9, 8, 7]));

      expect(manager.load(romInfo), [9, 8, 7]);
    });

    // the thumbnail file itself is read by the tile, see rom_tile_test.dart
    test('getRomTileData leaves the thumbnail to the tile', () {
      final romTileData = manager.getRomTileData(romInfo);

      expect(romTileData.title, 'test');
      expect(romTileData.thumbnail, isA<StoredThumbnail>());
    });

    test('saveThumbnail writes a decodable image', () async {
      await saveThumbnail(2);

      expect(
        await loadStoredThumbnail(manager.getThumbnailFile(romInfo)),
        isNotNull,
      );
    });

    test('saveThumbnail replaces an existing thumbnail', () async {
      await saveThumbnail(2);
      await saveThumbnail(4);

      final thumbnail = await loadStoredThumbnail(
        manager.getThumbnailFile(romInfo),
      );

      expect(thumbnail?.width, 4);
    });

    // the thumbnail is written next to its destination and renamed into
    // place. The rename itself is not observable, but it must not leave the
    // temporary file behind
    test('saveThumbnail leaves no temporary file behind', () async {
      await saveThumbnail(2);

      final thumbnails = Directory(
        p.dirname(manager.getThumbnailFile(romInfo).path),
      ).listSync().map((entity) => p.basename(entity.path));

      expect(thumbnails, ['test.png']);
    });
  });
}
