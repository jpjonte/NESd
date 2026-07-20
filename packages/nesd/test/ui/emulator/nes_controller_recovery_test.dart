import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../mocks.dart';

class _MockSettingsController extends Mock implements SettingsController {}

class _MockToaster extends Mock implements Toaster {}

class _MockRomManager extends Mock implements RomManager {}

class _MockFilesystem extends Mock implements Filesystem {}

/// Stands in for a wedged or dead emulator isolate: commands go nowhere and
/// no events ever arrive.
class _UnresponsiveHandle implements NesIsolateHandle {
  final StreamController<NesIsolateEvent> _events =
      StreamController<NesIsolateEvent>.broadcast();

  bool disposed = false;

  @override
  Stream<NesIsolateEvent> get events => _events.stream;

  @override
  void send(NesCommand command) {}

  @override
  Future<void> dispose() async {
    disposed = true;

    await _events.close();
  }
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
  });

  test('loadRom timeout tears down the isolate so the next load '
      'respawns', () async {
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

    final database = MockNesDatabase();

    final unresponsive = _UnresponsiveHandle();
    final handles = <NesIsolateHandle>[];

    Future<NesIsolateHandle> spawner() async {
      // First spawn yields a handle that never answers; later spawns work.
      final handle = handles.isEmpty ? unresponsive : FakeNesIsolateHandle();

      handles.add(handle);

      return handle;
    }

    addTearDown(() async {
      for (final handle in handles) {
        if (handle is FakeNesIsolateHandle) {
          await handle.dispose();
        }
      }
    });

    final controller = NesController(
      nesState: container.read(nesStateProvider.notifier),
      spawner: spawner,
      settingsController: settings,
      toaster: _MockToaster(),
      romManager: romManager,
      filesystem: _MockFilesystem(),
      database: database,
      cartridgeFactory: CartridgeFactory(database: database),
      romLoadTimeout: const Duration(milliseconds: 200),
    );

    const file = FilesystemFile(
      path: '/test/test.nes',
      name: 'test.nes',
      type: FilesystemFileType.file,
    );

    final rom = minimalValidRom();

    final first = await controller.loadRom(file, data: rom);

    expect(first, isFalse);
    expect(
      unresponsive.disposed,
      isTrue,
      reason: 'a load timeout must tear down the unresponsive isolate',
    );

    final second = await controller.loadRom(file, data: rom);

    expect(second, isTrue, reason: 'the retry must reach a fresh isolate');
    expect(handles, hasLength(2));
  });
}
