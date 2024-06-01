import 'dart:async';
import 'dart:isolate';

import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/nes/nes.dart';
import 'package:nes/nes/ppu/frame_buffer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stream_isolate/stream_isolate.dart';

part 'nes_controller.g.dart';

@riverpod
class NesController extends _$NesController {
  @override
  NES build() => NES();

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
    isolate.stream.listen((frameBuffer) {
      _streamController.add(frameBuffer);
    });
    _isolate = isolate;
  }

  void pause() {
    _isolate?.send(NesCommand.pause);
  }

  void resume() {
    _isolate?.send(NesCommand.resume);
  }
}
