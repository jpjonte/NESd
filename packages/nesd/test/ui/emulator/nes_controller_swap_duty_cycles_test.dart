import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/apu/mixer_settings.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/turbo_speed.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../mocks.dart';

class _MockSettingsController extends Mock implements SettingsController {}

class _MockToaster extends Mock implements Toaster {}

class _MockRomManager extends Mock implements RomManager {}

class _MockFilesystem extends Mock implements Filesystem {}

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
  });

  Future<FakeNesIsolateHandle> loadWith({required bool swapDutyCycles}) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(nesStateProvider, (_, _) {});

    final settings = _MockSettingsController();

    when(() => settings.cheats).thenReturn(const {});
    when(() => settings.breakpoints).thenReturn(const {});
    when(() => settings.region).thenReturn(null);
    when(() => settings.rewind).thenReturn(false);
    when(() => settings.volume).thenReturn(1.0);
    when(() => settings.lowPassFilter).thenReturn(false);
    when(() => settings.swapDutyCycles).thenReturn(swapDutyCycles);
    when(() => settings.mixer).thenReturn(const MixerSettings());
    when(() => settings.fastForwardSpeed).thenReturn(FastForwardSpeed.x2);
    when(() => settings.autoSave).thenReturn(false);
    when(() => settings.autoSaveInterval).thenReturn(5);
    when(() => settings.autoLoad).thenReturn(false);
    when(() => settings.logLevel).thenReturn(LogLevel.info);
    when(() => settings.turboSpeed).thenReturn(TurboSpeed.x1);

    final romManager = _MockRomManager();

    when(() => romManager.load(any())).thenAnswer((_) async => null);

    final database = MockNesDatabase();

    final handle = FakeNesIsolateHandle();
    addTearDown(handle.dispose);

    final controller = NesController(
      nesState: container.read(nesStateProvider.notifier),
      spawner: () async => handle,
      router: Router(),
      settingsController: settings,
      toaster: _MockToaster(),
      romManager: romManager,
      filesystem: _MockFilesystem(),
      database: database,
      cartridgeFactory: CartridgeFactory(database: database),
      romImporter: FakeRomImporter(),
    );

    const file = FilesystemFile(
      path: '/test/test.nes',
      name: 'test.nes',
      type: FilesystemFileType.file,
    );

    final loaded = await controller.loadRom(file, data: minimalValidRom());

    expect(loaded, isTrue);

    return handle;
  }

  test('loadRom sends the enabled duty cycle swap to the worker', () async {
    final handle = await loadWith(swapDutyCycles: true);

    final sent = handle.sentCommands
        .whereType<SetSwapDutyCyclesCommand>()
        .single;

    expect(sent.enabled, isTrue);
  });

  test('loadRom sends the disabled duty cycle swap to the worker', () async {
    final handle = await loadWith(swapDutyCycles: false);

    final sent = handle.sentCommands
        .whereType<SetSwapDutyCyclesCommand>()
        .single;

    expect(sent.enabled, isFalse);
  });

  test('loadRom sends the system palette to the worker', () async {
    final handle = await loadWith(swapDutyCycles: false);

    final sent = handle.sentCommands.whereType<SetPaletteCommand>().single;

    expect(sent.palette, equals(expandRgbToPalette(defaultPaletteRgb)));
  });
}
