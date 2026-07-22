import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/chip/eeprom_24c02.dart';

class Eeprom24C02State {
  const Eeprom24C02State({
    required this.previousScl,
    required this.previousSda,
    required this.address,
    required this.bit,
    required this.control,
    required this.shift,
    required this.flush,
    required this.mode,
    required this.buffer,
    required this.data,
    required this.output,
  });

  factory Eeprom24C02State.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => Eeprom24C02State._version0(reader),
      _ => throw InvalidSerializationVersion('Eeprom24C02', version),
    };
  }

  factory Eeprom24C02State._version0(PayloadReader reader) {
    return Eeprom24C02State(
      previousScl: reader.get(uint8),
      previousSda: reader.get(uint8),
      address: reader.get(uint8),
      bit: reader.get(uint8),
      control: reader.get(uint8),
      shift: reader.get(uint8),
      flush: reader.get(boolean),
      mode: reader.get(enumeration(Eeprom24C02Mode.values)),
      buffer: Uint8List.fromList(reader.get(list(uint8))),
      data: Uint8List.fromList(reader.get(list(uint8))),
      output: reader.get(uint8),
    );
  }

  final int previousScl;
  final int previousSda;

  final int address;
  final int bit;
  final int control;
  final int shift;

  final bool flush;

  final Eeprom24C02Mode mode;

  final Uint8List buffer;

  final Uint8List data;

  final int output;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(uint8, previousScl)
      ..set(uint8, previousSda)
      ..set(uint8, address)
      ..set(uint8, bit)
      ..set(uint8, control)
      ..set(uint8, shift)
      ..set(boolean, flush)
      ..set(enumeration(Eeprom24C02Mode.values), mode)
      ..set(list(uint8), buffer)
      ..set(list(uint8), data)
      ..set(uint8, output);
  }
}
