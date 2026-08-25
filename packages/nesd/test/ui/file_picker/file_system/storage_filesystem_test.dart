import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/native_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/web_storage_filesystem.dart';

void main() {
  group('WebStorageFilesystem', () {
    late StorageFilesystem storage;

    setUp(() async {
      storage = await WebStorageFilesystem.open(newIdbFactoryMemory());
    });

    _contract(() => storage);

    test('a failing operation surfaces as a NesdException', () async {
      final factory = newIdbFactoryMemory();
      final failingStorage = await WebStorageFilesystem.open(factory);

      await factory.deleteDatabase('nesd');

      await expectLater(
        () => failingStorage.read('/nesd/x.bin'),
        throwsA(isA<NesdException>()),
      );
      await expectLater(
        () => failingStorage.delete('/nesd/x.bin'),
        throwsA(isA<NesdException>()),
      );
      await expectLater(
        () => failingStorage.exists('/nesd/x.bin'),
        throwsA(isA<NesdException>()),
      );
      await expectLater(
        () => failingStorage.list('/nesd'),
        throwsA(isA<NesdException>()),
      );
      await expectLater(
        () => failingStorage.lastModified('/nesd/x.bin'),
        throwsA(isA<NesdException>()),
      );
    });
  });

  group('NativeStorageFilesystem', () {
    late StorageFilesystem storage;
    late Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('nesd_storage_test');
      storage = NativeStorageFilesystem();
    });

    tearDown(() => temp.deleteSync(recursive: true));

    _contract(() => storage, root: () => temp.path);

    test('write leaves no temporary file behind', () async {
      final target = '${temp.path}/saves/a.sav';

      await storage.write(target, Uint8List.fromList([1, 2, 3]));

      expect(File('$target.tmp').existsSync(), isFalse);
    });
  });

  group('MemoryStorageFilesystem', () {
    late StorageFilesystem storage;

    setUp(() => storage = MemoryStorageFilesystem());

    _contract(() => storage);
  });
}

void _contract(
  StorageFilesystem Function() storage, {
  String Function()? root,
}) {
  String path(String name) {
    final getRoot = root;

    return getRoot == null ? '/nesd/$name' : '${getRoot()}/$name';
  }

  test('write then read round-trips', () async {
    final data = Uint8List.fromList([1, 2, 3]);

    await storage().write(path('saves/a.sav'), data);

    expect(await storage().read(path('saves/a.sav')), data);
    expect(await storage().exists(path('saves/a.sav')), isTrue);
  });

  test('read of a missing file returns null', () async {
    expect(await storage().read(path('missing.bin')), isNull);
    expect(await storage().exists(path('missing.bin')), isFalse);
  });

  test('delete removes a file', () async {
    await storage().write(path('x.bin'), Uint8List(1));
    await storage().delete(path('x.bin'));

    expect(await storage().exists(path('x.bin')), isFalse);
  });

  test('list returns files directly under a directory', () async {
    await storage().write(path('states/a.0.state'), Uint8List(1));
    await storage().write(path('states/b.1.state'), Uint8List(1));
    await storage().write(path('thumbnails/a.png'), Uint8List(1));

    final entries = await storage().list(path('states'));

    expect(entries, hasLength(2));
    expect(entries.every((e) => e.contains('states/')), isTrue);
  });

  test('list excludes nested entries', () async {
    await storage().write(path('states/a.state'), Uint8List(1));
    await storage().write(path('states/sub/b.state'), Uint8List(1));

    final entries = await storage().list(path('states'));

    expect(entries, hasLength(1));
    expect(entries.single, endsWith('a.state'));
  });

  test('lastModified is set for written files', () async {
    await storage().write(path('t.bin'), Uint8List(1));

    expect(await storage().lastModified(path('t.bin')), isNotNull);
  });
}
