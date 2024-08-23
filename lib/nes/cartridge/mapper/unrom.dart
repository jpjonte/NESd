import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/single_prg_bank_state.dart';

class UNROM extends Mapper {
  UNROM() : super(2);

  int prgBank = 0;

  @override
  String name = 'UNROM';

  @override
  SinglePrgBankState get state => SinglePrgBankState(id: 2, prgBank: prgBank);

  @override
  set state(covariant SinglePrgBankState state) {
    prgBank = state.prgBank;
  }

  @override
  void reset() {
    prgBank = 0;
  }

  @override
  int readPrgRom(int address) {
    if (address < 0xc000) {
      return cartridge.prgRom[((prgBank & 0xf) << 14) | (address & 0x3fff)];
    }

    return cartridge
        .prgRom[(cartridge.prgRomSize - 0x4000) | (address & 0x3fff)];
  }

  @override
  void writePrg(int address, int value) {
    prgBank = value & 0x0f;
  }
}
