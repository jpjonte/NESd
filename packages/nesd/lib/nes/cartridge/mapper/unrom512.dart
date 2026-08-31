import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/unrom512_state.dart';

class UNROM512 extends Mapper {
  UNROM512(int subMapperId) : super(30, subMapperId);

  int latch = 0;

  int get prgBank => latch & 0x1f;

  int get chrBank => (latch >> 5) & 0x03;

  late final bool _lowRegister =
      (subMapperId == 0 && !cartridge.hasBattery) || subMapperId == 2;

  @override
  String name = 'UNROM 512';

  @override
  int prgRomPageSize = 0x4000;

  @override
  int chrPageSize = 0x2000;

  @override
  int get minChrRamSize => 0x8000;

  @override
  UNROM512State get state => UNROM512State(latch: latch);

  @override
  set state(covariant UNROM512State state) {
    latch = state.latch;

    _updateState();
  }

  @override
  void reset() {
    super.reset();

    latch = 0;

    _updateState();
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    if (address < 0x8000) {
      return;
    }

    if (address < 0xc000 && !_lowRegister) {
      return;
    }

    latch = _lowRegister ? value & cpuRead(address) : value;

    _updateState();
  }

  void _updateState() {
    _updateBanks();
    _updateMirroring();
  }

  void _updateBanks() {
    mapCpu(0x8000, 0xbfff, prgBank);
    mapCpu(0xc000, 0xffff, -1);
    mapPpu(0x0000, 0x1fff, chrBank);
  }

  void _updateMirroring() {
    if (subMapperId == 3) {
      nametableLayout = latch.bit(7) == 0
          ? NametableLayout.vertical
          : NametableLayout.horizontal;

      return;
    }

    if (!cartridge.alternativeNametableLayout ||
        cartridge.nametableLayout == NametableLayout.horizontal) {
      nametableLayout = cartridge.nametableLayout;

      return;
    }

    nametableLayout = latch.bit(7) == 0
        ? NametableLayout.singleLower
        : NametableLayout.singleUpper;
  }
}
