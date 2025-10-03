import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3.dart';

class TxSROM extends MMC3 {
  TxSROM() : super(118);

  @override
  String get name => 'TxSROM';

  @override
  void cpuWrite(int address, int value) {
    switch (address & 0xe001) {
      // bank data (0x8001 - 0x9fff, odd)
      case 0x8001:
        final nametable = value.bit(7);

        switch (register) {
          case 0:
            if (chrBankMode == 0) {
              setNametable(0, nametable);
              setNametable(1, nametable);
            }
          case 1:
            if (chrBankMode == 0) {
              setNametable(2, nametable);
              setNametable(3, nametable);
            }
          case 2:
            if (chrBankMode == 1) {
              setNametable(0, nametable);
            }
          case 3:
            if (chrBankMode == 1) {
              setNametable(1, nametable);
            }
          case 4:
            if (chrBankMode == 1) {
              setNametable(2, nametable);
            }
          case 5:
            if (chrBankMode == 1) {
              setNametable(3, nametable);
            }
        }

        // ignore: parameter_assignments
        value = value & 0x7f;
      // Mirroring (0xa000 - 0xbffe, even)
      case 0xa000:
        return;
    }

    super.cpuWrite(address, value);
  }
}
