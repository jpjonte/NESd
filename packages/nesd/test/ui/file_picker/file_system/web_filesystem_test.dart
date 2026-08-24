import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:nesd/exception/file_not_found.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/web_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/web_storage_filesystem.dart';

void main() {
  late WebFilesystem filesystem;
  late WebStorageFilesystem storage;

  setUp(() async {
    storage = await WebStorageFilesystem.open(newIdbFactoryMemory());
    filesystem = WebFilesystem(storage: storage);
  });

  test('read returns stored bytes', () async {
    await storage.write('/nesd/roms/a.nes', Uint8List.fromList([1, 2]));

    expect(await filesystem.read('/nesd/roms/a.nes'), [1, 2]);
  });

  test('read of a vanished ROM throws FileNotFound', () async {
    await expectLater(
      () => filesystem.read('/nesd/roms/gone.nes'),
      throwsA(isA<FileNotFound>()),
    );
  });

  test('list maps storage entries to files', () async {
    await storage.write('/nesd/roms/a.nes', Uint8List(1));

    final entries = await filesystem.list('/nesd/roms');

    expect(entries, hasLength(1));
    expect(entries.single.name, 'a.nes');
    expect(entries.single.type, FilesystemFileType.file);
  });
}
