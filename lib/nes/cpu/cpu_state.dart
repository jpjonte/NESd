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

  CPUState.dummy()
      : PC = 0,
        SP = 0,
        A = 0,
        X = 0,
        Y = 0,
        P = 0,
        irq = 0,
        nmi = false,
        ram = Uint8List(1),
        oamDma = false,
        oamDmaStarted = false,
        oamDmaOffset = 0,
        oamDmaValue = 0,
        dmcDma = false,
        dmcDmaRead = false,
        dmcDmaDummy = false,
        dmcDmaValue = 0,
        oamDmaPage = 0,
        cycles = 0;

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

class _LegacyCPUStateContract extends BinaryContract<CPUState>
    implements CPUState {
  _LegacyCPUStateContract() : super(CPUState.dummy());

  @override
  CPUState order(CPUState contract) {
    return CPUState(
      PC: contract.PC,
      SP: contract.SP,
      A: contract.A,
      X: contract.X,
      Y: contract.Y,
      P: contract.P,
      irq: contract.irq,
      nmi: contract.nmi,
      ram: Uint8List.fromList(contract.ram),
      oamDma: contract.oamDma,
      oamDmaStarted: contract.oamDmaStarted,
      oamDmaOffset: contract.oamDmaOffset,
      oamDmaValue: contract.oamDmaValue,
      dmcDma: contract.dmcDma,
      dmcDmaRead: contract.dmcDmaRead,
      dmcDmaDummy: contract.dmcDmaDummy,
      dmcDmaValue: contract.dmcDmaValue,
      oamDmaPage: contract.oamDmaPage,
      cycles: contract.cycles,
    );
  }

  @override
  int get PC => type(uint16, (o) => o.PC);

  @override
  int get A => type(uint8, (o) => o.A);

  @override
  int get P => type(uint8, (o) => o.P);

  @override
  int get SP => type(uint8, (o) => o.SP);

  @override
  int get X => type(uint8, (o) => o.X);

  @override
  int get Y => type(uint8, (o) => o.Y);

  @override
  int get cycles => type(uint64, (o) => o.cycles);

  @override
  bool get dmcDma => type(boolean, (o) => o.dmcDma);

  @override
  bool get dmcDmaDummy => type(boolean, (o) => o.dmcDmaDummy);

  @override
  bool get dmcDmaRead => type(boolean, (o) => o.dmcDmaRead);

  @override
  int get dmcDmaValue => type(uint8, (o) => o.dmcDmaValue);

  @override
  int get irq => type(uint8, (o) => o.irq);

  @override
  bool get nmi => type(boolean, (o) => o.nmi);

  @override
  bool get oamDma => type(boolean, (o) => o.oamDma);

  @override
  int get oamDmaOffset => type(uint8, (o) => o.oamDmaOffset);

  @override
  int get oamDmaPage => type(uint8, (o) => o.oamDmaPage);

  @override
  bool get oamDmaStarted => type(boolean, (o) => o.oamDmaStarted);

  @override
  int get oamDmaValue => type(uint8, (o) => o.oamDmaValue);

  @override
  Uint8List get ram => Uint8List.fromList(
        type(list(uint8), (o) => o.ram.toList()),
      );

  @override
  void serialize(PayloadWriter writer) => throw UnimplementedError();
}

final legacyCpuStateContract = _LegacyCPUStateContract();
