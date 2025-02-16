import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class AXROMState extends MapperState {
  const AXROMState({
    required this.prgBank,
    required this.vramBank,
    super.id = 7,
  });

  factory AXROMState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => AXROMState.version0(reader),
      _ => throw InvalidSerializationVersion('AXROM', version),
    };
  }

  factory AXROMState.version0(PayloadReader reader) {
    return AXROMState(
      prgBank: reader.get(uint8),
      vramBank: reader.get(uint8),
    );
  }

  final int prgBank;

  final int vramBank;

  @override
  int get byteLength => 2;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, prgBank)
      ..set(uint8, vramBank);
  }
}

class _AXROMState extends PayloadType<AXROMState> {
  const _AXROMState();

  @override
  int length(AXROMState value) => 3;

  @override
  AXROMState get(ByteData data, int offset) {
    final version = data.getUint8(offset);

    return switch (version) {
      0 => _version0(data, offset + 1),
      _ => throw InvalidSerializationVersion('AXROM', version),
    };
  }

  @override
  void set(AXROMState value, ByteData data, int offset) {
    data
      ..setUint8(offset, 0) // version
      ..setUint8(offset, value.prgBank)
      ..setUint8(offset + 1, value.vramBank);
  }

  AXROMState _version0(ByteData data, int offset) {
    return AXROMState(
      prgBank: data.getUint8(offset),
      vramBank: data.getUint8(offset + 1),
    );
  }
}

const axromStateType = _AXROMState();
