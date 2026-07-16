import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
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

  test('concurrent loadRom calls spawn exactly one isolate', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Keep the autoDispose state provider alive for the test's duration.
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

    // MockNesDatabase concretely overrides find() to return null.
    final database = MockNesDatabase();

    final handles = <FakeNesIsolateHandle>[];

    Future<NesIsolateHandle> spawner() async {
      // Widen the check-then-act window: both racing loadRom calls must
      // already be past the null check before the first handle exists.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final handle = FakeNesIsolateHandle();

      handles.add(handle);

      return handle;
    }

    addTearDown(() async {
      for (final handle in handles) {
        await handle.dispose();
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
    );

    const file = FilesystemFile(
      path: '/soak/test.nes',
      name: 'test.nes',
      type: FilesystemFileType.file,
    );

    final rom = minimalValidRom();

    final results = await Future.wait([
      controller.loadRom(file, data: rom),
      controller.loadRom(file, data: rom),
    ]);

    expect(results, [true, true]);
    expect(
      handles,
      hasLength(1),
      reason:
          'racing loadRom calls must reuse one isolate: a second '
          'spawn means a second worker and a second native audio init',
    );
  });
}
