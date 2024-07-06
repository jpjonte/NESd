import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:nes/audio/audio_output.dart';
import 'package:nes/exception/empty_archive.dart';
import 'package:nes/exception/too_many_roms.dart';
import 'package:nes/exception/unsupported_file_type.dart';
import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/nes/nes.dart';
import 'package:nes/nes/ppu/frame_buffer.dart';
import 'package:nes/ui/emulator/save_manager.dart';
import 'package:nes/ui/settings/settings.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nes_controller.g.dart';

@riverpod
class NesController extends _$NesController {
  NesController() {
    _lifecycleListener = AppLifecycleListener(
      onPause: suspend,
      onInactive: suspend,
      onShow: suspend,
      onResume: _appResumed,
    );

    audioSampleStream.listen(_audioOutput.processSamples);
  }

  @override
  NES? build() {
    ref
      ..listen(
        settingsControllerProvider.select((settings) => settings.volume),
        (_, volume) => _audioOutput.volume = volume,
        fireImmediately: true,
      )
      ..listen(
        settingsControllerProvider
            .select((settings) => settings.autoSaveInterval),
        (_, interval) => _setAutoSave(interval),
        fireImmediately: true,
      )
      ..onDispose(_dispose);

    return null;
  }

  // ignore: unused_field
  late final AppLifecycleListener _lifecycleListener;

  bool lifeCycleListenerEnabled = true;

  final _audioOutput = AudioOutput();

  double get volume => _audioOutput.volume;

  set volume(double value) => _audioOutput.volume = value;

  final _saveManager = SaveManager();

  Timer? _autoSaveTimer;

  final StreamController<NesEvent> _streamController =
      StreamController.broadcast();

  Stream<FrameBuffer> get frameBufferStream => _streamController.stream
      .where((event) => event is FrameNesEvent)
      .map((event) => (event as FrameNesEvent).frameBuffer);

  Stream<Float32List> get audioSampleStream => _streamController.stream
      .where((event) => event is FrameNesEvent)
      .map((event) => (event as FrameNesEvent).samples);

  Future<void> loadCartridge(String path) async {
    state?.stop();

    final rom = switch (p.extension(path)) {
      '.nes' => await File(path).readAsBytes(),
      '.zip' => _loadZip(path),
      _ => throw UnsupportedFileType(p.extension(path)),
    };

    final cartridge = Cartridge.fromFile(path, rom);

    // give the loop a chance to end
    await Future.delayed(const Duration(milliseconds: 500));

    _save();

    state = NES(cartridge);
  }

  Future<void> run() async {
    state?.run().listen((event) => _streamController.add(event)).onError(
      // ignore: avoid_types_on_closure_parameters
      (Object error, StackTrace stackTrace) {
        return _streamController.addError(error, stackTrace);
      },
    );

    _load();
  }

  void suspend() => state?.suspend();

  void togglePause() => state?.togglePause();

  void resume() => state?.resume();

  void reset() {
    state?.reset();
    _audioOutput.reset();
    _load();
  }

  void save() => _save();

  void runUntilFrame() => state?.runUntilFrame();

  void stop() {
    state?.stop();
    state = null;
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
      await loadCartridge(path);
      run();
    } on Exception catch (e) {
      _streamController.addError('Failed to load ROM: $e');

      resume();
    }
  }

  void _dispose() {
    _autoSaveTimer?.cancel();
    _audioOutput.dispose();
  }

  void _appResumed() {
    if (lifeCycleListenerEnabled) {
      resume();
    }
  }

  void _setAutoSave(int? interval) {
    _autoSaveTimer?.cancel();

    if (interval != null) {
      _autoSaveTimer = Timer.periodic(
        Duration(minutes: interval),
        (_) => save(),
      );
    }
  }

  void _save() {
    if (state case final state?) {
      _saveManager.save(state);
    }
  }

  void _load() {
    if (state case final state?) {
      _saveManager.load(state);
    }
  }

  Uint8List _loadZip(String path) {
    final inputStream = InputFileStream(path);
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
}
