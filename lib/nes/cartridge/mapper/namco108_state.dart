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

  factory Namco108State.fromByteData(ByteData data, int offset) {
    final version = data.getUint8(offset);

    return switch (version) {
      0 => Namco108State.version0(data, offset + 1),
      _ => throw InvalidSerializationVersion('Namco108', version),
    };
  }

  factory Namco108State.version0(ByteData data, int offset) {
    return Namco108State(
      register: data.getUint8(offset),
      r0: data.getUint8(offset + 1),
      r1: data.getUint8(offset + 2),
      r2: data.getUint8(offset + 3),
      r3: data.getUint8(offset + 4),
      r4: data.getUint8(offset + 5),
      r5: data.getUint8(offset + 6),
      r6: data.getUint8(offset + 7),
      r7: data.getUint8(offset + 8),
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
  int get byteLength => 10;

  @override
  void toByteData(ByteData data, int offset) {
    data
      ..setUint8(offset, 0) // version
      ..setUint8(offset + 1, register)
      ..setUint8(offset + 2, r0)
      ..setUint8(offset + 3, r1)
      ..setUint8(offset + 4, r2)
      ..setUint8(offset + 5, r3)
      ..setUint8(offset + 6, r4)
      ..setUint8(offset + 7, r5)
      ..setUint8(offset + 8, r6)
      ..setUint8(offset + 9, r7);
  }
}
