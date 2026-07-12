import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/nes/apu/apu.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cheat/cheat.dart';
import 'package:nesd/nes/cpu/cpu.dart';
import 'package:nesd/nes/cpu/instruction.dart';
import 'package:nesd/nes/cpu/operation.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/pacing_governor.dart';
import 'package:nesd/nes/ppu/ppu.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/nes/rewind/rewind_buffer.dart';
import 'package:nesd/nes/rewind/rewind_profiler.dart';
import 'package:nesd/nes/serialization/nes_state.dart';
import 'package:nesd/util/wait.dart';

class NES {
  NES({
    required Cartridge cartridge,
    required this.eventBus,
    this.governor = const PacingGovernor(),
    this.audioFillProbe,
  }) : bus = Bus(cartridge) {
    bus
      ..cpu = cpu
      ..ppu = ppu
      ..apu = apu;

    cartridge.mapper.bus = bus;
    cpu.cartridgeNeedsStep = cartridge.mapper.needsStep;
    ppu.mapperNeedsPpuAddress = cartridge.mapper.needsPpuAddressUpdates;
  }

  final Bus bus;
  late final CPU cpu = CPU(eventBus: eventBus, bus: bus);
  late final PPU ppu = PPU(bus);
  late final APU apu = APU(bus);

  final EventBus eventBus;

  final PacingGovernor governor;
  final AudioFillProbe? audioFillProbe;

  bool on = false;
  bool running = false;
  bool paused = false;
  bool stopAfterNextFrame = false;
  bool _inLoop = false;

  bool get inLoop => _inLoop;

  bool fastForward = false;

  bool get rewind => _rewind;

  set rewind(bool value) {
    if (value != _rewind) {
      // A new rewind session must start with a pop, and leaving rewind
      // must not leak hold frames into the next session.
      _rewindHold = 0;
    }

    _rewind = value;
  }

  bool rewindEnabled = false;

  int get rewindCaptureInterval => _rewindCaptureInterval;

  set rewindCaptureInterval(int value) {
    if (value < 1) {
      throw ArgumentError.value(value, 'rewindCaptureInterval', '>= 1');
    }

    _rewindCaptureInterval = value;
    _rewindBuffer = _createRewindBuffer();
  }

  int _rewindCaptureInterval = 1;

  /// Remaining silent filler frames before the next rewind pop; keeps
  /// playback at ~1x when snapshots span multiple frames.
  int _rewindHold = 0;

  bool _rewind = false;

  bool shouldCaptureRewind(int frame) => frame % _rewindCaptureInterval == 0;

  final RewindProfiler? _rewindProfiler = maybeRewindProfiler();

  late RewindBuffer _rewindBuffer = _createRewindBuffer();

  RewindBuffer _createRewindBuffer() => RewindBuffer(
    // Must be at least 2, because a RingBuffer of size 1 has a usable size of 0
    size: max(2, 3600 ~/ _rewindCaptureInterval),
    profiler: _rewindProfiler,
  );

  @visibleForTesting
  int get rewindItemCapacity => _rewindBuffer.itemCapacity;

  int frameRate = 60;

  Region? _region;

  final Stopwatch _clock = Stopwatch();

  /// Marked when a frame's sleep ends; measures pure work time per frame
  /// (the governor input).
  int _lastFrameMarkMicros = 0;

  /// Marked when a frame event is emitted; measures the full frame period
  /// (what the debug overlay reports as frame time / fps).
  int _lastEventMarkMicros = 0;

  Duration _frameTime = Duration.zero;

  static final Float32List _emptySamples = Float32List(0);

  final List<Breakpoint> _breakpoints = [];

  List<Breakpoint> get breakpoints => _breakpoints;

  set breakpoints(List<Breakpoint> breakpoints) {
    _breakpoints
      ..clear()
      ..addAll(breakpoints);
  }

  List<Cheat> get cheats => bus.cheatEngine.cheats;

  set cheats(List<Cheat> cheats) {
    bus.cheatEngine.removeAllCheats();

    for (final cheat in cheats) {
      bus.cheatEngine.addCheat(cheat);
    }
  }

  void addBreakpoint(Breakpoint breakpoint) {
    if (_breakpoints.any((b) => b.address == breakpoint.address)) {
      return;
    }

    _breakpoints.add(breakpoint);
  }

  void removeBreakpoint(int address) {
    _breakpoints.removeWhere((b) => b.address == address);
  }

  NESState? _lastState;

  /// The current console state.
  ///
  /// While the console is on, this captures a fresh snapshot of the live
  /// emulator state on every read. While it is off, it returns the state
  /// from the last `state =` assignment (load time) — not the last played
  /// frame.
  NESState? get state => on ? _captureState() : _lastState;

  set state(NESState? state) {
    _lastState = state;

    if (state == null) {
      return;
    }

    reset();

    _applyState(state);

    _resetPacing();
  }

  NESState _captureState() => NESState(
    cpuState: cpu.state,
    ppuState: ppu.state,
    apuState: apu.state,
    cartridgeState: bus.cartridge.state,
  );

  void _applyState(NESState state) {
    cpu.state = state.cpuState;
    ppu.state = state.ppuState;
    apu.state = state.apuState;
    bus.cartridge.state = state.cartridgeState;
  }

  Region get region => _region ?? Region.ntsc;

  set region(Region region) {
    _region = region;

    cpu.region = region;
    apu.region = region;
    ppu.region = region;

    frameRate = switch (region) {
      Region.ntsc => 60,
      Region.pal => 50,
    };
  }

  Uint8List? save() => bus.cartridge.save();

