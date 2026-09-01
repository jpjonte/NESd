import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/main_menu/main_menu.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../robot.dart';
import 'rom_load_helper.dart';

const _collection = FilesystemFile(
  path: '/test/roms/collection.zip',
  name: 'collection.zip',
  type: FilesystemFileType.file,
);

List<String> _errors(Robot r) => [
  for (final toast in r.container.read(toastStateProvider))
    if (toast.type == ToastType.error) toast.message,
];

void main() {
  testWidgets('an archive holding several ROMs opens the file picker and '
      'starts the chosen entry', (tester) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        _collection.path: zipOf({
          'alpha.nes': nestestBytes(),
          'beta.nes': nestestBytes(),
        }),
      },
    );

    unawaited(r.container.read(nesControllerProvider).startRom(_collection));

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == FilePickerRoute.name,
    );

    r.filePickerScreen.expectFilesFound(2);

    await r.filePickerScreen.tapFile('beta.nes');

    await r.waitUntil(() => r.container.read(nesStateProvider) != null);
    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
    );

    expect(
      r.container.read(nesStateProvider)!.romInfo.file.path,
      '${_collection.path}:beta.nes',
    );
    expect(_errors(r), isEmpty);

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });

  testWidgets('backing out of the archive picker starts nothing', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        _collection.path: zipOf({
          'alpha.nes': nestestBytes(),
          'beta.nes': nestestBytes(),
        }),
      },
    );

    bool? started;

    unawaited(
      r.container
          .read(nesControllerProvider)
          .startRom(_collection)
          .then((value) => started = value),
    );

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == FilePickerRoute.name,
    );

    await r.goBack();
    await r.waitUntil(() => started != null);

    expect(started, isFalse);
    expect(r.container.read(nesStateProvider), isNull);
    expect(r.container.read(currentRouteProvider), MainRoute.name);
    expect(_errors(r), isEmpty);
  });

  testWidgets('an archive holding a single ROM loads without the picker', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        _collection.path: zipOf({
          'readme.txt': Uint8List.fromList('hello'.codeUnits),
          'alpha.nes': nestestBytes(),
        }),
      },
    );

    final started = await r.container
        .read(nesControllerProvider)
        .startRom(_collection);

    expect(started, isTrue);

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
    );

    expect(_errors(r), isEmpty);

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });

  testWidgets('an archive holding no ROM still reports the error', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        _collection.path: zipOf({
          'readme.txt': Uint8List.fromList('hello'.codeUnits),
        }),
      },
    );

    final started = await r.container
        .read(nesControllerProvider)
        .startRom(_collection);

    await r.fixAsync();

    expect(started, isFalse);
    expect(r.container.read(nesStateProvider), isNull);
    expect(_errors(r), contains(contains('does not contain a NES ROM')));
  });

  testWidgets('an archive that cannot be read is reported instead of '
      'breaking startRom', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();

    final started = await r.container
        .read(nesControllerProvider)
        .startRom(_collection);

    await r.fixAsync();

    expect(started, isFalse);
    expect(r.container.read(currentRouteProvider), MainRoute.name);
    expect(_errors(r), contains(contains('Failed to load ROM')));
  });

  testWidgets('a multi-ROM archive passed at startup opens the file picker', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        _collection.path: zipOf({
          'alpha.nes': nestestBytes(),
          'beta.nes': nestestBytes(),
        }),
      },
      overrides: [
        initialRomProvider.overrideWith(
          () => InitialRom(initialValue: _collection.path),
        ),
      ],
      settle: false,
    );

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == FilePickerRoute.name,
    );

    r.filePickerScreen.expectFilesFound(2);

    await r.filePickerScreen.tapFile('alpha.nes');

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
    );

    expect(
      r.container.read(nesStateProvider)!.romInfo.file.path,
      '${_collection.path}:alpha.nes',
    );

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });
}
