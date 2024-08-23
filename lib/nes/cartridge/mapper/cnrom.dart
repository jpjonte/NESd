import 'package:nesd/nes/cartridge/mapper/cnrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';

class CNROM extends Mapper {
  CNROM() : super(3);

  int chrBank = 0;

  @override
  CNROMState get state => CNROMState(chrBank: chrBank);

  @override
  set state(covariant CNROMState state) {
    chrBank = state.chrBank;
  }

  @override
  String name = 'CNROM';

  @override
  void reset() {
    chrBank = 0;
  }

  @override
  int chrAddress(int address) {
    return ((chrBank << 13) | (address & 0x1fff)) % cartridge.chr.length;
  }

  @override
  void writePrg(int address, int value) {
    chrBank = value & 0x0f;
  }
}
