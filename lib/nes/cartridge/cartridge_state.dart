import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class CartridgeState {
  const CartridgeState({
    required this.chr,
    required this.sram,
    required this.mapperId,
    required this.mapperState,
  });

  factory CartridgeState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => CartridgeState._version0(reader),
      _ => throw InvalidSerializationVersion('CartridgeState', version),
    };
  }

  factory CartridgeState._version0(PayloadReader reader) {
    return CartridgeState(
      chr: reader.get(uint8List(lengthType: uint32)),
      sram: reader.get(uint8List(lengthType: uint32)),
      mapperId: reader.get(uint8),
      mapperState: MapperState.deserialize(reader),
    );
  }

  final Uint8List chr;

  final Uint8List sram;

  final int mapperId;

  final MapperState mapperState;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(uint8List(lengthType: uint32), chr)
      ..set(uint8List(lengthType: uint32), sram)
      ..set(uint8, mapperId);

    mapperState.serialize(writer);
  }
}
