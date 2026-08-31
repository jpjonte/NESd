import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide Router;
import 'package:nesd/exception/empty_archive.dart';
import 'package:nesd/exception/too_many_roms.dart';
import 'package:nesd/exception/unsupported_file_type.dart';
import 'package:nesd/features.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/isolate/local_nes_handle.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/emulator_active.dart';
import 'package:nesd/ui/emulator/nes_palette_provider.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/emulator/rom_importer.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/zip_filesystem.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nes_controller.g.dart';

const mobileRewindCaptureInterval = 4;

typedef NesIsolateSpawner = Future<NesIsolateHandle> Function();

@riverpod
NesIsolateSpawner nesIsolateSpawner(Ref ref) =>
    kIsWeb ? LocalNesHandle.spawn : NesIsolate.spawn;

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
    router: ref.read(routerProvider),
    settingsController: ref.read(settingsControllerProvider.notifier),
    toaster: ref.watch(toasterProvider),
    romManager: ref.watch(romManagerProvider),
    filesystem: ref.read(filesystemProvider),
    database: ref.watch(databaseProvider),
    cartridgeFactory: ref.watch(cartridgeFactoryProvider),
    romImporter: ref.watch(romImporterProvider),
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

  final lowPassFilterSubscription = ref.listen(
    settingsControllerProvider.select((settings) => settings.lowPassFilter),
    (_, enabled) => controller.nes?.lowPassFilter = enabled,
    fireImmediately: true,
  );

  ref.onDispose(lowPassFilterSubscription.close);

  final swapDutyCyclesSubscription = ref.listen(
    settingsControllerProvider.select((settings) => settings.swapDutyCycles),
    (_, enabled) => controller.nes?.swapDutyCycles = enabled,
    fireImmediately: true,
  );

  ref.onDispose(swapDutyCyclesSubscription.close);

  final paletteSubscription = ref.listen(
    nesPaletteProvider,
    (_, palette) => controller.systemPalette = palette,
    fireImmediately: true,
  );

  ref.onDispose(paletteSubscription.close);

  final fastForwardSpeedSubscription = ref.listen(
    settingsControllerProvider.select((settings) => settings.fastForwardSpeed),
    (_, speed) => controller.nes?.fastForwardSpeed = speed,
    fireImmediately: true,
  );

  ref.onDispose(fastForwardSpeedSubscription.close);

  final turboSpeedSubscription = ref.listen(
    settingsControllerProvider.select((settings) => settings.turboSpeed),
    (_, speed) => controller.nes?.turboSpeed = speed,
    fireImmediately: true,
  );

  ref.onDispose(turboSpeedSubscription.close);

  final regionSubscription = ref.listen(
    settingsControllerProvider.select((settings) => settings.region),
    (_, region) => controller.nes?.region = region,
    fireImmediately: true,
  );

  ref.onDispose(regionSubscription.close);

  final rewindSubscription = ref.listen(
    settingsControllerProvider.select((settings) => settings.rewind),
    (_, rewind) =>
        controller.nes?.rewindEnabled = controller.rewindSupported && rewind,
    fireImmediately: true,
  );

  ref.onDispose(rewindSubscription.close);

  final logLevelSubscription = ref.listen(
    settingsControllerProvider.select((settings) => settings.logLevel),
    (_, level) => controller._isolate?.send(SetLogLevelCommand(level: level)),
  );

  ref.onDispose(logLevelSubscription.close);

  final routeSubscription = ref.listen(
    emulatorActiveProvider,
    (_, active) => controller.emulatorActive = active,
    fireImmediately: true,
  );

  ref.onDispose(routeSubscription.close);

  return controller;
}

class NesController {
  NesController({
    required this.nesState,
    required this.spawner,
    required this.router,
    required this.settingsController,
    required this.toaster,
    required this.romManager,
    required this.filesystem,
    required this.database,
    required this.cartridgeFactory,
    required this.romImporter,
    this.romLoadTimeout = const Duration(seconds: 10),
    this.rewindSupported = Features.rewind,
  }) {
    _lifecycleListener = AppLifecycleListener(
      onPause: _appSuspended,
      onInactive: _appSuspended,
      onShow: _appSuspended,
      onResume: _appResumed,
    );
  }

