import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_picker_screen.dart';
import 'package:nesd/ui/file_picker/file_system/file_extensions.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';

import '../mocks.dart';
import '../robot.dart';

const _romsDirectory = FilesystemFile(
  path: '/test/roms',
  name: '/test/roms',
  type: FilesystemFileType.directory,
);

const _romsDirectorySettings = {
  'lastRomPath': {
    'path': '/test/roms',
    'name': '/test/roms',
    'type': 'directory',
  },
};

void main() {
  testWidgets(
    'picking a ROM with an unsupported mapper keeps the picker open',
    (tester) async {
      final r = Robot(tester)..initSettings(_romsDirectorySettings);

      await r.pumpApp(
        extraFiles: {'/test/roms/unsupported.nes': unsupportedMapperRom()},
      );

      await r.mainMenu.tapOpenRomButton();
      r.filePickerScreen.expectFilePickerScreenFound();

      await r.filePickerScreen.tapFile('unsupported.nes');
      await r.fixAsync();

      expect(r.container.read(nesStateProvider), isNull);
      expect(r.container.read(currentRouteProvider), FilePickerRoute.name);
      r.filePickerScreen.expectFilePickerScreenFound();
    },
  );

  testWidgets('starting a ROM from the picker takes the picker off the stack', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();

    await r.mainMenu.tapOpenRomButton();
    r.filePickerScreen.expectFilePickerScreenFound();

    await r.filePickerScreen.tapFile('nestest.nes');

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
    );

    expect(
      r.container.read(routerProvider).stackData.map((data) => data.name),
      isNot(contains(FilePickerRoute.name)),
    );

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });

  testWidgets('the picker shows progress while a pick is loading', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();

    final selection = Completer<bool>();

    await r.openPickerWith((_) => selection.future);

    expect(find.byType(LinearProgressIndicator), findsNothing);

    await r.filePickerScreen.tapFile('nestest.nes');

    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    selection.complete(false);
    await r.fixAsync();

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('a second pick is ignored while the first one is loading', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp();

    final selection = Completer<bool>();
    var picks = 0;

    await r.openPickerWith((_) {
      picks++;

      return selection.future;
    });

    await r.filePickerScreen.tapFile('nestest.nes');
    await r.filePickerScreen.tapFile('nestest.nes');

    expect(picks, 1);

    selection.complete(false);
    await r.fixAsync();

    await r.filePickerScreen.tapFile('nestest.nes');

    expect(picks, 2);
  });
}

extension on Robot {
  Future<void> openPickerWith(Future<bool> Function(FilesystemFile) onSelect) {
    unawaited(
      container
          .read(routerProvider)
          .push(
            FilePickerRoute(
              title: 'Select a ROM',
              initialDirectory: _romsDirectory,
              type: FilePickerType.file,
              allowedExtensions: romPickerExtensions,
              onSelect: onSelect,
            ),
          ),
    );

    return fixAsync();
  }
}
