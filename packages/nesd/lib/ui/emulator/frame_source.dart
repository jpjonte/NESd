import 'package:flutter/foundation.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';

class FrameHandle {
  const FrameHandle({
    required this.bytes,
    required this.width,
    required this.height,
    required this.pointerAddress,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int pointerAddress;
}

abstract class FrameSource extends ChangeNotifier {
  FrameHandle? takeFrame();

  void releaseFrame(FrameHandle handle);
}

class LocalFrameSource extends FrameSource {
  LocalFrameSource({required this.frameBuffer});

  final FrameBuffer frameBuffer;

  @override
  FrameHandle? takeFrame() {
    final buffer = frameBuffer.takeReadyBuffer();

    if (buffer == null) {
      return null;
    }

    final pointerAddress = frameBuffer.pointerForBuffer(buffer);

    if (pointerAddress == null) {
      frameBuffer.releaseDisplayBuffer(buffer);

      return null;
    }

    return FrameHandle(
      bytes: buffer,
      width: frameBuffer.width,
      height: frameBuffer.height,
      pointerAddress: pointerAddress,
    );
  }

  @override
  void releaseFrame(FrameHandle handle) {
    frameBuffer.releaseDisplayBuffer(handle.bytes);
  }

  void frameAvailable() => notifyListeners();
}
