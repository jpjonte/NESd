import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class Namco108State extends MapperState {
  const Namco108State({
    required this.register,
    required this.r0,
    required this.r1,
    required this.r2,
    required this.r3,
    required this.r4,
    required this.r5,
    required this.r6,
    required this.r7,
    super.id = 206,
  });

  factory Namco108State.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => Namco108State._version0(reader),
      _ => throw InvalidSerializationVersion('Namco108', version),
    };
  }

  factory Namco108State._version0(PayloadReader reader) {
    return Namco108State(
      register: reader.get(uint8),
      r0: reader.get(uint8),
      r1: reader.get(uint8),
      r2: reader.get(uint8),
      r3: reader.get(uint8),
      r4: reader.get(uint8),
      r5: reader.get(uint8),
      r6: reader.get(uint8),
      r7: reader.get(uint8),
    );
  }

  final int register;

  final int r0;
  final int r1;
  final int r2;
  final int r3;
  final int r4;
  final int r5;
  final int r6;
  final int r7;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, register)
      ..set(uint8, r0)
      ..set(uint8, r1)
      ..set(uint8, r2)
      ..set(uint8, r3)
      ..set(uint8, r4)
      ..set(uint8, r5)
      ..set(uint8, r6)
      ..set(uint8, r7);
  }
}
