import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
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
import 'package:nesd/ui/emulator/rom_importer.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../mocks.dart';

class _MockSettingsController extends Mock implements SettingsController {}

class _MockToaster extends Mock implements Toaster {}

class _MockRomManager extends Mock implements RomManager {}

const _runningPath = '/test/roms/nestest.nes';
const _corruptPath = '/test/roms/corrupt.nes';
const _corruptZipPath = '/test/roms/corrupt.zip';

const _corrupt = FilesystemFile(
  path: _corruptPath,
  name: 'corrupt.nes',
  type: FilesystemFileType.file,
);

class _Harness {
  factory _Harness() {
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

    final romManager = _MockRomManager();

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
    final handle = FakeNesIsolateHandle();

    addTearDown(handle.dispose);

    final filesystem = MockFileSystem()
      ..addFile(
        _runningPath,
        File('../../roms/test/nestest/nestest.nes').readAsBytesSync(),
      )
      ..addFile(_corruptPath, Uint8List.fromList(('JUNK' * 8).codeUnits))
      ..addFile(_corruptZipPath, Uint8List.fromList(('JUNK' * 8).codeUnits));

    final toaster = _MockToaster();

    final controller = NesController(
      nesState: container.read(nesStateProvider.notifier),
      spawner: () async => handle,
      router: Router(),
      settingsController: settings,
      toaster: toaster,
      romManager: romManager,
      filesystem: filesystem,
      database: database,
      cartridgeFactory: CartridgeFactory(database: database),
      romImporter: NativeRomImporter(),
    );

    return _Harness._(container, controller, handle, toaster, romManager);
  }

  _Harness._(
    this.container,
    this.controller,
    this.handle,
    this.toaster,
    this.romManager,
  );

  final ProviderContainer container;
  final NesController controller;
  final FakeNesIsolateHandle handle;
  final _MockToaster toaster;
  final _MockRomManager romManager;

  Future<void> startRunning() async {
    controller.emulatorActive = true;

    final loaded = await controller.loadRom(
      const FilesystemFile(
        path: _runningPath,
        name: 'nestest.nes',
        type: FilesystemFileType.file,
      ),
    );

    expect(loaded, isTrue);
  }

  List<NesCommand> commandsSince(int index) =>
      handle.sentCommands.sublist(index);

  List<Toast> get toasts =>
      verify(() => toaster.send(captureAny())).captured.cast<Toast>();
}

void main() {
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
    registerFallbackValue(Toast.info('fallback'));
  });

  test('a ROM rejected before the swap keeps the running game', () async {
    final h = _Harness();

    await h.startRunning();

    final running = h.container.read(nesStateProvider);
    final commandsBefore = h.handle.sentCommands.length;

    final loaded = await h.controller.loadRom(_corrupt);

    expect(loaded, isFalse);
    expect(h.container.read(nesStateProvider), same(running));
    expect(h.commandsSince(commandsBefore).whereType<StopCommand>(), isEmpty);

    final error = h.toasts.lastWhere((toast) => toast.type == ToastType.error);

    expect(error.message, contains('Failed to load ROM'));

    final stopsBefore = h.handle.sentCommands.length;

    await h.controller.stop();

    expect(
      h.commandsSince(stopsBefore).whereType<StopCommand>(),
      hasLength(1),
      reason: 'the kept game must still be stopped (and saved) on quit',
    );
    verify(
      () => h.romManager.saveThumbnail(
        any(),
        width: any(named: 'width'),
        height: any(named: 'height'),
        pixels: any(named: 'pixels'),
      ),
    ).called(1);
  });

  test('a corrupt archive keeps the running game', () async {
    final h = _Harness();

    await h.startRunning();

    final running = h.container.read(nesStateProvider);

    final loaded = await h.controller.loadRom(
      const FilesystemFile(
        path: _corruptZipPath,
        name: 'corrupt.zip',
        type: FilesystemFileType.file,
      ),
    );

    expect(loaded, isFalse);
    expect(h.container.read(nesStateProvider), same(running));

    await h.controller.stop();
  });

  test('dropping a corrupt ROM mid-game resumes the running game', () async {
    final h = _Harness();

    await h.startRunning();

    final running = h.container.read(nesStateProvider);
    final commandsBefore = h.handle.sentCommands.length;

    await h.controller.openDroppedRom([XFile(_corruptPath)]);

    expect(h.container.read(nesStateProvider), same(running));
    expect(
      h.commandsSince(commandsBefore),
      containsAllInOrder([isA<SuspendCommand>(), isA<ResumeCommand>()]),
    );

    await h.controller.stop();
  });
}
