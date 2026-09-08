import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/apu/mixer_settings.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/nes/turbo_speed.dart';
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

Uint8List _batteryRom() {
  return Uint8List(16 + 0x4000 + 0x2000)
    ..setAll(0, [0x4e, 0x45, 0x53, 0x1a, 1, 1, 0x02, 0])
    ..setAll(16, [0x4c, 0x00, 0xc0])
    ..setAll(16 + 0x3ffa, [0x00, 0xc0, 0x00, 0xc0, 0x00, 0xc0]);
}

const _romFile = FilesystemFile(
  path: '/test/roms/battery.nes',
  name: 'battery.nes',
  type: FilesystemFileType.file,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const RomInfo(file: _romFile));
    registerFallbackValue(Toast.info('fallback'));
    registerFallbackValue(Uint8List(0));
  });

  late ProviderContainer container;
  late _MockSettingsController settings;
  late _MockRomManager romManager;
  late _MockToaster toaster;
  late NesController controller;

  late List<String> events;

  setUp(() async {
    container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(nesStateProvider, (_, _) {});

    settings = _MockSettingsController();

    when(() => settings.cheats).thenReturn(const {});
    when(() => settings.breakpoints).thenReturn(const {});
    when(() => settings.region).thenReturn(null);
    when(() => settings.rewind).thenReturn(false);
    when(() => settings.volume).thenReturn(1.0);
    when(() => settings.lowPassFilter).thenReturn(false);
    when(() => settings.swapDutyCycles).thenReturn(false);
    when(() => settings.mixer).thenReturn(const MixerSettings());
    when(() => settings.fastForwardSpeed).thenReturn(FastForwardSpeed.x2);
    when(() => settings.turboSpeed).thenReturn(TurboSpeed.x1);
    when(() => settings.autoSave).thenReturn(true);
    when(() => settings.autoSaveInterval).thenReturn(60);
    when(() => settings.autoLoad).thenReturn(false);
    when(() => settings.logLevel).thenReturn(LogLevel.info);
    when(() => settings.addRecentRom(any())).thenAnswer((_) {});

    romManager = _MockRomManager();
    toaster = _MockToaster();

    events = [];

    when(() => romManager.load(any())).thenAnswer((_) async => null);
    when(() => romManager.save(any(), any())).thenAnswer((_) async {
      events.add('sram');
    });
    when(() => romManager.saveState(any(), any(), any())).thenAnswer((_) async {
      events.add('state');
    });
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

    addTearDown(controller.dispose);

    final loaded = await controller.loadRom(_romFile, data: _batteryRom());

    expect(loaded, isTrue);

    addTearDown(() async {
      if (container.read(nesStateProvider) != null) {
        await controller.stop();
      }
    });
  });

  List<int> savedStateSlots() => verify(
    () => romManager.saveState(any(), captureAny(), any()),
  ).captured.cast<int>();

  test('quitting a game writes the auto save state', () async {
    await controller.stop();

    expect(savedStateSlots(), [0]);
  });

  test('quitting a game writes no state with auto save off', () async {
    when(() => settings.autoSave).thenReturn(false);

    await controller.stop();

    verifyNever(() => romManager.saveState(any(), any(), any()));
  });

  test('the save runs even though the emulator is suspended', () async {
    expect(container.read(nesStateProvider)!.running, isFalse);

    await controller.stop();

    expect(savedStateSlots(), [0]);
  });

  test('switching to another ROM saves the outgoing game', () async {
    final loaded = await controller.loadRom(
      const FilesystemFile(
        path: '/test/roms/other.nes',
        name: 'other.nes',
        type: FilesystemFileType.file,
      ),
      data: _batteryRom(),
    );

    expect(loaded, isTrue);

    final captured = verify(
      () => romManager.saveState(captureAny(), captureAny(), any()),
    ).captured;

    expect(captured, hasLength(2));
    expect((captured[0] as RomInfo).file.name, 'battery.nes');
    expect(captured[1], autoSaveSlot);
  });
}