  final NesState nesState;

  final Router router;

  final SettingsController settingsController;

  final Toaster toaster;

  final RomManager romManager;

  final Filesystem filesystem;

  final NesDatabase database;

  final CartridgeFactory cartridgeFactory;

  final NesIsolateSpawner spawner;

  final RomImporter romImporter;

  final Duration romLoadTimeout;

  final bool rewindSupported;

  RemoteNes? get nes => nesState.nes;

  late final AppLifecycleListener _lifecycleListener;

  bool lifeCycleListenerEnabled = true;

  bool _emulatorActive = false;

  Uint32List _systemPalette = defaultPalette;

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

  /// Reads the SRAM before issuing the reset so the restore lands right
  /// behind it in the command queue instead of frames later.
  Future<void> reset() async {
    if (nes case final nes?) {
      Uint8List? data;

      try {
        data = await romManager.load(nes.romInfo);
      } on Exception catch (e) {
        log.rom.error('Failed to load SRAM', error: e);

        toaster.send(Toast.error('Failed to load SRAM: $e'));
      }

      nes.reset();

      if (data != null) {
        nes.loadSram(data);

        toaster.send(Toast.info('SRAM save loaded'));
      }
    }
  }

  Future<void> stop() async {
    if (nes case final nes?) {
      try {
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
      } on Exception catch (e) {
        log.rom.error('Failed to save on stop', error: e);

        toaster.send(Toast.error('Failed to save game data: $e'));
      }

      await nes.stop();
    }

    nesState.clear();
  }

  Future<void> selectRom() async {
    suspend();

    final FilesystemFile? file;

    try {
      file = await romImporter.pickRom();
    } on Exception catch (e) {
      log.rom.error('Failed to import picked ROM', error: e);

      toaster.send(Toast.error('Failed to import ROM: $e'));

      _applyRunState();

      return;
    }

    if (file == null) {
      _applyRunState();

      return;
    }

    final started = await startRom(file);

    if (!started) {
      _applyRunState();
    }
  }

  /// Loads [file] and, if it loaded, switches to the emulator.
  ///
  /// This is the single entry point for opening a ROM. Navigating is part of
  /// starting a game. [loadRom] already reports failures via [Toaster], so
  /// callers only need the returned flag if they want to react themselves.
  Future<bool> startRom(
    FilesystemFile file, {
    Uint8List? stateBytes,
    Uint8List? data,
    bool suspended = false,
  }) async {
    final loaded = await loadRom(
      file,
      stateBytes: stateBytes,
      data: data,
      suspended: suspended,
    );

    if (!loaded) {
      return false;
    }

    unawaited(router.navigate(const EmulatorRoute()));

    return true;
  }

