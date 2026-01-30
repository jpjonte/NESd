import 'package:nesd/nes/cartridge/mapper/cnrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';

class CNROM extends Mapper {
  CNROM() : super(3);

  int chrBank = 0;

  @override
  int prgRomPageSize = 0x8000;

  @override
  int chrPageSize = 0x2000;

  @override
  CNROMState get state => CNROMState(chrBank: chrBank);

  @override
  set state(covariant CNROMState state) {
    chrBank = state.chrBank;

    _updateState();
  }

  @override
  String name = 'CNROM';

  @override
  void reset() {
    super.reset();

    chrBank = 0;

    _updateState();
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    if (address < 0x8000) {
      return;
    }

    chrBank = value & 0x0f;

    _updateChrPages();
  }

  void _updateState() {
    _updatePrgPages();
    _updateChrPages();
  }

  void _updatePrgPages() {
    mapCpu(0x8000, 0xffff, 0, type: CpuMemoryType.prgRom);
  }

  void _updateChrPages() {
    mapPpu(0x0000, 0x1fff, chrBank);
  }
}
