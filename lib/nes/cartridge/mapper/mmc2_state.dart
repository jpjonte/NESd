import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class MMC2State extends MapperState {
  const MMC2State({
    required this.prgBank,
    required this.chrBank0,
    required this.chrBank1,
    required this.chrLatch0,
    required this.chrLatch1,
    required this.mirroring,
    super.id = 9,
  });

  factory MMC2State.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => MMC2State._version0(reader),
      _ => throw InvalidSerializationVersion('MMC2', version),
    };
  }

  factory MMC2State._version0(PayloadReader reader) {
    return MMC2State(
      prgBank: reader.get(uint8),
      chrBank0: [reader.get(uint8), reader.get(uint8)],
      chrBank1: [reader.get(uint8), reader.get(uint8)],
      chrLatch0: reader.get(uint8),
      chrLatch1: reader.get(uint8),
      mirroring: reader.get(uint8),
    );
  }

  final int prgBank;

  final List<int> chrBank0;
  final List<int> chrBank1;

  final int chrLatch0;
  final int chrLatch1;

  final int mirroring;

  @override
  int get byteLength => 9;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, prgBank)
      ..set(uint8, chrBank0[0])
      ..set(uint8, chrBank0[1])
      ..set(uint8, chrBank1[0])
      ..set(uint8, chrBank1[1])
      ..set(uint8, chrLatch0)
      ..set(uint8, chrLatch1)
      ..set(uint8, mirroring);
  }
}