  Future<bool> loadRom(
    FilesystemFile file, {
    Uint8List? stateBytes,
    Uint8List? data,
    bool suspended = false,
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

      // make sure database is loaded before querying it
      await database.ready;

      // CartridgeFactory queries the database
      final cartridge = cartridgeFactory.fromFile(file, rom);

      cartridge.databaseEntry = database.find(cartridge.romInfo);

      final romInfo = cartridge.romInfo;
      final databaseEntry = cartridge.databaseEntry;

      if (nes case final oldNes?) {
        try {
          final oldSram = await oldNes.requestSram();

          if (oldSram != null) {
            await romManager.save(oldNes.romInfo, oldSram);
          }
        } on Exception catch (e) {
          log.rom.error('Failed to save SRAM', error: e);

          toaster.send(Toast.error('Failed to save SRAM: $e'));
        }
      }

      await nes?.stop();

      final isolate = await _ensureIsolate();

      final sram = await romManager.load(romInfo);
      final initialState = stateBytes ?? await _autoLoadBytes(romInfo);
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
          rom: NesBytes.fromList([rom]),
          file: file,
          databaseEntry: databaseEntry,
          region: settingsController.region,
          rewindEnabled: rewindSupported && settingsController.rewind,
          rewindCaptureInterval: defaultTargetPlatform == TargetPlatform.android
              ? mobileRewindCaptureInterval
              : 1,
          cheats: cheats,
          breakpoints: breakpoints,
          initialState: initialState == null
              ? null
              : NesBytes.fromList([initialState]),
          sram: sram == null ? null : NesBytes.fromList([sram]),
          suspended: suspended,
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

      remote
        ..volume = settingsController.volume
        ..lowPassFilter = settingsController.lowPassFilter
        ..fastForwardSpeed = settingsController.fastForwardSpeed
        ..turboSpeed = settingsController.turboSpeed
        ..swapDutyCycles = settingsController.swapDutyCycles
        ..systemPalette = _systemPalette;

      nesState.set(remote);

      if (sram != null && initialState == null) {
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

      // The NES that existed when the active-screen signal last changed was
      // a different one (or none at all), so apply the current run state to
      // the instance that just came up.
      _applyRunState();
    } on PathNotFoundException {
      log.rom.warning('ROM file not found', context: {'path': file.path});

      return false;
    } on TimeoutException {
      log.emulator.error(
        'Emulator did not respond. Restarting the isolate',
        context: {'path': file.path},
      );

      await _teardownIsolate();

      toaster.send(Toast.error('Emulator did not respond and was restarted'));

      remote?.dispose();
      nesState.clear();

      return false;
    } on Exception catch (e) {
      log.rom.error(
        'Failed to load ROM',
        context: {'path': file.path},
        error: e,
      );

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

    isolate.send(SetLogLevelCommand(level: settingsController.logLevel));

    return isolate;
  }

  void _handleIsolateEvent(NesIsolateEvent event) {
    switch (event) {
      case ErrorEvent(:final message):
        log.emulator.error(message);

        toaster.send(Toast.error(message));
      case LogEvent(:final record):
        NesdLog.instance.ingest(record);
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

      try {
        await romManager.saveState(nes.romInfo, slot, data);
      } on Exception catch (e) {
        log.emulator.error('Failed to save state', error: e);

        toaster.send(Toast.error('Failed to save state: $e'));

        return;
      }

      toaster.send(Toast.info('Saved state to slot $slot'));
    }
  }

  Future<void> loadState(int slot) async {
    if (nes case final nes?) {
      final Uint8List? saveState;

      try {
        saveState = await romManager.loadState(nes.romInfo, slot);
      } on Exception catch (e) {
        log.emulator.error('Failed to load state', error: e);

        toaster.send(Toast.error('Failed to load state: $e'));

        return;
      }

      if (saveState == null) {
        toaster.send(Toast.warning('No save state found in slot $slot'));
      } else {
        nes.loadState(saveState);

        toaster.send(Toast.info('State loaded from slot $slot'));
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
      _applyRunState();
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

  // ignore: avoid_setters_without_getters
  set systemPalette(Uint32List palette) {
    _systemPalette = palette;

    nes?.systemPalette = palette;
  }

  // ignore: avoid_setters_without_getters
  set emulatorActive(bool value) {
    _emulatorActive = value;
    lifeCycleListenerEnabled = value;

    _applyRunState();
  }

  void _applyRunState() {
    if (_emulatorActive) {
      resume();

      return;
    }

    suspend();
  }

  Future<Uint8List?> _autoLoadBytes(RomInfo romInfo) async {
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

      try {
        await romManager.saveState(nes.romInfo, 0, data);
      } on Exception catch (e) {
        log.emulator.error('Auto-save failed', error: e);

        toaster.send(Toast.error('Auto-save failed: $e'));

        return;
      }

      toaster.send(Toast.info('Saved state to slot 0'));
    }
  }
}
