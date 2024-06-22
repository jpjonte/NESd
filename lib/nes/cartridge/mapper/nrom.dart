import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cartridge/mapper/mapper.dart';
import 'package:nes/nes/cartridge/mapper/mapper_state.dart';
import 'package:nes/nes/cartridge/mapper/nrom_state.dart';

class NROM extends Mapper {
  NROM() : super(0);

  @override
  String name = 'NROM';

  @override
  NROMState get state => const NROMState();

  @override
  set state(MapperState state) {
    // No-op
  }

  @override
  int read(Bus bus, int address) {
    if (address < 0x2000) {
      if (cartridge.chr.isEmpty) {
        return 0;
      }

      return cartridge.chr[address % cartridge.chr.length];
    }

    if (address < 0x3f00) {
      return bus.ppu.ram[nametableMirror(address)];
    }

    if (address < 0x6000) {
      return 0;
    }

    if (address < 0x8000) {
      if (!cartridge.hasBattery) {
        return 0;
      }

      return cartridge.sram[address - 0x6000];
    }

    if (address <= 0xffff) {
      return cartridge.prgRom[address % cartridge.prgRomSize];
    }

    return 0;
  }

  @override
  void write(Bus bus, int address, int value) {
    if (address < 0x2000) {
      return;
    }

    if (address < 0x3f00) {
      bus.ppu.ram[nametableMirror(address)] = value;

      return;
    }

    if (address < 0x6000) {
      return;
    }

    if (address < 0x8000) {
      if (!cartridge.hasBattery) {
        return;
      }

      cartridge.sram[address - 0x6000] = value;

      return;
    }
  }
}
