import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/exception/unsupported_mapper.dart';
import 'package:nesd/nes/cartridge/mapper/axrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/bandai_fcg_state.dart';
import 'package:nesd/nes/cartridge/mapper/cnrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/gxrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper176_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper45_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc1_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc2_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc5_state.dart';
import 'package:nesd/nes/cartridge/mapper/namco108_state.dart';
import 'package:nesd/nes/cartridge/mapper/namco163_state.dart';
import 'package:nesd/nes/cartridge/mapper/nrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/single_prg_bank_state.dart';
import 'package:nesd/nes/cartridge/mapper/unrom512_state.dart';
import 'package:nesd/nes/cartridge/mapper/vt/vt02_state.dart';

abstract class MapperState {
  const MapperState({required this.id});

  factory MapperState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => MapperState._fromId(reader, reader.get(uint8)),
      1 => MapperState._fromId(reader, reader.get(uint16)),
      _ => throw InvalidSerializationVersion('MapperState', version),
    };
  }

  factory MapperState._fromId(PayloadReader reader, int id) {
    return switch (id) {
      0 => const NROMState(),
      1 => MMC1State.deserialize(reader),
      2 => SinglePrgBankState.deserialize(reader, 2),
      3 => CNROMState.deserialize(reader),
      4 => MMC3State.deserialize(reader),
      5 => MMC5State.deserialize(reader),
      7 => AXROMState.deserialize(reader),
      9 => MMC2State.deserialize(reader),
      16 => BandaiFCGState.deserialize(reader),
      19 => Namco163State.deserialize(reader),
      30 => UNROM512State.deserialize(reader),
      45 => Mapper45State.deserialize(reader),
      66 => GxROMState.deserialize(reader),
      71 => SinglePrgBankState.deserialize(reader, 71),
      176 => Mapper176State.deserialize(reader),
      206 => Namco108State.deserialize(reader),
      256 => VT02State.deserialize(reader, 256),
      _ => throw UnsupportedMapper(id, 0),
    };
  }

  final int id;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 1) // version
      ..set(uint16, id);
  }
}
