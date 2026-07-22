import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/mapper/chip/eeprom_24c02_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class BandaiFCGState extends MapperState {
  const BandaiFCGState({
    required this.chrPages,
    required this.prgPage,
    required this.nametableLayout,
    required this.irqEnabled,
    required this.irqCounter,
    required this.irqLatch,
    required this.eeprom,
    super.id = 16,
  });

  factory BandaiFCGState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => BandaiFCGState._version0(reader),
      _ => throw InvalidSerializationVersion('Bandai FCG', version),
    };
  }

  factory BandaiFCGState._version0(PayloadReader reader) {
    final chrPages = reader.get(list(uint8));
    final prgPage = reader.get(uint8);
    final nametableLayout = reader.get(enumeration(NametableLayout.values));
    final irqEnabled = reader.get(boolean);
    final irqCounter = reader.get(uint16);
    final irqLatch = reader.get(uint16);
    final hasEeprom = reader.get(boolean);

    return BandaiFCGState(
      chrPages: chrPages,
      prgPage: prgPage,
      nametableLayout: nametableLayout,
      irqEnabled: irqEnabled,
      irqCounter: irqCounter,
      irqLatch: irqLatch,
      eeprom: hasEeprom ? Eeprom24C02State.deserialize(reader) : null,
    );
  }

  final List<int> chrPages;

  final int prgPage;

  final NametableLayout nametableLayout;

  final bool irqEnabled;
  final int irqCounter;
  final int irqLatch;

  final Eeprom24C02State? eeprom;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(list(uint8), chrPages)
      ..set(uint8, prgPage)
      ..set(enumeration(NametableLayout.values), nametableLayout)
      ..set(boolean, irqEnabled)
      ..set(uint16, irqCounter)
      ..set(uint16, irqLatch)
      ..set(boolean, eeprom != null);

    eeprom?.serialize(writer);
  }
}
