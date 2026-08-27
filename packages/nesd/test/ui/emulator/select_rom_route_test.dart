import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/rom_importer.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/web_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/web_storage_filesystem.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';

import '../mocks.dart';
import '../robot.dart';

base class FakePlatformFile extends PlatformFile {
  FakePlatformFile({
    required this.name,
    required this.path,
    this.size = 0,
    this.bytes,
  });

  @override
  final String name;

  @override
  final String path;

  final int size;

  /// Bytes returned by [readAsBytes], simulating web where the picker
  /// preloads the file's contents rather than exposing a local path.
  final Uint8List? bytes;

  @override
  Future<int> length() async => size;

  @override
  Stream<Uint8List> readAsByteStream() {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> readAsBytes() async {
    final bytes = this.bytes;

    if (bytes == null) {
      throw UnimplementedError();
    }

    return bytes;
  }

  @override
  Uri get uri => Uri.parse(path);

  @override
  XFile get xFile => throw UnimplementedError();
}

class FakeFilePickerPlatform extends FilePickerPlatform {
  FakeFilePickerPlatform(this.path);

  final String path;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    return FakePlatformFile(path: path, name: 'nestest.nes');
  }
}

/// A file picker that reports the user cancelled the dialog.
class CancellingFilePickerPlatform extends FilePickerPlatform {
  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    return null;
  }
}

class _MockSettingsController extends Mock implements SettingsController {}

class _MockToaster extends Mock implements Toaster {}

class _MockRomManager extends Mock implements RomManager {}

class _FailingWriteStorage implements StorageFilesystem {
  @override
  Future<Uint8List?> read(String path) => throw UnimplementedError();

  @override
  Future<void> write(String path, Uint8List data) =>
      throw NesdException('Browser storage is unavailable: quota exceeded');

  @override
  Future<void> delete(String path) => throw UnimplementedError();

  @override
  Future<bool> exists(String path) => throw UnimplementedError();

  @override
  Future<List<String>> list(String directory) => throw UnimplementedError();

  @override
  Future<void> createDirectory(String path) => throw UnimplementedError();

