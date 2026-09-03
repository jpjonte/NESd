import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/nes/ppu/frame_buffer_memory.dart';
import 'package:nesd/nes/rewind/lz4_native.dart';
import 'package:nesd/nes/rewind/rewind_frame_lane.dart';

Uint8List frame(int seed) {
  final pixels = FrameBufferMemory.allocate(wordCount: 16);

  for (var i = 0; i < pixels.length; i++) {
    pixels[i] = (i * seed + seed) & 0xff;
  }

  return pixels;
}

void main() {
  late RewindFrameLane lane;

  setUp(() => lane = RewindFrameLane(size: 64));
  tearDown(() => lane.dispose());

  test('starts without a current frame', () {
    expect(lane.hasCurrent, isFalse);
  });

  test('setCurrent copies the frame and marks it current', () {
    final first = frame(3);

    lane.setCurrent(first);

    expect(lane.hasCurrent, isTrue);
    expect(lane.current, first);
  });

  test('restore walks back through the diffs to each earlier frame', () {
    final frames = [frame(1), frame(5), frame(9), frame(13)];

    lane.setCurrent(frames[0]);

    final diffs = [for (final next in frames.skip(1)) lane.captureDiff(next)];

    expect(lane.current, frames.last);

    for (var i = diffs.length - 1; i >= 0; i--) {
      final restored = Uint8List.fromList(lane.restore(diffs[i]));

      expect(restored, frames[i + 1], reason: 'restore ${i + 1}');
      expect(lane.current, frames[i], reason: 'current after restore $i');
    }
  });

  test('a diff of an identical frame is tiny', () {
    final same = frame(7);

    lane.setCurrent(same);

    expect(lane.captureDiff(same).length, lessThan(16));
  });

  test('a corrupt diff throws NesdException and keeps current', () {
    final before = frame(2);

    lane.setCurrent(before);

    final diff = lane.captureDiff(frame(4));

    for (var i = 4; i < diff.length; i++) {
      diff[i] = 0xff;
    }

    expect(() => lane.restore(diff), throwsA(isA<NesdException>()));
    expect(lane.current, frame(4));
  });

  test('clear forgets the current frame', () {
    lane
      ..setCurrent(frame(1))
      ..clear();

    expect(lane.hasCurrent, isFalse);
  });

  test('rejects frames of another size', () {
    expect(
      () => lane.setCurrent(FrameBufferMemory.allocate(wordCount: 8)),
      throwsArgumentError,
    );
  });

  test('rejects a size that is not a positive multiple of 4', () {
    expect(() => RewindFrameLane(size: 6), throwsArgumentError);
  });

  test('a diff decompressing to the wrong length throws NesdException '
      'and keeps current', () {
    final before = frame(2);

    lane.setCurrent(before);

    // A hand-built block whose prefix claims 32 bytes, decompressed
    // into a 64-byte lane: restore must not accept a short tail.
    final block = Lz4.instance.compressBytes(Uint8List(32));

    expect(() => lane.restore(block), throwsA(isA<NesdException>()));
    expect(lane.current, before);
  });
}
