import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class VRC24State extends MapperState {
  const VRC24State({
    required super.id,
    required this.prgBanks,
    required this.chrBanks,
    required this.mirroring,
    required this.swapMode,
    required this.workRamEnabled,
    required this.latch,
    required this.irqLatch,
    required this.irqCounter,
    required this.irqPrescaler,
    required this.irqEnabled,
    required this.irqEnableAfterAck,
    required this.irqCycleMode,
  });

  factory VRC24State.deserialize(PayloadReader reader, int id) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => VRC24State._version0(reader, id),
      _ => throw InvalidSerializationVersion('VRC24', version),
    };
  }

  factory VRC24State._version0(PayloadReader reader, int id) {
    return VRC24State(
      id: id,
      prgBanks: [for (var i = 0; i < 2; i++) reader.get(uint8)],
      chrBanks: [for (var i = 0; i < 8; i++) reader.get(uint16)],
      mirroring: reader.get(uint8),
      swapMode: reader.get(boolean),
      workRamEnabled: reader.get(boolean),
      latch: reader.get(uint8),
      irqLatch: reader.get(uint8),
      irqCounter: reader.get(uint8),
      irqPrescaler: reader.get(uint16),
      irqEnabled: reader.get(boolean),
      irqEnableAfterAck: reader.get(boolean),
      irqCycleMode: reader.get(boolean),
    );
  }

  final List<int> prgBanks;

  final List<int> chrBanks;

  final int mirroring;

  final bool swapMode;

  final bool workRamEnabled;

  final int latch;

  final int irqLatch;
  final int irqCounter;
  final int irqPrescaler;

  final bool irqEnabled;
  final bool irqEnableAfterAck;
  final bool irqCycleMode;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer.set(uint8, 0); // version

    for (final bank in prgBanks) {
      writer.set(uint8, bank);
    }

    for (final bank in chrBanks) {
      writer.set(uint16, bank);
    }

    writer
      ..set(uint8, mirroring)
      ..set(boolean, swapMode)
      ..set(boolean, workRamEnabled)
      ..set(uint8, latch)
      ..set(uint8, irqLatch)
      ..set(uint8, irqCounter)
      ..set(uint16, irqPrescaler)
      ..set(boolean, irqEnabled)
      ..set(boolean, irqEnableAfterAck)
      ..set(boolean, irqCycleMode);
  }
}
