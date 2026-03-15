import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/single_prg_bank_state.dart';

class BR909x extends Mapper {
  BR909x() : super(71);

  int prgBank = 0;

  @override
  int prgRomPageSize = 0x4000;

  @override
  int chrPageSize = 0x2000;

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
    super.reset();

    prgBank = 0;

    _updatePrgPages();
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    if (address < 0x8000) {
      return;
    }

    prgBank = value & 0x0f;

    _updatePrgPages();
  }

  void _updatePrgPages() {
    mapCpu(0x8000, 0xbfff, prgBank);
    mapCpu(0xc000, 0xffff, -1);
  }
}
