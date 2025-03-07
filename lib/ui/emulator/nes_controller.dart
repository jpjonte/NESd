import 'dart:async';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart' hide Router;
import 'package:nesd/audio/audio_output.dart';
import 'package:nesd/exception/empty_archive.dart';
import 'package:nesd/exception/too_many_roms.dart';
import 'package:nesd/exception/unsupported_file_type.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/nes_state.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/file_system.dart';
import 'package:nesd/ui/file_picker/file_system/zip_file_system.dart';
import 'package:nesd/ui/router.dart';
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
    router: ref.read(routerProvider),
    settingsController: ref.read(settingsControllerProvider.notifier),
    toaster: ref.watch(toasterProvider),
    romManager: ref.watch(romManagerProvider),
    fileSystem: ref.read(fileSystemProvider),
  );

  ref.onDispose(controller._dispose);

  final settingsSubscription = ref.listen(
    settingsControllerProvider.select(
      (settings) => (settings.autoSave, settings.autoSaveInterval),
    ),
    (_, setting) =>
        controller.setAutoSave(enabled: setting.$1, interval: setting.$2),
    fireImmediately: true,
  );

  ref.onDispose(settingsSubscription.close);

  return controller;
}

class NesController {
  NesController({
    required this.eventBus,
    required this.nesState,
    required this.audioOutput,
    required this.router,
    required this.settingsController,
    required this.toaster,
    required this.romManager,
    required this.fileSystem,
  }) {
    _lifecycleListener = AppLifecycleListener(
      onPause: _appSuspended,
      onInactive: _appSuspended,
      onShow: _appSuspended,
      onResume: _appResumed,
    );

    router.addListener(_updateRoute);

    _nesEventSubscription = eventBus.stream.listen(_handleNesEvent)
      ..onError((error, stackTrace) {
        toaster.send(Toast.error(error.toString()));
        nesState.stop();
      });
  }

  final EventBus eventBus;

  final NesState nesState;

  final AudioOutput audioOutput;

  final Router router;

  final SettingsController settingsController;

  final Toaster toaster;

  final RomManager romManager;

  final FileSystem fileSystem;

  NES? get nes => nesState.nes;

  late final AppLifecycleListener _lifecycleListener;

  bool lifeCycleListenerEnabled = true;

  Timer? _autoSaveTimer;

  StreamSubscription<NesEvent>? _nesEventSubscription;

  Future<Cartridge> loadCartridge(String path) async {
    final loaded = nes != null;

    nes?.stop();

    final data = await _readFile(path);

    final rom = switch (p.extension(path)) {
      '.nes' => data,
      '.zip' => _loadZip(path, data),
      _ => throw UnsupportedFileType(p.extension(path)),
    };

    final cartridge = Cartridge.fromFile(path, rom);

    if (loaded) {
      // give the existing loop a chance to end
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _save();

    return cartridge;
  }

  Future<Uint8List> _readFile(String path) async {
    final data = await switch (path.contains(':') && path.contains('.zip')) {
      true => ZipFileSystem(
        path: path.split(':').first,
        zipData: await fileSystem.read(path.split(':').first),
      ).read(path.split(':').last),
      false => fileSystem.read(path),
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

    await loadRom(path);
  }

  Future<void> loadRom(String path, {NESState? state}) async {
    suspend();

    try {
      final cartridge = await loadCartridge(path);

      final newNes = NES(cartridge: cartridge, eventBus: eventBus)..reset();

      final newState = state ?? _handleAutoLoad(newNes);

      if (newState != null) {
        newNes.state = newState;
      }

      nesState.run(newNes);

      setAutoSave(
        enabled: settingsController.autoSave,
        interval: settingsController.autoSaveInterval,
      );

      settingsController.addRecentRom(cartridge.romInfo);

      _load();
    } on Exception catch (e) {
      toaster.send(Toast.error('Failed to load ROM: $e'));

      resume();
    }
  }

  void saveState(int slot) {
    if (nes case final nes?) {
      final data = nes.state.serialize();

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
    router.removeListener(_updateRoute);
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

  void _updateRoute() {
    final route = router.current.name;

    if (route == MainRoute.name) {
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
        final data = nes.state.serialize();

        romManager.saveState(nes.bus.cartridge.romInfo, 0, data);

        toaster.send(Toast.info('Saved state to slot 0'));
      }
    }
  }
}