  @override
  Future<DateTime?> lastModified(String path) => throw UnimplementedError();
}

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
    registerFallbackValue(Toast.info('fallback'));
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
    when(() => settings.lowPassFilter).thenReturn(false);
    when(() => settings.autoSave).thenReturn(false);
    when(() => settings.autoSaveInterval).thenReturn(5);
    when(() => settings.autoLoad).thenReturn(false);
    when(() => settings.logLevel).thenReturn(LogLevel.info);

    final romManager = _MockRomManager();

    when(() => romManager.load(any())).thenAnswer((_) async => null);
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
            romImporter: NativeRomImporter(),
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

  test('selectRom on web stores picked bytes into web storage', () async {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    container.listen(nesStateProvider, (_, _) {});

    final settings = _MockSettingsController();

    when(() => settings.cheats).thenReturn(const {});
    when(() => settings.breakpoints).thenReturn(const {});
    when(() => settings.region).thenReturn(null);
    when(() => settings.rewind).thenReturn(false);
    when(() => settings.volume).thenReturn(1.0);
    when(() => settings.lowPassFilter).thenReturn(false);
    when(() => settings.autoSave).thenReturn(false);
    when(() => settings.autoSaveInterval).thenReturn(5);
    when(() => settings.autoLoad).thenReturn(false);
    when(() => settings.logLevel).thenReturn(LogLevel.info);

    final romManager = _MockRomManager();

    when(() => romManager.load(any())).thenAnswer((_) async => null);

    final database = MockNesDatabase();
    final handle = FakeNesIsolateHandle();

    addTearDown(handle.dispose);

    final storage = await WebStorageFilesystem.open(newIdbFactoryMemory());
    final romBytes = Uint8List.fromList([1, 2, 3, 4]);

    final controller = NesController(
      nesState: container.read(nesStateProvider.notifier),
      spawner: () async => handle,
      router: Router(),
      settingsController: settings,
      toaster: _MockToaster(),
      romManager: romManager,
      filesystem: MockFileSystem(),
      database: database,
      cartridgeFactory: CartridgeFactory(database: database),
      romImporter: WebRomImporter(
        storage: storage,
        pickFile: ({required type, allowedExtensions}) async =>
            FakePlatformFile(name: 'game.nes', path: '', bytes: romBytes),
      ),
    );

    await controller.selectRom();

    expect(await storage.read('$webRomsDirectory/game.nes'), romBytes);
  });

  test('selectRom imports a zip on web and starts the contained ROM', () async {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    container.listen(nesStateProvider, (_, _) {});

    final settings = _MockSettingsController();

    when(() => settings.cheats).thenReturn(const {});
    when(() => settings.breakpoints).thenReturn(const {});
    when(() => settings.region).thenReturn(null);
    when(() => settings.rewind).thenReturn(false);
    when(() => settings.volume).thenReturn(1.0);
    when(() => settings.lowPassFilter).thenReturn(false);
    when(() => settings.autoSave).thenReturn(false);
    when(() => settings.autoSaveInterval).thenReturn(5);
    when(() => settings.autoLoad).thenReturn(false);
    when(() => settings.logLevel).thenReturn(LogLevel.info);
    when(() => settings.addRecentRom(any())).thenAnswer((_) {});

    final romManager = _MockRomManager();

    when(() => romManager.load(any())).thenAnswer((_) async => null);
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

    final storage = await WebStorageFilesystem.open(newIdbFactoryMemory());

    final romBytes = File(
      '../../roms/test/nestest/nestest.nes',
    ).readAsBytesSync();
    final archive = Archive()
      ..addFile(ArchiveFile('nestest.nes', romBytes.length, romBytes));
    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));

    final controller = NesController(
      nesState: container.read(nesStateProvider.notifier),
      spawner: () async => handle,
      router: Router(),
      settingsController: settings,
      toaster: _MockToaster(),
      romManager: romManager,
      // Reads go through browser storage, like production web.
      filesystem: WebFilesystem(storage: storage),
      database: database,
      cartridgeFactory: CartridgeFactory(database: database),
      romImporter: WebRomImporter(
        storage: storage,
        pickFile: ({required type, allowedExtensions}) async =>
            FakePlatformFile(name: 'game.zip', path: '', bytes: zipBytes),
      ),
    );

    await controller.selectRom();

    expect(await storage.read('$webRomsDirectory/game.zip'), zipBytes);
    expect(container.read(nesStateProvider), isNotNull);

    await controller.stop();
  });

  test('a failed web storage write is reported and does not wedge the '
      'emulator in suspend', () async {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    container.listen(nesStateProvider, (_, _) {});

    final settings = _MockSettingsController();

    when(() => settings.cheats).thenReturn(const {});
    when(() => settings.breakpoints).thenReturn(const {});
    when(() => settings.region).thenReturn(null);
    when(() => settings.rewind).thenReturn(false);
    when(() => settings.volume).thenReturn(1.0);
    when(() => settings.lowPassFilter).thenReturn(false);
    when(() => settings.autoSave).thenReturn(false);
    when(() => settings.autoSaveInterval).thenReturn(5);
    when(() => settings.autoLoad).thenReturn(false);
    when(() => settings.logLevel).thenReturn(LogLevel.info);

    final romManager = _MockRomManager();

    when(() => romManager.load(any())).thenAnswer((_) async => null);
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

    final toaster = _MockToaster();

    final controller = NesController(
      nesState: container.read(nesStateProvider.notifier),
      spawner: () async => handle,
      router: Router(),
      settingsController: settings,
      toaster: toaster,
      romManager: romManager,
      filesystem: filesystem,
      database: database,
      cartridgeFactory: CartridgeFactory(database: database),
      romImporter: WebRomImporter(
        storage: _FailingWriteStorage(),
        pickFile: ({required type, allowedExtensions}) async =>
            FakePlatformFile(
              name: 'game.nes',
              path: '',
              bytes: Uint8List.fromList([1, 2, 3, 4]),
            ),
      ),
    )..emulatorActive = true;

    final loaded = await controller.loadRom(
      const FilesystemFile(
        path: '/test/roms/nestest.nes',
        name: 'nestest.nes',
        type: FilesystemFileType.file,
      ),
    );

    expect(loaded, isTrue);

    final commandsBeforeSelectRom = handle.sentCommands.length;

    await controller.selectRom();

    final commandsFromSelectRom = handle.sentCommands.sublist(
      commandsBeforeSelectRom,
    );

    expect(
      commandsFromSelectRom,
      containsAllInOrder([isA<SuspendCommand>(), isA<ResumeCommand>()]),
      reason:
          'selectRom suspends for the picker; a storage failure must '
          'still resume afterwards instead of leaving the emulator '
          'wedged in suspend',
    );

    final toasts = verify(() => toaster.send(captureAny())).captured;
    final errorToast = toasts.whereType<Toast>().lastWhere(
      (t) => t.type == ToastType.error,
    );

    expect(errorToast.message, contains('Failed to import ROM'));

    await controller.stop();
  });
}
