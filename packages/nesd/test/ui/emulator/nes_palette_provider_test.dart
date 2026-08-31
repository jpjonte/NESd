import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/palette_library.dart';
import 'package:nesd/ui/emulator/nes_palette_provider.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('nesPalette re-resolves the real Warm palette once the library '
      'finishes loading, instead of staying on the default it falls back '
      'to while loading', () async {
    final prefs = _MockSharedPreferences();

    when(() => prefs.getString(any())).thenReturn(null);
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);

    final libraryCompleter = Completer<PaletteLibrary>();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        paletteLibraryProvider.overrideWith((ref) => libraryCompleter.future),
      ],
    );

    addTearDown(container.dispose);

    container.read(settingsControllerProvider.notifier).paletteId =
        NesPaletteId.warm;

    final values = <Uint32List>[];
    final rebuilt = Completer<Uint32List>();

    container.listen(nesPaletteProvider, (_, next) {
      values.add(next);

      if (values.length == 2 && !rebuilt.isCompleted) {
        rebuilt.complete(next);
      }
    }, fireImmediately: true);

    final defaultPalette = expandRgbToPalette(defaultPaletteRgb);

    expect(values.single, equals(defaultPalette));

    final realLibrary = PaletteLibrary();

    await realLibrary.ready;

    libraryCompleter.complete(realLibrary);

    final resolved = await rebuilt.future.timeout(const Duration(seconds: 5));

    expect(resolved, isNot(equals(defaultPalette)));
  });
}
