// we need to mask the addresses a lot
// ignore_for_file: parameter_assignments

import 'dart:ui';

import 'package:nesd/nes/apu/apu.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cpu/cpu.dart';
import 'package:nesd/nes/cpu/irq_source.dart';
import 'package:nesd/nes/input/controller.dart';
import 'package:nesd/nes/input/input_device.dart';
import 'package:nesd/nes/input/zapper.dart';
import 'package:nesd/nes/ppu/ppu.dart';

const addressNone = -1;
const addressA = -2;

enum NesButton { a, b, select, start, up, down, left, right }

class Bus {
  Bus(this.cartridge) {
    if (cartridge.databaseEntry?.hasZapper ?? false) {
      _inputs[1] = _zapper;
    }
  }

  final Cartridge cartridge;

  late final CPU cpu;
  late final PPU ppu;
  late final APU apu;

  final List<InputDevice> _inputs = [Controller(), Controller()];

  late final Zapper _zapper = Zapper(bus: this);

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
      return _inputs[0].read(address, disableSideEffects: disableSideEffects);
    }

    if (address == 0x4017) {
      return _inputs[1].read(address, disableSideEffects: disableSideEffects);
    }

    if (address < 0x4020) {
      return 0;
    }

    return cartridge.cpuRead(address, disableSideEffects: disableSideEffects);
  }

  void cpuWrite(int address, int value) {
    value &= 0xff;

    if (address == addressA) {
      cpu.A = value;

      return;
    }

    address &= 0xffff;

    if (address < 0x2000) {
      cpu.ram[address & 0x7ff] = value;

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
      _inputs[0].write(address, value);
      _inputs[1].write(address, value);

      return;
    }

    if (address < 0x4020) {
      return;
    }

    cartridge.cpuWrite(address, value);
  }

  int ppuRead(int address, {bool disableSideEffects = false}) {
    address = address & 0x3fff;

    if (address < 0x3f00) {
      return cartridge.ppuRead(address, disableSideEffects: disableSideEffects);
    }

    return ppu.palette[_paletteAddress(address)];
  }

  void ppuWrite(int address, int value) {
    if (address < 0x3f00) {
      cartridge.ppuWrite(address, value);

      return;
    }

    if (address < 0x3fff) {
      final idx = _paletteAddress(address);

      ppu.palette[idx] = value;
      // notify PPU to refresh LUT entry for this palette index
      // (safe even if LUT is not used yet)
      ppu.onPaletteWrite(idx);

      return;
    }
  }

  void buttonDown(int controller, NesButton button) {
    if (_inputs[controller] case final Controller controller) {
      controller.buttonDown(button);
    }
  }

  void buttonUp(int controller, NesButton button) {
    if (_inputs[controller] case final Controller controller) {
      controller.buttonUp(button);
    }
  }

  void buttonToggle(int controller, NesButton button) {
    if (_inputs[controller] case final Controller controller) {
      controller.buttonToggle(button);
    }
  }

  void triggerIrq(IrqSource source) => cpu.triggerIrq(source);

  void clearIrq(IrqSource source) => cpu.clearIrq(source);

  void triggerNmi() => cpu.triggerNmi();

  void clearNmi() => cpu.clearNmi();

  void triggerDmcDma() => cpu.triggerDmcDma();

  void zapperPull() => _zapper.trigger = true;

  void zapperRelease() => _zapper.trigger = false;

  Offset? get zapperPosition => _zapper.position;

  set zapperPosition(Offset? position) => _zapper.position = position;

  @pragma('vm:prefer-inline')
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
