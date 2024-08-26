import 'package:binarize/binarize.dart';
import 'package:nesd/exception/unsupported_mapper.dart';
import 'package:nesd/nes/cartridge/mapper/axrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/cnrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/gxrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc1_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc2_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3_state.dart';
import 'package:nesd/nes/cartridge/mapper/namco108_state.dart';
import 'package:nesd/nes/cartridge/mapper/nrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/single_prg_bank_state.dart';

abstract class MapperState {
  const MapperState({required this.id});

  factory MapperState.fromByteData(int id, ByteData data, int offset) {
    return switch (id) {
      0 => const NROMState(),
      1 => MMC1State.fromByteData(data, offset),
      2 => SinglePrgBankState.fromByteData(2, data, offset),
      3 => CNROMState.fromByteData(data, offset),
      4 => MMC3State.fromByteData(data, offset),
      7 => AXROMState.fromByteData(data, offset),
      9 => MMC2State.fromByteData(data, offset),
      66 => GxROMState.fromByteData(data, offset),
      71 => SinglePrgBankState.fromByteData(71, data, offset),
      206 => Namco108State.fromByteData(data, offset),
      _ => throw UnsupportedMapper(id),
    };
  }

  final int id;

  int get byteLength;

  void toByteData(ByteData data, int offset);
}

class _MapperState extends PayloadType<MapperState> {
  const _MapperState();

  @override
  int length(MapperState value) => value.byteLength + 1;

  @override
  MapperState get(ByteData data, int offset) {
    final id = data.getUint8(offset);

    return MapperState.fromByteData(id, data, offset + 1);
  }

  @override
  void set(MapperState value, ByteData data, int offset) {
    data.setUint8(offset, value.id);

    value.toByteData(data, offset + 1);
  }
}

const mapperStateType = _MapperState();
