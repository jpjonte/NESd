// register names don't follow dart naming conventions
// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:nesd/exception/invalid_opcode.dart';
import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cpu/address_mode.dart';
import 'package:nesd/nes/cpu/cpu_state.dart';
import 'package:nesd/nes/cpu/instruction.dart';
import 'package:nesd/nes/cpu/irq_source.dart';
import 'package:nesd/nes/cpu/operation.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/util/ring_buffer.dart';

const nmiVector = 0xfffa;
const resetVector = 0xfffc;
const irqVector = 0xfffe;

typedef CpuCycle = void Function(CPU);

const pipelineSize = 20;

class CPU {
  CPU({
    required this.eventBus,
    required this.bus,
    this.disableSideEffects = false,
  });

  final EventBus eventBus;
  final Bus bus;
  final bool disableSideEffects;

  bool executionLogEnabled = false;

  int cycles = 0;

  int PC = 0x0000;
  int SP = 0x00;
  int A = 0x00;
  int X = 0x00;
  int Y = 0x00;
  int P = 0x00;

  int address = 0;
  int operand = 0;

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

  void zero(int result) => Z = result == 0 ? 1 : 0;

  void negative(int result) => N = result.bit(7);

  int irq = 0;

  bool _doIrq = false;
  bool _previousDoIrq = false;

  bool nmi = false;
  bool _previousNmi = false;
  bool doNmi = false;

  bool _oamDma = false;
  bool _oamDmaStarted = false;

  int _oamDmaPage = 0;
  int _oamDmaOffset = 0;
  int _oamDmaValue = 0;

  bool _dmcDma = false;
  bool _dmcDmaRead = false;
  bool _dmcDmaDummy = false;

  int _dmcDmaValue = 0;

  final List<int> callStack = [];

  final RingBuffer<CpuCycle, List<CpuCycle>> _pipeline = RingBuffer(
    bufferConstructor: (size) => List.filled(size, (cpu) {}),
    size: pipelineSize,
  );

  bool get fetching => _pipeline.isEmpty;

  bool get executing => _pipeline.isNotEmpty;

  CPUState get state => CPUState(
    PC: PC,
    SP: SP,
    A: A,
    X: X,
    Y: Y,
    P: P,
    irq: irq,
    doIrq: _doIrq,
    previousDoIrq: _previousDoIrq,
    nmi: nmi,
    previousNmi: _previousNmi,
    doNmi: doNmi,
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
    callStack: callStack,
  );

  set state(CPUState state) {
    cycles = state.cycles;

    PC = state.PC;
    SP = state.SP;
    A = state.A;
    X = state.X;
    Y = state.Y;
    P = state.P;

    irq = state.irq;
    _doIrq = state.doIrq;
    _previousDoIrq = state.previousDoIrq;

    nmi = state.nmi;
    _previousNmi = state.previousNmi;
    doNmi = state.doNmi;

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

    callStack
      ..clear()
      ..addAll(state.callStack);
  }

  int read(int address) =>
      bus.cpuRead(address, disableSideEffects: disableSideEffects);

  int read16(int address, {bool wrap = false}) => bus.cpuRead16(
    address,
    wrap: wrap,
    disableSideEffects: disableSideEffects,
  );

  int readHighByte(int address, {bool wrap = false}) => bus.cpuReadHighByte(
    address,
    wrap: wrap,
    disableSideEffects: disableSideEffects,
  );

  void write(int address, int value) => bus.cpuWrite(address, value);

  void pushStack(int value) {
    write(0x100 + SP, value & 0xff);

    SP = (SP - 1) & 0xff;
  }

  void pushStack16(int value) {
    pushStack(value >> 8);
    pushStack(value & 0xff);
  }

  int popStack() {
    SP = (SP + 1) & 0xff;

    final value = read(0x100 + SP);

    return value;
  }

  int popStack16() {
    final low = popStack();
    final high = popStack();

    return (high << 8) | low;
  }

  int peekStack() => read(0x100 + SP);

  int peekStack16() {
    final low = read(0x100 + SP + 1);
    final high = read(0x100 + SP);

    return (high << 8) | low;
  }

