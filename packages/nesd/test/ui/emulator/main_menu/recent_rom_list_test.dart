import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/native_storage_filesystem.dart';

import '../../../helpers/gated_storage.dart';
import '../../robot.dart';

void main() {
  const romInfo = RomInfo(
    file: FilesystemFile(
      path: '/test/roms/nestest.nes',
      name: '/test/roms/nestest.nes',
      type: FilesystemFileType.file,
    ),
  );

  ui.Image? thumbnailOf(WidgetTester tester) => tester
      .widget<RawImage>(
        find.descendant(
          of: find.byType(RomTile),
          matching: find.byType(RawImage),
        ),
      )
      .image;

  testWidgets('reloads a thumbnail written after the list was built', (
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
      });

    await r.pumpApp();

    expect(thumbnailOf(tester), isNull);

    await tester.runAsync(
      () => r.container
          .read(romManagerProvider)
          .saveThumbnail(
            romInfo,
            width: 2,
            height: 2,
            pixels: Uint8List(2 * 2 * 4),
          ),
    );

    for (var round = 0; round < 20; round++) {
      await tester.runAsync(
        () async =>
            await Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();

      if (thumbnailOf(tester) != null) {
        break;
      }
    }

    expect(
      thumbnailOf(tester),
      isNotNull,
      reason: 'the tile kept the thumbnail it read before the game was saved',
    );
  });

  testWidgets('reads each thumbnail once while the menu settles', (
    tester,
  ) async {
    final storage = GatedStorage(
      NativeStorageFilesystem(),
      gateThumbnails: false,
    );

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

    await r.pumpApp(storage: storage);

    await tester.pump(const Duration(seconds: 1));

    expect(storage.readsMatching('.png'), 1);
  });
}
