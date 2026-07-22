import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart' hide Router;
import 'package:nesd/exception/empty_archive.dart';
import 'package:nesd/exception/too_many_roms.dart';
import 'package:nesd/exception/unsupported_file_type.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/zip_filesystem.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nes_controller.g.dart';

const mobileRewindCaptureInterval = 4;

/// Builds a [NesIsolateHandle]. Production spawns a real [NesIsolate];
/// tests override [nesIsolateSpawnerProvider] with an in-process fake so
/// widget tests never spawn a real isolate (or touch real audio).
typedef NesIsolateSpawner = Future<NesIsolateHandle> Function();

@riverpod
NesIsolateSpawner nesIsolateSpawner(Ref ref) => NesIsolate.spawn;

@riverpod
class NesState extends _$NesState {
  @override
  RemoteNes? build() {
    return null;
  }

  RemoteNes? get nes => state;

  void set(RemoteNes remoteNes) {
    state?.dispose();

    state = remoteNes;
  }

  void clear() {
    state?.dispose();

    state = null;
  }
}

@riverpod
NesController nesController(Ref ref) {
  final controller = NesController(
    nesState: ref.watch(nesStateProvider.notifier),
    spawner: ref.watch(nesIsolateSpawnerProvider),
    settingsController: ref.read(settingsControllerProvider.notifier),
    toaster: ref.watch(toasterProvider),
    romManager: ref.watch(romManagerProvider),
    filesystem: ref.read(filesystemProvider),
    database: ref.watch(databaseProvider),
    cartridgeFactory: ref.watch(cartridgeFactoryProvider),
  );

  ref.onDispose(controller._dispose);

  final autoSaveSubscription = ref.listen(
    settingsControllerProvider.select(
      (settings) => (settings.autoSave, settings.autoSaveInterval),
    ),
    (_, setting) =>
        controller.setAutoSave(enabled: setting.$1, interval: setting.$2),
    fireImmediately: true,
  );

  ref.onDispose(autoSaveSubscription.close);

  final volumeSubscription = ref.listen(
    settingsControllerProvider.select((settings) => settings.volume),
    (_, volume) => controller.nes?.volume = volume,
    fireImmediately: true,
  );

  ref.onDispose(volumeSubscription.close);

  final regionSubscription = ref.listen(
    settingsControllerProvider.select((settings) => settings.region),
    (_, region) => controller.nes?.region = region,
    fireImmediately: true,
  );

  ref.onDispose(regionSubscription.close);

  final rewindSubscription = ref.listen(
    settingsControllerProvider.select((settings) => settings.rewind),
    (_, rewind) => controller.nes?.rewindEnabled = rewind,
    fireImmediately: true,
  );

  ref.onDispose(rewindSubscription.close);

  final routeSubscription = ref.listen(
    routerObserverProvider,
    (_, route) => controller._updateRoute(route),
  );

  ref.onDispose(routeSubscription.close);

  return controller;
}

class NesController {
  NesController({
    required this.nesState,
    required this.spawner,
    required this.settingsController,
    required this.toaster,
    required this.romManager,
    required this.filesystem,
    required this.database,
    required this.cartridgeFactory,
    this.romLoadTimeout = const Duration(seconds: 10),
  }) {
    _lifecycleListener = AppLifecycleListener(
      onPause: _appSuspended,
      onInactive: _appSuspended,
      onShow: _appSuspended,
      onResume: _appResumed,
    );
  }

  final NesState nesState;

  final SettingsController settingsController;

  final Toaster toaster;

  final RomManager romManager;

  final Filesystem filesystem;

  final NesDatabase database;

  final CartridgeFactory cartridgeFactory;

  final NesIsolateSpawner spawner;

  final Duration romLoadTimeout;

  RemoteNes? get nes => nesState.nes;

  late final AppLifecycleListener _lifecycleListener;

  bool lifeCycleListenerEnabled = true;

  Timer? _autoSaveTimer;

  NesIsolateHandle? _isolate;

  Future<NesIsolateHandle>? _isolateFuture;

  StreamSubscription<NesIsolateEvent>? _eventSubscription;

  bool get isOn => nesState.nes != null;

  Future<Uint8List> _readFile(String path) async {
    final data = await switch (path.contains(':') && path.contains('.zip')) {
      true => ZipFilesystem(
        path: path.split(':').first,
        zipData: await filesystem.read(path.split(':').first),
      ).read(path.split(':').last),
      false => filesystem.read(path),
    };

    return data;
  }

