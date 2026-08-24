import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
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

const _file = FilesystemFile(
  path: '/test/toast.nes',
  name: 'toast.nes',
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
    when(() => settings.autoSave).thenReturn(false);
    when(() => settings.autoSaveInterval).thenReturn(5);
    when(() => settings.autoLoad).thenReturn(true);
    when(() => settings.logLevel).thenReturn(LogLevel.info);
    when(() => settings.addRecentRom(any())).thenAnswer((_) {});

    final romManager = _MockRomManager();

    when(() => romManager.load(any())).thenAnswer((_) async => null);
    when(() => romManager.loadLatestState(any())).thenAnswer((_) async => null);
    when(() => romManager.save(any(), any())).thenAnswer((_) async {});

    final database = MockNesDatabase();
    final handle = FakeNesIsolateHandle();

    addTearDown(handle.dispose);

    Future<NesIsolateHandle> spawner() async => handle;

    final toaster = _MockToaster();

    final controller = NesController(
      nesState: container.read(nesStateProvider.notifier),
      spawner: spawner,
      router: Router(),
      settingsController: settings,
      toaster: toaster,
      romManager: romManager,
      filesystem: _MockFilesystem(),
      database: database,
      cartridgeFactory: CartridgeFactory(database: database),
    );

    return _Harness._(
      controller: controller,
      romManager: romManager,
      toaster: toaster,
    );
  }

  _Harness._({
    required this.controller,
    required this.romManager,
    required this.toaster,
  });

  final NesController controller;
  final _MockRomManager romManager;
  final _MockToaster toaster;

  Future<Uint8List> captureState() async {
    await controller.loadRom(_file, data: minimalValidRom());

    final state = await controller.nes!.requestSaveState();

    return state!;
  }

  List<String> takeMessages() => verify(
    () => toaster.send(captureAny()),
  ).captured.whereType<Toast>().map((toast) => toast.message).toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Toast.info('fallback'));
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

  test('loading a state alongside SRAM does not announce the SRAM', () async {
    final harness = _Harness();
    final state = await harness.captureState();

    when(
      () => harness.romManager.load(any()),
    ).thenAnswer((_) async => Uint8List(0x2000));
    when(
      () => harness.romManager.loadLatestState(any()),
    ).thenAnswer((_) async => state);

    clearInteractions(harness.toaster);

    await harness.controller.loadRom(_file, data: minimalValidRom());

    final messages = harness.takeMessages();

    expect(messages, contains('Loaded latest save state'));
    expect(messages, isNot(contains('SRAM save loaded')));
  });

  test('loading SRAM without a state announces the SRAM', () async {
    final harness = _Harness();

    when(
      () => harness.romManager.load(any()),
    ).thenAnswer((_) async => Uint8List(0x2000));

    await harness.controller.loadRom(_file, data: minimalValidRom());

    expect(harness.takeMessages(), contains('SRAM save loaded'));
  });
}
