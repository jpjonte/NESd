import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart' hide Router;
import 'package:nesd/audio/audio_output.dart';
import 'package:nesd/exception/empty_archive.dart';
import 'package:nesd/exception/too_many_roms.dart';
import 'package:nesd/exception/unsupported_file_type.dart';
import 'package:nesd/extension/string_extension.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/nes/serialization/nes_state.dart';
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

@riverpod
class NesState extends _$NesState {
  @override
  NES? build() {
    return null;
  }

  NES? get nes => state;

  void run(NES newNes) {
    state?.stop();

    state = newNes;

    newNes.run();
  }

  void stop() {
    state?.stop();
    state = null;
  }
}

@riverpod
NesController nesController(Ref ref) {
  final controller = NesController(
    eventBus: ref.watch(eventBusProvider),
    nesState: ref.watch(nesStateProvider.notifier),
    audioOutput: ref.watch(audioOutputProvider),
    settingsController: ref.read(settingsControllerProvider.notifier),
    toaster: ref.watch(toasterProvider),
    romManager: ref.watch(romManagerProvider),
    filesystem: ref.read(filesystemProvider),
    database: ref.watch(databaseProvider),
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

  final regionSubscription = ref.listen(
    settingsControllerProvider.select((settings) => settings.region),
    (_, region) {
      if (controller.nes case final nes?) {
        controller._setRegion(nes, region);
      }
    },
    fireImmediately: true,
  );

  ref.onDispose(regionSubscription.close);

  final routeSubscription = ref.listen(
    routerObserverProvider,
    (_, route) => controller._updateRoute(route),
  );

  ref.onDispose(routeSubscription.close);

  return controller;
}

class NesController {
  NesController({
    required this.eventBus,
    required this.nesState,
    required this.audioOutput,
    required this.settingsController,
    required this.toaster,
    required this.romManager,
    required this.filesystem,
    required this.database,
  }) {
    _lifecycleListener = AppLifecycleListener(
      onPause: _appSuspended,
      onInactive: _appSuspended,
      onShow: _appSuspended,
      onResume: _appResumed,
    );

    _nesEventSubscription = eventBus.stream.listen(_handleNesEvent)
      ..onError((error, stackTrace) {
        toaster.send(Toast.error(error.toString()));
        nesState.stop();
      });
  }

  final EventBus eventBus;

  final NesState nesState;

  final AudioOutput audioOutput;

  final SettingsController settingsController;

  final Toaster toaster;

  final RomManager romManager;

  final Filesystem filesystem;

  final NesDatabase database;

  NES? get nes => nesState.nes;

  late final AppLifecycleListener _lifecycleListener;

  bool lifeCycleListenerEnabled = true;

  Timer? _autoSaveTimer;

  StreamSubscription<NesEvent>? _nesEventSubscription;

  bool get isOn => nesState.nes != null;

  Future<Cartridge> loadCartridge(FilesystemFile file) async {
    final loaded = nes != null;

    nes?.stop();

    final data = await _readFile(file.path);

    final extension = p.extension(file.name);

    final rom = switch (extension) {
      '.nes' => data,
      '.zip' => _loadZip(file.path, data),
      _ => throw UnsupportedFileType(extension),
    };

    final cartridge = Cartridge.fromFile(file, rom);

    cartridge.databaseEntry = database.find(cartridge.romInfo);

    if (loaded) {
      // give the existing loop a chance to end
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _save();

    return cartridge;
  }

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

  void reset() {
    nes?.reset();
    audioOutput.reset();
    _load();
  }

  void runUntilFrame() => nes?.runUntilFrame();

  void stop() {
    _save();
    _saveThumbnail();
    nesState.stop();
  }

  Future<void> selectRom() async {
    suspend();

    final result = await FilePicker.platform.pickFiles(
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

  Future<bool> loadRom(FilesystemFile file, {NESState? state}) async {
    suspend();

    nes?.stop();

    try {
      final cartridge = await loadCartridge(file);

      final newNes = NES(cartridge: cartridge, eventBus: eventBus)..reset();

      final newState = state ?? _handleAutoLoad(newNes);

      if (newState != null) {
        newNes.state = newState;
      }

      _setRegion(newNes, settingsController.region);

      nesState.run(newNes);

      setAutoSave(
        enabled: settingsController.autoSave,
        interval: settingsController.autoSaveInterval,
      );

      settingsController.addRecentRom(cartridge.romInfo);

      _load();
    } on PathNotFoundException {
      return false;
    } on Exception catch (e) {
      toaster.send(Toast.error('Failed to load ROM: $e'));

      resume();
    }

    return true;
  }

  void _setRegion(NES nes, Region? region) {
    nes.region = region ?? _autoDetectRegion(nes.bus.cartridge) ?? Region.ntsc;
  }

  void saveState(int slot) {
    if (nes case final nes?) {
      final data = nes.state?.serialize();

      if (data == null) {
        toaster.send(Toast.error('Failed to save state'));

        return;
      }

      romManager.saveState(nes.bus.cartridge.romInfo, slot, data);

      toaster.send(Toast.info('Saved state to slot $slot'));
    }
  }

  void loadState(int slot) {
    if (nes case final nes?) {
      final saveState = romManager.loadState(nes.bus.cartridge.romInfo, slot);

      if (saveState == null) {
        toaster.send(Toast.warning('No save state found in slot $slot'));
      } else {
        nes.state = NESState.fromBytes(saveState);

        toaster.send(Toast.info('State loaded from slot $slot'));
      }
    }
  }

  void _handleNesEvent(NesEvent event) {
    switch (event) {
      case FrameNesEvent():
        audioOutput.processSamples(event.samples);
      case ErrorNesEvent():
        toaster.send(Toast.error(event.error.toString()));
      default:
      // do nothing
    }
  }

  void _dispose() {
    _autoSaveTimer?.cancel();
    audioOutput.dispose();
    _lifecycleListener.dispose();
    _nesEventSubscription?.cancel();
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
        (_) => _autoSave(),
      );
    }
  }

  void _save() {
    if (nes case final nes?) {
      final data = nes.save();

      if (data != null) {
        romManager.save(nes.bus.cartridge.romInfo, data);

        toaster.send(Toast.info('SRAM saved'));
      }
    }
  }

  void _load() {
    if (nes case final nes?) {
      final data = romManager.load(nes.bus.cartridge.romInfo);

      if (data != null) {
        nes.load(data);

        toaster.send(Toast.info('SRAM save loaded'));
      }
    }
  }

  Uint8List _loadZip(String path, Uint8List data) {
    final archive = ZipDecoder().decodeBytes(data);

    final roms =
        archive.files
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

  void _saveThumbnail() {
    if (nes case final nes?) {
      romManager.saveThumbnail(nes.bus.cartridge.romInfo, nes.ppu.frameBuffer);
    }
  }

  NESState? _handleAutoLoad(NES newNes) {
    if (!settingsController.autoLoad) {
      return null;
    }

    final data = romManager.loadLatestState(newNes.bus.cartridge.romInfo);

    if (data == null) {
      return null;
    }

    toaster.send(Toast.info('Loaded latest save state'));

    return NESState.fromBytes(data);
  }

  void _autoSave() {
    if (nes case final nes?) {
      if (nes.running) {
        final data = nes.state?.serialize();

        if (data == null) {
          toaster.send(Toast.error('Failed to save state'));

          return;
        }

        romManager.saveState(nes.bus.cartridge.romInfo, 0, data);

        toaster.send(Toast.info('Saved state to slot 0'));
      }
    }
  }

  Region? _autoDetectRegion(Cartridge cartridge) {
    final databaseEntry = cartridge.databaseEntry;

    if (databaseEntry != null) {
      return databaseEntry.region;
    }

    final filename = cartridge.romInfo.file.name.toUpperCase();

    if (filename.containsAny(['(U)', '(USA)', '(J)', '(JU)', '(NTSC)'])) {
      return Region.ntsc;
    }

    if (filename.containsAny(['(E)', '(EUR)', '(EUROPE)', '(PAL)'])) {
      return Region.pal;
    }

    return null;
  }
}
