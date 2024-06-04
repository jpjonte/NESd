import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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

    return NES();
  }

  late final CartridgeState _cartridgeState;

  // ignore: unused_field
  late final AppLifecycleListener _lifecycleListener;

  final StreamController<FrameBuffer> _streamController =
      StreamController.broadcast();

  Stream<FrameBuffer> get stream => _streamController.stream;

  void loadCartridge(String path) {
    sendCommand(NesStopCommand());

    final cartridge = Cartridge.fromFile(path);

    _cartridgeState.cartridge = cartridge;

    state.loadCartridge(cartridge);
  }

  Future<void> run() async {
    state.run().listen((frameBuffer) => _streamController.add(frameBuffer));
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
}
