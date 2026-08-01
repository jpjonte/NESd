import 'package:flutter_test/flutter_test.dart';

import 'mmc5_harness.dart';

void main() {
  test('extended attribute CHR fetches wrap instead of crashing', () {
    // In extended attribute mode the CHR bank comes from ExRAM, and the mode
    // can express banks far past the end of a small CHR ROM.
    final mapper = buildMmc5()..cpuWrite(0x5104, 0x01);

    // Four identical nametable reads are what tells the MMC5 it is inside a
    // rendered frame.
    for (var i = 0; i < 4; i++) {
      mapper.ppuRead(0x2000);
    }

    // Read past the end of this cartridge's 64 KB
    mapper
      ..cpuWrite(0x5130, 0x03) // upper CHR bank bits
      ..cpuWrite(0x5c00, 0x3f) // lower bits -> bank 255
      ..ppuRead(0x2000)
      ..ppuRead(0x0000);

    expect(() => mapper.ppuRead(0x0001), returnsNormally);
  });
}
