// ignore_for_file: non_constant_identifier_names

import 'package:binarize/binarize.dart';
import 'package:nesd/exception/invalid_serialization_version.dart';

class CPUState {
  const CPUState({
    required this.PC,
    required this.SP,
    required this.A,
    required this.X,
    required this.Y,
    required this.P,
    required this.irq,
    required this.nmi,
    required this.ram,
    required this.oamDma,
    required this.oamDmaStarted,
    required this.oamDmaOffset,
    required this.oamDmaValue,
    required this.dmcDma,
    required this.dmcDmaRead,
    required this.dmcDmaDummy,
    required this.dmcDmaValue,
    required this.oamDmaPage,
    required this.cycles,
  });

  factory CPUState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => CPUState._version0(reader),
      _ => throw InvalidSerializationVersion('CPUState', version),
    };
  }

  factory CPUState._version0(PayloadReader reader) {
    return CPUState(
      PC: reader.get(uint16),
      SP: reader.get(uint8),
      A: reader.get(uint8),
      X: reader.get(uint8),
      Y: reader.get(uint8),
      P: reader.get(uint8),
      irq: reader.get(uint8),
      nmi: reader.get(boolean),
      ram: Uint8List.fromList(reader.get(list(uint8))),
      oamDma: reader.get(boolean),
      oamDmaStarted: reader.get(boolean),
      oamDmaOffset: reader.get(uint8),
      oamDmaValue: reader.get(uint8),
      dmcDma: reader.get(boolean),
      dmcDmaRead: reader.get(boolean),
      dmcDmaDummy: reader.get(boolean),
      dmcDmaValue: reader.get(uint8),
      oamDmaPage: reader.get(uint8),
      cycles: reader.get(uint64),
    );
  }

  final int PC;
  final int SP;
  final int A;
  final int X;
  final int Y;
  final int P;

  final int irq;
  final bool nmi;

  final Uint8List ram;

  final bool oamDma;
  final bool oamDmaStarted;
  final int oamDmaOffset;
  final int oamDmaValue;

  final bool dmcDma;
  final bool dmcDmaRead;
  final bool dmcDmaDummy;
  final int dmcDmaValue;
  final int oamDmaPage;

  final int cycles;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 0) // version
      ..set(uint16, PC)
      ..set(uint8, SP)
      ..set(uint8, A)
      ..set(uint8, X)
      ..set(uint8, Y)
      ..set(uint8, P)
      ..set(uint8, irq)
      ..set(boolean, nmi)
      ..set(list(uint8), ram)
      ..set(boolean, oamDma)
      ..set(boolean, oamDmaStarted)
      ..set(uint8, oamDmaOffset)
      ..set(uint8, oamDmaValue)
      ..set(boolean, dmcDma)
      ..set(boolean, dmcDmaRead)
      ..set(boolean, dmcDmaDummy)
      ..set(uint8, dmcDmaValue)
      ..set(uint8, oamDmaPage)
      ..set(uint64, cycles);
  }
}
