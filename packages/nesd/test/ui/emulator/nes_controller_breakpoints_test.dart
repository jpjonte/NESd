import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks.dart';

class _MockToaster extends Mock implements Toaster {}

class _MockRomManager extends Mock implements RomManager {}

class _MockSharedPreferences extends Mock implements SharedPreferences {}

const _romPath = '/test/roms/nestest.nes';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      const RomInfo(
        file: FilesystemFile(
          path: '/x',
          name: 'x',
          type: FilesystemFileType.file,
        ),
      ),
    );
    registerFallbackValue(Uint8List(0));
  });

  late Uint8List rom;
  late String fileHash;
  late String romHash;
  late ProviderContainer container;
  late SettingsController settings;
  late FakeNesIsolateHandle handle;
  late NesController controller;

  setUp(() {
    rom = File('../../roms/test/nestest/nestest.nes').readAsBytesSync();
    fileHash = sha1.convert(rom).toString();
    romHash = sha1.convert(rom.sublist(16)).toString();

    final prefs = _MockSharedPreferences();

    when(() => prefs.getString(any())).thenReturn('{}');
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);

    container =
        ProviderContainer(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          )
          ..listen(settingsControllerProvider, (_, _) {})
          ..listen(nesStateProvider, (_, _) {});

    settings = container.read(settingsControllerProvider.notifier);

    handle = FakeNesIsolateHandle();

    final romManager = _MockRomManager();

    when(() => romManager.load(any())).thenAnswer((_) async => null);
    when(() => romManager.save(any(), any())).thenAnswer((_) async {});
    when(() => romManager.loadLatestState(any())).thenAnswer((_) async => null);

    final database = NesDatabase();

    controller = NesController(
      nesState: container.read(nesStateProvider.notifier),
      spawner: () async => handle,
      router: Router(),
      settingsController: settings,
      toaster: _MockToaster(),
      romManager: romManager,
      filesystem: MockFileSystem()..addFile(_romPath, rom),
      database: database,
      cartridgeFactory: CartridgeFactory(database: database),
      romImporter: FakeRomImporter(),
    );

    addTearDown(() {
      handle.dispose();
      container.dispose();
    });
  });

  Future<bool> loadRom() => controller.loadRom(
    const FilesystemFile(
      path: _romPath,
      name: 'nestest.nes',
      type: FilesystemFileType.file,
    ),
  );

  test('breakpoints stored under the old file hash follow the ROM', () async {
    final breakpoints = [Breakpoint(0x8000)];

    settings.setBreakpoints(fileHash, breakpoints);

    expect(await loadRom(), isTrue);

    expect(settings.breakpoints[romHash], breakpoints);
    expect(settings.breakpoints.containsKey(fileHash), isFalse);
  });

  test('breakpoints already keyed by content hash are left alone', () async {
    final breakpoints = [Breakpoint(0xc000)];

    settings.setBreakpoints(romHash, breakpoints);

    expect(await loadRom(), isTrue);

    expect(settings.breakpoints[romHash], breakpoints);
  });

  test('a ROM with no stored breakpoints adds no key', () async {
    expect(await loadRom(), isTrue);

    expect(settings.breakpoints, isEmpty);
  });
}
