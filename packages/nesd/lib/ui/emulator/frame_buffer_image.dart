import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:nesd/nes/ppu/frame_buffer.dart';

Future<ui.Image> convertFrameBufferToImage(FrameBuffer frameBuffer) async {
  final queued = frameBuffer.takeReadyBuffer();
  final bytes = queued ?? Uint8List.fromList(frameBuffer.pixels);

  final completer = Completer<ui.Image>();

  ui.decodeImageFromPixels(
    bytes,
    frameBuffer.width,
    frameBuffer.height,
    ui.PixelFormat.rgba8888,
    completer.complete,
    rowBytes: frameBuffer.width * 4,
  );

  try {
    return await completer.future;
  } finally {
    if (queued != null) {
      frameBuffer.releaseDisplayBuffer(queued);
    }
  }
}
