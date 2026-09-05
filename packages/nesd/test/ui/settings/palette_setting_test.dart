import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/ntsc_palette_settings.dart';
import 'package:nesd/nes/ppu/palette/palette_selection.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('a user palette selection survives a JSON round trip', () {
    final settings = Settings(
      paletteId: NesPaletteId.user,
      userPalette: 'Composite',
    );

    final decoded = Settings.fromJson(settings.toJson());

    expect(decoded.paletteId, equals(NesPaletteId.user));
    expect(decoded.userPalette, equals('Composite'));
  });

  test('settings stored before user palettes still load', () {
    final legacy = Settings().toJson()..remove('userPalette');

    expect(Settings.fromJson(legacy).userPalette, isNull);
  });

  test('paletteSelection maps a built-in id', () {
    expect(
      Settings(paletteId: NesPaletteId.warm).paletteSelection,
      equals(const BuiltInPaletteSelection(NesPaletteId.warm)),
    );
  });

  test('paletteSelection maps a user palette by name', () {
    expect(
      Settings(
        paletteId: NesPaletteId.user,
        userPalette: 'Foo',
      ).paletteSelection,
      equals(const UserPaletteSelection('Foo')),
    );
  });

  test('a user selection without a name falls back to the default', () {
    expect(
      Settings(paletteId: NesPaletteId.user).paletteSelection,
      equals(PaletteSelection.defaultSelection),
    );
  });

  test('selecting a user palette writes both fields and selecting a '
      'built-in clears the name', () async {
    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );

    addTearDown(container.dispose);

    container.listen(settingsControllerProvider, (_, _) {});

    final controller = container.read(settingsControllerProvider.notifier);

    // ignore: cascade_invocations
    controller.paletteSelection = const UserPaletteSelection('Foo');

    expect(controller.paletteId, equals(NesPaletteId.user));
    expect(
      container.read(settingsControllerProvider).userPalette,
      equals('Foo'),
    );
    expect(
      controller.paletteSelection,
      equals(const UserPaletteSelection('Foo')),
    );

    controller.paletteSelection = const BuiltInPaletteSelection(
      NesPaletteId.cool,
    );

    expect(controller.paletteId, equals(NesPaletteId.cool));
    expect(container.read(settingsControllerProvider).userPalette, isNull);
  });
}
