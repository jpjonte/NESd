import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_bytes_web.dart';

void main() {
  test('concatenates payloads, honoring views with non-zero offsets', () {
    final backing = Uint8List.fromList([1, 2, 3, 4, 5, 6]);
    final view = Uint8List.view(backing.buffer, 2, 3); // [3, 4, 5]

    final bytes = NesBytes.fromList([
      Uint8List.fromList([9]),
      view,
    ]);

    expect(bytes.materialize().asUint8List(), [9, 3, 4, 5]);
  });

  test('carries non-Uint8List payloads byte for byte', () {
    final floats = Float32List.fromList([1.0, -1.0]);

    final bytes = NesBytes.fromList([floats]);
    final result = bytes.materialize().asFloat32List();

    expect(result, [1.0, -1.0]);
  });
}
