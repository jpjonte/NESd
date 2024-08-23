import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/mapper/axrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';

class AxROM extends Mapper {
  AxROM() : super(7);

  int prgBank = 0;

  int vramBank = 0;

  @override
  AXROMState get state => AXROMState(
        prgBank: prgBank,
        vramBank: vramBank,
      );

  @override
  set state(covariant AXROMState state) {
    prgBank = state.prgBank;
    vramBank = state.vramBank;
  }

  @override
  String name = 'AxROM';

  @override
  void reset() {
    prgBank = 0;
    vramBank = 0;
  }

  @override
  void writePrg(int address, int value) {
    prgBank = value & 0x07;
    vramBank = value.bit(4);
  }

  @override
  int nametableAddress(int address) {
    return vramBank << 10 | address & 0x3ff;
  }

  @override
  int prgAddress(int address) {
    return prgBank << 15 | address & 0x7fff;
  }
}
