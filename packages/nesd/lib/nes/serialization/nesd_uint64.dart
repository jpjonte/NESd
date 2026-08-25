import 'package:binarize/binarize.dart';

class _NesdUint64 extends PayloadType<int> {
  const _NesdUint64();

  @override
  int get(ByteReader reader, [Endian? endian]) {
    final resolved = endian ?? Endian.big;
    final first = reader.uint32(resolved);
    final second = reader.uint32(resolved);

    return resolved == Endian.big
        ? first * 0x100000000 + second
        : second * 0x100000000 + first;
  }

  @override
  void set(ByteWriter writer, int value, [Endian? endian]) {
    // Real throws, not asserts: a violation in a release build would
    // silently write garbage into the persistent save-state format.
    if (value < 0 || value >= 0x20000000000000) {
      throw RangeError.range(
        value,
        0,
        0x20000000000000 - 1,
        'value',
        'nesdUint64 values must stay in [0, 2^53) to survive dart2js',
      );
    }

    final resolved = endian ?? Endian.big;
    final high = value ~/ 0x100000000;
    final low = value - high * 0x100000000;

    if (resolved == Endian.big) {
      writer
        ..uint32(high, resolved)
        ..uint32(low, resolved);
    } else {
      writer
        ..uint32(low, resolved)
        ..uint32(high, resolved);
    }
  }
}

/// Drop-in replacement for binarize's `uint64` for the NESd save-state format.
///
/// The JavaScript compilers have no 64-bit [ByteData] accessors, so
/// binarize's `uint64` throws `Unsupported operation: Uint64 accessor`
/// on web. This type writes the same eight bytes as two 32-bit halves,
/// keeping the wire format identical to `uint64` for values below 2^53.
/// Always use this instead of binarize's `uint64` in state serializers.
const nesdUint64 = _NesdUint64();
