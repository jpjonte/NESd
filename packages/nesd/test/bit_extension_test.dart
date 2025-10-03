import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/extension/bit_extension.dart';

void main() {
  test('test get bit', () {
    expect(0x00.bit(0), equals(0));
    expect(0x00.bit(1), equals(0));
    expect(0x00.bit(2), equals(0));
    expect(0x00.bit(3), equals(0));
    expect(0x00.bit(4), equals(0));
    expect(0x00.bit(5), equals(0));
    expect(0x00.bit(6), equals(0));
    expect(0x00.bit(7), equals(0));

    expect(0xff.bit(0), equals(1));
    expect(0xff.bit(1), equals(1));
    expect(0xff.bit(2), equals(1));
    expect(0xff.bit(3), equals(1));
    expect(0xff.bit(4), equals(1));
    expect(0xff.bit(5), equals(1));
    expect(0xff.bit(6), equals(1));
    expect(0xff.bit(7), equals(1));
  });

  test('test set bit', () {
    expect(0x00.setBit(0, 1), equals(1));
    expect(0x00.setBit(1, 1), equals(2));
    expect(0x00.setBit(2, 1), equals(4));
    expect(0x00.setBit(3, 1), equals(8));
    expect(0x00.setBit(4, 1), equals(16));
    expect(0x00.setBit(5, 1), equals(32));
    expect(0x00.setBit(6, 1), equals(64));
    expect(0x00.setBit(7, 1), equals(128));

    expect(0xff.setBit(0, 0), equals(0xfe));
    expect(0xff.setBit(1, 0), equals(0xfd));
    expect(0xff.setBit(2, 0), equals(0xfb));
    expect(0xff.setBit(3, 0), equals(0xf7));
    expect(0xff.setBit(4, 0), equals(0xef));
    expect(0xff.setBit(5, 0), equals(0xdf));
    expect(0xff.setBit(6, 0), equals(0xbf));
    expect(0xff.setBit(7, 0), equals(0x7f));
  });

  test('test get bits', () {
    expect(0x00.bits(0, 0), equals(0));
    expect(0x00.bits(0, 1), equals(0));
    expect(0x00.bits(0, 2), equals(0));
    expect(0x00.bits(0, 3), equals(0));
    expect(0x00.bits(0, 4), equals(0));
    expect(0x00.bits(0, 5), equals(0));
    expect(0x00.bits(0, 6), equals(0));
    expect(0x00.bits(0, 7), equals(0));

    expect(0xff.bits(0, 0), equals(1));
    expect(0xff.bits(0, 1), equals(3));
    expect(0xff.bits(0, 2), equals(7));
    expect(0xff.bits(0, 3), equals(15));
    expect(0xff.bits(0, 4), equals(31));
    expect(0xff.bits(0, 5), equals(63));
    expect(0xff.bits(0, 6), equals(127));
    expect(0xff.bits(0, 7), equals(255));
  });
}
