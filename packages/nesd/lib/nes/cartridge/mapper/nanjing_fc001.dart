import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/nanjing_fc001_state.dart';

class NanjingFC001 extends Mapper {
  NanjingFC001() : super(163);

  @override
  String name = 'Nanjing FC-001';

  @override
  bool get hasFixedMirroring => true;

  @override
  int prgRomPageSize = 0x8000;

  @override
  int chrPageSize = 0x1000;

  @override
  int get minChrRamSize => 0x2000;

  int _prgLow = 0;
  int _feedback = 0;
  int _prgHigh = 0;
  int _mode = 0;

  bool _pa09 = false;
  bool _pa13 = false;

  int? _mappedChrHalf;

  bool get _chrAutoSwitch => _prgLow & 0x80 != 0;

  bool get _swapBits => _mode & 0x01 != 0;

  bool get _prgA15A16FromRegister => _mode & 0x04 != 0;

  int get _lastSwappedRegister => cartridge.prgRom.length < 0x200000 ? 1 : 2;

  @override
  NanjingFC001State get state => NanjingFC001State(
    prgLow: _prgLow,
    feedback: _feedback,
    prgHigh: _prgHigh,
    mode: _mode,
    pa09: _pa09,
    pa13: _pa13,
  );

  @override
  set state(covariant NanjingFC001State state) {
    _prgLow = state.prgLow;
    _feedback = state.feedback;
    _prgHigh = state.prgHigh;
    _mode = state.mode;

    _pa09 = state.pa09;
    _pa13 = state.pa13;

    _updateState();
  }

  @override
  void reset() {
    super.reset();

    _prgLow = 0;
    _feedback = 0;
    _prgHigh = 0;
    _mode = 0;

    _pa09 = false;
    _pa13 = false;

    _updateState();
  }

  @override
  int cpuRead(int address, {bool disableSideEffects = false}) {
    if (address & 0xf800 == 0x5000) {
      return ~_feedback & 0x04;
    }

    return super.cpuRead(address, disableSideEffects: disableSideEffects);
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    if (address & 0xf800 != 0x5000) {
      return;
    }

    final register = (address >> 8) & 0x03;

    final data = _swapBits && register <= _lastSwappedRegister
        ? (value & 0xfc) | ((value << 1) & 0x02) | ((value >> 1) & 0x01)
        : value;

    if (address & 0x01 != 0) {
      if (_feedback & 0x01 != 0 && data & 0x01 == 0) {
        _feedback ^= 0x04;
      }

      return;
    }

    switch (register) {
      case 0:
        _prgLow = data;
      case 1:
        _feedback = data;
      case 2:
        _prgHigh = data;
      case 3:
        _mode = data;
    }

    _updateState();
  }

  @override
  void ppuWrite(int address, int value) {
    final chrRam = cartridge.chrRam;

    if (address < 0x2000 && chrRam.isNotEmpty) {
      chrRam[address % chrRam.length] = value;

      return;
    }

    super.ppuWrite(address, value);
  }

  @override
  bool get needsPpuAddressUpdates => true;

  @override
  void updatePpuAddress(int address) {
    final pa13 = address & 0x2000 != 0;

    if (pa13 && !_pa13) {
      _pa09 = address & 0x0200 != 0;
    }

    _pa13 = pa13;

    _updateChrPages();
  }

  void _updateState() {
    _updatePrgPages();

    _mappedChrHalf = null;
    _updateChrPages();
  }

  void _updatePrgPages() {
    final fixedA15A16 = _prgA15A16FromRegister ? 0 : 0x03;

    mapCpu(0x8000, 0xffff, _prgHigh << 4 | _prgLow & 0x0f | fixedA15A16);
  }

  void _updateChrPages() {
    final half = _chrAutoSwitch ? (_pa09 ? 1 : 0) : -1;

    if (half == _mappedChrHalf) {
      return;
    }

    _mappedChrHalf = half;

    if (half < 0) {
      mapPpu(0x0000, 0x1fff, 0);

      return;
    }

    mapPpu(0x0000, 0x0fff, half);
    mapPpu(0x1000, 0x1fff, half);
  }
}
