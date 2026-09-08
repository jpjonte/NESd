import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

const _romHash = 'a1b2c3d4e5f60718293a4b5c6d7e8f9012345678';
const _otherRomHash = '0f1e2d3c4b5a69788796a5b4c3d2e1f001234567';

RomInfo _rom({
  String path = '/roms/game.nes',
  String name = 'game.nes',
  String? romHash = _romHash,
}) => RomInfo(
  file: FilesystemFile(path: path, name: name, type: FilesystemFileType.file),
  romHash: romHash,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late SettingsController controller;

  setUp(() {
    final prefs = _MockSharedPreferences();

    when(() => prefs.getString(any())).thenReturn('{}');
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);

    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    )..listen(settingsControllerProvider, (_, _) {});

    controller = container.read(settingsControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('two games sharing a file name both stay in the list', () {
    final usa = _rom(path: '/roms/usa/game.nes');
    final japan = _rom(path: '/roms/jp/game.nes', romHash: _otherRomHash);

    controller
      ..addRecentRom(usa)
      ..addRecentRom(japan);

    expect(controller.recentRoms, [japan, usa]);
  });

  test('the same game under a new name replaces the old entry', () {
    controller
      ..addRecentRom(_rom())
      ..addRecentRom(_rom(path: '/roms/The Game (USA).nes', name: 'The Game'));

    expect(controller.recentRoms, hasLength(1));
    expect(controller.recentRoms.single.file.name, 'The Game');
  });

  test('a legacy entry without a hash is replaced by the hashed one', () {
    controller
      ..addRecentRom(_rom(romHash: null))
      ..addRecentRom(_rom());

    expect(controller.recentRoms, hasLength(1));
    expect(controller.recentRoms.single.romHash, _romHash);
  });

  test('re-adding a game moves it back to the front', () {
    final other = _rom(path: '/roms/other.nes', romHash: _otherRomHash);

    controller
      ..addRecentRom(_rom())
      ..addRecentRom(other)
      ..addRecentRom(_rom());

    expect(controller.recentRoms, [_rom(), other]);
  });

  test('removing a game leaves the one sharing its name alone', () {
    final usa = _rom(path: '/roms/usa/game.nes');
    final japan = _rom(path: '/roms/jp/game.nes', romHash: _otherRomHash);

    controller
      ..addRecentRom(usa)
      ..addRecentRom(japan)
      ..removeRecentRom(usa);

    expect(controller.recentRoms, [japan]);
  });

  test('a renamed game is removed by its content hash', () {
    controller
      ..addRecentRom(_rom())
      ..removeRecentRom(_rom(path: '/elsewhere/renamed.nes', name: 'x.nes'));

    expect(controller.recentRoms, isEmpty);
  });
}
