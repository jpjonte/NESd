// ignore_for_file: parameter_assignments

import 'package:nes/exception/cartridge_not_loaded.dart';
import 'package:nes/nes/apu/apu.dart';
import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/nes/cpu/cpu.dart';
import 'package:nes/nes/ppu/ppu.dart';

const addressNone = -1;
const addressA = -2;

class Bus {
  late final CPU cpu;
  late final PPU ppu;
  late final APU apu;

  Cartridge? cartridge;

  int cpuRead(int address) {
    if (address == addressA) {
      return cpu.A;
    }

    if (address < 0x2000) {
      return cpu.ram[address & 0x07ff];
    }

    if (address < 0x4000) {
      return ppu.readRegister(0x2000 | (address & 0x07));
    }

    if (address < 0x4015) {
      return 0;
    }

    if (address == 0x4015) {
      return apu.status;
    }

    if (address == 0x4016) {
      // TODO bud-27.05.24 controller 1
      return 0;
    }

    if (address == 0x4017) {
      // TODO bud-27.05.24 controller 2
      return 0;
    }

    if (address < 0x4020) {
      return 0;
    }

    final cartridge = this.cartridge;

    if (cartridge == null) {
      throw CartridgeNotLoaded();
    }

    return cartridge.read(address);
  }

  int cpuRead16(int address, {bool wrap = false}) {
    final low = cpuRead(address);

    final highAddress =
        wrap ? (address & 0xff00 | ((address + 1) & 0xff)) : address + 1;

    final high = cpuRead(highAddress);

    return low | (high << 8);
  }

  void cpuWrite(int address, int value) {
    if (address == addressA) {
      cpu.A = value;

      return;
    }

    address &= 0xffff;
    value &= 0xff;

    if (address < 0x2000) {
      cpu.ram[address % 0x800] = value;

      return;
    }

    if (address < 0x4000) {
      ppu.writeRegister(address, value);

      return;
    }

    if (address == 0x4014) {
      cpu
        ..dma = DmaType.oam
        ..dmaPage = value
        ..dmaOffset = 0;
    }

    if (address < 0x4015) {
      return;
    }

    if (address == 0x4015) {
      apu.write(address, value);

      return;
    }

    if (address == 0x4016) {
      // TODO bud-27.05.24

      return;
    }

    if (address == 0x4017) {
      // TODO bud-27.05.24
      return;
    }

    if (address < 0x4020) {
      return;
    }

    final cartridge = this.cartridge;

    if (cartridge == null) {
      throw CartridgeNotLoaded();
    }

    cartridge.write(address, value);
  }

  int ppuRead(int address) {
    address = address & 0x3fff;

    if (address < 0x2000) {
      final cartridge = this.cartridge;

      if (cartridge == null) {
        throw CartridgeNotLoaded();
      }

      return cartridge.read(address);
    }

    if (address < 0x3f00) {
      // TODO bud-31.05.24 nametable mirroring
      return ppu.ram[address & 0x07ff];
    }

    return ppu.palette[address & 0x1f];
  }

  void ppuWrite(int address, int value) {
    // TODO bud-01.06.24 check mirrors
    if (address >= 0x2000 && address < 0x3f00) {
      ppu.ram[address & 0x7ff] = value;

      return;
    }

    if (address < 0x3f20) {
      ppu.palette[address & 0x1f] = value;

      return;
    }
  }

  int apuRead(int address) {
    return 0;
  }

  void apuWrite(int address, int value) {}
}
