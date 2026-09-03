import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../robot.dart';

Uint8List nestestBytes() =>
    File('../../roms/test/nestest/nestest.nes').readAsBytesSync();

Uint8List zipContaining(String entryName, Uint8List bytes) =>
    zipOf({entryName: bytes});

Uint8List sevenZipFixture(String name) =>
    File('test/fixtures/archive/$name').readAsBytesSync();

Uint8List zipOf(Map<String, Uint8List> entries) {
  final archive = Archive();

  for (final MapEntry(key: name, value: bytes) in entries.entries) {
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

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
