import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';
import 'package:nesd/nes/apu/expansion/sunsoft5b_audio_state.dart';
import 'package:nesd/nes/cartridge/mapper/mapper_state.dart';

class FME7State extends MapperState {
  const FME7State({
    required this.command,
    required this.prgBanks,
    required this.chrBanks,
    required this.workRamBank,
    required this.workRamSelected,
    required this.workRamEnabled,
    required this.arrangement,
    required this.irqCounter,
    required this.irqCounterEnabled,
    required this.irqEnabled,
    required this.audioState,
    super.id = 69,
  });

  factory FME7State.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => FME7State._version0(reader),
      _ => throw InvalidSerializationVersion('FME7', version),
    };
  }

  factory FME7State._version0(PayloadReader reader) {
    return FME7State(
      command: reader.get(uint8),
      prgBanks: [for (var i = 0; i < 3; i++) reader.get(uint8)],
      chrBanks: [for (var i = 0; i < 8; i++) reader.get(uint8)],
      workRamBank: reader.get(uint8),
      workRamSelected: reader.get(boolean),
      workRamEnabled: reader.get(boolean),
      arrangement: reader.get(uint8),
      irqCounter: reader.get(uint16),
      irqCounterEnabled: reader.get(boolean),
      irqEnabled: reader.get(boolean),
      audioState: Sunsoft5BAudioState.deserialize(reader),
    );
  }

  final int command;

  final List<int> prgBanks;

  final List<int> chrBanks;

  final int workRamBank;

  final bool workRamSelected;
  final bool workRamEnabled;

  final int arrangement;

  final int irqCounter;

  final bool irqCounterEnabled;
  final bool irqEnabled;

  final Sunsoft5BAudioState audioState;

  @override
  void serialize(PayloadWriter writer) {
    super.serialize(writer);

    writer
      ..set(uint8, 0) // version
      ..set(uint8, command);

    for (final bank in prgBanks) {
      writer.set(uint8, bank);
    }

    for (final bank in chrBanks) {
      writer.set(uint8, bank);
    }

    writer
      ..set(uint8, workRamBank)
      ..set(boolean, workRamSelected)
      ..set(boolean, workRamEnabled)
      ..set(uint8, arrangement)
      ..set(uint16, irqCounter)
      ..set(boolean, irqCounterEnabled)
      ..set(boolean, irqEnabled);

    audioState.serialize(writer);
  }
}
