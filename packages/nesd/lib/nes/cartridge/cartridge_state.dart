import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class CartridgeState {
  const CartridgeState({
    required this.chrRam,
    required this.prgRam,
    required this.prgSaveRam,
    required this.mapperId,
    required this.mapperState,
  });

  factory CartridgeState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => CartridgeState._version0(reader),
      1 => CartridgeState._version1(reader),
      _ => throw InvalidSerializationVersion('CartridgeState', version),
    };
  }

  factory CartridgeState._version0(PayloadReader reader) {
    return CartridgeState(
      chrRam: reader.get(uint8List(lengthType: uint32)),
      prgRam: Uint8List(0),
      prgSaveRam: reader.get(uint8List(lengthType: uint32)),
      mapperId: reader.get(uint8),
      mapperState: MapperState.deserialize(reader),
    );
  }

  factory CartridgeState._version1(PayloadReader reader) {
    return CartridgeState(
      chrRam: reader.get(uint8List(lengthType: uint32)),
      prgRam: reader.get(uint8List(lengthType: uint32)),
      prgSaveRam: reader.get(uint8List(lengthType: uint16)),
      mapperId: reader.get(uint8),
      mapperState: MapperState.deserialize(reader),
    );
  }

  final Uint8List chrRam;

  final Uint8List prgRam;

  final Uint8List prgSaveRam;

  final int mapperId;

  final MapperState mapperState;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 1) // version
      ..set(uint8List(lengthType: uint32), chrRam)
      ..set(uint8List(lengthType: uint32), prgRam)
      ..set(uint8List(lengthType: uint16), prgSaveRam)
      ..set(uint8, mapperId);

    mapperState.serialize(writer);
  }
}
