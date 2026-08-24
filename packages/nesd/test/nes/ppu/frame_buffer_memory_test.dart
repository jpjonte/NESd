import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/ppu/frame_buffer_memory.dart';

void main() {
  test('words view aliases the byte buffer', () {
    final buffer = FrameBufferMemory.allocate(wordCount: 4);
    final words = FrameBufferMemory.words(buffer);

    words[0] = 0xaabbccdd;

    expect(buffer[0], 0xdd);
    expect(buffer[3], 0xaa);
  });

  test('allocates four bytes per word, zeroed', () {
    final buffer = FrameBufferMemory.allocate(wordCount: 4);

    expect(buffer.length, 16);
    expect(buffer.every((byte) => byte == 0), isTrue);
  });

  test('words rejects foreign buffers', () {
    expect(() => FrameBufferMemory.words(Uint8List(16)), throwsArgumentError);
  });

  test(
    'pointerAddress is stable per buffer on native',
    skip: kIsWeb ? 'no pointers on web' : null,
    () {
      final buffer = FrameBufferMemory.allocate(wordCount: 4);

      expect(
        FrameBufferMemory.pointerAddress(buffer),
        FrameBufferMemory.pointerAddress(buffer),
      );
      expect(FrameBufferMemory.pointerAddress(buffer), isNotNull);
    },
  );

  test('pointerAddress is null on web', skip: kIsWeb ? null : 'native', () {
    final buffer = FrameBufferMemory.allocate(wordCount: 4);

    expect(FrameBufferMemory.pointerAddress(buffer), isNull);
  });
}
