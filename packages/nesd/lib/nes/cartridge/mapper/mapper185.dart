import 'dart:typed_data';

import 'package:nesd/nes/cartridge/mapper/mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mapper185_state.dart';

class Mapper185 extends Mapper {
  Mapper185(int subMapperId)
    : _enablingChipSelect = switch (subMapperId) {
        4 => 0,
        5 => 1,
        6 => 2,
        7 => 3,
        _ => null,
      },
      super(185, subMapperId);

  static final _unmapped = Uint8List(0);

  static const _heuristicDisabledReads = 2;

  static const _openBus = 0xff;

  final int? _enablingChipSelect;

  int _latch = 0;
  int _disabledReads = 0;

  @override
  int prgRomPageSize = 0x8000;

  @override
  int chrPageSize = 0x2000;

  @override
  String name = 'CNROM (CHR-ROM protection)';

  @override
  bool get hasFixedMirroring => true;

  @override
  Mapper185State get state =>
      Mapper185State(latch: _latch, disabledReads: _disabledReads);

  @override
  set state(covariant Mapper185State state) {
    _latch = state.latch;
    _disabledReads = state.disabledReads;

    _updateChrPages();
  }

  bool get _chrEnabled => switch (_enablingChipSelect) {
    final chipSelect? => (_latch & 0x03) == chipSelect,
    null => _disabledReads == 0,
  };

  @override
  void reset() {
    super.reset();

    _latch = 0;
    _disabledReads = _enablingChipSelect == null ? _heuristicDisabledReads : 0;

    mapCpu(0x8000, 0xffff, 0, type: CpuMemoryType.prgRom);

    _updateChrPages();
  }

  @override
  void cpuWrite(int address, int value) {
    super.cpuWrite(address, value);

    if (address < 0x8000) {
      return;
    }

    _latch = value & cpuRead(address, disableSideEffects: true);

    _updateChrPages();
  }

  @override
  int ppuRead(int address, {bool disableSideEffects = false}) {
    if (address >= 0x2000 || _chrEnabled) {
      return super.ppuRead(address, disableSideEffects: disableSideEffects);
    }

    if (!disableSideEffects && _disabledReads > 0) {
      _disabledReads--;

      _updateChrPages();
    }

    return _openBus;
  }

  void _updateChrPages() {
    if (_chrEnabled) {
      mapPpu(0x0000, 0x1fff, 0);

      return;
    }

    mapPpu(0x0000, 0x1fff, 0, source: _unmapped);
  }
}
