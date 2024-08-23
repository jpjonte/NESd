import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/single_prg_bank_state.dart';

class BR909x extends Mapper {
  BR909x() : super(71);

  int prgBank = 0;

  @override
  int prgBankSize = 0x4000;

  @override
  int chrBankSize = 0x2000;

  @override
  String name = 'BR909x';

  @override
  SinglePrgBankState get state => SinglePrgBankState(id: 71, prgBank: prgBank);

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
