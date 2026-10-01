import 'package:flutter_test/flutter_test.dart';

import 'package:nesd/nes/cartridge/mapper/vt/vt02.dart';

import 'vt02_harness.dart';

int _prgBankAt(VT02 mapper, int address) =>
    mapper.cpuRead(address) | (mapper.cpuRead(address + 1) << 8);

void main() {
  test('a soft reset returns the bank registers to power-on', () {
    final (:nes, :mapper) = buildVt02();

    addTearDown(() => nes.on = false);

    nes.bus
      ..cpuWrite(0x4100, 0x10)
      ..cpuWrite(0x4107, 0x05)
      ..cpuWrite(0x2012, 0x07);

    nes.softReset();

    expect(mapper.registerAt(0x4100), 0);
    expect(mapper.registerAt(0x4107), 0);
    expect(mapper.registerAt(0x2012), 0);
  });

  test('a soft reset maps the power-on PRG banks back in', () {
    final (:nes, :mapper) = buildVt02(prgBanks: 256);

    addTearDown(() => nes.on = false);

    final powerOn = _prgBankAt(mapper, 0xe000);

    nes.bus.cpuWrite(0x4100, 0x10);

    expect(_prgBankAt(mapper, 0xe000), isNot(powerOn));

    nes.softReset();

    expect(_prgBankAt(mapper, 0xe000), powerOn);
  });

  test('a soft reset turns opcode scrambling back on', () {
    final (:nes, mapper: _) = buildVt02(subMapperId: 15);

    addTearDown(() => nes.on = false);

    nes.bus.cpuWrite(0x4169, 0x01);

    nes.softReset();

    expect(nes.cpu.opcodeTable, isNotNull);
  });
}
