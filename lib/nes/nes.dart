// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:binarize/binarize.dart';
import 'package:nesd/nes/apu/apu.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cpu/cpu.dart';
import 'package:nesd/nes/cpu/instruction.dart';
import 'package:nesd/nes/cpu/operation.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes_state.dart';
import 'package:nesd/nes/ppu/ppu.dart';
import 'package:nesd/util/wait.dart';

class NES {
  NES({required Cartridge cartridge, required this.eventBus})
      : bus = Bus(cartridge) {
    bus
      ..cpu = cpu
      ..ppu = ppu
      ..apu = apu;

    cartridge.mapper.bus = bus;
  }

  final Bus bus;
  late final CPU cpu = CPU(eventBus: eventBus, bus: bus);
  late final PPU ppu = PPU(bus);
  late final APU apu = APU(bus);

  final EventBus eventBus;

  bool on = false;
  bool running = false;
  bool paused = false;
  bool stopAfterNextFrame = false;

  bool fastForward = false;

  late DateTime _frameStart;

  int cycles = 0;

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

  void setBreakpoints(List<Breakpoint> breakpoints) {
    _breakpoints
      ..clear()
      ..addAll(breakpoints);
  }

  void addBreakpoint(Breakpoint breakpoint) {
    _breakpoints.add(breakpoint);
  }

  void removeBreakpoint(int address) {
    _breakpoints.removeWhere((b) => b.address == address);
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
        eventBus.add(
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

    eventBus.add(SuspendNesEvent());
  }

  void resume() {
    if (!paused) {
      running = true;
      _frameStart = DateTime.now();
      _sleepBudget = Duration.zero;

      eventBus.add(ResumeNesEvent());
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

    if (_breakpoints.isNotEmpty) {
      final breakpoint = _breakpoints
          .where((b) => b.enabled && b.address == cpu.PC)
          .firstOrNull;

      if (breakpoint != null) {
        pause();

        if (breakpoint.removeOnHit) {
          _breakpoints.remove(breakpoint);
        }
      }
    }
  }

  void stepInto() {
    final start = cpu.PC;

    do {
      step();
      apu.sampleIndex = 0;
    } while (start == cpu.PC);

    eventBus.add(DebuggerNesEvent());
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

    eventBus.add(DebuggerNesEvent());
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

    eventBus.add(DebuggerNesEvent());
  }
}
