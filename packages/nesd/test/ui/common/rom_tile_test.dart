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

import '../../helpers/gated_storage.dart';

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

  const storedTileData = RomTileData(
    romInfo: romInfo,
    title: 'test',
    thumbnail: StoredThumbnail(),
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

  ui.Image? thumbnailOf(WidgetTester tester) =>
      tester.widget<RawImage>(find.byType(RawImage)).image;

  /// Alternate between real async work and test frames until the tile shows an
  /// image.
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

  Future<void> pumpTile(
    WidgetTester tester,
    RomTileData romTileData, {
    StorageFilesystem? storageOverride,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        applicationSupportPathProvider.overrideWithValue(tempDir.path),
        storageFilesystemProvider.overrideWithValue(storageOverride ?? storage),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: RomTile(romTileData: romTileData, onPressed: () {}),
        ),
      ),
    ),
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

  group('RomTile thumbnail loading', () {
    late GatedStorage gated;

    setUp(() => gated = GatedStorage(storage));

    final spinner = find.byType(CircularProgressIndicator);

    Future<void> pumpGatedTile(WidgetTester tester) =>
        pumpTile(tester, storedTileData, storageOverride: gated);

    double opacityOf(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byKey(RomTile.thumbnailFadeKey),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity
        .value;

    testWidgets('shows no progress indicator while the read is still quick', (
      tester,
    ) async {
      await pumpGatedTile(tester);

      await tester.pump(const Duration(milliseconds: 100));

      expect(spinner, findsNothing);
    });

    testWidgets('shows a progress indicator once the read drags on', (
      tester,
    ) async {
      await pumpGatedTile(tester);

      await tester.pump(const Duration(milliseconds: 300));

      expect(spinner, findsOneWidget);
    });

    testWidgets('hides the progress indicator when the thumbnail arrives', (
      tester,
    ) async {
      await tester.runAsync(saveThumbnail);

      await pumpGatedTile(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(spinner, findsOneWidget);

      gated.openGate();

      expect(await pumpUntilThumbnail(tester), isNotNull);
      expect(spinner, findsNothing);
    });

    testWidgets('keeps the thumbnail transparent until it loads', (
      tester,
    ) async {
      await tester.runAsync(saveThumbnail);

      await pumpGatedTile(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(opacityOf(tester), 0);
    });

    testWidgets('keeps the delay running when the tile data is replaced', (
      tester,
    ) async {
      await pumpGatedTile(tester);

      await tester.pump(const Duration(milliseconds: 100));

      expect(spinner, findsNothing);

      await pumpTile(
        tester,
        // ignore: prefer_const_constructors
        RomTileData(
          romInfo: romInfo,
          title: 'test',
          thumbnail: const StoredThumbnail(),
        ),
        storageOverride: gated,
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(spinner, findsOneWidget);
    });

    testWidgets('fades the thumbnail in instead of showing it at once', (
      tester,
    ) async {
      await tester.runAsync(saveThumbnail);

      await pumpGatedTile(tester);

      gated.openGate();

      expect(await pumpUntilThumbnail(tester), isNotNull);

      expect(opacityOf(tester), lessThan(1));

      await tester.pump(const Duration(milliseconds: 500));

      expect(opacityOf(tester), 1);
    });
  });
}
