import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';

import '../mocks.dart';
import '../robot.dart';

void main() {
  testWidgets('startRom loads the ROM and switches to the emulator', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/start.nes': File(
          '../../roms/test/nestest/nestest.nes',
        ).readAsBytesSync(),
      },
    );

    final started = await r.container
        .read(nesControllerProvider)
        .startRom(
          const FilesystemFile(
            path: '/test/roms/start.nes',
            name: 'start.nes',
            type: FilesystemFileType.file,
          ),
        );

    expect(started, isTrue);

    await r.waitUntil(
      () => r.container.read(routerObserverProvider) == EmulatorRoute.name,
    );

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });

  testWidgets('startRom does not navigate when the ROM fails to load', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(extraFiles: {forcedRomLoadFailurePath: minimalValidRom()});

    final started = await r.container
        .read(nesControllerProvider)
        .startRom(
          const FilesystemFile(
            path: forcedRomLoadFailurePath,
            name: 'force_load_failure.nes',
            type: FilesystemFileType.file,
          ),
        );

    expect(started, isFalse);
    expect(r.container.read(nesStateProvider), isNull);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(r.container.read(routerObserverProvider), MainRoute.name);
  });
}
