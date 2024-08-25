import 'package:nesd/exception/unsupported_mapper.dart';
import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/axrom.dart';
import 'package:nesd/nes/cartridge/mapper/br909x.dart';
import 'package:nesd/nes/cartridge/mapper/cnrom.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc1.dart';
import 'package:nesd/nes/cartridge/mapper/mmc2.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3.dart';
import 'package:nesd/nes/cartridge/mapper/namco108.dart';
import 'package:nesd/nes/cartridge/mapper/nrom.dart';
import 'package:nesd/nes/cartridge/mapper/unrom.dart';

abstract class Mapper {
  Mapper(this.id);

  factory Mapper.fromId(int mapper) {
    return switch (mapper) {
      0 => NROM(),
      1 => MMC1(),
      2 => UNROM(),
      3 => CNROM(),
      4 => MMC3(),
      7 => AxROM(),
      9 => MMC2(),
      71 => BR909x(),
      206 => Namco108(),
      _ => throw UnsupportedMapper(mapper),
    };
  }

  final int id;

  late final Bus bus;

  late final Cartridge _cartridge;

  Cartridge get cartridge => _cartridge;

  set cartridge(Cartridge cartridge) {
    _cartridge = cartridge;
    nametableLayout = cartridge.nametableLayout;
  }

  late NametableLayout nametableLayout;

  MapperState get state;

  set state(MapperState state);

  String get name;

  int get prgBankSize => 0x4000;

  late final List<int> _prgBankToPrgPage = List.filled(_totalPrgBanks, 0);

  late final int _totalPrgBanks = 0x8000 ~/ prgBankSize;
  late final int _totalPrgPages = cartridge.prgRomSize ~/ prgBankSize;

  int get chrBankSize => 0x2000;

  late final List<int> _chrBankToChrPage = List.filled(_totalChrBanks, 0);

  late final int _totalChrBanks = 0x2000 ~/ chrBankSize;
  late final int _totalChrPages = cartridge.chrRomSize ~/ chrBankSize;

  void reset() {}

  int read(int address, {bool disableSideEffects = false}) {
    if (address < 0x2000) {
      return readChr(address);
    }

    if (address < 0x3f00) {
      return readPpuRam(address);
    }

    if (address < 0x6000) {
      return 0;
    }

    if (address < 0x8000) {
      return readSram(address);
    }

    if (address <= 0xffff) {
      return readPrgRom(address);
    }

    return 0;
  }

  int readChr(int address) {
    if (cartridge.chr.isEmpty) {
      return 0;
    }

    return cartridge.chr[chrAddress(address)];
  }

  int readPpuRam(int address) => bus.ppu.ram[nametableAddress(address)];

  int readSram(int address) => cartridge.sram[address & 0x1fff];

  int readPrgRom(int address) => cartridge.prgRom[prgAddress(address)];

  int chrAddress(int address) {
    final bank = _chrBankForAddress(address);
    final page = _chrPageForBank(bank);

    final mappedAddress = (page * chrBankSize) | (address & (chrBankSize - 1));

    return mappedAddress % cartridge.chr.length;
  }

  int nametableAddress(int address) {
    return switch (nametableLayout) {
      NametableLayout.vertical => (address & 0x7ff).setBit(10, address.bit(11)),
      NametableLayout.horizontal => address & 0x7ff,
      NametableLayout.four => address & 0xfff,
      NametableLayout.singleUpper => address & 0x3ff,
      NametableLayout.singleLower => 0x400 + address & 0x3ff,
    };
  }

  int prgAddress(int address) {
    final bank = _prgBankForAddress(address);
    final page = _prgPageForBank(bank);

    final mappedAddress =
        (page * prgBankSize) | ((address - 0x8000) & (prgBankSize - 1));

    return mappedAddress % cartridge.prgRom.length;
  }

  void write(Bus bus, int address, int value) {
    if (address < 0x2000) {
      writeChr(address, value);

      return;
    }

    if (address < 0x3f00) {
      writePpuRam(address, value);

      return;
    }

    if (address < 0x6000) {
      return;
    }

    if (address < 0x8000) {
      writeCartridgeSram(address, value);

      return;
    }

    if (address <= 0xffff) {
      writePrg(address, value);
    }
  }

  void writeChr(int address, int value) {
    if (cartridge.chrRomSize > 0) {
      // no CHR RAM -> not writable
      return;
    }

    cartridge.chr[chrAddress(address)] = value;
  }

  void writePpuRam(int address, int value) {
    bus.ppu.ram[nametableAddress(address)] = value;
  }

  void writeCartridgeSram(int address, int value) {
    cartridge.sram[address & 0x1fff] = value;
  }

  void writePrg(int address, int value) {}

  void updatePpuAddress(int address) {}

  void setPrgPage(int bank, int page) {
    _prgBankToPrgPage[bank] = page % _totalPrgPages;
  }

  void setChrPage(int bank, int page) {
    _chrBankToChrPage[bank] = page % _totalChrPages;
  }

  int _prgPageForBank(int bank) {
    return _prgBankToPrgPage[bank % _totalPrgBanks];
  }

  int _prgBankForAddress(int address) {
    return (address - 0x8000) ~/ prgBankSize;
  }

  int _chrBankForAddress(int address) {
    return address ~/ chrBankSize;
  }

  int _chrPageForBank(int bank) {
    return _chrBankToChrPage[bank % _totalChrBanks];
  }
}
