import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
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

/// Minimal battery-backed NROM with an idle loop and vectors at $c000.
Uint8List _batteryRom() {
  return Uint8List(16 + 0x4000 + 0x2000)
    ..setAll(0, [0x4e, 0x45, 0x53, 0x1a, 1, 1, 0x02, 0])
    ..setAll(16, [0x4c, 0x00, 0xc0])
    ..setAll(16 + 0x3ffa, [0x00, 0xc0, 0x00, 0xc0, 0x00, 0xc0]);
}

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
    registerFallbackValue(Toast.info('fallback'));
    registerFallbackValue(Uint8List(0));
  });

  late ProviderContainer container;
  late _MockRomManager romManager;
  late _MockToaster toaster;
  late NesController controller;

  setUp(() async {
    container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(nesStateProvider, (_, _) {});

    final settings = _MockSettingsController();

    when(() => settings.cheats).thenReturn(const {});
    when(() => settings.breakpoints).thenReturn(const {});
    when(() => settings.region).thenReturn(null);
    when(() => settings.rewind).thenReturn(false);
    when(() => settings.volume).thenReturn(1.0);
    when(() => settings.lowPassFilter).thenReturn(false);
    when(() => settings.autoSave).thenReturn(false);
    when(() => settings.autoSaveInterval).thenReturn(5);
    when(() => settings.autoLoad).thenReturn(false);
    when(() => settings.logLevel).thenReturn(LogLevel.info);
    when(() => settings.addRecentRom(any())).thenAnswer((_) {});

    romManager = _MockRomManager();
    toaster = _MockToaster();

    when(() => romManager.load(any())).thenAnswer((_) async => null);

    final database = MockNesDatabase();
    final handle = FakeNesIsolateHandle();

    addTearDown(handle.dispose);

    controller = NesController(
      nesState: container.read(nesStateProvider.notifier),
      spawner: () async => handle,
      router: Router(),
      settingsController: settings,
      toaster: toaster,
      romManager: romManager,
      filesystem: MockFileSystem(),
      database: database,
      cartridgeFactory: CartridgeFactory(database: database),
      romImporter: FakeRomImporter(),
    );

    final loaded = await controller.loadRom(
      const FilesystemFile(
        path: '/test/roms/battery.nes',
        name: 'battery.nes',
        type: FilesystemFileType.file,
      ),
      data: _batteryRom(),
    );

    expect(loaded, isTrue);

    // Registered after container.dispose above, so it runs first (LIFO)
    // and no worker is left running behind a disposed container.
    addTearDown(() async {
      if (container.read(nesStateProvider) != null) {
        when(() => romManager.save(any(), any())).thenAnswer((_) async {});
        when(
          () => romManager.saveThumbnail(
            any(),
            width: any(named: 'width'),
            height: any(named: 'height'),
            pixels: any(named: 'pixels'),
          ),
        ).thenAnswer((_) async {});

        await controller.stop();
      }
    });
  });

  Iterable<Toast> sentToasts() =>
      verify(() => toaster.send(captureAny())).captured.whereType<Toast>();

  test('stop() with a failing save still tears the emulator down', () async {
    when(
      () => romManager.save(any(), any()),
    ).thenThrow(NesdException('quota exceeded'));

    await controller.stop();

    expect(container.read(nesStateProvider), isNull);
    expect(
      sentToasts().where(
        (t) =>
            t.type == ToastType.error && t.message.contains('Failed to save'),
      ),
      isNotEmpty,
    );
  });

  test('saveState surfaces storage failures as a toast', () async {
    when(
      () => romManager.saveState(any(), any(), any()),
    ).thenThrow(NesdException('quota exceeded'));

    await controller.saveState(1);

    expect(
      sentToasts().where(
        (t) =>
            t.type == ToastType.error &&
            t.message.contains('Failed to save state'),
      ),
      isNotEmpty,
    );
  });

  test('loadState surfaces storage failures as a toast', () async {
    when(
      () => romManager.loadState(any(), any()),
    ).thenThrow(NesdException('backend gone'));

    await controller.loadState(1);

    expect(
      sentToasts().where(
        (t) =>
            t.type == ToastType.error &&
            t.message.contains('Failed to load state'),
      ),
      isNotEmpty,
    );
  });

  test('reset still resets when the SRAM read fails', () async {
    when(() => romManager.load(any())).thenThrow(NesdException('backend gone'));

    await controller.reset();

    expect(
      sentToasts().where(
        (t) =>
            t.type == ToastType.error &&
            t.message.contains('Failed to load SRAM'),
      ),
      isNotEmpty,
    );
  });
}
