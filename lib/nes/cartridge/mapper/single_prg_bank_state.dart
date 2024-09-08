import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/exception/unsupported_mapper.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class SinglePrgBankState extends MapperState {
  const SinglePrgBankState({
    required super.id,
    required this.prgBank,
  });

  factory SinglePrgBankState.deserialize(PayloadReader reader, int id) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => SinglePrgBankState._version0(reader, id),
      _ => throw InvalidSerializationVersion('SinglePrgBankState', version),
    };
  }

  factory SinglePrgBankState._version0(PayloadReader reader, int id) {
    return switch (id) {
      2 || 71 => SinglePrgBankState(id: id, prgBank: reader.get(uint8)),
      _ => throw UnsupportedMapper(id),
    };
  }

  factory SinglePrgBankState.legacyFromByteData(
    int id,
    ByteData data,
    int offset,
  ) {
    return SinglePrgBankState(
      id: id,
      prgBank: data.getUint8(offset),
    );
  }

  final int prgBank;

  @override
  int get byteLength => 1;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, prgBank);
  }
}
