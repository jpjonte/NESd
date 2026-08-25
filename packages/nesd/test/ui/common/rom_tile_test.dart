import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/native_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';

void main() {
  late Directory tempDir;
  late StorageFilesystem storage;
  late RomManager manager;

  const romInfo = RomInfo(
    file: FilesystemFile(
      path: '/roms/test.nes',
      name: 'test.nes',
      type: FilesystemFileType.file,
    ),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nesd_rom_tile');
    storage = NativeStorageFilesystem();
    manager = RomManager(baseDirectory: tempDir.path, storage: storage);
  });

  tearDown(() async {
    manager.dispose();
    await tempDir.delete(recursive: true);
  });

  Future<Uint8List?> thumbnailBytes() => manager.readThumbnail(romInfo);

  Future<void> saveThumbnail() => manager.saveThumbnail(
    romInfo,
    width: 2,
    height: 2,
    pixels: Uint8List(2 * 2 * 4),
  );

  group('loadStoredThumbnail', () {
    test('returns null when the file does not exist', () async {
      expect(await loadStoredThumbnail(await thumbnailBytes()), isNull);
    });

    test('decodes a stored thumbnail', () async {
      await saveThumbnail();

      final thumbnail = await loadStoredThumbnail(await thumbnailBytes());

      expect(thumbnail, isNotNull);
      expect(thumbnail!.width, 2);
      expect(thumbnail.height, 2);
    });

    test('returns null for a file that cannot be decoded', () async {
      await storage.write(
        manager.thumbnailPath(romInfo),
        Uint8List.fromList([0, 1, 2, 3]),
      );

      expect(await loadStoredThumbnail(await thumbnailBytes()), isNull);
    });
  });

  group('RomTile', () {
    const storedTileData = RomTileData(
      romInfo: romInfo,
      title: 'test',
      thumbnail: StoredThumbnail(),
    );

    ui.Image? thumbnailOf(WidgetTester tester) =>
        tester.widget<RawImage>(find.byType(RawImage)).image;

    /// Alternates real async work and frames until the tile shows an image.
    ///
    /// Every `await` of the file read and the image decoding needs its own
    /// round of real time before the fake clock can carry the result into the
    /// widget tree.
    Future<ui.Image?> pumpUntilThumbnail(
      WidgetTester tester, {
      int rounds = 20,
    }) async {
      for (var round = 0; round < rounds; round++) {
        await tester.runAsync(
          () async => await Future.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();

        if (thumbnailOf(tester) case final image?) {
          return image;
        }
      }

      return null;
    }

    Future<void> pumpTile(WidgetTester tester, RomTileData romTileData) =>
        tester.pumpWidget(
          ProviderScope(
            overrides: [
              applicationSupportPathProvider.overrideWithValue(tempDir.path),
              storageFilesystemProvider.overrideWithValue(storage),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: RomTile(romTileData: romTileData, onPressed: () {}),
              ),
            ),
          ),
        );

    testWidgets('loads a stored thumbnail', (tester) async {
      await tester.runAsync(saveThumbnail);

      await pumpTile(tester, storedTileData);

      expect(await pumpUntilThumbnail(tester), isNotNull);
    });

    testWidgets('shows no image when no thumbnail is stored', (tester) async {
      await pumpTile(tester, storedTileData);

      expect(await pumpUntilThumbnail(tester), isNull);

      // a missing thumbnail must not keep the ROM from being listed
      // (StrokeText paints the title twice: outline and fill)
      expect(find.text('test'), findsWidgets);
    });

    testWidgets('shows an already decoded thumbnail', (tester) async {
      final image = await tester.runAsync(() async {
        await saveThumbnail();

        return await loadStoredThumbnail(await thumbnailBytes());
      });

      await pumpTile(
        tester,
        RomTileData(
          romInfo: romInfo,
          title: 'test',
          thumbnail: DecodedThumbnail(image!),
        ),
      );

      expect(thumbnailOf(tester), same(image));
    });
  });
}
