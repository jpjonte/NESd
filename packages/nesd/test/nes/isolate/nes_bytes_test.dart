import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';

void main() {
  test('round-trips one list', () {
    final data = Uint8List.fromList([1, 2, 3, 4]);

    final bytes = NesBytes.fromList([data]);

    expect(bytes.materialize().asUint8List(), [1, 2, 3, 4]);
  });

  test('concatenates multiple lists', () {
    final bytes = NesBytes.fromList([
      Uint8List.fromList([1, 2]),
      Uint8List.fromList([3, 4]),
    ]);

    expect(bytes.materialize().asUint8List(), [1, 2, 3, 4]);
  });

  test('carries float32 payloads', () {
    final floats = Float32List.fromList([1.5, -2.5]);

    final bytes = NesBytes.fromList([floats]);

    expect(bytes.materialize().asFloat32List(), [1.5, -2.5]);
  });
}
