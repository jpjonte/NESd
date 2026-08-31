import 'dart:typed_data';

import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/palette_library.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nes_palette_provider.g.dart';

@riverpod
Uint32List nesPalette(Ref ref) {
  final library = ref.watch(paletteLibraryProvider).value;

  final id = ref.watch(settingsControllerProvider.select((s) => s.paletteId));
  final ntsc = ref.watch(
    settingsControllerProvider.select((s) => s.ntscPalette),
  );

  if (library == null) {
    return defaultPalette;
  }

  return library.resolve(id, ntsc);
}
