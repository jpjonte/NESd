import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

class Sunsoft5BAudioState {
  const Sunsoft5BAudioState({
    required this.registers,
    required this.address,
    required this.writesDisabled,
    required this.toneCounters,
    required this.toneOutputs,
    required this.noiseCounter,
    required this.noiseHalf,
    required this.noiseShift,
    required this.envelopeCounter,
    required this.envelopeStep,
    required this.envelopeContinue,
    required this.envelopeAttack,
    required this.envelopeAlternate,
    required this.envelopeHold,
    required this.envelopeHolding,
    required this.envelopeHoldLevel,
    required this.prescaler,
  });

  Sunsoft5BAudioState.initial()
    : registers = Uint8List(16),
      address = 0,
      writesDisabled = false,
      toneCounters = const [0, 0, 0],
      toneOutputs = const [false, false, false],
      noiseCounter = 0,
      noiseHalf = false,
      noiseShift = 1,
      envelopeCounter = 0,
      envelopeStep = 0,
      envelopeContinue = false,
      envelopeAttack = false,
      envelopeAlternate = false,
      envelopeHold = false,
      envelopeHolding = false,
      envelopeHoldLevel = 0,
      prescaler = 0;

  factory Sunsoft5BAudioState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => Sunsoft5BAudioState._version0(reader),
      _ => throw InvalidSerializationVersion('Sunsoft5BAudioState', version),
    };
  }

  factory Sunsoft5BAudioState._version0(PayloadReader reader) {
    return Sunsoft5BAudioState(
      registers: Uint8List.fromList(reader.get(list(uint8))),
      address: reader.get(uint8),
      writesDisabled: reader.get(boolean),
      toneCounters: [for (var i = 0; i < 3; i++) reader.get(uint16)],
      toneOutputs: [for (var i = 0; i < 3; i++) reader.get(boolean)],
      noiseCounter: reader.get(uint8),
      noiseHalf: reader.get(boolean),
      noiseShift: reader.get(uint32),
      envelopeCounter: reader.get(uint16),
      envelopeStep: reader.get(uint8),
      envelopeContinue: reader.get(boolean),
      envelopeAttack: reader.get(boolean),
      envelopeAlternate: reader.get(boolean),
      envelopeHold: reader.get(boolean),
      envelopeHolding: reader.get(boolean),
      envelopeHoldLevel: reader.get(uint8),
      prescaler: reader.get(uint8),
    );
  }

  final Uint8List registers;

  final int address;
  final bool writesDisabled;

  final List<int> toneCounters;
  final List<bool> toneOutputs;

  final int noiseCounter;
  final bool noiseHalf;
  final int noiseShift;

  final int envelopeCounter;
  final int envelopeStep;

  final bool envelopeContinue;
  final bool envelopeAttack;
  final bool envelopeAlternate;
  final bool envelopeHold;

  final bool envelopeHolding;
  final int envelopeHoldLevel;

  final int prescaler;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(list(uint8), registers)
      ..set(uint8, address)
      ..set(boolean, writesDisabled);

    for (final counter in toneCounters) {
      writer.set(uint16, counter);
    }

    for (final output in toneOutputs) {
      writer.set(boolean, output);
    }

    writer
      ..set(uint8, noiseCounter)
      ..set(boolean, noiseHalf)
      ..set(uint32, noiseShift)
      ..set(uint16, envelopeCounter)
      ..set(uint8, envelopeStep)
      ..set(boolean, envelopeContinue)
      ..set(boolean, envelopeAttack)
      ..set(boolean, envelopeAlternate)
      ..set(boolean, envelopeHold)
      ..set(boolean, envelopeHolding)
      ..set(uint8, envelopeHoldLevel)
      ..set(uint8, prescaler);
  }
}
