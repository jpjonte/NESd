import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../mocks.dart';

class _MockSettingsController extends Mock implements SettingsController {}

class _MockToaster extends Mock implements Toaster {}

class _MockRomManager extends Mock implements RomManager {}

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

  test(
    'a ROM loaded while the emulator is not active starts suspended',
    () async {
      final container = ProviderContainer();

      addTearDown(container.dispose);

      container.listen(nesStateProvider, (_, _) {});

      final settings = _MockSettingsController();

      when(() => settings.cheats).thenReturn(const {});
      when(() => settings.breakpoints).thenReturn(const {});
      when(() => settings.region).thenReturn(null);
      when(() => settings.rewind).thenReturn(false);
      when(() => settings.volume).thenReturn(1.0);
      when(() => settings.autoSave).thenReturn(false);
      when(() => settings.autoSaveInterval).thenReturn(5);
      when(() => settings.autoLoad).thenReturn(false);

      final romManager = _MockRomManager();

      when(() => romManager.load(any())).thenReturn(null);
      when(() => romManager.save(any(), any())).thenAnswer((_) async {});
      when(
        () => romManager.saveThumbnail(
          any(),
          width: any(named: 'width'),
          height: any(named: 'height'),
          pixels: any(named: 'pixels'),
        ),
      ).thenAnswer((_) async {});

      final database = MockNesDatabase();

      final handle = FakeNesIsolateHandle();

      addTearDown(handle.dispose);

      final filesystem = MockFileSystem()
        ..addFile(
          '/test/roms/nestest.nes',
          File('../../roms/test/nestest/nestest.nes').readAsBytesSync(),
        );

      final controller =
          NesController(
              nesState: container.read(nesStateProvider.notifier),
              spawner: () async => handle,
              router: Router(),
              settingsController: settings,
              toaster: _MockToaster(),
              romManager: romManager,
              filesystem: filesystem,
              database: database,
              cartridgeFactory: CartridgeFactory(database: database),
            )
            // The emulator screen is not on top. E.g. the ROM is still loading
            // while the user is looking at the file picker.
            ..emulatorActive = false;

      final loaded = await controller.loadRom(
        const FilesystemFile(
          path: '/test/roms/nestest.nes',
          name: 'nestest.nes',
          type: FilesystemFileType.file,
        ),
      );

      expect(loaded, isTrue);

      final loadIndex = handle.sentCommands.indexWhere(
        (c) => c is LoadRomCommand,
      );
      final suspendIndex = handle.sentCommands.indexWhere(
        (c) => c is SuspendCommand,
      );

      expect(loadIndex, isNonNegative);
      expect(
        suspendIndex,
        greaterThan(loadIndex),
        reason: 'the newly created NES must be suspended after it is loaded',
      );

      await controller.stop();
    },
  );

  test('a ROM loaded while the emulator is active starts resumed', () async {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    container.listen(nesStateProvider, (_, _) {});

    final settings = _MockSettingsController();

    when(() => settings.cheats).thenReturn(const {});
    when(() => settings.breakpoints).thenReturn(const {});
    when(() => settings.region).thenReturn(null);
    when(() => settings.rewind).thenReturn(false);
    when(() => settings.volume).thenReturn(1.0);
    when(() => settings.autoSave).thenReturn(false);
    when(() => settings.autoSaveInterval).thenReturn(5);
    when(() => settings.autoLoad).thenReturn(false);

    final romManager = _MockRomManager();

    when(() => romManager.load(any())).thenReturn(null);
    when(() => romManager.save(any(), any())).thenAnswer((_) async {});
    when(
      () => romManager.saveThumbnail(
        any(),
        width: any(named: 'width'),
        height: any(named: 'height'),
        pixels: any(named: 'pixels'),
      ),
    ).thenAnswer((_) async {});

    final database = MockNesDatabase();

    final handle = FakeNesIsolateHandle();

    addTearDown(handle.dispose);

    final filesystem = MockFileSystem()
      ..addFile(
        '/test/roms/nestest.nes',
        File('../../roms/test/nestest/nestest.nes').readAsBytesSync(),
      );

    final controller =
        NesController(
            nesState: container.read(nesStateProvider.notifier),
            spawner: () async => handle,
            router: Router(),
            settingsController: settings,
            toaster: _MockToaster(),
            romManager: romManager,
            filesystem: filesystem,
            database: database,
            cartridgeFactory: CartridgeFactory(database: database),
          )
          // The emulator screen is on top. E.g. the ROM was picked from
          // "File -> Open..." while the emulator route was already active.
          ..emulatorActive = true;

    final loaded = await controller.loadRom(
      const FilesystemFile(
        path: '/test/roms/nestest.nes',
        name: 'nestest.nes',
        type: FilesystemFileType.file,
      ),
    );

    expect(loaded, isTrue);

    final loadIndex = handle.sentCommands.indexWhere(
      (c) => c is LoadRomCommand,
    );
    final resumeIndex = handle.sentCommands.indexWhere(
      (c) => c is ResumeCommand,
    );

    expect(loadIndex, isNonNegative);
    expect(
      resumeIndex,
      greaterThan(loadIndex),
      reason: 'the newly created NES must be resumed after it is loaded',
    );

    await controller.stop();
  });
}