  void load(Uint8List save) => bus.cartridge.load(save);

  void _resetPacing() {
    if (!_clock.isRunning) {
      _clock.start();
    }

    _lastFrameMarkMicros = _clock.elapsedMicroseconds;
    _lastEventMarkMicros = _lastFrameMarkMicros;
  }

  void reset() {
    _resetPacing();

    if (!_inLoop) {
      run();
    }

    fastForward = false;

    bus.cartridge.reset();

    cpu.reset();
    apu.reset();
    ppu.reset();

    _rewindBuffer.clear();

    if (paused) {
      eventBus.add(DebuggerNesEvent());
    }
  }

  Future<void> run() async {
    if (_inLoop) {
      return;
    }

    _inLoop = true;

    on = true;
    running = true;
    paused = false;

    _resetPacing();

    _frameTime = Duration.zero;

    while (on) {
      if (!running) {
        await wait(const Duration(milliseconds: 10));

        continue;
      }

      if (rewind) {
        await _handleRewind();

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

    _inLoop = false;
  }

  Future<void> _handleRewind() async {
    if (_rewindHold > 0) {
      _rewindHold--;

      await _presentRewindHold();

      return;
    }

    final rewindState = _rewindBuffer.pop();

    if (rewindState == null) {
      // The setter zeroes _rewindHold on this false transition.
      rewind = false;

      return;
    }

    _rewindHold = _rewindCaptureInterval - 1;

    _applyState(rewindState);

    ppu.frameBuffer.swap();

    final nowMicros = _clock.elapsedMicroseconds;

    final workTime = Duration(microseconds: nowMicros - _lastFrameMarkMicros);

    _frameTime = Duration(microseconds: nowMicros - _lastEventMarkMicros);
    _lastEventMarkMicros = nowMicros;

    eventBus.add(
      FrameNesEvent(
        samples: Float32List.fromList(
          apu.sampleBuffer.sublist(0, apu.sampleIndex).reversed.toList(),
        ),
        frameTime: _frameTime,
        frame: ppu.frames,
        sleepTime: Duration.zero,
        rewindSize: _rewindBuffer.size,
      ),
    );

    final sleepTime = governor.sleepFor(
      samplesProduced: apu.sampleIndex,
      elapsed: workTime,
      audio: audioFillProbe?.call(),
    );

    await wait(sleepTime);

    _lastFrameMarkMicros = _clock.elapsedMicroseconds;
  }

  Future<void> _presentRewindHold() async {
    final nowMicros = _clock.elapsedMicroseconds;

    final workTime = Duration(microseconds: nowMicros - _lastFrameMarkMicros);

    _frameTime = Duration(microseconds: nowMicros - _lastEventMarkMicros);
    _lastEventMarkMicros = nowMicros;

    final samples = Float32List(apu.sampleIndex);

    eventBus.add(
      FrameNesEvent(
        samples: samples,
        frameTime: _frameTime,
        frame: ppu.frames,
        sleepTime: Duration.zero,
        rewindSize: _rewindBuffer.size,
      ),
    );

    final sleepTime = governor.sleepFor(
      samplesProduced: samples.length,
      elapsed: workTime,
      audio: audioFillProbe?.call(),
    );

    await wait(sleepTime);

    _lastFrameMarkMicros = _clock.elapsedMicroseconds;
  }

  Future<void> _sendFrame() async {
    ppu.frameBuffer.swap();

    final nowMicros = _clock.elapsedMicroseconds;

    final workTime = Duration(microseconds: nowMicros - _lastFrameMarkMicros);

    _frameTime = Duration(microseconds: nowMicros - _lastEventMarkMicros);
    _lastEventMarkMicros = nowMicros;

    final samples = fastForward
        ? _emptySamples
        : apu.sampleBuffer.sublist(0, apu.sampleIndex);

    final sleepTime = fastForward
        ? Duration.zero
        : governor.sleepFor(
            samplesProduced: apu.sampleIndex,
            elapsed: workTime,
            audio: audioFillProbe?.call(),
          );

    eventBus.add(
      FrameNesEvent(
        samples: samples,
        frameTime: _frameTime,
        frame: ppu.frames,
        sleepTime: sleepTime,
        rewindSize: _rewindBuffer.size,
      ),
    );

    if (rewindEnabled && shouldCaptureRewind(ppu.frames)) {
      final watch = _rewindProfiler == null ? null : (Stopwatch()..start());

      final captured = _captureState();

      if (watch != null) {
        _rewindProfiler!.addCapture(watch.elapsedMicroseconds);
      }

      _rewindBuffer.add(captured);
    }

    if (stopAfterNextFrame) {
      stopAfterNextFrame = false;

      pause();
    }

    apu.sampleIndex = 0;

    await wait(sleepTime);

    _lastFrameMarkMicros = _clock.elapsedMicroseconds;
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

    _resetPacing();
  }

  void toggleRewind() {
    rewind = rewindEnabled && !rewind;

    if (!rewind) {
      _rewindBuffer.clear();
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

      _resetPacing();

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

  void buttonToggle(int controller, NesButton button) {
    bus.buttonToggle(controller, button);
  }

  void step() {
    cpu.step();

    if (_breakpoints.isNotEmpty) {
      _checkBreakpoints();
    }
  }

  void stepInto() {
    step();

    apu.sampleIndex = 0;

    eventBus.add(DebuggerNesEvent());
  }

  void stepOver() {
    final op = ops[bus.cpuRead(cpu.PC)];

    if (op.instruction is! JSR && op.instruction is! BRK) {
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
