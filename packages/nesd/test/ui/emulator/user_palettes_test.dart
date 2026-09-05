import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/emulator/user_palettes.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';

import '../../helpers/pal_file.dart';

ProviderContainer _containerFor(MemoryStorageFilesystem storage) {
  final container = ProviderContainer(
    overrides: [
      storageFilesystemProvider.overrideWithValue(storage),
      applicationSupportPathProvider.overrideWithValue('/app'),
    ],
  );

  addTearDown(container.dispose);

  container.listen(userPalettesProvider, (_, _) {});

  return container;
}

/// In-memory storage whose [read] fails for one path, standing in for a
/// file the platform cannot open.
class _UnreadableStorage extends MemoryStorageFilesystem {
  _UnreadableStorage(this.unreadablePath);

  final String unreadablePath;

  @override
  Future<Uint8List?> read(String path) {
    if (path == unreadablePath) {
      throw NesdException('Failed to read $path');
    }

    return super.read(path);
  }
}

void main() {
  late MemoryStorageFilesystem storage;

  setUp(() {
    storage = MemoryStorageFilesystem();
  });

  test('loads and parses the stored palettes', () async {
    await storage.write('/app/palettes/Foo.pal', greyPalFile(0x10));
    await storage.write('/app/palettes/Bar.pal', greyPalFile(0x20));

    final container = _containerFor(storage);

    final palettes = await container.read(userPalettesProvider.future);

    expect(palettes.keys, unorderedEquals(['Foo', 'Bar']));
    expect(palettes['Foo']!.length, equals(nesPaletteLength));
    expect(palettes['Foo']![0], equals(packPaletteColor(0x10, 0x10, 0x10)));
    expect(palettes['Bar']![0], equals(packPaletteColor(0x20, 0x20, 0x20)));
  });

  test('skips a stored file that does not parse', () async {
    await storage.write('/app/palettes/Good.pal', greyPalFile(0x10));
    await storage.write('/app/palettes/Bad.pal', Uint8List(7));

    final container = _containerFor(storage);

    final palettes = await container.read(userPalettesProvider.future);

    expect(palettes.keys, equals(['Good']));
  });

  test('skips a stored file that cannot be read', () async {
    storage = _UnreadableStorage('/app/palettes/Bad.pal');

    await storage.write('/app/palettes/Good.pal', greyPalFile(0x10));
    await storage.write('/app/palettes/Bad.pal', greyPalFile(0x20));

    final container = _containerFor(storage);

    final palettes = await container.read(userPalettesProvider.future);

    expect(palettes.keys, equals(['Good']));
  });

  test('import rejects a wrong-sized file without writing it', () async {
    final container = _containerFor(storage);
    final notifier = container.read(userPalettesProvider.notifier);

    await expectLater(
      notifier.import('Bad', Uint8List(7)),
      throwsFormatException,
    );

    expect(await storage.exists('/app/palettes/Bad.pal'), isFalse);
    expect(await container.read(userPalettesProvider.future), isEmpty);
  });

  test('import stores the file and publishes the parsed palette', () async {
    final container = _containerFor(storage);
    final notifier = container.read(userPalettesProvider.notifier);

    await notifier.import('Foo', greyPalFile(0x30));

    expect(await storage.exists('/app/palettes/Foo.pal'), isTrue);

    final palettes = container.read(userPalettesProvider).requireValue;

    expect(palettes['Foo']![0], equals(packPaletteColor(0x30, 0x30, 0x30)));
  });

  test('importing an existing name replaces it', () async {
    final container = _containerFor(storage);
    final notifier = container.read(userPalettesProvider.notifier);

    await notifier.import('Foo', greyPalFile(0x30));
    await notifier.import('Foo', greyPalFile(0x50));

    final palettes = container.read(userPalettesProvider).requireValue;

    expect(palettes.keys, equals(['Foo']));
    expect(palettes['Foo']![0], equals(packPaletteColor(0x50, 0x50, 0x50)));
  });

  test('remove deletes the file and drops the palette', () async {
    final container = _containerFor(storage);
    final notifier = container.read(userPalettesProvider.notifier);

    await notifier.import('Foo', greyPalFile(0x30));
    await notifier.remove('Foo');

    expect(await storage.exists('/app/palettes/Foo.pal'), isFalse);
    expect(container.read(userPalettesProvider).requireValue, isEmpty);
  });
}
