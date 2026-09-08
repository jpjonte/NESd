import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Router;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/apu/mixer_settings.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/turbo_speed.dart';
import 'package:nesd/ui/app_controller.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

import 'mocks.dart';

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

Future<void> _setLifecycleState(AppLifecycleState state) async {
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'flutter/lifecycle',
        const StringCodec().encodeMessage(state.toString()),
        (_) {},
      );
}

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
  late FakeNesIsolateHandle handle;
  late NesController nesController;
  late AppController controller;

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

    when(() => romManager.load(any())).thenAnswer((_) async => null);
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

    handle = FakeNesIsolateHandle();

    addTearDown(handle.dispose);

    nesController = NesController(
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

    addTearDown(nesController.dispose);

    controller = AppController(nesController: nesController);

    addTearDown(controller.dispose);

    final loaded = await nesController.loadRom(_romFile, data: _batteryRom());

    expect(loaded, isTrue);

    addTearDown(() async {
      if (container.read(nesStateProvider) != null) {
        await nesController.stop();
      }
    });
  });

  test('losing focus suspends the emulator', () async {
    await _setLifecycleState(AppLifecycleState.resumed);

    handle.sentCommands.clear();

    await _setLifecycleState(AppLifecycleState.inactive);

    expect(handle.sentCommands, contains(isA<SuspendCommand>()));
  });

  test('losing focus leaves the emulator alone with suspending off', () async {
    controller.suspendWhenHidden = false;

    await _setLifecycleState(AppLifecycleState.resumed);

    handle.sentCommands.clear();

    await _setLifecycleState(AppLifecycleState.inactive);

    expect(handle.sentCommands, isNot(contains(isA<SuspendCommand>())));
  });
}
