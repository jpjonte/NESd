import 'dart:typed_data';

import 'package:nesd/log/log.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/palette_library.dart';
import 'package:nesd/nes/ppu/palette/palette_selection.dart';
import 'package:nesd/ui/emulator/user_palettes.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nes_palette_provider.g.dart';

@riverpod
Uint32List nesPalette(Ref ref) {
  final library = ref.watch(paletteLibraryProvider).value;
  final userPalettes = ref.watch(userPalettesProvider).value;

  final selection = ref.watch(
    settingsControllerProvider.select((s) => s.paletteSelection),
  );
  final ntsc = ref.watch(
    settingsControllerProvider.select((s) => s.ntscPalette),
  );

  return switch (selection) {
    BuiltInPaletteSelection(:final id) =>
      library?.resolve(id, ntsc) ?? defaultPalette,
    UserPaletteSelection(:final name) => _resolveUser(name, userPalettes),
  };
}

Uint32List _resolveUser(String name, Map<String, Uint32List>? loaded) {
  if (loaded == null) {
    return defaultPalette;
  }

  final palette = loaded[name];

  if (palette == null) {
    log.video.warning('User palette "$name" is missing; using the default');

    return defaultPalette;
  }

  return palette;
}
