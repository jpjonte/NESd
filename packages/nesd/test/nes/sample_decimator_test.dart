import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/sample_decimator.dart';

void main() {
  test('averages each group of factor samples', () {
    final decimator = SampleDecimator();

    final output = decimator.decimate(
      Float32List.fromList([1, 3, 5, 7, 2, 4]),
      2,
    );

    expect(output, [2.0, 6.0, 3.0]);
  });

  test('carries leftover samples into the next call', () {
    final decimator = SampleDecimator();

    final first = decimator.decimate(Float32List.fromList([1, 3, 5]), 2);
    final second = decimator.decimate(Float32List.fromList([7]), 2);

    expect(first, [2.0]);
    expect(second, [6.0]);
  });

  test('a factor change discards the carried partial group', () {
    final decimator = SampleDecimator();

    final first = decimator.decimate(Float32List.fromList([1, 1, 1]), 4);

    final second = decimator.decimate(Float32List.fromList([2, 4, 6, 8]), 2);

    expect(first, isEmpty);
    expect(second, [3.0, 7.0]);
  });

  test('reset discards carried samples', () {
    final decimator = SampleDecimator()
      ..decimate(Float32List.fromList([1, 3, 5]), 2)
      ..reset();

    final output = decimator.decimate(Float32List.fromList([7, 9]), 2);

    expect(output, [8.0]);
  });
}
