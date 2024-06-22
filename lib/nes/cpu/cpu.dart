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

  int cycles = 0;

  int PC = 0x0000;
  int SP = 0x00;
  int A = 0x00;
  int X = 0x00;
  int Y = 0x00;
  int P = 0x00;

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

  bool _irq = false;
  bool _nmi = false;

  bool _oamDma = false;
  bool _oamDmaStarted = false;

  int _oamDmaPage = 0;
  int _oamDmaOffset = 0;
  int _oamDmaValue = 0;

  bool _dmcDma = false;
  bool _dmcDmaRead = false;
  bool _dmcDmaDummy = false;

  int _dmcDmaValue = 0;

  CPUState get state => CPUState(
        PC: PC,
        SP: SP,
        A: A,
        X: X,
        Y: Y,
        P: P,
        irq: _irq,
        nmi: _nmi,
        ram: ram,
        oamDma: _oamDma,
        oamDmaStarted: _oamDmaStarted,
        oamDmaOffset: _oamDmaOffset,
        oamDmaValue: _oamDmaValue,
        dmcDma: _dmcDma,
        dmcDmaRead: _dmcDmaRead,
        dmcDmaDummy: _dmcDmaDummy,
        dmcDmaValue: _dmcDmaValue,
        oamDmaPage: _oamDmaPage,
        cycles: cycles,
      );

  set state(CPUState state) {
    cycles = state.cycles;

    PC = state.PC;
    SP = state.SP;
    A = state.A;
    X = state.X;
    Y = state.Y;
    P = state.P;

    _irq = state.irq;
    _nmi = state.nmi;

    _oamDma = state.oamDma;
    _oamDmaStarted = state.oamDmaStarted;
    _oamDmaOffset = state.oamDmaOffset;
    _oamDmaValue = state.oamDmaValue;
    _oamDmaPage = state.oamDmaPage;

    _dmcDma = state.dmcDma;
    _dmcDmaRead = state.dmcDmaRead;
    _dmcDmaDummy = state.dmcDmaDummy;
    _dmcDmaValue = state.dmcDmaValue;

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

    return (high << 8) | low;
  }

  void reset() {
    cycles = 0;

    SP = 0xfd;
    PC = read(0xfffc) | (read(0xfffd) << 8);
    P = 0x24;
    A = 0x00;
    X = 0x00;
    Y = 0x00;

    _irq = false;
    _nmi = false;

    _oamDma = false;
    _oamDmaStarted = false;
    _oamDmaOffset = 0;
    _oamDmaValue = 0;
    _oamDmaPage = 0;

    _dmcDma = false;
    _dmcDmaRead = false;
    _dmcDmaDummy = false;
    _dmcDmaValue = 0;

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
      additionalCycles = wasPageCrossed(start, PC) ? 2 : 1;
    }

    if (op.pageCrossAddsCycle && pageCrossed) {
      additionalCycles++;
    }

    cycles += op.cycles + additionalCycles;
  }

  void _handleInterrupts() {
    if (_nmi) {
      _nmi = false;

      handleIrq(0xfffa);
    }

    if (_irq && I == 0) {
      _irq = false;

      handleIrq(0xfffe);
    }
  }

  bool _handleDMA() {
    if (!_oamDma && !_dmcDma) {
      return false;
    }

    if (_dmcDma) {
      _handleDMCDMA();
    } else if (_oamDma) {
      _handleOAMDMA();
    }

    cycles += 1;

    return true;
  }

  void _handleOAMDMA() {
    if (cycles.isEven) {
      // read
      _oamDmaValue = read(_oamDmaPage << 8 | _oamDmaOffset);
      _oamDmaStarted = true;
    } else if (_oamDmaStarted) {
      // write
      bus.ppu.writeOAM(_oamDmaOffset++, _oamDmaValue);

      if (_oamDmaOffset == 256) {
        _oamDma = false;
        _oamDmaOffset = 0;
        _oamDmaStarted = false;
      }
    }
  }

  void _handleDMCDMA() {
    if (!_dmcDmaDummy) {
      _dmcDmaDummy = true;

      return;
    }

    if (cycles.isEven) {
      // read
      _dmcDmaValue = read(bus.apu.dmc.address);
      _dmcDmaRead = true;
    } else if (_dmcDmaRead) {
      // write
      bus.apu.dmc.writeDma(_dmcDmaValue);

      _dmcDmaRead = false;
      _dmcDmaDummy = false;
      _dmcDma = false;
    }
  }

  void handleIrq(int address) {
    _irq = false;

    pushStack16(PC);
    PHP.execute(this, 0);

    I = 1;
    PC = read16(address);
  }

  void triggerIrq() {
    _irq = true;
  }

  void acknowledgeIrq() {
    _irq = false;
  }

  void triggerNmi() {
    _nmi = true;
  }

  void triggerDmcDma() {
    _dmcDma = true;
  }

  void triggerOamDma(int page) {
    _oamDma = true;
    _oamDmaPage = page;
    _oamDmaOffset = 0;
  }
}
