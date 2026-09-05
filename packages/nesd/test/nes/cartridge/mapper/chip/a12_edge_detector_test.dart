import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/mapper/chip/a12_edge_detector.dart';

void main() {
  test('reports a rising edge after A12 was low for four cycles', () {
    final detector = A12EdgeDetector();

    expect(detector.detect(0x0000, 10), isFalse);
    expect(detector.detect(0x1000, 14), isTrue);
  });

  test('ignores a rising edge before four cycles have elapsed', () {
    final detector = A12EdgeDetector();

    expect(detector.detect(0x0000, 10), isFalse);
    expect(detector.detect(0x1000, 13), isFalse);
  });

  test('ignores a high address with no preceding low period', () {
    final detector = A12EdgeDetector();

    expect(detector.detect(0x1000, 10), isFalse);
  });

  test('restarts the low period after each edge', () {
    final detector = A12EdgeDetector()
      ..detect(0x0000, 10)
      ..detect(0x1000, 14);

    expect(detector.detect(0x1000, 20), isFalse);
    expect(detector.detect(0x0000, 21), isFalse);
    expect(detector.detect(0x1000, 25), isTrue);
  });

  test('exposes lowStart so owners can serialize the anchor', () {
    final detector = A12EdgeDetector()..detect(0x0000, 42);

    expect(detector.lowStart, 42);

    detector.lowStart = 7;

    expect(detector.detect(0x1000, 11), isTrue);
  });
}
