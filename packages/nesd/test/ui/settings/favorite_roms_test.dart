import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_sort_order.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

const _romHash = 'a1b2c3d4e5f60718293a4b5c6d7e8f9012345678';
const _otherRomHash = '0f1e2d3c4b5a69788796a5b4c3d2e1f001234567';

RomInfo _rom({String path = '/roms/game.nes', String? romHash = _romHash}) =>
    RomInfo(
      file: FilesystemFile(
        path: path,
        name: path.split('/').last,
        type: FilesystemFileType.file,
      ),
      romHash: romHash,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late SettingsController controller;
  late List<String> writes;

  setUp(() {
    final prefs = _MockSharedPreferences();

    writes = [];

    when(() => prefs.getString(any())).thenReturn('{}');
    when(() => prefs.setString(any(), any())).thenAnswer((invocation) async {
      writes.add(invocation.positionalArguments[1] as String);

      return true;
    });

    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    )..listen(settingsControllerProvider, (_, _) {});

    controller = container.read(settingsControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('a starred game is a favorite, newest first', () {
    final other = _rom(path: '/roms/other.nes', romHash: _otherRomHash);

    controller
      ..addFavorite(_rom())
      ..addFavorite(other);

    expect(controller.favoriteRoms, [other, _rom()]);
    expect(controller.isFavorite(_rom(path: '/elsewhere/renamed.nes')), isTrue);
  });

  test('a game that was never starred is not a favorite', () {
    controller.addFavorite(_rom());

    expect(
      controller.isFavorite(_rom(path: '/roms/b.nes', romHash: _otherRomHash)),
      isFalse,
    );
  });

  test('starring the same game twice keeps one entry', () {
    controller
      ..addFavorite(_rom())
      ..addFavorite(_rom(path: '/roms/copy.nes'));

    expect(controller.favoriteRoms, hasLength(1));
  });

  test('unstarring removes the game', () {
    controller
      ..addFavorite(_rom())
      ..removeFavorite(_rom(path: '/roms/copy.nes'));

    expect(controller.favoriteRoms, isEmpty);
  });

  test('launching a favorite from a new path updates its path in place', () {
    final other = _rom(path: '/roms/other.nes', romHash: _otherRomHash);

    controller
      ..addFavorite(_rom())
      ..addFavorite(other)
      ..addRecentRom(_rom(path: '/moved/game.nes'));

    expect(
      [for (final rom in controller.favoriteRoms) rom.file.path],
      ['/roms/other.nes', '/moved/game.nes'],
    );
  });

  test('the sort order defaults to name ascending', () {
    expect(controller.fileSortOrder, FileSortOrder.nameAscending);
  });

  test('favorites and the sort order are written to storage', () {
    controller
      ..addFavorite(_rom())
      ..fileSortOrder = FileSortOrder.modifiedNewest;

    final saved = Settings.fromJson(
      jsonDecode(writes.last) as Map<String, dynamic>,
    );

    expect(saved.favoriteRoms, [_rom()]);
    expect(saved.fileSortOrder, FileSortOrder.modifiedNewest);
  });
}
