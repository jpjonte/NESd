import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/palette_library.dart';
import 'package:nesd/nes/ppu/palette/palette_selection.dart';
import 'package:nesd/ui/emulator/nes_palette_provider.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/emulator/user_palettes.dart';
import 'package:nesd/ui/file_picker/file_system/memory_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pal_file.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

ProviderContainer _container({List<Override> overrides = const []}) {
  final prefs = _MockSharedPreferences();

  when(() => prefs.getString(any())).thenReturn(null);
  when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      storageFilesystemProvider.overrideWithValue(MemoryStorageFilesystem()),
      applicationSupportPathProvider.overrideWithValue('/app'),
      ...overrides,
    ],
  );

  addTearDown(container.dispose);

  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fallback = expandRgbToPalette(defaultPaletteRgb);

  test('nesPalette re-resolves the real Warm palette once the library '
      'finishes loading, instead of staying on the default it falls back '
      'to while loading', () async {
    final libraryCompleter = Completer<PaletteLibrary>();

    final container = _container(
      overrides: [
        paletteLibraryProvider.overrideWith((ref) => libraryCompleter.future),
      ],
    );

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

    expect(values.single, equals(fallback));

    final realLibrary = PaletteLibrary();

    await realLibrary.ready;

    libraryCompleter.complete(realLibrary);

    final resolved = await rebuilt.future.timeout(const Duration(seconds: 5));

    expect(resolved, isNot(equals(fallback)));
  });

  test('a user selection resolves to the imported palette', () async {
    final container = _container();

    // ignore: cascade_invocations
    container.listen(nesPaletteProvider, (_, _) {});

    await container
        .read(userPalettesProvider.notifier)
        .import('Grey', greyPalFile(0x40));

    container.read(settingsControllerProvider.notifier).paletteSelection =
        const UserPaletteSelection('Grey');

    final palette = container.read(nesPaletteProvider);

    expect(palette[0], equals(packPaletteColor(0x40, 0x40, 0x40)));
  });

  test('a user selection that is not loaded resolves to the default', () async {
    final container = _container();

    // ignore: cascade_invocations
    container.listen(nesPaletteProvider, (_, _) {});

    await container.read(userPalettesProvider.future);

    container.read(settingsControllerProvider.notifier).paletteSelection =
        const UserPaletteSelection('Nope');

    expect(container.read(nesPaletteProvider), equals(fallback));
  });

  test('a user selection resolves to the default while the user palettes '
      'are still loading', () {
    final loading = Completer<Map<String, Uint32List>>();

    final container = _container(
      overrides: [
        userPalettesProvider.overrideWith(() => _StuckUserPalettes(loading)),
      ],
    );

    // ignore: cascade_invocations
    container.listen(nesPaletteProvider, (_, _) {});

    container.read(settingsControllerProvider.notifier).paletteSelection =
        const UserPaletteSelection('Grey');

    expect(container.read(nesPaletteProvider), equals(fallback));

    loading.complete({});
  });
}

class _StuckUserPalettes extends UserPalettes {
  _StuckUserPalettes(this.loading);

  final Completer<Map<String, Uint32List>> loading;

  @override
  Future<Map<String, Uint32List>> build() => loading.future;
}
