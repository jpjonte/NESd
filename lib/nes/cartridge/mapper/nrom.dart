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
}
