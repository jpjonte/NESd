// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:nes/exception/invalid_opcode.dart';
import 'package:nes/extension/bit_extension.dart';
import 'package:nes/nes/bus.dart';
import 'package:nes/nes/cpu/address_mode.dart';
import 'package:nes/nes/cpu/instruction.dart';
import 'package:nes/nes/cpu/operation.dart';

enum DmaType {
  oam,
  dmc,
}

class CPU {
  CPU(this.bus);

  final Bus bus;

  int PC = 0x0000;
  int SP = 0x00;
  int A = 0x00;
  int X = 0x00;
  int Y = 0x00;
  int P = 0x00;

  int joy1 = 0;
  int joy2 = 0;

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

  DmaType? dma;
  int dmaPage = 0;
  int dmaOffset = 0;
  int dmaValue = 0;
  bool dmaStarted = false;

  int cycles = 0;

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
    SP = 0xfd;
    PC = read(0xfffc) | (read(0xfffd) << 8);
    P = 0x24;
    cycles = 0;
  }

  int step() {
    _handleInterrupts();

    if (_handleDMA()) {
      return 1;
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

    final executedCycles = op.cycles + additionalCycles;

    cycles += executedCycles;

    return executedCycles;
  }

  void _handleInterrupts() {
    // TODO bud-28.05.24 /NMI is an edge-sensitive interrupt
    // TODO bud-28.05.24 make sure that NMI is only triggered
    // TODO bud-28.05.24 when changing from false to true
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
    if (dma == null) {
      return false;
    }

    switch (dma) {
      case DmaType.oam:
        _handleOAMDMA();
      case DmaType.dmc:
        _handleDMCDMA();
      default:
        return false;
    }

    cycles += 1;

    return true;
  }

  void _handleOAMDMA() {
    // TODO bud-01.06.24 refactor this to be more accurate
    // https://www.nesdev.org/wiki/DMA
    if (cycles.isEven) {
      // read
      dmaValue = read(dmaPage << 8 | dmaOffset);
      dmaStarted = true;
    } else if (dmaStarted) {
      // write
      bus.ppu.writeOAM(dmaOffset++, dmaValue);

      if (dmaOffset == 256) {
        dma = null;
        dmaOffset = 0;
        dmaStarted = false;
      }
    }
  }

  void _handleDMCDMA() {
    // TODO bud-01.06.24 implement DMC DMA
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
}
