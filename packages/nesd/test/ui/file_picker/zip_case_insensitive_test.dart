import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/file_picker/file_picker_controller.dart';
import 'package:nesd/ui/file_picker/file_picker_screen.dart';
import 'package:nesd/ui/file_picker/file_picker_state.dart';

import '../robot.dart';

const _romsDirectorySettings = {
  'lastRomPath': {
    'path': '/test/roms',
    'name': '/test/roms',
    'type': 'directory',
  },
};

Uint8List _zipContaining(List<String> entryNames) {
  final archive = Archive();

  for (final name in entryNames) {
    final bytes = Uint8List(16);

    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  testWidgets('tapping an uppercase .ZIP browses into the archive', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/COLLECTION.ZIP': _zipContaining([
          'first.nes',
          'second.nes',
        ]),
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

  testWidgets('an uppercase .ZIP holding one ROM pops that ROM directly', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_romsDirectorySettings);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/SINGLE.ZIP': _zipContaining(['only.nes']),
      },
    );

    await r.mainMenu.tapOpenRomButton();
    r.filePickerScreen.expectFilePickerScreenFound();

    await r.filePickerScreen.tapFile('SINGLE.ZIP');

    await r.waitUntil(() => find.byType(FilePickerScreen).evaluate().isEmpty);

    r.mainMenu.expectMainMenuFound();
  });
}