  void suspend() => nes?.suspend();

  void resume() => nes?.resume();

  void pause() => nes?.pause();

  void unpause() => nes?.unpause();

  void togglePause() => nes?.togglePause();

  void stepInto() => nes?.stepInto();

  void stepOver() => nes?.stepOver();

  void stepOut() => nes?.stepOut();

  void runUntilFrame() => nes?.runUntilFrame();

  void reset() {
    nes?.reset();

    _loadSram();
  }

  Future<void> stop() async {
    if (nes case final nes?) {
      final sram = await nes.requestSram();

      if (sram != null) {
        await romManager.save(nes.romInfo, sram);

        toaster.send(Toast.info('SRAM saved'));
      }

      final thumbnail = await nes.requestThumbnail();

      if (thumbnail != null) {
        await romManager.saveThumbnail(
          nes.romInfo,
          width: thumbnail.width,
          height: thumbnail.height,
          pixels: thumbnail.pixels,
        );
      }

      await nes.stop();
    }

    nesState.clear();
  }

  Future<void> selectRom() async {
    suspend();

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['nes', 'zip'],
    );

    if (result == null) {
      resume();

      return;
    }

    final path = result.files.single.path;

    if (path == null) {
      resume();

      return;
    }

    await loadRom(
      FilesystemFile(
        path: path,
        name: p.basename(path),
        type: FilesystemFileType.file,
      ),
    );
  }

  Future<bool> loadRom(
    FilesystemFile file, {
    Uint8List? stateBytes,
    Uint8List? data,
  }) async {
    nes?.suspend();

    RemoteNes? remote;

    try {
      final bytes = data ?? await _readFile(file.path);
      final extension = p.extension(file.name);

      final rom = switch (extension) {
        '.nes' => bytes,
        '.zip' => _loadZip(file.path, bytes),
        _ => throw UnsupportedFileType(extension),
      };

      final cartridge = cartridgeFactory.fromFile(file, rom);

      cartridge.databaseEntry = database.find(cartridge.romInfo);

      final romInfo = cartridge.romInfo;
      final databaseEntry = cartridge.databaseEntry;

      if (nes case final oldNes?) {
        final oldSram = await oldNes.requestSram();

        if (oldSram != null) {
          await romManager.save(oldNes.romInfo, oldSram);
        }
      }

      await nes?.stop();

      final isolate = await _ensureIsolate();

      final sram = romManager.load(romInfo);
      final initialState = stateBytes ?? _autoLoadBytes(romInfo);
      final cheats = settingsController.cheats[_cheatsKey(romInfo)] ?? const [];
      final breakpoints =
          settingsController.breakpoints[cartridge.fileHash] ?? const [];

      remote = RemoteNes(
        isolate: isolate,
        romInfo: romInfo,
        fileHash: cartridge.fileHash,
        hasZapper: databaseEntry?.hasZapper ?? false,
        cartridgeInfo: CartridgeInfo.fromCartridge(cartridge),
      );

      isolate.send(
        LoadRomCommand(
          rom: TransferableTypedData.fromList([rom]),
          file: file,
          databaseEntry: databaseEntry,
          region: settingsController.region,
          rewindEnabled: settingsController.rewind,
          rewindCaptureInterval: Platform.isAndroid
              ? mobileRewindCaptureInterval
              : 1,
          cheats: cheats,
          breakpoints: breakpoints,
          initialState: initialState == null
              ? null
              : TransferableTypedData.fromList([initialState]),
          sram: sram == null ? null : TransferableTypedData.fromList([sram]),
        ),
      );

      final loaded = await isolate.events
          .firstWhere(
            (event) => event is RomLoadedEvent || event is RomLoadFailedEvent,
          )
          .timeout(romLoadTimeout);

      if (loaded case RomLoadFailedEvent(:final message)) {
        toaster.send(Toast.error('Failed to load ROM: $message'));

        remote.dispose();
        nesState.clear();

        return false;
      }

      remote.volume = settingsController.volume;

      nesState.set(remote);

      if (sram != null) {
        toaster.send(Toast.info('SRAM save loaded'));
      }

      if (initialState != null && stateBytes == null) {
        toaster.send(Toast.info('Loaded latest save state'));
      }

      setAutoSave(
        enabled: settingsController.autoSave,
        interval: settingsController.autoSaveInterval,
      );

      settingsController.addRecentRom(romInfo);
    } on PathNotFoundException {
      return false;
    } on TimeoutException {
      await _teardownIsolate();

      toaster.send(Toast.error('Emulator did not respond and was restarted'));

      remote?.dispose();
      nesState.clear();

      return false;
    } on Exception catch (e) {
      toaster.send(Toast.error('Failed to load ROM: $e'));

      remote?.dispose();
      nesState.clear();

      return false;
    }

    return true;
  }

  Future<NesIsolateHandle> _ensureIsolate() {
    if (_isolate case final isolate?) {
      return Future.value(isolate);
    }

    return _isolateFuture ??= _spawnIsolate();
  }

  Future<void> _teardownIsolate() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;

    final isolate = _isolate;

    _isolate = null;
    _isolateFuture = null;

    await isolate?.dispose();
  }

  Future<NesIsolateHandle> _spawnIsolate() async {
    final isolate = await spawner();

    _isolate = isolate;

    _eventSubscription = isolate.events.listen(_handleIsolateEvent);

    return isolate;
  }

  void _handleIsolateEvent(NesIsolateEvent event) {
    switch (event) {
      case ErrorEvent(:final message):
        toaster.send(Toast.error(message));
      case BreakpointsEvent(:final fileHash, :final breakpoints):
        settingsController.setBreakpoints(fileHash, breakpoints);
      default:
        break;
    }
  }

  Future<void> saveState(int slot) async {
    if (nes case final nes?) {
      final data = await nes.requestSaveState();

      if (data == null) {
        toaster.send(Toast.error('Failed to save state'));

        return;
      }

      await romManager.saveState(nes.romInfo, slot, data);

      toaster.send(Toast.info('Saved state to slot $slot'));
    }
  }

  void loadState(int slot) {
    if (nes case final nes?) {
      final saveState = romManager.loadState(nes.romInfo, slot);

      if (saveState == null) {
        toaster.send(Toast.warning('No save state found in slot $slot'));
      } else {
        nes.loadState(saveState);

        toaster.send(Toast.info('State loaded from slot $slot'));
      }
    }
  }

  void _loadSram() {
    if (nes case final nes?) {
      final data = romManager.load(nes.romInfo);

      if (data != null) {
        nes.loadSram(data);

        toaster.send(Toast.info('SRAM save loaded'));
      }
    }
  }

  void _dispose() {
    _autoSaveTimer?.cancel();
    _lifecycleListener.dispose();

    unawaited(_eventSubscription?.cancel());
    unawaited(_isolate?.dispose());
  }

  void _appSuspended() {
    if (lifeCycleListenerEnabled) {
      suspend();
    }
  }

  void _appResumed() {
    if (lifeCycleListenerEnabled) {
      resume();
    }
  }

  void setAutoSave({required bool enabled, required int? interval}) {
    _autoSaveTimer?.cancel();

    if (enabled && interval != null) {
      _autoSaveTimer = Timer.periodic(
        Duration(minutes: interval),
        (_) => unawaited(_autoSave()),
      );
    }
  }

  Uint8List _loadZip(String path, Uint8List data) {
    final archive = ZipDecoder().decodeBytes(data);

    final roms = archive.files
        .where((file) => p.extension(file.name) == '.nes')
        .toList();

    if (roms.isEmpty) {
      throw EmptyArchive(path);
    }

    if (roms.length > 1) {
      throw TooManyRoms(path);
    }

    return Uint8List.fromList(roms.single.content as List<int>);
  }

  void _updateRoute(String? route) {
    if (route == EmulatorRoute.name) {
      lifeCycleListenerEnabled = true;

      resume();
    } else {
      suspend();

      lifeCycleListenerEnabled = false;
    }
  }

  Uint8List? _autoLoadBytes(RomInfo romInfo) {
    if (!settingsController.autoLoad) {
      return null;
    }

    return romManager.loadLatestState(romInfo);
  }

  String _cheatsKey(RomInfo romInfo) =>
      romInfo.romHash ?? romInfo.hash ?? romInfo.file.name;

  Future<void> _autoSave() async {
    if (nes case final nes?) {
      if (!nes.running) {
        return;
      }

      final data = await nes.requestSaveState();

      if (data == null) {
        toaster.send(Toast.error('Failed to save state'));

        return;
      }

      await romManager.saveState(nes.romInfo, 0, data);

      toaster.send(Toast.info('Saved state to slot 0'));
    }
  }
}
