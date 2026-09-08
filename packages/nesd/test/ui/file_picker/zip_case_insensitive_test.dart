import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_picker_controller.dart';
import 'package:nesd/ui/file_picker/file_picker_state.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';

import '../emulator/rom_load_helper.dart';
import '../robot.dart';

const _romsDirectorySettings = {
  'lastRomPath': {
    'path': '/test/roms',
    'name': '/test/roms',
    'type': 'directory',
  },
};

void main() {
  testWidgets('tapping an uppercase .ZIP browses into the archive', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/COLLECTION.ZIP': zipOf({
          'first.nes': Uint8List(16),
          'second.nes': Uint8List(16),
        }),
      },
    );

    await r.mainMenu.tapOpenRomButton();
    r.filePickerScreen.expectFilePickerScreenFound();

    await r.filePickerScreen.tapFile('COLLECTION.ZIP');

    final state = r.container.read(filePickerStateProvider);

    expect(state, isA<FilePickerData>());
    expect(
      [for (final file in (state as FilePickerData).files) file.name],
      ['first.nes', 'second.nes'],
    );
  });

  testWidgets('an uppercase .ZIP holding one ROM starts that ROM directly', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/SINGLE.ZIP': zipOf({'only.nes': nestestBytes()}),
      },
    );

    await r.mainMenu.tapOpenRomButton();
    r.filePickerScreen.expectFilePickerScreenFound();

    await r.filePickerScreen.tapFile('SINGLE.ZIP');

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
    );

    expect(
      r.container.read(nesStateProvider)!.romInfo.file.path,
      '/test/roms/SINGLE.ZIP:only.nes',
    );

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });
}
