import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/util/ring_buffer.dart';

void main() {
  RingBuffer<double, Float32List> createBuffer(int size) =>
      RingBuffer(bufferConstructor: Float32List.new, size: size);

  Float32List samples(List<double> values) => Float32List.fromList(values);

  group('RingBuffer', () {
    test('write stores data and readInto retrieves it', () {
      final buffer = createBuffer(8);

      final written = buffer.write(samples([1, 2, 3]));

      expect(written, 3);
      expect(buffer.current, 3);

      final target = Float32List(8);
      final read = buffer.readInto(target, 3);

      expect(read, 3);
      expect(target.sublist(0, 3), [1, 2, 3]);
      expect(buffer.isEmpty, isTrue);
    });

    test('write wraps around the end of the backing buffer', () {
      final buffer = createBuffer(8);
      final target = Float32List(8);

      buffer
        ..write(samples([1, 2, 3, 4, 5, 6]))
        ..readInto(target, 4)
        // end is at 6; writing 4 elements wraps to the start
        ..write(samples([7, 8, 9, 10]));

      final result = Float32List(8);
      final read = buffer.readInto(result, 6);

      expect(read, 6);
      expect(result.sublist(0, 6), [5, 6, 7, 8, 9, 10]);
    });

    test('readInto wraps around the end of the backing buffer', () {
      final buffer = createBuffer(8);
      final scratch = Float32List(8);

      buffer
        ..write(samples([1, 2, 3, 4, 5, 6, 7]))
        ..readInto(scratch, 6)
        ..write(samples([8, 9, 10, 11, 12]));

      // start is at 6; reading 6 elements crosses the wrap point
      final result = Float32List(8);
      final read = buffer.readInto(result, 6);

      expect(read, 6);
      expect(result.sublist(0, 6), [7, 8, 9, 10, 11, 12]);
    });

    test('write truncates when the buffer is full', () {
      // a size-4 ring holds size - 1 = 3 elements
      final buffer = createBuffer(4);

      final written = buffer.write(samples([1, 2, 3, 4, 5]));

      expect(written, 3);
      expect(buffer.isFull, isTrue);
    });

    test('readInto reads at most the available count', () {
      final buffer = createBuffer(8)..write(samples([1, 2]));

      final target = Float32List(8);

      expect(buffer.readInto(target, 5), 2);
    });

    test('readInto is limited by the target length', () {
      final buffer = createBuffer(8)..write(samples([1, 2, 3, 4, 5]));

      final target = Float32List(2);

      expect(buffer.readInto(target, 5), 2);
      expect(target, [1, 2]);
      expect(buffer.current, 3);
    });
  });
}
