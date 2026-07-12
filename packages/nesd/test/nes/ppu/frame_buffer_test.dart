import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';

void main() {
  group('FrameBuffer', () {
    test('freshly allocated buffers are zero-initialized', () {
      // Dirty the native heap with a same-sized garbage block first, so
      // a non-zeroing allocator is likely to hand the recycled block to
      // the FrameBuffer. This is what happens when multiple test
      // isolates share one process: full_palette's golden hash covers
      // bytes the PPU never writes (forced blank), so uninitialized
      // memory here caused rare golden flakes under parallel isolates.
      const size = 256 * 240 * 4;

      final garbage = malloc<Uint8>(size);

      garbage.asTypedList(size).fillRange(0, size, 0xab);

      malloc.free(garbage);

      final frameBuffer = FrameBuffer(width: 256, height: 240);
      final pixels = frameBuffer.pixels;

      var nonZero = 0;

      for (var i = 0; i < pixels.length; i++) {
        if (pixels[i] != 0) {
          nonZero++;
        }
      }

      expect(
        nonZero,
        equals(0),
        reason:
            '$nonZero of ${pixels.length} bytes were not '
            'zero-initialized',
      );
    });
  });
}
