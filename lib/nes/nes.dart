import 'dart:async';

import 'package:binarize/binarize.dart';
import 'package:nesd/exception/nesd_exception.dart';
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

  Duration _frameTime = Duration.zero;

  int cycles = 0;

  var _sleepBudget = Duration.zero;

  final List<Breakpoint> _breakpoints = [];

  List<Breakpoint> get breakpoints => _breakpoints;

  set breakpoints(List<Breakpoint> breakpoints) {
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

  NESState? _lastState;

  NESState? get state => _lastState;

  set state(NESState? state) {
    _lastState = state;

    if (state == null) {
      return;
    }

    reset();

    cpu.state = state.cpuState;
    ppu.state = state.ppuState;
    apu.state = state.apuState;
    bus.cartridge.state = state.cartridgeState;
    cycles = state.cycles;

    _frameStart = DateTime.now();
    _sleepBudget = Duration.zero;
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

    if (paused) {
      eventBus.add(DebuggerNesEvent());
    }
  }

  Future<void> run() async {
    on = true;
    running = true;
    paused = false;

    _frameStart = DateTime.now();

    _frameTime = Duration.zero;

    while (on) {
      if (cpu.fetching && !running) {
        await wait(const Duration(milliseconds: 10));

        continue;
      }

      final vblankBefore = ppu.PPUSTATUS_V;

      try {
        step();
      } on NesdException catch (e) {
        eventBus.add(ErrorNesEvent(e));

        pause();
      }

      if (vblankBefore == 0 && ppu.PPUSTATUS_V == 1) {
        await _sendFrame();
      }
    }
  }

  Future<void> _sendFrame() async {
    eventBus.add(
      FrameNesEvent(
        samples: apu.sampleBuffer.sublist(0, apu.sampleIndex),
        frameTime: _frameTime, // last frame time
        frame: ppu.frames,
        sleepBudget: _sleepBudget,
      ),
    );

    _lastState = NESState(
      cpuState: cpu.state,
      ppuState: ppu.state,
      apuState: apu.state,
      cartridgeState: bus.cartridge.state,
      cycles: cycles,
    );

    if (stopAfterNextFrame) {
      stopAfterNextFrame = false;

      pause();
    }

    _frameTime = DateTime.now().difference(_frameStart);

    _frameStart = DateTime.now();

    final sleepTime = _calculateSleepTime(_frameTime, apu.sampleIndex);

    apu.sampleIndex = 0;

    _sleepBudget += sleepTime;

    if (_sleepBudget.isNegative) {
      _sleepBudget = Duration.zero;
    }

    await wait(_sleepBudget);
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
    cpu.step();

    cycles += 12;

    bus.cartridge.step();

    var iterations = cycles - ppu.cycles * 4;

    do {
      ppu.step();

      iterations -= 4;
    } while (iterations > 0);

    apu.step();

    if (cpu.fetching && _breakpoints.isNotEmpty) {
      _checkBreakpoints();
    }
  }

  void stepInto() {
    do {
      step();

      apu.sampleIndex = 0;
    } while (cpu.executing || cpu.runningDma);

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

    _breakpoints.add(Breakpoint(next, hidden: true, removeOnHit: true));

    unpause();
  }

  void stepOut() {
    if (cpu.callStack.isEmpty) {
      stepInto();

      return;
    }

    final returnAddress = cpu.callStack.last;

    _breakpoints.add(
      Breakpoint(returnAddress, hidden: true, removeOnHit: true),
    );

    unpause();
  }

  void _checkBreakpoints() {
    final toRemove = <Breakpoint>[];

    for (final breakpoint in _breakpoints) {
      if (!breakpoint.enabled) {
        continue;
      }

      if (breakpoint.address != cpu.PC) {
        continue;
      }

      pause();

      if (breakpoint.removeOnHit) {
        toRemove.add(breakpoint);
      }

      if (breakpoint.disableOnHit) {
        breakpoint.enabled = false;
      }
    }

    _breakpoints.removeWhere((b) => toRemove.contains(b));
  }
}
