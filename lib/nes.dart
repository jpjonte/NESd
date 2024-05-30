import 'package:nes/apu.dart';
import 'package:nes/bus.dart';
import 'package:nes/cartridge.dart';
import 'package:nes/cpu.dart';
import 'package:nes/ppu.dart';

class NES {
  NES() {
    bus
      ..cpu = cpu
      ..ppu = ppu
      ..apu = apu;
  }

  Cartridge? cartridge;

  final Bus bus = Bus();
  late final CPU cpu = CPU(bus);
  late final PPU ppu = PPU(bus);
  late final APU apu = APU(bus);

  void loadCartridge(Cartridge cartridge) {
    bus.cartridge = cartridge;

    reset();
  }

  void reset() {
    cpu.reset();
    apu.reset();
    ppu.reset();
  }

  void step() {
    final cycles = cpu.step();

    for (var i = 0; i < cycles * 3; i++) {
      ppu.step();
    }
  }
}
