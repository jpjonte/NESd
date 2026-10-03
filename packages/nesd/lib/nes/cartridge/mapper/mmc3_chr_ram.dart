import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3.dart';

class MMC3ChrRam extends MMC3 {
  MMC3ChrRam(super.id);

  @override
  String get name => switch (id) {
    119 => 'TQROM',
    _ => 'Waixing MMC3 ($id)',
  };

  @override
  int get minChrRamSize => switch (id) {
    74 => 0x800,
    119 => 0x2000,
    _ => 0x1000,
  };

  @override
  PpuMemoryType chrPageMemoryType(int page) {
    final isRam = switch (id) {
      74 => page == 8 || page == 9,
      119 => page.bit(6) == 1,
      _ => page >= 8 && page <= 11,
    };

    return isRam ? PpuMemoryType.chrRam : PpuMemoryType.chrRom;
  }
}
