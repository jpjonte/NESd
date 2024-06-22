import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:nes/audio/audio_output.dart';
import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/nes/nes.dart';
import 'package:nes/nes/ppu/frame_buffer.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/emulator/input/keyboard_input.dart';
import 'package:nes/ui/emulator/save_manager.dart';
import 'package:nes/ui/settings/settings.dart';
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
      ..listen(
        keyboardInputProvider,
        (_, input) {
          input
            ..keyDownStream.listen(_handleActionDown)
            ..keyUpStream.listen(_handleActionUp);
        },
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

    final cartridge = Cartridge.fromFile(path);

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

  void _saveState(int slot) {
    if (state case final state?) {
      _saveManager.saveState(state, slot);
    }
  }

  void _loadState(int slot) {
    if (state case final state?) {
      _saveManager.loadState(state, slot);
    }
  }

  void _handleActionDown(NesAction action) {
    switch (action) {
      case ControllerPress():
        state?.buttonDown(action.controller, action.button);
      case SaveState():
        _saveState(action.slot);
      case LoadState():
        _loadState(action.slot);
    }
  }

  void _handleActionUp(NesAction action) {
    switch (action) {
      case ControllerPress():
        state?.buttonUp(action.controller, action.button);
      default:
      // no-op
    }
  }
}
