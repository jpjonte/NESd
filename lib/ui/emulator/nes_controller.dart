import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:nes/audio/audio_output.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/nes/nes.dart';
import 'package:nes/nes/ppu/frame_buffer.dart';
import 'package:nes/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nes_controller.g.dart';

final logicalKeyToNesButton = {
  LogicalKeyboardKey.arrowUp: NesButton.up,
  LogicalKeyboardKey.arrowDown: NesButton.down,
  LogicalKeyboardKey.arrowLeft: NesButton.left,
  LogicalKeyboardKey.arrowRight: NesButton.right,
  LogicalKeyboardKey.enter: NesButton.start,
  LogicalKeyboardKey.shiftRight: NesButton.select,
  LogicalKeyboardKey.keyZ: NesButton.a,
  LogicalKeyboardKey.keyX: NesButton.b,
};

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
  }

  @override
  NES build() {
    HardwareKeyboard.instance.addHandler(_handleKey);

    _cartridgeState = ref.read(cartridgeStateProvider.notifier);

    audioSampleStream.listen(_audioOutput.processSamples);

    final settings = ref.read(settingsControllerProvider);

    _audioOutput.volume = settings.volume;

    ref.listen(
      settingsControllerProvider.select((settings) => settings.volume),
      (_, volume) => _audioOutput.volume = volume,
    );

    ref.listen(
      settingsControllerProvider
          .select((settings) => settings.autoSaveInterval),
      (_, interval) => _setAutoSave(interval),
    );

    _setAutoSave(settings.autoSaveInterval);

    return NES();
  }

  final _audioOutput = AudioOutput();

  double get volume => _audioOutput.volume;

  bool lifeCycleListenerEnabled = true;

  set volume(double value) => _audioOutput.volume = value;

  // ignore: unused_field
  late final AppLifecycleListener _lifecycleListener;
  late final CartridgeState _cartridgeState;

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
    sendCommand(NesStopCommand());

    final cartridge = Cartridge.fromFile(path);

    // give the loop a chance to end
    await Future.delayed(const Duration(milliseconds: 500));

    _cartridgeState.cartridge = cartridge;

    state.loadCartridge(cartridge);
  }

  Future<void> run() async {
    state.run().listen((event) => _streamController.add(event)).onError(
      // ignore: avoid_types_on_closure_parameters
      (Object error, StackTrace stackTrace) {
        return _streamController.addError(error, stackTrace);
      },
    );
  }

  void suspend() => sendCommand(NesSuspendCommand());

  void togglePause() => sendCommand(NesTogglePauseCommand());

  void resume() => sendCommand(NesResumeCommand());

  void reset() {
    sendCommand(NesResetCommand());
    _audioOutput.reset();
  }

  void save() => state.bus.cartridge?.save();

  void runUntilFrame() => sendCommand(NesRunUntilFrameCommand());

  void sendCommand(NesCommand command) => state.executeCommand(command);

  bool _handleKey(KeyEvent event) {
    final button = logicalKeyToNesButton[event.logicalKey];

    if (button == null) {
      return false;
    }

    switch (event) {
      case final KeyDownEvent _:
        sendCommand(NesButtonDownCommand(0, button));
      case final KeyUpEvent _:
        sendCommand(NesButtonUpCommand(0, button));
    }

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
}
