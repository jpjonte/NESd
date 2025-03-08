// register names don't follow dart naming conventions
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
    required this.doIrq,
    required this.previousDoIrq,
    required this.nmi,
    required this.previousNmi,
    required this.doNmi,
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
    required this.callStack,
  });

  factory CPUState.deserialize(PayloadReader reader) {
    final version = reader.get(uint8);

    return switch (version) {
      0 => CPUState._version0(reader),
      1 => CPUState._version1(reader),
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
      doIrq: false,
      previousDoIrq: false,
      nmi: reader.get(boolean),
      previousNmi: false,
      doNmi: false,
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
      callStack: [],
    );
  }

  factory CPUState._version1(PayloadReader reader) {
    return CPUState(
      PC: reader.get(uint16),
      SP: reader.get(uint8),
      A: reader.get(uint8),
      X: reader.get(uint8),
      Y: reader.get(uint8),
      P: reader.get(uint8),
      irq: reader.get(uint8),
      doIrq: reader.get(boolean),
      previousDoIrq: reader.get(boolean),
      nmi: reader.get(boolean),
      previousNmi: reader.get(boolean),
      doNmi: reader.get(boolean),
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
      callStack: reader.get(list(uint16)),
    );
  }

  final int PC;
  final int SP;
  final int A;
  final int X;
  final int Y;
  final int P;

  final int irq;
  final bool doIrq;
  final bool previousDoIrq;

  final bool nmi;
  final bool previousNmi;
  final bool doNmi;

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

  final List<int> callStack;

  void serialize(PayloadWriter writer) {
    writer
      ..set(uint8, 1) // version
      ..set(uint16, PC)
      ..set(uint8, SP)
      ..set(uint8, A)
      ..set(uint8, X)
      ..set(uint8, Y)
      ..set(uint8, P)
      ..set(uint8, irq)
      ..set(boolean, doIrq)
      ..set(boolean, previousDoIrq)
      ..set(boolean, nmi)
      ..set(boolean, previousNmi)
      ..set(boolean, doNmi)
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
      ..set(uint64, cycles)
      ..set(list(uint16), callStack);
  }
}
