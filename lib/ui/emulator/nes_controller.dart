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
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/ui/emulator/save_manager.dart';
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

  Stream<NesEvent> run(Cartridge cartridge) {
    final newNes = NES(cartridge);

    state = newNes;

    return newNes.run();
  }

  void stop() {
    state?.stop();
    state = null;
  }
}

@riverpod
NesController nesController(NesControllerRef ref) {
  final controller = NesController(
    nesState: ref.watch(nesStateProvider.notifier),
    audioOutput: ref.watch(audioOutputProvider),
    router: ref.read(routerProvider),
    settingsController: ref.read(settingsControllerProvider.notifier),
    toaster: ref.watch(toasterProvider),
    saveManager: ref.watch(saveManagerProvider),
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
    required this.nesState,
    required this.audioOutput,
    required this.router,
    required this.settingsController,
    required this.toaster,
    required this.saveManager,
    required this.fileSystem,
  }) {
    _lifecycleListener = AppLifecycleListener(
      onPause: _appSuspended,
      onInactive: _appSuspended,
      onShow: _appSuspended,
      onResume: _appResumed,
    );

    router.addListener(_updateRoute);
  }

  final NesState nesState;

  final AudioOutput audioOutput;

  final Router router;

  final SettingsController settingsController;

  final Toaster toaster;

  final SaveManager saveManager;

  final FileSystem fileSystem;

  NES? get nes => nesState.nes;

  // ignore: unused_field
  late final AppLifecycleListener _lifecycleListener;

  bool lifeCycleListenerEnabled = true;

  Timer? _autoSaveTimer;

  final StreamController<NesEvent> _streamController =
      StreamController.broadcast();

  Stream<FrameNesEvent> get frameEventStream => _streamController.stream
      .where((event) => event is FrameNesEvent)
      .map((event) => event as FrameNesEvent);

  Stream<FrameBuffer> get frameBufferStream =>
      frameEventStream.map((event) => event.frameBuffer);

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

  void togglePause() => nes?.togglePause();

  void resume() => nes?.resume();

  void reset() {
    nes?.reset();
    audioOutput.reset();
    _load();
  }

  void save() => _save();

  void runUntilFrame() => nes?.runUntilFrame();

  void stop() {
    nes?.stop();
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

      _nesEventSubscription?.cancel();

      _nesEventSubscription = nesState.run(cartridge).listen(_handleNesEvent)
        ..onError(
          // ignore: avoid_types_on_closure_parameters
          (Object error, StackTrace stackTrace) {
            toaster.send(Toast.error(error.toString()));
            nesState.stop();
          },
        );

      settingsController.addRecentRomPath(path);

      _load();
    } on Exception catch (e) {
      toaster.send(Toast.error('Failed to load ROM: $e'));

      resume();
    }
  }

  void _handleNesEvent(NesEvent event) {
    _streamController.add(event);

    if (event is FrameNesEvent) {
      audioOutput.processSamples(event.samples);
    }
  }

  void _dispose() {
    _autoSaveTimer?.cancel();
    audioOutput.dispose();
    _streamController.close();
    _lifecycleListener.dispose();
    router.removeListener(_updateRoute);
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

          saveManager.saveState(nes, 0);
        },
      );
    }
  }

  void _save() {
    saveManager.save(nes);
  }

  void _load() {
    saveManager.load(nes);
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
}
