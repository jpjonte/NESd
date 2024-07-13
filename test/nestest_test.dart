import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/nes.dart';

void main() {
  test('Run nestest', () {
    const path = 'roms/test/nestest/nestest.nes';

    final file = File(path);

    final cartridge = Cartridge.fromFile(path, file.readAsBytesSync());

    final nes = NES(cartridge, debug: true)
      ..cpu.PC = 0xc000
      ..cpu.cycles = 7
      ..ppu.cycle = 21;

    while (true) {
      final exit = nes.cpu.PC == 0xc66e;

      nes.step();

      final low = nes.cpu.read(0x02);
      final high = nes.cpu.read(0x03);
      final result = (high << 8) | low;

      expect(result, equals(0));

      if (exit) {
        break;
      }
    }
  });
}
