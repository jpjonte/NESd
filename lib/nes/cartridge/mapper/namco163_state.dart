import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class Namco163State extends MapperState {
  const Namco163State({
    required this.prgBank0,
    required this.prgBank1,
    required this.prgBank2,
    required this.prgRamWriteProtect,
    required this.chrBanks,
    required this.disableNametables0,
    required this.disableNametables1,
    required this.irqCounter,
    required this.irqEnabled,
    super.id = 19,
  });

  factory Namco163State.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => Namco163State._version0(reader),
      _ => throw InvalidSerializationVersion('Namco 163', version),
    };
  }

  factory Namco163State._version0(PayloadReader reader) {
    return Namco163State(
      prgBank0: reader.get(uint8),
      prgBank1: reader.get(uint8),
      prgBank2: reader.get(uint8),
      prgRamWriteProtect: reader.get(list(boolean)),
      chrBanks: reader.get(list(uint8)),
      disableNametables0: reader.get(boolean),
      disableNametables1: reader.get(boolean),
      irqCounter: reader.get(uint16),
      irqEnabled: reader.get(boolean),
    );
  }

  final int prgBank0;
  final int prgBank1;
  final int prgBank2;

  final List<bool> prgRamWriteProtect;

  final List<int> chrBanks;

  final bool disableNametables0;
  final bool disableNametables1;

  final int irqCounter;
  final bool irqEnabled;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, prgBank0)
      ..set(uint8, prgBank1)
      ..set(uint8, prgBank2)
      ..set(list(boolean), prgRamWriteProtect)
      ..set(list(uint8), chrBanks)
      ..set(boolean, disableNametables0)
      ..set(boolean, disableNametables1)
      ..set(uint16, irqCounter)
      ..set(boolean, irqEnabled);
  }
}
