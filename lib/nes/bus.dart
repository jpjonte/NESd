// ignore_for_file: parameter_assignments

import 'package:nesd/nes/apu/apu.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cpu/cpu.dart';
import 'package:nesd/nes/ppu/ppu.dart';

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
  Bus(this.cartridge);

  final Cartridge cartridge;

  late final CPU cpu;
  late final PPU ppu;
  late final APU apu;

  bool _inputStrobe = false;

  final _controllerStatus = [0, 0];
  final _controllerShift = [0, 0];

  int cpuRead(int address, {bool disableSideEffects = false}) {
    if (address == addressA) {
      return cpu.A;
    }

    address &= 0xffff;

    if (address < 0x2000) {
      return cpu.ram[address & 0x07ff];
    }

    if (address < 0x4000) {
      return ppu.readRegister(
        0x2000 | (address & 0x07),
        disableSideEffects: disableSideEffects,
      );
    }

    if (address == 0x4015) {
      return apu.readRegister(address, disableSideEffects: disableSideEffects);
    }

    if (address == 0x4016) {
      return _readController(0, disableSideEffects: disableSideEffects);
    }

    if (address == 0x4017) {
      return _readController(1, disableSideEffects: disableSideEffects);
    }

    if (address < 0x4020) {
      return 0;
    }

    return cartridge.read(
      this,
      address,
      disableSideEffects: disableSideEffects,
    );
  }

  int cpuRead16(
    int address, {
    bool wrap = false,
    bool disableSideEffects = false,
  }) {
    final low = cpuRead(address, disableSideEffects: disableSideEffects);

    final highAddress =
        wrap ? (address & 0xff00 | ((address + 1) & 0xff)) : address + 1;

    final high = cpuRead(highAddress, disableSideEffects: disableSideEffects);

    return low | (high << 8);
  }

  void cpuWrite(int address, int value) {
    value &= 0xff;

    if (address == addressA) {
      cpu.A = value;

      return;
    }

    address &= 0xffff;

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
      cpu.triggerOamDma(value);

      return;
    }

    if (address == 0x4016) {
      _strobeControllers(value);

      return;
    }

    if (address < 0x4020) {
      return;
    }

    cartridge.write(this, address, value);
  }

  int ppuRead(int address) {
    address = address & 0x3fff;

    if (address < 0x3f00) {
      return cartridge.read(this, address);
    }

    return ppu.palette[_paletteAddress(address)];
  }

  void ppuWrite(int address, int value) {
    if (address < 0x3f00) {
      cartridge.write(this, address, value);

      return;
    }

    if (address < 0x3fff) {
      ppu.palette[_paletteAddress(address)] = value;

      return;
    }
  }

  void buttonDown(int controller, NesButton button) {
    _controllerStatus[controller] |= 1 << button.index;
  }

  void buttonUp(int controller, NesButton button) {
    _controllerStatus[0] &= ~(1 << button.index);
  }

  void triggerIrq(IrqSource source) => cpu.triggerIrq(source);

  void clearIrq(IrqSource source) => cpu.clearIrq(source);

  void triggerNmi() => cpu.triggerNmi();

  void clearNmi() => cpu.clearNmi();

  void triggerDmcDma() => cpu.triggerDmcDma();

  int _readController(int controller, {bool disableSideEffects = false}) {
    final value = _controllerShift[controller] < 8
        ? (_controllerStatus[controller] >> _controllerShift[controller]) & 1
        : 1;

    if (!_inputStrobe && !disableSideEffects) {
      _controllerShift[controller]++;
    }

    return value;
  }

  void _strobeControllers(int value) {
    _inputStrobe = (value & 1) == 1;
    _controllerShift[0] = 0;
    _controllerShift[1] = 0;
  }

  int _paletteAddress(int address) {
    return switch (address & 0x1f) {
      0x10 => 0x00,
      0x14 => 0x04,
      0x18 => 0x08,
      0x1c => 0x0c,
      _ => address & 0x1f,
    };
  }
}
