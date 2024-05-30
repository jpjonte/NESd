import 'package:flutter_test/flutter_test.dart';
import 'package:nes/cartridge.dart';
import 'package:nes/nes.dart';

void main() {
  test('Run nestest', () {
    final nes = NES();

    final cartridge = Cartridge.fromFile('roms/test/nestest/nestest.nes');

    nes
      ..loadCartridge(cartridge)
      ..reset()
      ..cpu.PC = 0xc000
      ..cpu.cycles = 7
      ..cpu.debug = true
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
