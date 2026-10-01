import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/exception/nesd_exception.dart';
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
import 'package:nesd/ui/router/router_observer.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../mocks.dart';
import '../robot.dart';

class _MockSettingsController extends Mock implements SettingsController {}

class _MockToaster extends Mock implements Toaster {}

class _MockRomManager extends Mock implements RomManager {}

class _RecordingImporter implements RomImporter {
  _RecordingImporter({this.fail = false});

  final bool fail;

  final imported = <XFile>[];

  @override
  Future<FilesystemFile?> pickRom() async => null;

  @override
  Future<FilesystemFile> importDropped(XFile file) async {
    if (fail) {
      throw NesdException('Browser storage is unavailable: quota exceeded');
    }

    imported.add(file);

    return await NativeRomImporter().importDropped(file);
  }
}

const _romPath = '/test/roms/nestest.nes';

class _Harness {
  factory _Harness({bool failImport = false}) {
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
        _romPath,
        File('../../roms/test/nestest/nestest.nes').readAsBytesSync(),
      );

    final toaster = _MockToaster();
    final importer = _RecordingImporter(fail: failImport);

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
      romImporter: importer,
    );

    return _Harness._(container, controller, handle, toaster, importer);
  }

  _Harness._(
    this.container,
    this.controller,
    this.handle,
    this.toaster,
    this.importer,
  );

  final ProviderContainer container;
  final NesController controller;
  final FakeNesIsolateHandle handle;
  final _MockToaster toaster;
  final _RecordingImporter importer;

  Future<void> startRunning() async {
    controller.emulatorActive = true;

    final loaded = await controller.loadRom(
      const FilesystemFile(
        path: _romPath,
        name: 'nestest.nes',
        type: FilesystemFileType.file,
      ),
    );

    expect(loaded, isTrue);
  }

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

  testWidgets('starts the first dropped file that is a ROM', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();

    await r.container.read(nesControllerProvider).openDroppedRom([
      XFile('/test/notes.txt'),
      XFile(_romPath),
      XFile('/test/roms/z_fake.nes'),
    ]);

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
    );

    expect(r.container.read(nesStateProvider)?.romInfo.file.path, _romPath);

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });

  test('accepts archives and is case-insensitive about extensions', () async {
    final h = _Harness();

    await h.controller.openDroppedRom([
      XFile('/test/a.txt'),
      XFile('/test/B.ZIP'),
      XFile('/test/c.7z'),
    ]);

    expect(h.importer.imported.map((file) => file.path), ['/test/B.ZIP']);
  });

  test(
    'a drop without a ROM warns and leaves the running game alone',
    () async {
      final h = _Harness();

      await h.startRunning();

      final commandsBefore = h.handle.sentCommands.length;

      await h.controller.openDroppedRom([XFile('/test/game.fds')]);

      expect(h.importer.imported, isEmpty);
      expect(h.handle.sentCommands.sublist(commandsBefore), isEmpty);

      final warning = h.toasts.lastWhere(
        (toast) => toast.type == ToastType.warning,
      );

      expect(warning.message, 'Unsupported file: game.fds');

      await h.controller.stop();
    },
  );

  test('an empty drop does nothing', () async {
    final h = _Harness();

    await h.controller.openDroppedRom(const []);

    expect(h.importer.imported, isEmpty);
    verifyNever(() => h.toaster.send(any()));
  });

  test('a failed import is reported and resumes the running game', () async {
    final h = _Harness(failImport: true);

    await h.startRunning();

    final commandsBefore = h.handle.sentCommands.length;

    await h.controller.openDroppedRom([XFile('/test/roms/other.nes')]);

    expect(
      h.handle.sentCommands.sublist(commandsBefore),
      containsAllInOrder([isA<SuspendCommand>(), isA<ResumeCommand>()]),
    );

    final error = h.toasts.lastWhere((toast) => toast.type == ToastType.error);

    expect(error.message, contains('Failed to import ROM'));

    await h.controller.stop();
  });
}
