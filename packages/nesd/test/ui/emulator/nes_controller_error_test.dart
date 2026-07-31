import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
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
  });

  test('worker errors are toasted without the stack trace', () async {
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
    final toaster = _MockToaster();
    final handle = FakeNesIsolateHandle();

    addTearDown(handle.dispose);

    Future<NesIsolateHandle> spawner() async => handle;

    final controller = NesController(
      nesState: container.read(nesStateProvider.notifier),
      spawner: spawner,
      settingsController: settings,
      toaster: toaster,
      romManager: romManager,
      filesystem: _MockFilesystem(),
      database: database,
      cartridgeFactory: CartridgeFactory(database: database),
    );

    const file = FilesystemFile(
      path: '/test/error.nes',
      name: 'error.nes',
      type: FilesystemFileType.file,
    );

    await controller.loadRom(file, data: minimalValidRom());

    const message =
        'Invalid argument(s): failed to load library\n'
        '#0      _open (dart:ffi-patch/ffi_dynamic_library_patch.dart:11)\n'
        '#1      RewindBuffer.add (package:nesd/nes/rewind/rewind_buffer.dart:59)';

    handle.emit(const ErrorEvent(message: message));

    await pumpEventQueue();

    final toasts = verify(() => toaster.send(captureAny())).captured;
    final errorToast = toasts.whereType<Toast>().lastWhere(
      (t) => t.type == ToastType.error,
    );

    expect(errorToast.message, 'Invalid argument(s): failed to load library');
  });
}
