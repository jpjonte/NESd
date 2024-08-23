import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/single_prg_bank_state.dart';

class UNROM extends Mapper {
  UNROM() : super(2);

  int prgBank = 0;

  @override
  String name = 'UNROM';

  @override
  int prgBankSize = 0x4000;

  @override
  int chrBankSize = 0x2000;

  @override
  SinglePrgBankState get state => SinglePrgBankState(id: 2, prgBank: prgBank);

  @override
  set state(covariant SinglePrgBankState state) {
    prgBank = state.prgBank;

    _updatePrgPages();
  }

  @override
  void reset() {
    prgBank = 0;

    _updatePrgPages();
  }

  @override
  void writePrg(int address, int value) {
    prgBank = value & 0x0f;

    _updatePrgPages();
  }

  void _updatePrgPages() {
    setPrgPage(0, prgBank);
    setPrgPage(1, -1);
  }
}
