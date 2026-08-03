import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_method_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../mocks.dart';
import '../robot.dart';

class FakeFilePickerPlatform extends FilePickerPlatform {
  FakeFilePickerPlatform(this.path);

  final String path;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
    Object? androidSafOptions,
  }) async {
    return FilePickerResult([
      PlatformFile(path: path, name: 'nestest.nes', size: 0),
    ]);
  }
}

/// A file picker that reports the user cancelled the dialog.
class CancellingFilePickerPlatform extends FilePickerPlatform {
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
    Object? androidSafOptions,
  }) async {
    return null;
  }
}

class _MockSettingsController extends Mock implements SettingsController {}

class _MockToaster extends Mock implements Toaster {}

class _MockRomManager extends Mock implements RomManager {}

void main() {
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
    registerFallbackValue(Uint8List(0));
  });

  testWidgets('opening a ROM via the native file dialog switches to the '
      'emulator route', (tester) async {
    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: {
        '/test/roms/native.nes': File(
          '../../roms/test/nestest/nestest.nes',
        ).readAsBytesSync(),
      },
    );

    FilePickerPlatform.instance = FakeFilePickerPlatform(
      '/test/roms/native.nes',
    );

    addTearDown(() => FilePickerPlatform.instance = MethodChannelFilePicker());

    await r.container.read(nesControllerProvider).selectRom();
    await r.waitUntil(() => r.container.read(nesStateProvider) != null);

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
    );

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });

  testWidgets(
    'reopening a ROM without leaving the emulator route keeps the action '
    'handler in sync',
    (tester) async {
      final r = Robot(tester);

      await r.pumpApp(
        extraFiles: {
          '/test/roms/native.nes': File(
            '../../roms/test/nestest/nestest.nes',
          ).readAsBytesSync(),
        },
      );

      FilePickerPlatform.instance = FakeFilePickerPlatform(
        '/test/roms/native.nes',
      );

      addTearDown(
        () => FilePickerPlatform.instance = MethodChannelFilePicker(),
      );

      await r.container.read(nesControllerProvider).selectRom();
      await r.waitUntil(() => r.container.read(nesStateProvider) != null);
      await r.waitUntil(
        () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
      );

      final firstNes = r.container.read(nesStateProvider);

      unawaited(r.container.read(nesControllerProvider).selectRom());
      await r.waitUntil(() => r.container.read(nesStateProvider) != firstNes);

      expect(r.container.read(actionHandlerProvider).emulatorActive, isTrue);

      await r.emulator.tapMenu();
      await r.menuScreen.tapQuitGame();
      await r.waitUntil(() => r.container.read(nesStateProvider) == null);
    },
  );

  test('cancelling the picker while the emulator is covered does not resume '
      'it', () async {
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
    when(() => romManager.save(any(), any())).thenAnswer((_) async {});
    when(
      () => romManager.saveThumbnail(
        any(),
        width: any(named: 'width'),
        height: any(named: 'height'),
        pixels: any(named: 'pixels'),
      ),
    ).thenAnswer((_) async {});

    final database = MockNesDatabase();

    final handle = FakeNesIsolateHandle();

    addTearDown(handle.dispose);

    final filesystem = MockFileSystem()
      ..addFile(
        '/test/roms/nestest.nes',
        File('../../roms/test/nestest/nestest.nes').readAsBytesSync(),
      );

    final controller =
        NesController(
            nesState: container.read(nesStateProvider.notifier),
            spawner: () async => handle,
            router: Router(),
            settingsController: settings,
            toaster: _MockToaster(),
            romManager: romManager,
            filesystem: filesystem,
            database: database,
            cartridgeFactory: CartridgeFactory(database: database),
          )
          // A game is loaded and running.
          ..emulatorActive = true;

    final loaded = await controller.loadRom(
      const FilesystemFile(
        path: '/test/roms/nestest.nes',
        name: 'nestest.nes',
        type: FilesystemFileType.file,
      ),
    );

    expect(loaded, isTrue);

    // The in-game menu (or any other screen) now covers the emulator.
    controller.emulatorActive = false;

    FilePickerPlatform.instance = CancellingFilePickerPlatform();

    addTearDown(() => FilePickerPlatform.instance = MethodChannelFilePicker());

    final commandsBeforeSelectRom = handle.sentCommands.length;

    await controller.selectRom();

    final commandsFromSelectRom = handle.sentCommands.sublist(
      commandsBeforeSelectRom,
    );

    expect(
      commandsFromSelectRom.whereType<ResumeCommand>(),
      isEmpty,
      reason:
          'cancelling the picker while the emulator is covered must not '
          'resume it',
    );

    await controller.stop();
  });
}
