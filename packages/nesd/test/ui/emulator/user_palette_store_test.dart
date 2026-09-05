import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/user_palette_store.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';

void main() {
  late MemoryStorageFilesystem storage;
  late UserPaletteStore store;

  setUp(() {
    storage = MemoryStorageFilesystem();
    store = UserPaletteStore(storage: storage, directory: '/app/palettes');
  });

  test('lists nothing before anything is written', () async {
    expect(await store.list(), isEmpty);
  });

  test('lists written palettes by name, sorted case-insensitively', () async {
    await store.write('zeta', Uint8List(3));
    await store.write('Alpha', Uint8List(3));
    await store.write('beta', Uint8List(3));

    expect(await store.list(), equals(['Alpha', 'beta', 'zeta']));
  });

  test('matches the .pal extension case-insensitively and ignores other '
      'files', () async {
    await storage.write('/app/palettes/Upper.PAL', Uint8List(3));
    await storage.write('/app/palettes/notes.txt', Uint8List(3));

    expect(await store.list(), equals(['Upper']));
  });

  test('stores files under the directory with a .pal extension', () async {
    await store.write('Foo', Uint8List(3));

    expect(await storage.exists('/app/palettes/Foo.pal'), isTrue);
  });

  test('reads back what was written', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);

    await store.write('Foo', bytes);

    expect(await store.read('Foo'), equals(bytes));
  });

  test('reads null for a missing name', () async {
    expect(await store.read('Missing'), isNull);
  });

  test('delete removes the file', () async {
    await store.write('Foo', Uint8List(3));
    await store.delete('Foo');

    expect(await store.list(), isEmpty);
    expect(await storage.exists('/app/palettes/Foo.pal'), isFalse);
  });
}
