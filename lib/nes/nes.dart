import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:binarize/binarize.dart';
import 'package:nesd/extension/hex_extension.dart';
import 'package:nesd/nes/apu/apu.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cpu/address_mode.dart';
import 'package:nesd/nes/cpu/cpu.dart';
import 'package:nesd/nes/cpu/instruction.dart';
import 'package:nesd/nes/cpu/operation.dart';
import 'package:nesd/nes/nes_state.dart';
import 'package:nesd/nes/ppu/ppu.dart';
import 'package:nesd/util/wait.dart';

sealed class NesEvent {}

class FrameNesEvent extends NesEvent {
  FrameNesEvent({
    required this.samples,
    required this.frameTime,
    required this.sleepBudget,
  });

  final Float32List samples;
  final Duration frameTime;
  final Duration sleepBudget;
}

class StepNesEvent extends NesEvent {}

class SuspendNesEvent extends NesEvent {}

class ResumeNesEvent extends NesEvent {}

class Breakpoint {
  const Breakpoint(
    this.address, {
    this.hidden = false,
    this.removeOnHit = false,
  });

  final int address;
  final bool hidden;
  final bool removeOnHit;
}

class NES {
  NES(Cartridge cartridge, {this.debug = false}) : bus = Bus(cartridge) {
    bus
      ..cpu = cpu
      ..ppu = ppu
      ..apu = apu;

    cartridge.mapper.bus = bus;

    if (debug) {
      File('logs/debug.log').writeAsStringSync('');
    }
  }

  final bool debug;

  bool on = false;
  bool running = false;
  bool paused = false;
  bool stopAfterNextFrame = false;

  bool fastForward = false;

  late DateTime _frameStart;

  final Bus bus;
  late final CPU cpu = CPU(bus);
  late final PPU ppu = PPU(bus);
  late final APU apu = APU(bus);

  int cycles = 0;

  Stream<NesEvent> get eventStream => _streamController.stream;

  final _streamController = StreamController<NesEvent>.broadcast();

  var _sleepBudget = Duration.zero;

  final List<Breakpoint> _breakpoints = [];

  List<Breakpoint> get breakpoints => _breakpoints;

  NESState get state => NESState(
        cpuState: cpu.state,
        ppuState: ppu.state,
        apuState: apu.state,
        cartridgeState: bus.cartridge.state,
        cycles: cycles,
      );

  set state(NESState state) {
    cpu.state = state.cpuState;
    ppu.state = state.ppuState;
    apu.state = state.apuState;
    bus.cartridge.state = state.cartridgeState;
    cycles = state.cycles;

    _frameStart = DateTime.now();
    _sleepBudget = Duration.zero;
  }

  void addBreakpoint(Breakpoint breakpoint) {
    _breakpoints.add(breakpoint);
  }

  void removeBreakpoint(int address) {
    _breakpoints.removeWhere((b) => b.address == address);
  }

  void dispose() {
    _streamController.close();
  }

  Uint8List serialize() {
    final writer = Payload.write()..set(nesStateContract, state);

    return binarize(writer);
  }

  void deserialize(Uint8List bytes) {
    final reader = Payload.read(bytes);
    final state = reader.get(nesStateContract);

    this.state = state;
  }

  Uint8List? save() => bus.cartridge.save();

  void load(Uint8List save) => bus.cartridge.load(save);

  void reset() {
    cycles = 0;

    _frameStart = DateTime.now();
    _sleepBudget = Duration.zero;

    fastForward = false;

    bus.cartridge.reset();

    cpu.reset();
    apu.reset();
    ppu.reset();
  }

  Future<void> run() async {
    reset();

    on = true;
    running = true;
    paused = false;

    _frameStart = DateTime.now();

    var frameTime = Duration.zero;

    while (on) {
      if (!running) {
        await wait(const Duration(milliseconds: 10));

        continue;
      }

      final vblankBefore = ppu.PPUSTATUS_V;

      step();

      if (vblankBefore == 0 && ppu.PPUSTATUS_V == 1) {
        _streamController.add(
          FrameNesEvent(
            samples: apu.sampleBuffer.sublist(0, apu.sampleIndex),
            frameTime: frameTime, // last frame time
            sleepBudget: _sleepBudget,
          ),
        );

        if (stopAfterNextFrame) {
          stopAfterNextFrame = false;

          pause();
        }

        frameTime = DateTime.now().difference(_frameStart);

        _frameStart = DateTime.now();

        final sleepTime = _calculateSleepTime(frameTime, apu.sampleIndex);

        apu.sampleIndex = 0;

        _sleepBudget += sleepTime;

        if (_sleepBudget.isNegative) {
          _sleepBudget = Duration.zero;
        }

        await wait(_sleepBudget);
      }
    }
  }

  Duration _calculateSleepTime(Duration elapsedTime, int samples) {
    if (fastForward) {
      return Duration.zero;
    }

    final targetAudioTime = 1000000 * samples / apuSampleRate;
    final time = targetAudioTime - elapsedTime.inMicroseconds;

    return Duration(microseconds: time.floor());
  }

  void pause() {
    paused = true;

    suspend();
  }

