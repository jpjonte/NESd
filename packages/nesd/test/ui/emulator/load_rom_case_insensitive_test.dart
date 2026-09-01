import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../robot.dart';

Uint8List _nestestBytes() =>
    File('../../roms/test/nestest/nestest.nes').readAsBytesSync();

Uint8List _zipContaining(String entryName, Uint8List bytes) {
  final archive = Archive()
    ..addFile(ArchiveFile(entryName, bytes.length, bytes));

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

Future<void> expectRomLoads(
  WidgetTester tester,
  Robot r, {
  required String path,
  required String name,
}) async {
  final controller = r.container.read(nesControllerProvider);

  final loaded = await tester.runAsync(
    () => controller.loadRom(
      FilesystemFile(path: path, name: name, type: FilesystemFileType.file),
    ),
  );

  await r.fixAsync();

  final errors = [
    for (final toast in r.container.read(toastStateProvider))
      if (toast.type == ToastType.error) toast.message,
  ];

  expect(errors, isEmpty);
  expect(loaded, isTrue);
  expect(r.container.read(nesStateProvider), isNotNull);

  await tester.runAsync(controller.stop);
  await r.waitUntil(() => r.container.read(nesStateProvider) == null);
}

void main() {
  testWidgets('loadRom accepts an uppercase .NES extension', (tester) async {
    final r = Robot(tester);

    await r.pumpApp(extraFiles: {'/test/roms/GAME.NES': _nestestBytes()});

    await expectRomLoads(
      tester,
      r,
      path: '/test/roms/GAME.NES',
      name: 'GAME.NES',
    );
  });

  testWidgets('loadRom accepts an uppercase .ZIP extension', (tester) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/COLLECTION.ZIP': _zipContaining(
          'game.nes',
          _nestestBytes(),
        ),
      },
    );

    await expectRomLoads(
      tester,
      r,
      path: '/test/roms/COLLECTION.ZIP',
      name: 'COLLECTION.ZIP',
    );
  });

  testWidgets('loadRom finds an uppercase .NES entry inside an archive', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/collection.zip': _zipContaining(
          'GAME.NES',
          _nestestBytes(),
        ),
      },
    );

    await expectRomLoads(
      tester,
      r,
      path: '/test/roms/collection.zip',
      name: 'collection.zip',
    );
  });

  testWidgets('loadRom reads an entry picked out of an uppercase .ZIP', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/COLLECTION.ZIP': _zipContaining(
          'game.nes',
          _nestestBytes(),
        ),
      },
    );

    // The file picker hands archive entries back as `<archive>:<entry>`.
    await expectRomLoads(
      tester,
      r,
      path: '/test/roms/COLLECTION.ZIP:game.nes',
      name: 'game.nes',
    );
  });
}
