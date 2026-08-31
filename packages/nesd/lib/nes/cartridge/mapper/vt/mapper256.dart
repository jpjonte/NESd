import 'package:nesd/nes/cartridge/mapper/vt/vt02.dart';

/// VT03 OneBus. Minimal implementation until follow-up issues are implemented.
class Mapper256 extends VT02 {
  Mapper256([int subMapperId = 0]) : super(256, subMapperId);

  @override
  String get name => 'VT03 OneBus';

  @override
  void reset() {
    super.reset();

    final lastBank = cartridge.prgRom.length ~/ prgRomPageSize - 1;

    mapCpu(0x8000, 0xbfff, lastBank - 1);
    mapCpu(0xc000, 0xffff, lastBank);
    mapPpu(0x0000, 0x1fff, 0);
  }
}
