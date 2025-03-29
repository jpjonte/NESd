import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/exception/unsupported_mapper.dart';
import 'package:nesd/nes/cartridge/mapper/axrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/cnrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/gxrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc1_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc2_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc3_state.dart';
import 'package:nesd/nes/cartridge/mapper/mmc5_state.dart';
import 'package:nesd/nes/cartridge/mapper/namco108_state.dart';
import 'package:nesd/nes/cartridge/mapper/nrom_state.dart';
import 'package:nesd/nes/cartridge/mapper/single_prg_bank_state.dart';

abstract class MapperState {
  const MapperState({required this.id});

  factory MapperState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => MapperState._version0(reader),
      _ => throw InvalidSerializationVersion('MapperState', version),
    };
  }

  factory MapperState._version0(PayloadReader reader) {
    final id = reader.get(uint8);

    return switch (id) {
      0 => const NROMState(),
      1 => MMC1State.deserialize(reader),
      2 => SinglePrgBankState.deserialize(reader, 2),
      3 => CNROMState.deserialize(reader),
      4 => MMC3State.deserialize(reader),
      5 => MMC5State.deserialize(reader),
      7 => AXROMState.deserialize(reader),
      9 => MMC2State.deserialize(reader),
      66 => GxROMState.deserialize(reader),
      71 => SinglePrgBankState.deserialize(reader, 71),
      206 => Namco108State.deserialize(reader),
      _ => throw UnsupportedMapper(id),
    };
  }

  final int id;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(uint8, id);
  }
}
