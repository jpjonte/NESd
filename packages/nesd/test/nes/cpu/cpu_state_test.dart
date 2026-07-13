import 'package:binarize/binarize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cpu/cpu_state.dart';

CPUState buildState() {
  return CPUState(
    PC: 0xc123,
    SP: 0xfd,
    A: 0x12,
    X: 0x34,
    Y: 0x56,
    P: 0x24,
    irq: 3,
    doIrq: true,
    previousDoIrq: false,
    nmi: true,
    previousNmi: true,
    doNmi: false,
    ram: Uint8List.fromList(List.generate(2048, (i) => (i * 13) & 0xff)),
    oamDma: true,
    oamDmaStarted: false,
    oamDmaOffset: 0x45,
    oamDmaValue: 0x67,
    dmcDma: false,
    dmcDmaRead: true,
    dmcDmaDummy: false,
    dmcDmaValue: 0x89,
    oamDmaPage: 0x02,
    cycles: 123456789,
    consoleCycles: 987654321,
    callStack: [0x8000, 0x8123, 0xfffe],
  );
}

void expectStatesEqual(CPUState actual, CPUState expected) {
  expect(actual.PC, expected.PC);
  expect(actual.SP, expected.SP);
  expect(actual.A, expected.A);
  expect(actual.X, expected.X);
  expect(actual.Y, expected.Y);
  expect(actual.P, expected.P);
  expect(actual.irq, expected.irq);
  expect(actual.doIrq, expected.doIrq);
  expect(actual.previousDoIrq, expected.previousDoIrq);
  expect(actual.nmi, expected.nmi);
  expect(actual.previousNmi, expected.previousNmi);
  expect(actual.doNmi, expected.doNmi);
  expect(actual.ram, expected.ram);
  expect(actual.oamDma, expected.oamDma);
  expect(actual.oamDmaStarted, expected.oamDmaStarted);
  expect(actual.oamDmaOffset, expected.oamDmaOffset);
  expect(actual.oamDmaValue, expected.oamDmaValue);
  expect(actual.dmcDma, expected.dmcDma);
  expect(actual.dmcDmaRead, expected.dmcDmaRead);
  expect(actual.dmcDmaDummy, expected.dmcDmaDummy);
  expect(actual.dmcDmaValue, expected.dmcDmaValue);
  expect(actual.oamDmaPage, expected.oamDmaPage);
  expect(actual.cycles, expected.cycles);
  expect(actual.consoleCycles, expected.consoleCycles);
  expect(actual.callStack, expected.callStack);
}

void main() {
  test('serialize writes version 3 and round-trips', () {
    final original = buildState();

    final writer = Payload.write();
    original.serialize(writer);
    final bytes = binarize(writer);

    expect(bytes[0], 3, reason: 'CPUState version');

    final decoded = CPUState.deserialize(Payload.read(bytes));

    expectStatesEqual(decoded, original);
  });

  test('still reads legacy version 2 payloads', () {
    final original = buildState();

    // replicate the exact v2 wire format the previous code produced
    final writer = Payload.write()
      ..set(uint8, 2)
      ..set(uint16, original.PC)
      ..set(uint8, original.SP)
      ..set(uint8, original.A)
      ..set(uint8, original.X)
      ..set(uint8, original.Y)
      ..set(uint8, original.P)
      ..set(uint8, original.irq)
      ..set(boolean, original.doIrq)
      ..set(boolean, original.previousDoIrq)
      ..set(boolean, original.nmi)
      ..set(boolean, original.previousNmi)
      ..set(boolean, original.doNmi)
      ..set(list(uint8), original.ram)
      ..set(boolean, original.oamDma)
      ..set(boolean, original.oamDmaStarted)
      ..set(uint8, original.oamDmaOffset)
      ..set(uint8, original.oamDmaValue)
      ..set(boolean, original.dmcDma)
      ..set(boolean, original.dmcDmaRead)
      ..set(boolean, original.dmcDmaDummy)
      ..set(uint8, original.dmcDmaValue)
      ..set(uint8, original.oamDmaPage)
      ..set(uint64, original.cycles)
      ..set(uint64, original.consoleCycles)
      ..set(list(uint16), original.callStack);

    final decoded = CPUState.deserialize(Payload.read(binarize(writer)));

    expectStatesEqual(decoded, original);
  });
}
