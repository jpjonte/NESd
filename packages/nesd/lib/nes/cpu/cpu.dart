// register names don't follow dart naming conventions
// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cpu/address_mode.dart';
import 'package:nesd/nes/cpu/cpu_state.dart';
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

const ntscConsoleCyclesPerDot = 4;
const palConsoleCyclesPerDot = 5;

const _dmcDmaIdle = 0;
const _dmcDmaWaiting = 1;
const _dmcDmaHalted = 2;
const _dmcDmaAligning = 3;

class CPU {
  CPU({required this.eventBus, required this.bus});

  final EventBus eventBus;
  final Bus bus;

  bool executionLogEnabled = false;

  /// Maintained only while the debugger UI is open (drives step-out).
  bool callStackEnabled = false;

  int consoleCycles = 0;

  /// Set by NES at power-on; skips the empty mapper step call for
  /// mappers without cycle-driven logic.
  bool cartridgeNeedsStep = false;

  int _consoleCyclesPerCycle = ntscConsoleCyclesPerCycle;
  int _consoleCyclesPerDot = ntscConsoleCyclesPerDot;

  int cycles = 0;

  int PC = 0x0000;
  int SP = 0x00;
  int A = 0x00;
  int X = 0x00;
  int Y = 0x00;
  int P = 0x00;

  int address = 0;
  int result = 0;

  final List<Operation> _ops = ops;

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
  bool _previousDoNmi = false;

  bool _usePreviousSample = false;

  int openBus = 0;

  bool _oamDma = false;
  bool _oamDmaHalted = false;

  bool _oamDmaHolding = false;

  int _oamDmaPage = 0;
  int _oamDmaOffset = 0;
  int _oamDmaValue = 0;

  int _dmcDmaPhase = _dmcDmaIdle;

