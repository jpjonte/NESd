import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/single_prg_bank_state.dart';

class BR909x extends Mapper {
  BR909x() : super(71);

  int prgBank = 0;

  @override
  String name = 'BR909x';

  @override
  SinglePrgBankState get state => SinglePrgBankState(id: 71, prgBank: prgBank);

  @override
  set state(covariant SinglePrgBankState state) {
    prgBank = state.prgBank;
  }

  @override
  void reset() {
    prgBank = 0;
  }

  @override
  void writePrg(int address, int value) {
    prgBank = value & 0x0f;
  }

  @override
  int prgAddress(int address) {
    return switch (address) {
          >= 0x8000 && <= 0xbfff => prgBank * 0x4000 | address & 0x3fff,
          >= 0xc000 && <= 0xffff =>
            (cartridge.prgRom.length - 0x4000) | address & 0x3fff,
          _ => 0,
        } %
        cartridge.prgRom.length;
  }
}
