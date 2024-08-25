import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/namco108_state.dart';

class Namco108 extends Mapper {
  Namco108() : super(206);

  @override
  String name = 'Namco 108';

  @override
  int prgBankSize = 0x2000;

  @override
  int chrBankSize = 0x0400;

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
  void writePrg(int address, int value) {
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
    setPrgPage(0, _r6);
    setPrgPage(1, _r7);
    setPrgPage(2, -2);
    setPrgPage(3, -1);
  }

  void _updateChrPages() {
    setChrPage(0, _r0);
    setChrPage(1, _r0 + 1);
    setChrPage(2, _r1);
    setChrPage(3, _r1 + 1);
    setChrPage(4, _r2);
    setChrPage(5, _r3);
    setChrPage(6, _r4);
    setChrPage(7, _r5);
  }
}
