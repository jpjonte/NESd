import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/web_storage_filesystem.dart';
import 'package:nesd/ui/toast/toaster.dart';

class _MockToaster extends Mock implements Toaster {}

void main() {
  const romInfo = RomInfo(
    file: FilesystemFile(
      path: '/nesd/roms/game.nes',
      name: 'game.nes',
      type: FilesystemFileType.file,
    ),
  );

  late StorageFilesystem storage;
  late RomManager manager;

  setUpAll(() => registerFallbackValue(Toast.info('fallback')));

  setUp(() async {
    storage = await WebStorageFilesystem.open(newIdbFactoryMemory());

    manager = RomManager(baseDirectory: '/nesd', storage: storage);
  });

  tearDown(() => manager.dispose());

  test('SRAM round-trips', () async {
    await manager.save(romInfo, Uint8List.fromList([9, 9]));

    expect(await manager.load(romInfo), [9, 9]);
  });

  test('load returns null without a save', () async {
    expect(await manager.load(romInfo), isNull);
  });

  test('save states round-trip per slot', () async {
    await manager.saveState(romInfo, 3, [1, 2, 3]);

    expect(await manager.loadState(romInfo, 3), [1, 2, 3]);
    expect(await manager.loadState(romInfo, 4), isNull);
  });

  test('loadLatestState picks the newest slot', () async {
    await manager.saveState(romInfo, 1, [1]);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await manager.saveState(romInfo, 2, [2]);

    final latest = await manager.loadLatestState(romInfo);

    expect(latest?.slot, 2);
    expect(latest?.data, [2]);
  });

  test('loadLatestState returns null without any state', () async {
    expect(await manager.loadLatestState(romInfo), isNull);
  });

  test('backupUnreadableState copies the state next to the original', () async {
    await manager.saveState(romInfo, 0, [4, 2]);

    final name = await manager.backupUnreadableState(
      romInfo,
      LatestSaveState(
        slot: 0,
        data: Uint8List.fromList([4, 2]),
        modified: DateTime(2026, 9, 4, 18, 30, 12),
      ),
    );

    expect(name, 'game.0.20260904-183012.state.unreadable');
    expect(await storage.read('/nesd/states/$name'), [4, 2]);
    expect(await manager.loadState(romInfo, 0), [4, 2]);
  });

  test('backing up the same file again keeps a single copy', () async {
    final state = LatestSaveState(
      slot: 0,
      data: Uint8List.fromList([4, 2]),
      modified: DateTime(2026, 9, 4, 18, 30, 12),
    );

    await manager.backupUnreadableState(romInfo, state);
    await manager.backupUnreadableState(romInfo, state);

    final copies = (await storage.list(
      '/nesd/states',
    )).where((path) => path.endsWith('.unreadable'));

    expect(copies, hasLength(1));
  });

  test('a later unreadable file in the same slot gets its own copy', () async {
    await manager.backupUnreadableState(
      romInfo,
      LatestSaveState(
        slot: 0,
        data: Uint8List.fromList([1]),
        modified: DateTime(2026, 9, 4, 18, 30, 12),
      ),
    );
    await manager.backupUnreadableState(
      romInfo,
      LatestSaveState(
        slot: 0,
        data: Uint8List.fromList([2]),
        modified: DateTime(2026, 9, 5, 9),
      ),
    );

    expect(
      await storage.read(
        '/nesd/states/game.0.20260904-183012.state.unreadable',
      ),
      [1],
    );
    expect(
      await storage.read(
        '/nesd/states/game.0.20260905-090000.state.unreadable',
      ),
      [2],
    );
  });

  test('a truncated state shows up as an unreadable slot', () async {
    // A valid "NESd" header with nothing behind it: the reader runs off the
    // end of the buffer instead of raising a NesdException.
    await manager.saveState(romInfo, 4, [0x4e, 0x45, 0x53, 0x64, 0, 0, 0]);

    final tile = await manager.getRomTileDataForSlot(romInfo, 4);

    expect(tile?.error, 'The file is corrupt or truncated');
    expect(tile?.state, isNull);
    expect(tile?.thumbnail, isNull);
    expect(tile?.slot, 4);
    expect(tile?.title, startsWith('Slot 4 - '));
  });

  test('a state from another format version names the version', () async {
    // "NESd", container version 0, console type 0, NESState version 9.
    await manager.saveState(romInfo, 2, [0x4e, 0x45, 0x53, 0x64, 0, 0, 9]);

    final tile = await manager.getRomTileDataForSlot(romInfo, 2);

    expect(tile?.error, 'Invalid serialization version 9 for NESState');
  });

  test('backup copies are invisible to the slot lookups', () async {
    await manager.backupUnreadableState(
      romInfo,
      LatestSaveState(
        slot: 0,
        data: Uint8List.fromList([1]),
        modified: DateTime(2026, 9, 4, 18, 30, 12),
      ),
    );

    expect(await manager.loadLatestState(romInfo), isNull);
    expect(await manager.getRomTileDataForSlot(romInfo, 0), isNull);
  });

  test('thumbnails are decodable and re-saving replaces them', () async {
    await manager.saveThumbnail(
      romInfo,
      width: 2,
      height: 2,
      pixels: Uint8List(16),
    );

    final first = img.decodePng((await manager.readThumbnail(romInfo))!);

    expect(first?.width, 2);

    await manager.saveThumbnail(
      romInfo,
      width: 4,
      height: 4,
      pixels: Uint8List(64),
    );

    final second = img.decodePng((await manager.readThumbnail(romInfo))!);

    expect(second?.width, 4);
  });

  test('getRomTileData defers thumbnail loading to the tile', () {
    expect(manager.getRomTileData(romInfo).thumbnail, isA<StoredThumbnail>());
  });

  group('hash-keyed files', () {
    const hash = 'a1b2c3d4e5f60718293a4b5c6d7e8f9012345678';
    const tag = 'a1b2c3d4e5f6';

    const hashed = RomInfo(
      file: FilesystemFile(
        path: '/nesd/roms/game.nes',
        name: 'game.nes',
        type: FilesystemFileType.file,
      ),
      romHash: hash,
    );

    const renamed = RomInfo(
      file: FilesystemFile(
        path: '/nesd/roms/The Game (USA).nes',
        name: 'The Game (USA).nes',
        type: FilesystemFileType.file,
      ),
      romHash: hash,
    );

    test('a renamed ROM still finds its SRAM', () async {
      await manager.save(hashed, Uint8List.fromList([9, 9]));

      expect(await manager.load(renamed), [9, 9]);
    });

    test('a save from the name-keyed layout is adopted', () async {
      await storage.write('/nesd/saves/game.sav', Uint8List.fromList([1, 2]));

      expect(await manager.load(hashed), [1, 2]);
      expect(await storage.read('/nesd/saves/game.sav'), isNull);
      expect(await storage.read('/nesd/saves/game [$tag].sav'), [1, 2]);
    });

    test('a ROM without a usable hash keeps the plain name', () async {
      const unhashed = RomInfo(
        file: FilesystemFile(
          path: '/nesd/roms/game.nes',
          name: 'game.nes',
          type: FilesystemFileType.file,
        ),
        romHash: 'abc',
      );

      await manager.save(unhashed, Uint8List.fromList([4]));

      expect(await storage.read('/nesd/saves/game.sav'), [4]);
    });

    test('two ROMs sharing a name keep separate saves', () async {
      const japan = RomInfo(
        file: FilesystemFile(
          path: '/nesd/roms/jp/game.nes',
          name: 'game.nes',
          type: FilesystemFileType.file,
        ),
        romHash: '0f1e2d3c4b5a69788796a5b4c3d2e1f001234567',
      );

      await manager.save(hashed, Uint8List.fromList([1]));
      await manager.save(japan, Uint8List.fromList([2]));

      expect(await manager.load(hashed), [1]);
      expect(await manager.load(japan), [2]);
    });

    test('an archived ROM is named after the entry', () async {
      const archived = RomInfo(
        file: FilesystemFile(
          path: '/nesd/roms/collection.zip:game.nes',
          name: 'game.nes',
          type: FilesystemFileType.file,
        ),
        romHash: hash,
      );

      await manager.save(archived, Uint8List.fromList([5]));

      expect(await storage.read('/nesd/saves/game [$tag].sav'), [5]);
    });

    test('a save from the archive-keyed layout is adopted', () async {
      const archived = RomInfo(
        file: FilesystemFile(
          path: '/nesd/roms/collection.zip:game.nes',
          name: 'other.nes',
          type: FilesystemFileType.file,
        ),
        romHash: hash,
      );

      await storage.write(
        '/nesd/saves/collection.zip:game.sav',
        Uint8List.fromList([6]),
      );

      expect(await manager.load(archived), [6]);
      expect(await storage.read('/nesd/saves/collection.zip:game.sav'), isNull);
    });

    test('adoption takes the other slots and backups along', () async {
      await storage.write('/nesd/states/game.0.state', Uint8List.fromList([0]));
      await storage.write('/nesd/states/game.3.state', Uint8List.fromList([3]));
      await storage.write(
        '/nesd/states/game.0.20260904-183012.state.unreadable',
        Uint8List.fromList([9]),
      );

      expect(await manager.loadState(hashed, 3), [3]);
      expect(await manager.loadState(hashed, 0), [0]);
      expect(
        await storage.read(
          '/nesd/states/game [$tag].0.20260904-183012.state.unreadable',
        ),
        [9],
      );
      expect(await storage.list('/nesd/states'), hasLength(3));
    });
  });

  test('legacy flat files are migrated into their subdirectory', () async {
    final storage = await WebStorageFilesystem.open(newIdbFactoryMemory());

    await storage.write('/nesd/x.sav', Uint8List.fromList([1, 2, 3]));

    final migrated = RomManager(baseDirectory: '/nesd', storage: storage);
    addTearDown(migrated.dispose);

    await migrated.initialized;

    expect(await storage.read('/nesd/x.sav'), isNull);
    expect(await storage.read('/nesd/saves/x.sav'), [1, 2, 3]);
  });

  test('operations wait for the in-flight migration', () async {
    final storage = await WebStorageFilesystem.open(newIdbFactoryMemory());

    await storage.write('/nesd/game.sav', Uint8List.fromList([7]));

    final migrated = RomManager(baseDirectory: '/nesd', storage: storage);
    addTearDown(migrated.dispose);

    // Deliberately no `await migrated.initialized`: load must not
    // observe the pre-migration layout and report the save missing.
    expect(await migrated.load(romInfo), [7]);
  });

  test('a broken storage backend fails init without throwing', () async {
    final storage = _ThrowingStorageFilesystem();
    final toaster = _MockToaster();
    final manager = RomManager(
      baseDirectory: '/nesd',
      storage: storage,
      toaster: toaster,
    );
    addTearDown(manager.dispose);

    await expectLater(manager.initialized, completes);

    final toasts = verify(() => toaster.send(captureAny())).captured;

    expect(
      toasts.whereType<Toast>().map((t) => t.type),
      contains(ToastType.error),
    );
  });
}

class _ThrowingStorageFilesystem implements StorageFilesystem {
  @override
  Future<void> createDirectory(String path) async =>
      throw NesdException('broken');

  @override
  Future<void> delete(String path) async => throw NesdException('broken');

  @override
  Future<bool> exists(String path) async => throw NesdException('broken');

  @override
  Future<DateTime?> lastModified(String path) async =>
      throw NesdException('broken');

  @override
  Future<List<String>> list(String directory) async =>
      throw NesdException('broken');

  @override
  Future<Uint8List?> read(String path) async => throw NesdException('broken');

  @override
  Future<void> write(String path, Uint8List data) async =>
      throw NesdException('broken');
}
