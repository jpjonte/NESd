import 'dart:typed_data';

import 'package:nesd/log/log.dart';
import 'package:nesd/nes/ppu/palette/pal_file.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/emulator/user_palette_store.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_palettes.g.dart';

const userPalettesDirectory = 'palettes';

@riverpod
UserPaletteStore userPaletteStore(Ref ref) => UserPaletteStore(
  storage: ref.watch(storageFilesystemProvider),
  directory: p.join(
    ref.watch(applicationSupportPathProvider),
    userPalettesDirectory,
  ),
);

@riverpod
class UserPalettes extends _$UserPalettes {
  @override
  Future<Map<String, Uint32List>> build() async {
    final store = ref.watch(userPaletteStoreProvider);
    final palettes = <String, Uint32List>{};

    final List<String> names;

    try {
      names = await store.list();
    } on Object catch (e, s) {
      log.video.error('Failed to list user palettes', error: e, stackTrace: s);

      rethrow;
    }

    for (final name in names) {
      try {
        final bytes = await store.read(name);

        if (bytes == null) {
          continue;
        }

        palettes[name] = parsePalFile(bytes);
      } on Object catch (e, s) {
        log.video.error(
          'Skipping unreadable user palette $name',
          error: e,
          stackTrace: s,
        );
      }
    }

    return palettes;
  }

  Future<void> import(String name, Uint8List bytes) async {
    final palette = parsePalFile(bytes);

    await ref.read(userPaletteStoreProvider).write(name, bytes);

    state = AsyncData({...await future, name: palette});
  }

  Future<void> remove(String name) async {
    await ref.read(userPaletteStoreProvider).delete(name);

    final palettes = {...await future}..remove(name);

    state = AsyncData(palettes);
  }
}
