import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/nes/nes.dart';
import 'package:nes/nes/ppu/frame_buffer.dart';
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
      onShow: resume,
      onResume: resume,
    );
  }

  @override
  NES build() {
    HardwareKeyboard.instance.addHandler(_handleKey);

    _cartridgeState = ref.read(cartridgeStateProvider.notifier);
    _audioStream = getAudioStream();

    _audioStream
      ..init(bufferMilliSec: 100)
      ..resume();

    audioSampleStream.listen(_processSamples);

    return NES();
  }

  double _volume = 1.0;

  double get volume => _volume;

  final _audioBuffer = Float32List(44100);

  int _audioBufferIndex = 0;

  set volume(double value) {
    _volume = value.clamp(0.0, 1.0);
  }

  // ignore: unused_field
  late final AppLifecycleListener _lifecycleListener;
  late final CartridgeState _cartridgeState;
  late final AudioStream _audioStream;

  final StreamController<NesEvent> _streamController =
      StreamController.broadcast();

  Stream<FrameBuffer> get frameBufferStream => _streamController.stream
      .where((event) => event is FrameNesEvent)
      .map((event) => (event as FrameNesEvent).frameBuffer);

  Stream<Float32List> get audioSampleStream => _streamController.stream
      .where((event) => event is FrameNesEvent)
      .map((event) => (event as FrameNesEvent).samples);

  void loadCartridge(String path) {
    sendCommand(NesStopCommand());

    final cartridge = Cartridge.fromFile(path);

    _cartridgeState.cartridge = cartridge;

    state.loadCartridge(cartridge);
  }

  Future<void> run() async {
    state.run().listen((event) => _streamController.add(event));
  }

  void suspend() => sendCommand(NesSuspendCommand());

  void togglePause() => sendCommand(NesTogglePauseCommand());

  void resume() => sendCommand(NesResumeCommand());

  void reset() => sendCommand(NesResetCommand());

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

  void _processSamples(Float32List samples) {
    _flushSamples();

    for (final sample in samples) {
      if (_audioBufferIndex >= _audioBuffer.length) {
        break;
      }

      _audioBuffer[_audioBufferIndex++] = sample * _volume;
    }

    _flushSamples();
  }

  void _flushSamples() {
    final pushSize = (50 / 1000 * 44100).floor(); // push 50 ms at a time

    if (_audioBufferIndex < pushSize) {
      return;
    }

    final samples = _audioBuffer.sublist(0, pushSize);

    if (_audioStream.push(samples) == -1) {
      return;
    }

    final newSize = _audioBufferIndex - pushSize;

    _audioBuffer.setRange(0, newSize, _audioBuffer, pushSize);
    _audioBufferIndex = newSize;
  }
}
