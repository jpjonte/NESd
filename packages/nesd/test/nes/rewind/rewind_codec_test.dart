import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/rewind/rewind_codec.dart';

void main() {
  test(
    'compress and decompress round-trip',
    skip: kIsWeb ? 'native' : null,
    () {
      final data = Uint8List.fromList(List.generate(4096, (i) => i % 7));

      final compressed = rewindCompress(data);
      final restored = rewindDecompress(compressed);

      expect(restored, data);
      expect(compressed.length, lessThan(data.length));
    },
  );

  test('the web codec fails loudly', skip: kIsWeb ? null : 'web only', () {
    expect(() => rewindCompress(Uint8List(4)), throwsUnsupportedError);
    expect(() => rewindDecompress(Uint8List(4)), throwsUnsupportedError);
  });
}
