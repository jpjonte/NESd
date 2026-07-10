import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../mocks.dart';
import '../robot.dart';

void main() {
  testWidgets('loadRom uses provided bytes instead of reading the '
      'filesystem', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();

    final controller = r.container.read(nesControllerProvider);

    // The path exists on no test filesystem: success proves the read
    // was bypassed in favor of the provided bytes.
    final loaded = await tester.runAsync(
      () => controller.loadRom(
        const FilesystemFile(
          path: '/not/on/any/filesystem.nes',
          name: 'direct.nes',
          type: FilesystemFileType.file,
        ),
        data: minimalValidRom(),
      ),
    );

    await r.fixAsync();

    expect(loaded, isTrue);
    expect(r.container.read(nesStateProvider), isNotNull);

    // Stop the running NES before the test ends: tearing the widget tree
    // (and the worker inside it) down mid-run schedules run-loop timers
    // that trip flutter_test's pending-timer invariant check. `stop` does
    // real async work (worker round trips, file IO), so it must run under
    // `runAsync` like `loadRom` above.
    await tester.runAsync(controller.stop);
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });
}
