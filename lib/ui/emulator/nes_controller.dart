import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:nes/audio/audio_output.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/nes/nes.dart';
import 'package:nes/nes/ppu/frame_buffer.dart';
import 'package:nes/ui/emulator/save_manager.dart';
import 'package:nes/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nes_controller.g.dart';

@riverpod
class CartridgeState extends _$CartridgeState {
  @override
  Cartridge? build() {
    return state = null;
  }

  Cartridge? get cartridge => state;

  set cartridge(Cartridge? cartridge) {
    state = cartridge;
  }
}

@riverpod
class NesController extends _$NesController {
  NesController() {
    _lifecycleListener = AppLifecycleListener(
      onPause: suspend,
      onInactive: suspend,
      onShow: suspend,
      onResume: _appResumed,
    );

    HardwareKeyboard.instance.addHandler(_handleKey);

    audioSampleStream.listen(_audioOutput.processSamples);
  }

  @override
  NES? build() {
    _cartridgeState = ref.read(cartridgeStateProvider.notifier);

    final settings = ref.read(settingsControllerProvider);

    _audioOutput.volume = settings.volume;

    ref
      ..listen(
        settingsControllerProvider.select((settings) => settings.volume),
        (_, volume) => _audioOutput.volume = volume,
      )
      ..listen(
        settingsControllerProvider
            .select((settings) => settings.autoSaveInterval),
        (_, interval) => _setAutoSave(interval),
      )
      ..onDispose(_dispose);

    _setAutoSave(settings.autoSaveInterval);

    return null;
  }

  late final _keyMap = {
    (LogicalKeyboardKey.arrowUp, KeyDownEvent, shift: false): () =>
        state?.buttonDown(0, NesButton.up),
    (LogicalKeyboardKey.arrowUp, KeyUpEvent, shift: false): () =>
        state?.buttonUp(0, NesButton.up),
    (LogicalKeyboardKey.arrowDown, KeyDownEvent, shift: false): () =>
        state?.buttonDown(0, NesButton.down),
    (LogicalKeyboardKey.arrowDown, KeyUpEvent, shift: false): () =>
        state?.buttonUp(0, NesButton.down),
    (LogicalKeyboardKey.arrowLeft, KeyDownEvent, shift: false): () =>
        state?.buttonDown(0, NesButton.left),
    (LogicalKeyboardKey.arrowLeft, KeyUpEvent, shift: false): () =>
        state?.buttonUp(0, NesButton.left),
    (LogicalKeyboardKey.arrowRight, KeyDownEvent, shift: false): () =>
        state?.buttonDown(0, NesButton.right),
    (LogicalKeyboardKey.arrowRight, KeyUpEvent, shift: false): () =>
        state?.buttonUp(0, NesButton.right),
    (LogicalKeyboardKey.enter, KeyDownEvent, shift: false): () =>
        state?.buttonDown(0, NesButton.start),
    (LogicalKeyboardKey.enter, KeyUpEvent, shift: false): () =>
        state?.buttonUp(0, NesButton.start),
    (LogicalKeyboardKey.shiftRight, KeyDownEvent, shift: true): () =>
        state?.buttonDown(0, NesButton.select),
    (LogicalKeyboardKey.shiftRight, KeyUpEvent, shift: false): () =>
        state?.buttonUp(0, NesButton.select),
    (LogicalKeyboardKey.keyZ, KeyDownEvent, shift: false): () =>
        state?.buttonDown(0, NesButton.a),
    (LogicalKeyboardKey.keyZ, KeyUpEvent, shift: false): () =>
        state?.buttonUp(0, NesButton.a),
    (LogicalKeyboardKey.keyX, KeyDownEvent, shift: false): () =>
        state?.buttonDown(0, NesButton.b),
    (LogicalKeyboardKey.keyX, KeyUpEvent, shift: false): () =>
        state?.buttonUp(0, NesButton.b),
    (LogicalKeyboardKey.digit1, KeyDownEvent, shift: false): () =>
        _loadState(1),
    (LogicalKeyboardKey.digit1, KeyDownEvent, shift: true): () => _saveState(1),
    (LogicalKeyboardKey.digit2, KeyDownEvent, shift: false): () =>
        _loadState(2),
    (LogicalKeyboardKey.digit2, KeyDownEvent, shift: true): () => _saveState(2),
    (LogicalKeyboardKey.digit3, KeyDownEvent, shift: false): () =>
        _loadState(3),
    (LogicalKeyboardKey.digit3, KeyDownEvent, shift: true): () => _saveState(3),
    (LogicalKeyboardKey.digit4, KeyDownEvent, shift: false): () =>
        _loadState(4),
    (LogicalKeyboardKey.digit4, KeyDownEvent, shift: true): () => _saveState(4),
    (LogicalKeyboardKey.digit5, KeyDownEvent, shift: false): () =>
        _loadState(5),
    (LogicalKeyboardKey.digit5, KeyDownEvent, shift: true): () => _saveState(5),
    (LogicalKeyboardKey.digit6, KeyDownEvent, shift: false): () =>
        _loadState(6),
    (LogicalKeyboardKey.digit6, KeyDownEvent, shift: true): () => _saveState(6),
    (LogicalKeyboardKey.digit7, KeyDownEvent, shift: false): () =>
        _loadState(7),
    (LogicalKeyboardKey.digit7, KeyDownEvent, shift: true): () => _saveState(7),
    (LogicalKeyboardKey.digit8, KeyDownEvent, shift: false): () =>
        _loadState(8),
    (LogicalKeyboardKey.digit8, KeyDownEvent, shift: true): () => _saveState(8),
    (LogicalKeyboardKey.digit9, KeyDownEvent, shift: false): () =>
        _loadState(9),
    (LogicalKeyboardKey.digit9, KeyDownEvent, shift: true): () => _saveState(9),
    (LogicalKeyboardKey.digit0, KeyDownEvent, shift: false): () =>
        _loadState(0),
    (LogicalKeyboardKey.digit0, KeyDownEvent, shift: true): () => _saveState(0),
  };

  // ignore: unused_field
  late final AppLifecycleListener _lifecycleListener;

  bool lifeCycleListenerEnabled = true;

  final _audioOutput = AudioOutput();

  double get volume => _audioOutput.volume;

  set volume(double value) => _audioOutput.volume = value;

  late CartridgeState _cartridgeState;

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

    _cartridgeState.cartridge = cartridge;

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
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _autoSaveTimer?.cancel();
    _audioOutput.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyRepeatEvent) {
      return true;
    }

    final action = _keyMap[(
      event.logicalKey,
      event.runtimeType,
      shift: HardwareKeyboard.instance.isShiftPressed,
    )];

    if (action == null) {
      return false;
    }

    action();

    return true;
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
}
