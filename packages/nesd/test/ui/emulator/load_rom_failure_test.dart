import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../mocks.dart';
import '../robot.dart';

void main() {
  testWidgets(
    'a loadRom failure after a game is running surfaces an error toast '
    'and clears nesState instead of leaving the dead remote in place',
    (tester) async {
      final r = Robot(tester)
        ..initSettings({
          'recentRoms': [
            {
              'file': {
                'path': '/test/roms/nestest.nes',
                'name': '/test/roms/nestest.nes',
                'type': 'file',
              },
            },
          ],
        });

      await r.pumpApp(
        extraFiles: {forcedRomLoadFailurePath: minimalValidRom()},
      );
      r.mainMenu.expectMainMenuFound();

      await r.mainMenu.tapFirstRomTile();
      r.emulator.expectEmulatorWidgetFound();

      expect(r.container.read(nesStateProvider), isNotNull);

      final controller = r.container.read(nesControllerProvider);

      // Forced to fail by FakeNesIsolateHandle (see forcedRomLoadFailurePath)
      // rather than by malformed ROM bytes: NesController.loadRom parses
      // the cartridge client-side (for metadata) using the exact same
      // deterministic parser the worker uses, so any ROM bytes that would
      // make the worker reject the load would already have been rejected
      // client-side, before a RemoteNes is even constructed. Only a
      // worker-reported failure (RomLoadFailedEvent) can occur after the
      // new RemoteNes exists, which is the scenario that regressed.
      final loaded = await tester.runAsync(
        () => controller.loadRom(
          const FilesystemFile(
            path: forcedRomLoadFailurePath,
            name: 'force_load_failure.nes',
            type: FilesystemFileType.file,
          ),
        ),
      );

      await r.fixAsync();

      expect(loaded, isFalse);

      final toasts = r.container.read(toastStateProvider);

      expect(
        toasts.any(
          (toast) =>
              toast.type == ToastType.error &&
              toast.message.contains('Failed to load ROM'),
        ),
        isTrue,
        reason: 'expected an error toast for the failed ROM load',
      );

      expect(r.container.read(nesStateProvider), isNull);
    },
  );
}
