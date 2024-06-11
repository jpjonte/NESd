// ignore_for_file: parameter_assignments

import 'package:nes/exception/cartridge_not_loaded.dart';
import 'package:nes/nes/apu/apu.dart';
import 'package:nes/nes/cartridge/cartridge.dart';
import 'package:nes/nes/cpu/cpu.dart';
import 'package:nes/nes/ppu/ppu.dart';

const addressNone = -1;
const addressA = -2;

enum NesButton {
  a,
  b,
  select,
  start,
  up,
  down,
  left,
  right,
}

class Bus {
  late final CPU cpu;
  late final PPU ppu;
  late final APU apu;

  Cartridge? cartridge;

  bool inputStrobe = false;

  int controller1Status = 0;
  int controller1Shift = 0;
  int controller2Status = 0;
  int controller2Shift = 0;

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

    if (address == 0x4015) {
      return apu.readRegister(address);
    }

    if (address == 0x4016) {
      final value = controller1Shift < 8
          ? (controller1Status >> controller1Shift) & 1
          : 1;

      if (!inputStrobe) {
        controller1Shift++;
      }

      return value;
    }

    if (address == 0x4017) {
      final value = controller2Shift < 8
          ? (controller2Status >> controller2Shift) & 1
          : 1;

      if (!inputStrobe) {
        controller2Shift++;
      }

      return value;
    }

    if (address < 0x4020) {
      return 0;
    }

    final cartridge = this.cartridge;

    if (cartridge == null) {
      throw CartridgeNotLoaded();
    }

    return cartridge.read(this, address);
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

    if (address < 0x4009 ||
        (address >= 0x400A && address <= 0x400C) ||
        (address >= 0x400E && address <= 0x4013) ||
        address == 0x4015 ||
        address == 0x4017) {
      apu.writeRegister(address, value);

      return;
    }

    if (address == 0x4014) {
      cpu
        ..oamDma = true
        ..oamDmaPage = value
        ..oamDmaOffset = 0;
    }

    if (address == 0x4016) {
      inputStrobe = (value & 1) == 1;
      controller1Shift = 0;
      controller2Shift = 0;
    }

    if (address < 0x4020) {
      return;
    }

    final cartridge = this.cartridge;

    if (cartridge == null) {
      throw CartridgeNotLoaded();
    }

    cartridge.write(this, address, value);
  }

  int ppuRead(int address) {
    address = address & 0x3fff;

    if (address < 0x3f00) {
      return cartridge!.read(this, address);
    }

    return ppu.palette[_paletteAddress(address)];
  }

  void ppuWrite(int address, int value) {
    if (address < 0x3f00) {
      cartridge!.write(this, address, value);

      return;
    }

    if (address < 0x3f20) {
      ppu.palette[_paletteAddress(address)] = value;

      return;
    }
  }

  void buttonDown(int controller, NesButton button) {
    if (controller == 0) {
      controller1Status |= 1 << button.index;
    } else {
      controller2Status |= 1 << button.index;
    }
  }

  void buttonUp(int controller, NesButton button) {
    if (controller == 0) {
      controller1Status &= ~(1 << button.index);
    } else {
      controller2Status &= ~(1 << button.index);
    }
  }

  int _paletteAddress(int address) {
    address &= 0x1f;

    if (address == 0x10) {
      address = 0x00;
    }

    if (address == 0x14) {
      address = 0x04;
    }

    if (address == 0x18) {
      address = 0x08;
    }

    if (address == 0x1c) {
      address = 0x0c;
    }

    return address;
  }
}
