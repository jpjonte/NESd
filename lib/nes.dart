import 'package:nes/apu.dart';
import 'package:nes/cartridge.dart';
import 'package:nes/cpu.dart';
import 'package:nes/ppu.dart';

class NES {
  NES() {
    cpu
      ..ppu = ppu
      ..apu = apu;
  }

  Cartridge? cartridge;

  final CPU cpu = CPU();
  final PPU ppu = PPU();
  final APU apu = APU();

  void loadCartridge(Cartridge cartridge) {
    this.cartridge = cartridge;
    cpu.cartridge = cartridge;
    // TODO bud-26.05.24 start emulation
  }

  void step() {
    final cycles = cpu.step();

    for (var i = 0; i < cycles * 3; i++) {
      ppu.step();
    }
  }
}