  int _dmcDmaHaltAt = 0;

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
    oamDmaStarted: _oamDmaHolding,
    oamDmaOffset: _oamDmaOffset,
    oamDmaValue: _oamDmaValue,
    dmcDma: _dmcDmaPhase != _dmcDmaIdle,
    dmcDmaPhase: _dmcDmaPhase,
    dmcDmaHaltAt: _dmcDmaHaltAt,
    oamDmaPage: _oamDmaPage,
    cycles: cycles,
    consoleCycles: consoleCycles,
    callStack: callStack,
    openBus: openBus,
  );

  set state(CPUState state) {
    openBus = state.openBus;

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
    _oamDmaHolding = state.oamDmaStarted;
    _oamDmaOffset = state.oamDmaOffset;
    _oamDmaValue = state.oamDmaValue;
    _oamDmaPage = state.oamDmaPage;

    _dmcDmaPhase = state.dmcDma && state.dmcDmaPhase == _dmcDmaIdle
        ? _dmcDmaWaiting
        : state.dmcDmaPhase;
    _dmcDmaHaltAt = state.dmcDmaHaltAt;

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
        _consoleCyclesPerDot = ntscConsoleCyclesPerDot;
      case Region.pal:
        _consoleCyclesPerCycle = palConsoleCyclesPerCycle;
        _consoleCyclesPerDot = palConsoleCyclesPerDot;
    }
  }

  int read(int address) {
    _handleDMA();

    _startCycle();

    return bus.cpuRead(address);
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
    _previousDoNmi = false;

    _usePreviousSample = false;

    _oamDma = false;
    _oamDmaHalted = false;
    _oamDmaHolding = false;
    _oamDmaOffset = 0;
    _oamDmaValue = 0;
    _oamDmaPage = 0;

    _dmcDmaPhase = _dmcDmaIdle;
    _dmcDmaHaltAt = 0;

    callStack.clear();

    ram.fillRange(0, ram.length, 0);
  }

  void step() {
    final opcode = read(PC);

    final op = _ops[opcode];

    if (executionLogEnabled) {
      eventBus.add(StepNesEvent(opcode, op));
    }

    PC++;

    if (callStackEnabled) {
      _updateCallStack(opcode);
    }

    op.execute(this);

    if (opcode != 0x00) {
      _handleInterrupts();
    }
  }

  void _pollInterruptLines() {
    _previousDoNmi = doNmi;
    _previousDoIrq = _doIrq;

    if (!_previousNmi && nmi) {
      doNmi = true;
    }

    _previousNmi = nmi;

    _doIrq = irq > 0 && I == 0;
  }

  void _handleInterrupts() {
    final nmiPending = _usePreviousSample ? _previousDoNmi : doNmi;
    final irqPending = _usePreviousSample ? _previousDoIrq : _doIrq;

    _usePreviousSample = false;

    if (nmiPending) {
      doNmi = false;

      _interrupt(nmiVector);
    } else if (irqPending) {
      _interrupt(irqVector);
    }
  }

  bool get _dmcDmaDue =>
      _dmcDmaPhase == _dmcDmaWaiting && cycles + 1 >= _dmcDmaHaltAt;

  bool get runningDma => _oamDma || _dmcDmaPhase >= _dmcDmaHalted || _dmcDmaDue;

  void _handleDMA() {
    if (!_oamDma && !_dmcDmaDue) {
      return;
    }

    while (runningDma) {
      _startCycle();
      _stepDma();
    }
  }

  void _stepDma() {
    var stolen = false;

    switch (_dmcDmaPhase) {
      case _dmcDmaWaiting:
        if (cycles >= _dmcDmaHaltAt) {
          _dmcDmaPhase = _dmcDmaHalted;
        }
      case _dmcDmaHalted:
        _dmcDmaPhase = _dmcDmaAligning;
      case _dmcDmaAligning:
        if (_isGetCycle) {
          _readDmcSample();

          _dmcDmaPhase = _dmcDmaIdle;
          stolen = true;
        }
    }

    if (_oamDma && !stolen) {
      _stepOamDma();
    }
  }

  bool get _isGetCycle => cycles.isEven;

  void _stepOamDma() {
    if (!_oamDmaHalted) {
      _oamDmaHalted = true;

      return;
    }

    if (_isGetCycle) {
      _oamDmaValue = bus.cpuRead(_oamDmaPage << 8 | _oamDmaOffset);
      _oamDmaHolding = true;

      return;
    }

    if (!_oamDmaHolding) {
      return;
    }

    final dma = bus.dmaSettings;
    final start = dma?.start ?? 0;
    final end = dma?.end ?? 256;

    if (dma != null && dma.toPpuData) {
      bus.cpuWrite(0x2007, _oamDmaValue);
    } else {
      bus.ppu.writeOAM(_oamDmaOffset - start, _oamDmaValue);
    }

    _oamDmaHolding = false;
    _oamDmaOffset++;

    if (_oamDmaOffset >= end) {
      _oamDma = false;
      _oamDmaHalted = false;
      _oamDmaOffset = 0;
    }
  }

  void _readDmcSample() {
    final dmc = bus.apu.dmc;

    dmc.writeDma(bus.cpuRead(dmc.address));
  }

  void _interrupt(int vector) {
    if (callStackEnabled) {
      callStack.add(PC);
    }

    read(PC); // dummy read
    read(PC); // dummy read

    pushStack16(PC);

    pushStack(P.setBit(5, 1).setBit(4, 0));

    final target = doNmi ? nmiVector : vector;

    if (target == nmiVector) {
      doNmi = false;
    }

    I = 1;

    PC = read16(target);
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

  void triggerDmcDma({required bool load}) {
    if (_dmcDmaPhase != _dmcDmaIdle) {
      return;
    }

    var haltAt = cycles + (load ? 2 : 1);

    if (haltAt.isEven != load) {
      haltAt++;
    }

    _dmcDmaPhase = _dmcDmaWaiting;
    _dmcDmaHaltAt = haltAt;
  }

  void triggerOamDma(int page) {
    _oamDma = true;
    _oamDmaPage = page;
    _oamDmaOffset = bus.dmaSettings?.start ?? 0;
  }

  void _updateCallStack(int opcode) {
    switch (opcode) {
      case 0x00: // BRK
        callStack.add((PC + 1) & 0xffff);
      case 0x20: // JSR
        callStack.add((PC + 2) & 0xffff);
      case 0x40: // RTI
      case 0x60: // RTS
        if (callStack.isNotEmpty) {
          callStack.removeLast();
        }
    }
  }

  void branch({required bool doBranch}) {
    if (doBranch) {
      read(PC); // dummy read

      if (wasPageCrossed(PC, address)) {
        read(PC); // dummy read
      } else {
        // A taken branch without page cross doesn't poll on its last cycle
        _usePreviousSample = true;
      }

      PC = address;
    }
  }

  void _startCycle() {
    cycles++;

    final firstDotEnd = consoleCycles + _consoleCyclesPerDot;

    consoleCycles += _consoleCyclesPerCycle;

    bus.ppu.stepUntil(firstDotEnd);

    _pollInterruptLines();

    bus.ppu.stepUntil(consoleCycles);

    if (cartridgeNeedsStep) {
      bus.cartridge.step();
    }

    bus.apu.step();
  }
}
