// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:nes/exception/invalid_opcode.dart';
import 'package:nes/extension/bit_extension.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cpu/address_mode.dart';
import 'package:nes/nes/cpu/cpu_state.dart';
import 'package:nes/nes/cpu/instruction.dart';
import 'package:nes/nes/cpu/operation.dart';

class CPU {
  CPU(this.bus);

  final Bus bus;

  int PC = 0x0000;
  int SP = 0x00;
  int A = 0x00;
  int X = 0x00;
  int Y = 0x00;
  int P = 0x00;

  bool irq = false;
  bool nmi = false;

  Uint8List ram = Uint8List(0x0800);

  int get C => P.bit(0);
  int get Z => P.bit(1);
  int get I => P.bit(2);
  int get D => P.bit(3);
  int get B => P.bit(4);
  int get V => P.bit(6);
  int get N => P.bit(7);

  set C(int value) => P = P.setBit(0, value);
  set Z(int value) => P = P.setBit(1, value);
  set I(int value) => P = P.setBit(2, value);
  set D(int value) => P = P.setBit(3, value);
  set B(int value) => P = P.setBit(4, value);
  set V(int value) => P = P.setBit(6, value);
  set N(int value) => P = P.setBit(7, value);

  bool oamDma = false;
  bool oamDmaStarted = false;
  int oamDmaOffset = 0;
  int oamDmaValue = 0;

  bool dmcDma = false;
  bool dmcDmaRead = false;
  bool dmcDmaDummy = false;
  int dmcDmaValue = 0;
  int oamDmaPage = 0;

  int cycles = 0;

  CPUState get state => CPUState(
        PC: PC,
        SP: SP,
        A: A,
        X: X,
        Y: Y,
        P: P,
        irq: irq,
        nmi: nmi,
        ram: ram,
        oamDma: oamDma,
        oamDmaStarted: oamDmaStarted,
        oamDmaOffset: oamDmaOffset,
        oamDmaValue: oamDmaValue,
        dmcDma: dmcDma,
        dmcDmaRead: dmcDmaRead,
        dmcDmaDummy: dmcDmaDummy,
        dmcDmaValue: dmcDmaValue,
        oamDmaPage: oamDmaPage,
        cycles: cycles,
      );

  set state(CPUState state) {
    PC = state.PC;
    SP = state.SP;
    A = state.A;
    X = state.X;
    Y = state.Y;
    P = state.P;
    irq = state.irq;
    nmi = state.nmi;
    oamDma = state.oamDma;
    oamDmaStarted = state.oamDmaStarted;
    oamDmaOffset = state.oamDmaOffset;
    oamDmaValue = state.oamDmaValue;
    dmcDma = state.dmcDma;
    dmcDmaRead = state.dmcDmaRead;
    dmcDmaDummy = state.dmcDmaDummy;
    dmcDmaValue = state.dmcDmaValue;
    oamDmaPage = state.oamDmaPage;
    cycles = state.cycles;
    ram.setAll(0, state.ram);
  }

  int read(int address) => bus.cpuRead(address);

  int read16(int address, {bool wrap = false}) => bus.cpuRead16(
        address,
        wrap: wrap,
      );

  void write(int address, int value) => bus.cpuWrite(address, value);

  void pushStack(int value) => write(0x100 + SP--, value & 0xff);

  void pushStack16(int value) {
    pushStack(value >> 8);
    pushStack(value & 0xff);
  }

  int popStack() => read(0x100 + ++SP);

  int popStack16() {
    final low = popStack();
    final high = popStack();

    return low | (high << 8);
  }

  void reset() {
    cycles = 0;

    SP = 0xfd;
    PC = read(0xfffc) | (read(0xfffd) << 8);
    P = 0x24;
    A = 0x00;
    X = 0x00;
    Y = 0x00;

    irq = false;
    nmi = false;

    oamDma = false;
    oamDmaStarted = false;
    oamDmaOffset = 0;
    oamDmaValue = 0;
    oamDmaPage = 0;

    dmcDma = false;
    dmcDmaRead = false;
    dmcDmaDummy = false;
    dmcDmaValue = 0;

    ram.fillRange(0, ram.length, 0);
  }

  void step() {
    _handleInterrupts();

    if (_handleDMA()) {
      return;
    }

    final opcode = read(PC);

    final op = ops[opcode];

    if (op == null) {
      throw InvalidOpcode(PC, opcode);
    }

    PC++;

    final (address, pageCrossed) = op.addressMode.read(this, PC);

    PC += op.addressMode.operandCount;

    final start = PC;

    op.instruction.execute(this, address);

    var additionalCycles = 0;

    if (op.instruction.type == InstructionType.branch && start != PC) {
      additionalCycles = calculateBranchCycles(start, PC);
    }

    if (op.pageCrossAddsCycle && pageCrossed) {
      additionalCycles++;
    }

    cycles += op.cycles + additionalCycles;
  }

  void _handleInterrupts() {
    if (nmi) {
      nmi = false;

      handleIrq(0xfffa);
    }

    if (irq && I == 0) {
      irq = false;

      handleIrq(0xfffe);
    }
  }

  bool _handleDMA() {
    if (!oamDma && !dmcDma) {
      return false;
    }

    if (dmcDma) {
      _handleDMCDMA();
    } else if (oamDma) {
      _handleOAMDMA();
    }

    cycles += 1;

    return true;
  }

  void _handleOAMDMA() {
    if (cycles.isEven) {
      // read
      oamDmaValue = read(oamDmaPage << 8 | oamDmaOffset);
      oamDmaStarted = true;
    } else if (oamDmaStarted) {
      // write
      bus.ppu.writeOAM(oamDmaOffset++, oamDmaValue);

      if (oamDmaOffset == 256) {
        oamDma = false;
        oamDmaOffset = 0;
        oamDmaStarted = false;
      }
    }
  }

  void _handleDMCDMA() {
    if (!dmcDmaDummy) {
      dmcDmaDummy = true;

      return;
    }

    if (cycles.isEven) {
      dmcDmaValue = read(bus.apu.dmc.address);
      dmcDmaRead = true;
    } else if (dmcDmaRead) {
      bus.apu.dmc.writeDma(dmcDmaValue);
      dmcDmaRead = false;
      dmcDmaDummy = false;
      dmcDma = false;
    }
  }

  void handleIrq(int address) {
    irq = false;

    pushStack16(PC);
    PHP.execute(this, 0);

    I = 1;
    PC = read16(address);
  }

  int calculateBranchCycles(int from, int to) {
    return pageCrossed(from, to) ? 2 : 1;
  }

  void triggerIrq() {
    irq = true;
  }

  void acknowledgeIrq() {
    irq = false;
  }

  void triggerNmi() {
    nmi = true;
  }

  void triggerDmcDma() {
    dmcDma = true;
  }
}
