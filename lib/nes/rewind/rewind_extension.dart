import 'dart:math';

import 'package:es_compression/lz4.dart';

// TODO bundle lz4 library on Windows, Linux
extension IntListRewindExtension on List<int> {
  List<int> compress() => nesdLz4.encode(this);

  List<int> decompress() => nesdLz4.decode(this);

  @pragma('vm:prefer-inline')
  List<int> diff(List<int> other) {
    final diffLength = min(length, other.length);

    for (var i = 0; i < diffLength; i++) {
      this[i] ^= other[i];
    }

    return this;
  }
}

final nesdLz4 = Lz4Codec(level: -1);
