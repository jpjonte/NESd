import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mmc1_state.dart';

class MMC1 extends Mapper {
  MMC1() : super(1);

  @override
  String name = 'MMC1';

  int shift = 0x10;

  int control = 0x0c;

  int get controlMirroring => control & 0x3;
  int get controlPrgMode => (control >> 2) & 0x3;
  int get controlChrMode => control.bit(4);

  int chrBank0 = 0;

  int chrBank1 = 1;

  int prgBank = 0;

  int get prgBankValue => prgBank & 0xf;
  int get prgBankRam => (prgBank >> 4) & 0x1;

  @override
  MMC1State get state => MMC1State(
        shift: shift,
        control: control,
        chrBank0: chrBank0,
        chrBank1: chrBank1,
        prgBank: prgBank,
      );

  @override
  set state(covariant MMC1State state) {
    shift = state.shift;
    control = state.control;
    chrBank0 = state.chrBank0;
    chrBank1 = state.chrBank1;
    prgBank = state.prgBank;

    _updateMirroring();
  }

  @override
  void reset() {
    final mirroring = switch (cartridge.nametableLayout) {
      NametableLayout.vertical => 3,
      NametableLayout.horizontal => 2,
      NametableLayout.four => 0,
      NametableLayout.singleUpper => 0,
      NametableLayout.singleLower => 0,
    };

    shift = 0x10;
    control = 0x0c | mirroring;
    chrBank0 = 0;
    chrBank1 = 1;
    prgBank = 0;

    _updateMirroring();
  }

  @override
  void writePrg(int address, int value) {
    // TODO ignore consecutive cycle writes
    if (value.bit(7) == 1) {
      shift = 0x10;
      control = control | 0xc;

      _updateMirroring();

      return;
    }

    if (shift.bit(0) == 1) {
      final register = (address >> 13) & 0x3;
      final registerValue = value.bit(0) << 4 | ((shift >> 1) & 0xf);

      shift = 0x10;

      switch (register) {
        case 0:
          control = registerValue;
          _updateMirroring();
        case 1:
          chrBank0 = registerValue;
        case 2:
          chrBank1 = registerValue;
        case 3:
          prgBank = registerValue;
      }

      return;
    }

    shift >>= 1;
    shift = shift.setBit(4, value.bit(0));
  }

  @override
  int chrAddress(int address) {
    return switch (controlChrMode) {
          0 => ((chrBank0 & 0x1e) << 12) | (address & 0x1fff),
          1 => switch (address.bit(12)) {
              0 => (chrBank0 << 12) | (address & 0xfff),
              1 => (chrBank1 << 12) | (address & 0xfff),
              _ => 0,
            },
          _ => 0,
        } %
        cartridge.chr.length;
  }

  @override
  int prgAddress(int address) {
    return switch (controlPrgMode) {
          // switchable 32k bank
          0 || 1 => ((prgBankValue & 0xe) << 14) | (address & 0x7fff),
          2 => switch (address.bit(14)) {
              // fixed first bank at 0x8000
              0 => address & 0x3fff,
              // switchable 16k bank at 0xc000
              1 => ((prgBankValue & 0xf) << 14) | (address & 0x3fff),
              _ => 0,
            },
          3 => switch (address.bit(14)) {
              // switchable 16k bank at 0x9000
              0 => ((prgBankValue & 0xf) << 14) | (address & 0x3fff),
              // fixed last bank at 0xc000
              1 => (cartridge.prgRomSize - 0x4000) | (address & 0x3fff),
              _ => 0,
            },
          _ => 0,
        } %
        cartridge.prgRomSize;
  }

  void _updateMirroring() {
    nametableLayout = switch (controlMirroring) {
      0 => NametableLayout.singleLower,
      1 => NametableLayout.singleUpper,
      2 => NametableLayout.horizontal,
      3 => NametableLayout.vertical,
      _ => nametableLayout,
    };
  }
}
