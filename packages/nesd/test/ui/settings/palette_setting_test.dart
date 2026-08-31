import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/ntsc_palette_settings.dart';
import 'package:nesd/ui/settings/settings.dart';

void main() {
  test('palette defaults to the built-in palette', () {
    expect(Settings().paletteId, equals(NesPaletteId.defaultPalette));
    expect(
      Settings.fromJson({}).paletteId,
      equals(NesPaletteId.defaultPalette),
    );
  });

  test('ntsc palette settings default sensibly', () {
    expect(Settings().ntscPalette, equals(const NtscPaletteSettings()));
    expect(
      Settings.fromJson({}).ntscPalette,
      equals(const NtscPaletteSettings()),
    );
  });

  test('palette selection survives a JSON round trip', () {
    final settings = Settings(paletteId: NesPaletteId.generated);

    expect(
      Settings.fromJson(settings.toJson()).paletteId,
      equals(NesPaletteId.generated),
    );
  });

  test('ntsc palette settings survive a JSON round trip', () {
    final settings = Settings(
      ntscPalette: const NtscPaletteSettings(hue: 0.5, gamma: 2.0),
    );

    final decoded = Settings.fromJson(settings.toJson());

    expect(decoded.ntscPalette.hue, equals(0.5));
    expect(decoded.ntscPalette.gamma, equals(2.0));
  });

  test('settings stored before this feature still load', () {
    final legacy = Settings().toJson()
      ..remove('paletteId')
      ..remove('ntscPalette');

    final decoded = Settings.fromJson(legacy);

    expect(decoded.paletteId, equals(NesPaletteId.defaultPalette));
    expect(decoded.ntscPalette, equals(const NtscPaletteSettings()));
  });
}
