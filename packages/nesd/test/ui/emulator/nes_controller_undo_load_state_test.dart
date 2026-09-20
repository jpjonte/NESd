import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/apu/mixer_settings.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
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
  late FakeNesIsolateHandle handle;
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
    when(() => settings.swapDutyCycles).thenReturn(false);
    when(() => settings.oamCorruption).thenReturn(true);
    when(() => settings.mixer).thenReturn(const MixerSettings());
    when(() => settings.fastForwardSpeed).thenReturn(FastForwardSpeed.x2);
    when(() => settings.turboSpeed).thenReturn(TurboSpeed.x1);
    when(() => settings.autoSave).thenReturn(false);
    when(() => settings.autoSaveInterval).thenReturn(5);
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

    addTearDown(() async {
      if (container.read(nesStateProvider) != null) {
        await controller.stop();
      }
    });
  });

  Iterable<Toast> sentToasts() =>
      verify(() => toaster.send(captureAny())).captured.whereType<Toast>();

  Future<void> waitUntil(bool Function() condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));

    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out waiting for the emulator status');
      }

      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> saveAndLoadSlot1() async {
    late Uint8List saved;

    when(() => romManager.saveState(any(), any(), any())).thenAnswer((
      invocation,
    ) async {
      saved = invocation.positionalArguments[2] as Uint8List;
    });

    await controller.saveState(1);

    when(
      () => romManager.loadState(any(), any()),
    ).thenAnswer((_) async => saved);

    await controller.loadState(1);

    await waitUntil(() => controller.nes!.canUndoLoadState);
  }

  test('undo without a preceding load warns and sends no command', () async {
    controller.undoLoadState();

    expect(handle.sentCommands.whereType<UndoLoadStateCommand>(), isEmpty);
    expect(
      sentToasts().where(
        (t) => t.type == ToastType.warning && t.message == 'Nothing to undo',
      ),
      isNotEmpty,
    );
  });

  test('undo after a load sends the command and toasts', () async {
    await saveAndLoadSlot1();

    controller.undoLoadState();

    expect(handle.sentCommands.whereType<UndoLoadStateCommand>(), hasLength(1));
    expect(
      sentToasts().where(
        (t) => t.type == ToastType.info && t.message == 'Load state undone',
      ),
      isNotEmpty,
    );
  });

  test('a reset clears the undo offer', () async {
    await saveAndLoadSlot1();

    await controller.reset();

    await waitUntil(() => !controller.nes!.canUndoLoadState);

    controller.undoLoadState();

    expect(handle.sentCommands.whereType<UndoLoadStateCommand>(), isEmpty);
  });
}
