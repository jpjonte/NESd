import 'package:flutter_test/flutter_test.dart';

import 'vt02_harness.dart';

void main() {
  test('submapper 0 leaves opcodes alone', () {
    final (:nes, mapper: _) = buildVt02();

    expect(nes.cpu.opcodeTable, isNull);
  });

  group('submapper 11 (Vibes)', () {
    test('swaps D7/D6, D1/D2 and D5/D4 at power-on', () {
      final (:nes, mapper: _) = buildVt02(subMapperId: 11);

      expect(nes.cpu.opcodeTable![0x80], 0x40);
      expect(nes.cpu.opcodeTable![0x02], 0x04);
      expect(nes.cpu.opcodeTable![0x20], 0x10);
    });

    test(r'$411C.6 and $411C.1 switch the two swaps independently', () {
      final (:nes, mapper: _) = buildVt02(subMapperId: 11);

      nes.bus.cpuWrite(0x411c, 0x40);

      expect(nes.cpu.opcodeTable![0x80], 0x40);
      expect(nes.cpu.opcodeTable![0x20], 0x20);

      nes.bus.cpuWrite(0x411c, 0x02);

      expect(nes.cpu.opcodeTable![0x80], 0x80);
      expect(nes.cpu.opcodeTable![0x20], 0x10);

      nes.bus.cpuWrite(0x411c, 0x00);

      expect(nes.cpu.opcodeTable, isNull);
    });
  });

  test(r'submapper 12 (Cheertone) swaps D7/D6 and D1/D2 via $411C.6', () {
    final (:nes, mapper: _) = buildVt02(subMapperId: 12);

    expect(nes.cpu.opcodeTable![0x82], 0x44);
    expect(nes.cpu.opcodeTable![0x20], 0x20);

    nes.bus.cpuWrite(0x411c, 0x02);

    expect(nes.cpu.opcodeTable, isNull);
  });

  test(r'submapper 13 (Taikee) swaps D1/D4 until $4169.0 is set', () {
    final (:nes, mapper: _) = buildVt02(subMapperId: 13);

    expect(nes.cpu.opcodeTable![0x02], 0x10);

    nes.bus.cpuWrite(0x4169, 0x01);

    expect(nes.cpu.opcodeTable, isNull);

    nes.bus.cpuWrite(0x4169, 0x00);

    expect(nes.cpu.opcodeTable![0x10], 0x02);
  });

  test(r'submapper 14 (Karaoto) swaps D6/D7 via $411C.6', () {
    final (:nes, mapper: _) = buildVt02(subMapperId: 14);

    expect(nes.cpu.opcodeTable![0x82], 0x42);

    nes.bus.cpuWrite(0x411c, 0x00);

    expect(nes.cpu.opcodeTable, isNull);
  });

  group('submapper 15 (Jungletac)', () {
    test(r'swaps D5/D6 until $4169.0 is set', () {
      final (:nes, mapper: _) = buildVt02(subMapperId: 15);

      expect(nes.cpu.opcodeTable![0x20], 0x40);
      expect(nes.cpu.opcodeTable![0x60], 0x60);

      nes.bus.cpuWrite(0x4169, 0x01);

      expect(nes.cpu.opcodeTable, isNull);
    });

    test(r'ignores $411C', () {
      final (:nes, mapper: _) = buildVt02(subMapperId: 15);

      nes.bus.cpuWrite(0x411c, 0x00);

      expect(nes.cpu.opcodeTable, isNotNull);
    });

    test('the CPU descrambles opcodes but not operands', () {
      final (:nes, mapper: _) = buildVt02(subMapperId: 15);

      nes.bus
        ..cpuWrite(0x0000, 0xc9)
        ..cpuWrite(0x0001, 0x20);

      nes.cpu
        ..PC = 0x0000
        ..step();

      expect(nes.cpu.A, 0x20);
    });

    test('the scramble switch survives a save state', () {
      final (nes: sourceNes, mapper: source) = buildVt02(subMapperId: 15);
      final (nes: targetNes, mapper: target) = buildVt02(subMapperId: 15);

      sourceNes.bus.cpuWrite(0x4169, 0x01);

      target.state = source.state;

      expect(targetNes.cpu.opcodeTable, isNull);
    });
  });
}
