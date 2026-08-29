import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
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

class _GatedDatabase implements NesDatabase {
  final _completer = Completer<void>();

  int findCalls = 0;

  @override
  Future<void> get ready => _completer.future;

  @override
  NesDatabaseEntry? find(RomInfo info) {
    findCalls++;

    return null;
  }

  void finishLoading() => _completer.complete();
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
    registerFallbackValue(Uint8List(0));
  });

  test('waits for the ROM database before building the cartridge', () async {
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
    when(() => settings.autoSave).thenReturn(false);
    when(() => settings.autoSaveInterval).thenReturn(5);
    when(() => settings.autoLoad).thenReturn(false);
    when(() => settings.logLevel).thenReturn(LogLevel.info);
    when(() => settings.fastForwardSpeed).thenReturn(FastForwardSpeed.x2);
    when(() => settings.turboSpeed).thenReturn(TurboSpeed.x1);

    final romManager = _MockRomManager();

    when(() => romManager.load(any())).thenAnswer((_) async => null);
    when(() => romManager.save(any(), any())).thenAnswer((_) async {});

    final database = _GatedDatabase();

    final handle = FakeNesIsolateHandle();

    addTearDown(handle.dispose);

    final filesystem = MockFileSystem()
      ..addFile(
        '/test/roms/nestest.nes',
        File('../../roms/test/nestest/nestest.nes').readAsBytesSync(),
      );

    final controller = NesController(
      nesState: container.read(nesStateProvider.notifier),
      spawner: () async => handle,
      router: Router(),
      settingsController: settings,
      toaster: _MockToaster(),
      romManager: romManager,
      filesystem: filesystem,
      database: database,
      cartridgeFactory: CartridgeFactory(database: database),
      romImporter: FakeRomImporter(),
    );

    final loading = controller.loadRom(
      const FilesystemFile(
        path: '/test/roms/nestest.nes',
        name: 'nestest.nes',
        type: FilesystemFileType.file,
      ),
    );

    await pumpEventQueue();

    expect(
      database.findCalls,
      0,
      reason:
          'the cartridge was built before the database had finished '
          'loading, so no entry could be found for it',
    );

    database.finishLoading();

    expect(await loading, isTrue);
    expect(database.findCalls, greaterThan(0));
  });
}
