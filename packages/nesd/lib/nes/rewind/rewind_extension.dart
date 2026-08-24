import 'dart:math';
import 'dart:typed_data';

import 'package:nesd/nes/rewind/rewind_codec.dart';

extension Uint8ListRewindExtension on Uint8List {
  Uint8List compress() => rewindCompress(this);

  Uint8List decompress() => rewindDecompress(this);

  /// XORs this list with [other] over their common prefix, in place.
  ///
  /// Bytes past the common prefix keep their original values, which makes
  /// the operation reversible even for lists of unequal length.
  Uint8List diffWith(Uint8List other) {
    final diffLength = min(length, other.length);

    if (offsetInBytes % 4 == 0 && other.offsetInBytes % 4 == 0) {
      _diffWords(other, diffLength);
    } else {
      _diffBytes(other, 0, diffLength);
    }

    return this;
  }

  void _diffWords(Uint8List other, int diffLength) {
    final words = diffLength >> 2;
    final selfWords = Uint32List.view(buffer, offsetInBytes, words);
    final otherWords = Uint32List.view(
      other.buffer,
      other.offsetInBytes,
      words,
    );

    for (var i = 0; i < words; i++) {
      selfWords[i] ^= otherWords[i];
    }

    _diffBytes(other, words << 2, diffLength);
  }

  void _diffBytes(Uint8List other, int start, int end) {
    for (var i = start; i < end; i++) {
      this[i] ^= other[i];
    }
  }
}
