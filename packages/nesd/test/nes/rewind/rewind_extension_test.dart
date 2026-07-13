import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/rewind/rewind_extension.dart';

void main() {
  group('diffWith', () {
    test('XORs equal-length lists in place and returns receiver', () {
      final a = Uint8List.fromList([0x0f, 0xf0, 0xaa, 0x55, 0x01]);
      final b = Uint8List.fromList([0xff, 0xff, 0x00, 0xff, 0x01]);

      final result = a.diffWith(b);

      expect(identical(result, a), isTrue);
      expect(a, [0xf0, 0x0f, 0xaa, 0xaa, 0x00]);
    });

    test('is reversible: (a ^ b) ^ b == a', () {
      final original = Uint8List.fromList(
        List.generate(1027, (i) => (i * 31) & 0xff),
      );
      final a = Uint8List.fromList(original);
      final b = Uint8List.fromList(
        List.generate(1027, (i) => (i * 7 + 3) & 0xff),
      );

      a.diffWith(b);

      expect(a, isNot(equals(original)));

      a.diffWith(b);

      expect(a, original);
    });

    test('only touches the common prefix when other is shorter', () {
      final a = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9]);
      final b = Uint8List.fromList([1, 2, 3, 4, 5]);

      a.diffWith(b);

      expect(a, [0, 0, 0, 0, 0, 6, 7, 8, 9]);
    });

    test('ignores excess bytes of a longer other', () {
      final a = Uint8List.fromList([1, 2, 3]);
      final b = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

      a.diffWith(b);

      expect(a, [0, 0, 0]);
    });

    test('handles lengths around the word boundary', () {
      for (final length in [0, 1, 3, 4, 5, 7, 8, 9, 12, 13]) {
        final a = Uint8List.fromList(List.generate(length, (i) => i & 0xff));
        final b = Uint8List.fromList(
          List.generate(length, (i) => (255 - i) & 0xff),
        );
        final expected = List.generate(
          length,
          (i) => (i & 0xff) ^ ((255 - i) & 0xff),
        );

        expect(a.diffWith(b), expected, reason: 'length $length');
      }
    });

    test('works on non-word-aligned views', () {
      final backing = Uint8List.fromList(List.generate(21, (i) => i));
      final a = Uint8List.sublistView(backing, 1, 17);
      final b = Uint8List.fromList(List.filled(16, 0xff));

      a.diffWith(b);

      expect(a, List.generate(16, (i) => (i + 1) ^ 0xff));
    });
  });

  group('compress/decompress', () {
    test('round-trips bytes', () {
      final original = Uint8List.fromList(
        List.generate(4096, (i) => (i ~/ 16) & 0xff),
      );

      final compressed = original.compress();
      final restored = compressed.decompress();

      expect(compressed, isA<Uint8List>());
      expect(restored, original);
      expect(compressed.length, lessThan(original.length));
    });
  });
}
