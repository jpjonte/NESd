import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/ntsc_palette_settings.dart';
import 'package:nesd/nes/ppu/palette/palette_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolves the default palette without loading assets', () {
    final library = PaletteLibrary();

    expect(
      library.resolve(NesPaletteId.defaultPalette, const NtscPaletteSettings()),
      equals(expandRgbToPalette(defaultPaletteRgb)),
    );
  });

  test('resolves the generated palette from its settings', () {
    final library = PaletteLibrary();

    final bright = library.resolve(
      NesPaletteId.generated,
      const NtscPaletteSettings(brightness: 1.2),
    );

    final dim = library.resolve(
      NesPaletteId.generated,
      const NtscPaletteSettings(brightness: 0.8),
    );

    expect(bright, isNot(equals(dim)));
    expect(bright.length, equals(nesPaletteLength));
  });

  test('falls back to the default palette before assets are ready', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    final completer = Completer<ByteData?>();

    messenger.setMockMessageHandler('flutter/assets', (_) => completer.future);

    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));

    final library = PaletteLibrary();

    expect(
      library.resolve(NesPaletteId.warm, const NtscPaletteSettings()),
      equals(expandRgbToPalette(defaultPaletteRgb)),
    );

    final bytes = File('assets/palettes/warm.pal').readAsBytesSync();

    completer.complete(ByteData.sublistView(bytes));

    await library.ready;
  });

  test('loads every bundled palette', () async {
    final library = PaletteLibrary();

    await library.ready;

    for (final id in NesPaletteId.values) {
      final palette = library.resolve(id, const NtscPaletteSettings());

      expect(palette.length, equals(nesPaletteLength), reason: id.name);
    }
  });

  test(
    'bundled palettes differ from each other and from the default',
    () async {
      final library = PaletteLibrary();

      await library.ready;

      const ntsc = NtscPaletteSettings();

      final warm = library.resolve(NesPaletteId.warm, ntsc);
      final cool = library.resolve(NesPaletteId.cool, ntsc);
      final flat = library.resolve(NesPaletteId.flat, ntsc);
      final fallback = library.resolve(NesPaletteId.defaultPalette, ntsc);

      expect(warm, isNot(equals(cool)));
      expect(warm, isNot(equals(flat)));
      expect(cool, isNot(equals(flat)));
      expect(warm, isNot(equals(fallback)));
      expect(cool, isNot(equals(fallback)));
      expect(flat, isNot(equals(fallback)));
    },
  );

  test('names every palette', () {
    for (final id in NesPaletteId.values) {
      expect(id.displayName, isNotEmpty, reason: id.name);
    }
  });

  test('bundled assets keep NES color and emphasis-row ordering', () async {
    final library = PaletteLibrary();

    await library.ready;

    const bundledIds = [
      NesPaletteId.warm,
      NesPaletteId.cool,
      NesPaletteId.flat,
    ];

    for (final id in bundledIds) {
      final palette = library.resolve(id, const NtscPaletteSettings());

      final white = palette[0x20];
      final black = palette[0x0f];

      expect(_red(white), greaterThanOrEqualTo(235), reason: id.name);
      expect(_green(white), greaterThanOrEqualTo(235), reason: id.name);
      expect(_blue(white), greaterThanOrEqualTo(235), reason: id.name);

      expect(_red(black), lessThanOrEqualTo(20), reason: id.name);
      expect(_green(black), lessThanOrEqualTo(20), reason: id.name);
      expect(_blue(black), lessThanOrEqualTo(20), reason: id.name);

      final emphasised = palette[(1 << 6) | 0x20];

      final redRatio = _red(emphasised) / _red(white);
      final greenRatio = _green(emphasised) / _green(white);

      expect(redRatio, greaterThan(greenRatio), reason: id.name);
    }
  });

  test('paletteLibraryProvider waits for the library to be ready before '
      'resolving, and hands back the real bundled data', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    final completer = Completer<ByteData?>();

    messenger.setMockMessageHandler('flutter/assets', (_) => completer.future);

    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));

    final container = ProviderContainer();

    addTearDown(container.dispose);

    var resolved = false;

    final future = container.read(paletteLibraryProvider.future).then((
      library,
    ) {
      resolved = true;

      return library;
    });

    await Future<void>.delayed(Duration.zero);

    expect(
      resolved,
      isFalse,
      reason: 'paletteLibraryProvider must wait for the library to load',
    );

    final bytes = File('assets/palettes/warm.pal').readAsBytesSync();

    completer.complete(ByteData.sublistView(bytes));

    final library = await future;

    final warm = library.resolve(
      NesPaletteId.warm,
      const NtscPaletteSettings(),
    );

    expect(warm, isNot(equals(expandRgbToPalette(defaultPaletteRgb))));
  });
}

int _red(int packedColor) => packedColor & 0xff;

int _green(int packedColor) => (packedColor >> 8) & 0xff;

int _blue(int packedColor) => (packedColor >> 16) & 0xff;
