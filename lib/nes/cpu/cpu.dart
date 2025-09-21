// register names don't follow dart naming conventions
// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cpu/address_mode.dart';
import 'package:nesd/nes/cpu/cpu_state.dart';
import 'package:nesd/nes/cpu/instruction.dart';
import 'package:nesd/nes/cpu/irq_source.dart';
import 'package:nesd/nes/cpu/operation.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/region.dart';

const nmiVector = 0xfffa;
const resetVector = 0xfffc;
const irqVector = 0xfffe;

typedef CpuCycle = void Function(CPU);

const pipelineSize = 20;

const ntscConsoleCyclesPerCycle = 12;
const palConsoleCyclesPerCycle = 16;

class CPU {
  CPU({required this.eventBus, required this.bus});

  final EventBus eventBus;
  final Bus bus;

  bool executionLogEnabled = false;

  int consoleCycles = 0;

  int _consoleCyclesPerCycle = ntscConsoleCyclesPerCycle;

  int cycles = 0;

  int PC = 0x0000;
  int SP = 0x00;
  int A = 0x00;
  int X = 0x00;
  int Y = 0x00;
  int P = 0x00;

  int address = 0;
  int result = 0;

  late Operation operation;

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
    consoleCycles: consoleCycles,
    callStack: callStack,
  );

  set state(CPUState state) {
    consoleCycles = state.consoleCycles;
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

  // we don't need a getter for this
  // ignore: avoid_setters_without_getters
  set region(Region region) {
    switch (region) {
      case Region.ntsc:
        _consoleCyclesPerCycle = ntscConsoleCyclesPerCycle;
      case Region.pal:
        _consoleCyclesPerCycle = palConsoleCyclesPerCycle;
    }
  }

  int read(int address) {
    _handleDMA();

    _startCycle();

    final value = bus.cpuRead(address);

    _endCycle();

    return value;
  }

  int read16(int address, {bool wrap = false}) {
    final low = read(address);

    final pageAddress = address & 0xff00;
    final highByteAddress = address + 1;

    final highAddress = switch (wrap) {
      true => pageAddress | (highByteAddress & 0xff),
      false => highByteAddress,
    };

    final high = read(highAddress);

    return (high << 8) | low;
  }

  void write(int address, int value) {
    _startCycle();

    bus.cpuWrite(address, value);

    _endCycle();
  }

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

    return read(0x100 + SP);
  }

  int popStack16() {
    final low = popStack();
    final high = popStack();

    return (high << 8) | low;
  }

  void reset() {
    consoleCycles = 0;
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

    callStack.clear();

    ram.fillRange(0, ram.length, 0);
  }

  void step() {
    final opcode = read(PC);

    final op = ops[opcode];

    operation = op;

    if (executionLogEnabled) {
      eventBus.add(StepNesEvent(opcode, op));
    }

    PC++;

    _updateCallStack(op);

    op.execute(this);

    _handleInterrupts();
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

  void _handleDMA() {
    if (!_oamDma && !_dmcDma) {
      return;
    }

    while (runningDma) {
      _startCycle();

      if (_dmcDma) {
        handleDMCDMA();
      } else if (_oamDma) {
        handleOAMDMA();
      }

      _endCycle();
    }
  }

  void handleOAMDMA() {
    if (cycles.isEven) {
      // read
      _oamDmaValue = bus.cpuRead(_oamDmaPage << 8 | _oamDmaOffset);
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

  void handleDMCDMA() {
    if (!_dmcDmaDummy) {
      _dmcDmaDummy = true;

      return;
    }

    if (cycles.isEven) {
      // read
      _dmcDmaValue = bus.cpuRead(bus.apu.dmc.address);
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

    read(PC); // dummy read
    read(PC); // dummy read

    pushStack16(PC);

    pushStack(P.setBit(5, 1));

    I = 1;

    PC = read16(address);
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
    if (op.instruction is JSR) {
      callStack.add(PC + 2);
    } else if (op.instruction is BRK) {
      callStack.add(PC + 1);
    } else if (callStack.isNotEmpty &&
        (op.instruction is RTI || op.instruction is RTS)) {
      callStack.removeLast();
    }
  }

  void branch({required bool doBranch}) {
    if (doBranch) {
      read(PC); // dummy read

      if (wasPageCrossed(PC, address)) {
        read(PC); // dummy read
      }

      PC = address;
    }
  }

  void _startCycle() {
    cycles++;

    consoleCycles += _consoleCyclesPerCycle;

    bus.ppu.stepUntil(consoleCycles);

    bus.cartridge.step();
    bus.apu.step();
  }

  void _endCycle() {
    _triggerInterrupts();
  }
}
