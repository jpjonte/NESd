import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/ntsc_palette_generator.dart';
import 'package:nesd/nes/ppu/palette/ntsc_palette_settings.dart';
import 'package:nesd/nes/ppu/palette/pal_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'palette_library.g.dart';

const _assets = {
  NesPaletteId.warm: 'assets/palettes/warm.pal',
  NesPaletteId.cool: 'assets/palettes/cool.pal',
  NesPaletteId.flat: 'assets/palettes/flat.pal',
};

class PaletteLibrary {
  PaletteLibrary() {
    ready = _load();
  }

  late final Future<void> ready;

  final _loaded = <NesPaletteId, Uint32List>{};

  Uint32List resolve(NesPaletteId id, NtscPaletteSettings ntsc) => switch (id) {
    NesPaletteId.defaultPalette => defaultPalette,
    NesPaletteId.generated => generateNtscPalette(ntsc),
    _ => _loaded[id] ?? defaultPalette,
  };

  Future<void> _load() async {
    for (final entry in _assets.entries) {
      try {
        final data = await rootBundle.load(entry.value);

        _loaded[entry.key] = parsePalFile(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      } on Object catch (e, s) {
        log.video.error(
          'Failed to load bundled palette: ${entry.value}',
          error: e,
          stackTrace: s,
        );
      }
    }
  }
}

@riverpod
Future<PaletteLibrary> paletteLibrary(Ref ref) async {
  final library = PaletteLibrary();

  await library.ready;

  return library;
}
