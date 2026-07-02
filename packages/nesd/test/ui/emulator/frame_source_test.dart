import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/ui/emulator/frame_source.dart';

void main() {
  test('LocalFrameSource hands out and releases pool buffers', () {
    final frameBuffer = FrameBuffer(width: 4, height: 4);
    final source = LocalFrameSource(frameBuffer: frameBuffer);

    expect(source.takeFrame(), isNull);

    frameBuffer.swap(); // one ready buffer

    final handle = source.takeFrame();

    expect(handle, isNotNull);
    expect(handle!.width, 4);
    expect(handle.height, 4);
    expect(handle.pointerAddress, isNonZero);
    expect(handle.bytes.length, 4 * 4 * 4);

    source.releaseFrame(handle);

    expect(source.takeFrame(), isNull);
  });

  test('LocalFrameSource notifies on frameAvailable', () {
    final source = LocalFrameSource(
      frameBuffer: FrameBuffer(width: 2, height: 2),
    );
    var notified = 0;

    source
      ..addListener(() => notified++)
      ..frameAvailable();

    expect(notified, 1);
  });
}