  void togglePause() {
    if (running) {
      pause();
    } else {
      unpause();
    }
  }

  void toggleFastForward() {
    fastForward = !fastForward;

    if (fastForward) {
      _sleepBudget = Duration.zero;
    }
  }

  void unpause() {
    paused = false;

    resume();
  }

  void suspend() {
    running = false;

    _streamController.add(SuspendNesEvent());
  }

  void resume() {
    if (!paused) {
      running = true;
      _frameStart = DateTime.now();
      _sleepBudget = Duration.zero;

      _streamController.add(ResumeNesEvent());
    }
  }

  void stop() {
    on = false;
    running = false;
  }

  void runUntilFrame() {
    stopAfterNextFrame = true;

    unpause();
  }

  void buttonDown(int controller, NesButton button) {
    bus.buttonDown(controller, button);
  }

  void buttonUp(int controller, NesButton button) {
    bus.buttonUp(controller, button);
  }

  void step() {
    _debug();

    final diff = cycles - cpu.cycles * 12;

    if (diff > 0) {
      cycles += diff;
    }

    final cpuCycles = cpu.step();

    cycles += cpuCycles * 12;

    final ppuDiff = cycles - ppu.cycles * 4;

    for (var i = 0; i < ppuDiff; i++) {
      ppu.step();
    }

    final apuDiff = cycles - apu.cycles * 12;

    for (var i = 0; i < apuDiff; i++) {
      apu.step();
    }

    final breakpoint =
        _breakpoints.where((b) => b.address == cpu.PC).firstOrNull;

    if (breakpoint != null) {
      pause();

      if (breakpoint.removeOnHit) {
        _breakpoints.remove(breakpoint);
      }
    }
  }

  void stepInto() {
    final start = cpu.PC;

    do {
      step();
      apu.sampleIndex = 0;
    } while (start == cpu.PC);

    _streamController.add(StepNesEvent());
  }

  void stepOver() {
    final op = ops[bus.cpuRead(cpu.PC)];

    if (op == null) {
      return;
    }

    if (op.instruction != JSR && op.instruction != BRK) {
      stepInto();

      return;
    }

    final next = cpu.PC + op.addressMode.operandCount + 1;

    do {
      step();

      apu.sampleIndex = 0;
    } while (cpu.PC != next);

    _streamController.add(StepNesEvent());
  }

  void stepOut() {
    if (cpu.callStack.isEmpty) {
      stepInto();

      return;
    }

    final returnAddress = cpu.callStack.last;

    do {
      step();

      apu.sampleIndex = 0;
    } while (cpu.PC != returnAddress);

    _streamController.add(StepNesEvent());
  }

  void _debug() {
    if (!debug) {
      return;
    }

    final pc = cpu.PC;

    final opcode = bus.cpu.read(pc);

    _debugOp(pc, opcode);

    final op = ops[opcode];

    if (op == null) {
      return;
    }

    final operands = _getOperands(op, pc);

    _debugOpAssembly(op, operands);
    _debugOpDisassembled(pc, op, operands);
    _debugRegisters();
    _debugCycles();
  }

  void _debugOp(int pc, int opcode) {
    _writeDebug('${pc.toHex(width: 4)}  ${opcode.toHex()} ');
  }

  List<int> _getOperands(Operation op, int pc) {
    final count = op.addressMode.operandCount;

    final operands = List.generate(
      count,
      (index) => bus.cpuRead(pc + 1 + index),
      growable: false,
    );
    return operands;
  }

  void _debugOpAssembly(Operation op, List<int> operands) {
    final formattedOperands = operands.map((o) => '${o.toHex()} ').join();
    final assembly = formattedOperands + ('   ' * (2 - operands.length));

    _writeDebug('$assembly ');
  }

  void _debugOpDisassembled(int pc, Operation op, List<int> operands) {
    final (address, _) = op.addressMode.read(cpu, pc + 1);
    final value = bus.cpuRead(address);

    final addressDebug = op.addressMode.debug(cpu, pc + 1, operands, address);

    var operandDebug = '';

    if (operands.isNotEmpty &&
        op.addressMode != immediate &&
        ![
          InstructionType.jump,
          InstructionType.branch,
        ].contains(op.instruction.type)) {
      operandDebug = ' = ${value.toHex()}';
    }

    final disassembly = addressDebug + operandDebug;

    final mark = op.unofficial ? '*' : ' ';

    _writeDebug(
      '$mark${op.instruction.name} '
      '${disassembly.padRight(28)}',
    );
  }

  void _debugRegisters() {
    _writeDebug('A:${cpu.A.toHex()} '
        'X:${cpu.X.toHex()} '
        'Y:${cpu.Y.toHex()} '
        'P:${cpu.P.toHex()} '
        'SP:${cpu.SP.toHex()} ');
  }

  void _debugCycles() {
    _writeDebug(
      'PPU:${bus.ppu.scanline.toString().padLeft(3)}, '
      '${bus.ppu.cycle.toString().padLeft(3)}'
      ' CYC:${cpu.cycles}\n',
    );
  }

  void _writeDebug(String message) {
    File('logs/debug.log').writeAsStringSync(message, mode: FileMode.append);
  }
}
