import 'dart:async';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/nes/nes.dart';
import 'package:nes/nes/ppu/frame_buffer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stream_isolate/stream_isolate.dart';

part 'nes_controller.g.dart';

final logicalKeyToNesButton = {
  LogicalKeyboardKey.arrowUp: NesButton.up,
  LogicalKeyboardKey.arrowDown: NesButton.down,
  LogicalKeyboardKey.arrowLeft: NesButton.left,
  LogicalKeyboardKey.arrowRight: NesButton.right,
  LogicalKeyboardKey.enter: NesButton.start,
  LogicalKeyboardKey.shift: NesButton.select,
  LogicalKeyboardKey.keyZ: NesButton.a,
  LogicalKeyboardKey.keyX: NesButton.b,
};

@riverpod
class NesController extends _$NesController {
  NesController() {
    _lifecycleListener = AppLifecycleListener(
      onPause: pause,
      onInactive: pause,
      onShow: resume,
      onResume: resume,
    );
  }

  @override
  NES build() {
    HardwareKeyboard.instance.addHandler(_handleKey);

    return NES();
  }

  // ignore: unused_field
  late final AppLifecycleListener _lifecycleListener;

  final StreamController<FrameBuffer> _streamController =
      StreamController.broadcast();

  BidirectionalStreamIsolate<NesCommand, FrameBuffer, void>? _isolate;

  Stream<FrameBuffer> get stream => _streamController.stream;

  void loadCartridge(String path) {
    _isolate?.kill(priority: Isolate.immediate);

    final cartridge = Cartridge.fromFile(path);

    state.loadCartridge(cartridge);
  }

  Future<void> run() async {
    final isolate = await BidirectionalStreamIsolate.spawn(state.run);
    isolate.stream.listen(
      (frameBuffer) {
        _streamController.add(frameBuffer);
      },
      onError: (error) {
        _isolate = null;
      },
      onDone: () {
        _isolate = null;
      },
    );
    _isolate = isolate;
  }

  void pause() {
    sendCommand(NesPauseCommand());
  }

  void resume() {
    sendCommand(NesResumeCommand());
  }

  void togglePause() {
    sendCommand(NesTogglePauseCommand());
  }

  void sendCommand(NesCommand command) => _isolate?.send(command);

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
}