  void reset() {
    cycles = 0;

    SP = 0xfd;
    PC = read16(resetVector);
    P = 0x24;
    A = 0x00;
    X = 0x00;
    Y = 0x00;

    irq = 0;
    _doIrq = false;
    _previousDoIrq = false;

    nmi = false;
    doNmi = false;
    _previousNmi = false;

    _oamDma = false;
    _oamDmaStarted = false;
    _oamDmaOffset = 0;
    _oamDmaValue = 0;
    _oamDmaPage = 0;

    _dmcDma = false;
    _dmcDmaRead = false;
    _dmcDmaDummy = false;
    _dmcDmaValue = 0;

    _pipeline.clear();

    callStack.clear();

    ram.fillRange(0, ram.length, 0);
  }

  void appendCycles(List<CpuCycle> cycles) {
    for (final cycle in cycles) {
      _pipeline.append(cycle);
    }
  }

  void prependCycles(List<CpuCycle> cycles) {
    for (var i = cycles.length - 1; i >= 0; i--) {
      _pipeline.prepend(cycles[i]);
    }
  }

  void step() {
    if (_handleDMA()) {
      return;
    }

    if (_pipeline.isEmpty) {
      _fillPipeline();
    } else {
      _executePipeline();
    }

    cycles++;

    _triggerInterrupts();
  }

  void _fillPipeline() {
    final opcode = read(PC);

    final op = ops[opcode];

    if (op == null) {
      throw InvalidOpcode(PC, opcode);
    }

    if (executionLogEnabled) {
      eventBus.add(StepNesEvent(opcode, op));
    }

    PC++;

    op.pipeline(this);

    _updateCallStack(op);
  }

  void _executePipeline() {
    final cycle = _pipeline.popStart();

    cycle(this);

    if (_pipeline.isEmpty) {
      _handleInterrupts();
    }
  }

  void _triggerInterrupts() {
    if (!_previousNmi && nmi) {
      doNmi = true;
    }

    _previousNmi = nmi;

    _previousDoIrq = _doIrq;
    _doIrq = irq > 0 && I == 0;
  }

  void _handleInterrupts() {
    if (doNmi) {
      doNmi = false;

      _handleIrq(nmiVector);
    } else if (_previousDoIrq) {
      _handleIrq(irqVector);
    }
  }

  bool get runningDma => _oamDma || _dmcDma;

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

  void _handleIrq(int address) {
    callStack.add(PC);

    var low = 0;

    appendCycles([
      (cpu) => cpu.read(cpu.PC),
      (cpu) => cpu.read(cpu.PC),
      (cpu) => cpu.pushStack(cpu.PC >> 8),
      (cpu) => cpu.pushStack(cpu.PC & 0xff),
      (cpu) {
        cpu
          ..pushStack(cpu.P.setBit(5, 1))
          ..I = 1;
      },
      (cpu) => low = cpu.read(address),
      (cpu) => cpu.PC = (cpu.readHighByte(address) << 8) | low,
    ]);
  }

  void triggerIrq(IrqSource source) {
    irq = irq | source.value;
  }

  void clearIrq(IrqSource source) {
    irq = irq & ~source.value;
  }

  void triggerNmi() {
    nmi = true;
  }

  void clearNmi() {
    nmi = false;
  }

  void triggerDmcDma() {
    _dmcDma = true;
  }

  void triggerOamDma(int page) {
    _oamDma = true;
    _oamDmaPage = page;
    _oamDmaOffset = 0;
  }

  void _updateCallStack(Operation op) {
    if (op.instruction == JSR) {
      callStack.add(PC + 2);
    } else if (op.instruction == BRK) {
      callStack.add(PC + 1);
    } else if (callStack.isNotEmpty &&
        (op.instruction == RTI || op.instruction == RTS)) {
      callStack.removeLast();
    }
  }

  void branch({required bool doBranch}) {
    if (doBranch) {
      prependCycles([
        if (wasPageCrossed(PC, address))
          (cpu) => cpu.read(cpu.PC), // dummy read
        (cpu) => cpu.PC = cpu.address,
      ]);
    }
  }
}
