import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../cartridge/mapper/vt/vt02_harness.dart';
import 'four_bpp_harness.dart';

Uint8List _buildNromRom() {
  const prgSize = 2 * 0x4000;

  final rom = Uint8List(16 + prgSize + 0x2000)
    ..setAll(0, [
      0x4e, 0x45, 0x53, 0x1a, //
      2, 1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    ]);

  rom[16] = 0x4c;
  rom[16 + prgSize - 4] = 0x00;
  rom[16 + prgSize - 3] = 0x80;

  return rom;
}

void main() {
  group('OAM byte 2 reads', () {
    test('a VT mapper returns the raw attribute byte', () {
      final (:nes, mapper: _) = buildVt02();

      nes.bus.cpuWrite(0x2003, 2);
      nes.bus.cpuWrite(0x2004, 0xff);
      nes.bus.cpuWrite(0x2003, 2);

      expect(nes.bus.cpuRead(0x2004), 0xff);
    });

    test('a stock mapper drives bits 2-4 low', () {
      final nes = buildNes(_buildNromRom());

      nes.bus.cpuWrite(0x2003, 2);
      nes.bus.cpuWrite(0x2004, 0xff);
      nes.bus.cpuWrite(0x2003, 2);

      expect(nes.bus.cpuRead(0x2004), 0xe3);
    });
  });
}
