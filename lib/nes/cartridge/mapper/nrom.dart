import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';
import 'package:nesd/nes/cartridge/mapper/nrom_state.dart';

class NROM extends Mapper {
  NROM() : super(0);

  @override
  String name = 'NROM';

  @override
  NROMState get state => const NROMState();

  @override
  set state(MapperState state) {
    // No-op
  }

  @override
  int prgRomPageSize = 0x4000;

  @override
  int chrPageSize = 0x2000;

  @override
  void reset() {
    super.reset();

    mapCpu(0x8000, 0xbfff, 0);
    mapCpu(0xc000, 0xffff, -1);

    mapPpu(0x0000, 0x1fff, 0);
  }
}
