import 'package:binarize/binarize.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/serialization/nesd_uint64.dart';

// Values covering both 32-bit halves and the top of the JS-safe range.
const _samples = [
  0,
  1,
  0xFFFFFFFF,
  0x100000000,
  0x0012345678ABCDEF,
  0x1FFFFFFFFFFFFF, // 2^53 - 1
];

void main() {
  test('round-trips through a payload', () {
    final writer = Payload.write();

    for (final value in _samples) {
      writer.set(nesdUint64, value);
    }

    final reader = Payload.read(binarize(writer));

    for (final value in _samples) {
      expect(reader.get(nesdUint64), value);
    }
  });

  test(
    'produces the same bytes as binarize uint64',
    skip: kIsWeb ? 'binarize uint64 cannot run on web' : false,
    () {
      for (final value in _samples) {
        final reference = Payload.write()..set(uint64, value);
        final compat = Payload.write()..set(nesdUint64, value);

        expect(
          binarize(compat),
          binarize(reference),
          reason: 'byte layout differs for $value',
        );
      }
    },
  );

  test('reads bytes written by binarize uint64', () {
    // 0x0012345678ABCDEF big-endian, written out by hand so this check
    // also runs on web where the reference writer is unavailable.
    final reader = Payload.read(const [
      0x00,
      0x12,
      0x34,
      0x56,
      0x78,
      0xAB,
      0xCD,
      0xEF,
    ]);

    expect(reader.get(nesdUint64), 0x0012345678ABCDEF);
  });
}
