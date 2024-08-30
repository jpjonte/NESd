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
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/file_system.dart';
import 'package:nesd/ui/router.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nes_controller.g.dart';

@riverpod
class NesState extends _$NesState {
  @override
  NES? build() {
    return null;
  }

  NES? get nes => state;

  void run({required Cartridge cartridge, required EventBus eventBus}) {
    final newNes = NES(cartridge: cartridge, eventBus: eventBus);

    state = newNes;

    newNes.run();
  }

  void stop() {
    state?.stop();
    state = null;
  }
}

@riverpod
NesController nesController(NesControllerRef ref) {
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
    settingsControllerProvider
        .select((settings) => (settings.autoSave, settings.autoSaveInterval)),
    (_, setting) => controller.setAutoSave(
      enabled: setting.$1,
      interval: setting.$2,
    ),
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
      ..onError(
        // ignore: avoid_types_on_closure_parameters
        (Object error, StackTrace stackTrace) {
          toaster.send(Toast.error(error.toString()));
          nesState.stop();
        },
      );
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

  // ignore: unused_field
  late final AppLifecycleListener _lifecycleListener;

  bool lifeCycleListenerEnabled = true;

  Timer? _autoSaveTimer;

  StreamSubscription<NesEvent>? _nesEventSubscription;

  Future<Cartridge> loadCartridge(String path) async {
    nes?.stop();

    final data = await fileSystem.read(path);

    final rom = switch (p.extension(path)) {
      '.nes' => data,
      '.zip' => _loadZip(path, data),
      _ => throw UnsupportedFileType(p.extension(path)),
    };

    final cartridge = Cartridge.fromFile(path, rom);

    // give the loop a chance to end
    await Future.delayed(const Duration(milliseconds: 500));

    _save();

    return cartridge;
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

  Future<void> loadRom(String path) async {
    suspend();

    try {
      final cartridge = await loadCartridge(path);

      nesState.run(eventBus: eventBus, cartridge: cartridge);

      settingsController.addRecentRom(cartridge.romInfo);

      _load();
    } on Exception catch (e) {
      toaster.send(Toast.error('Failed to load ROM: $e'));

      resume();
    }
  }

  void _handleNesEvent(NesEvent event) {
    if (event is FrameNesEvent) {
      audioOutput.processSamples(event.samples);
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

  void setAutoSave({
    required bool enabled,
    required int? interval,
  }) {
    _autoSaveTimer?.cancel();

    if (enabled && interval != null) {
      _autoSaveTimer = Timer.periodic(
        Duration(minutes: interval),
        (_) {
          if (nes == null) {
            return;
          }

          if (!nes!.running) {
            return;
          }

          if (nes case final nes?) {
            romManager.saveState(nes, 0);
          }
        },
      );
    }
  }

  void _save() {
    if (nes case final nes?) {
      romManager.save(nes);
    }
  }

  void _load() {
    if (nes case final nes?) {
      romManager.load(nes);
    }
  }

  Uint8List _loadZip(String path, Uint8List data) {
    final inputStream = InputStream(data);
    final archive = ZipDecoder().decodeBuffer(inputStream);

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
      romManager.saveThumbnail(nes);
    }
  }
}
