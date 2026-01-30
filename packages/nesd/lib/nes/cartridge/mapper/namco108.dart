import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/namco108_state.dart';

class Namco108 extends Mapper {
  Namco108() : super(206);

  @override
  String name = 'Namco 108';

  @override
  int prgRomPageSize = 0x2000;

  @override
  int chrPageSize = 0x0400;

  int _register = 0;

  int _r0 = 0;
  int _r1 = 0;
  int _r2 = 0;
  int _r3 = 0;
  int _r4 = 0;
  int _r5 = 0;
  int _r6 = 0;
  int _r7 = 0;

  @override
  Namco108State get state => Namco108State(
    register: _register,
    r0: _r0,
    r1: _r1,
    r2: _r2,
    r3: _r3,
    r4: _r4,
    r5: _r5,
    r6: _r6,
    r7: _r7,
  );

  @override
  set state(covariant Namco108State state) {
    _register = state.register;
    _r0 = state.r0;
    _r1 = state.r1;
    _r2 = state.r2;
    _r3 = state.r3;
    _r4 = state.r4;
    _r5 = state.r5;
    _r6 = state.r6;
    _r7 = state.r7;

    _updateState();
  }

  @override
  void reset() {
    super.reset();

    _register = 0;
    _r0 = 0;
    _r1 = 0;
    _r2 = 0;
    _r3 = 0;
    _r4 = 0;
    _r5 = 0;
    _r6 = 0;
    _r7 = 0;

    _updateState();
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    switch (address & 0x9001) {
      case 0x8000:
      case 0x9000:
        _register = value & 0x07;
      case 0x8001:
      case 0x9001:
        switch (_register) {
          case 0:
            _r0 = value;
            _updateChrPages();
          case 1:
            _r1 = value;
            _updateChrPages();
          case 2:
            _r2 = value;
            _updateChrPages();
          case 3:
            _r3 = value;
            _updateChrPages();
          case 4:
            _r4 = value;
            _updateChrPages();
          case 5:
            _r5 = value;
            _updateChrPages();
          case 6:
            _r6 = value;
            _updatePrgPages();
          case 7:
            _r7 = value;
            _updatePrgPages();
        }
    }
  }

  void _updateState() {
    _updatePrgPages();
    _updateChrPages();
  }

  void _updatePrgPages() {
    mapCpu(0x8000, 0x9fff, _r6);
    mapCpu(0xa000, 0xbfff, _r7);
    mapCpu(0xc000, 0xdfff, -2);
    mapCpu(0xe000, 0xffff, -1);
  }

  void _updateChrPages() {
    mapPpu(0x0000, 0x03ff, _r0);
    mapPpu(0x0400, 0x07ff, _r0 + 1);
    mapPpu(0x0800, 0x0bff, _r1);
    mapPpu(0x0c00, 0x0fff, _r1 + 1);
    mapPpu(0x1000, 0x13ff, _r2);
    mapPpu(0x1400, 0x17ff, _r3);
    mapPpu(0x1800, 0x1bff, _r4);
    mapPpu(0x1c00, 0x1fff, _r5);
  }
}
