import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/log/log.dart';
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
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/nes/pacing_governor.dart';
import 'package:nesd/nes/ppu/ppu.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/nes/rewind/rewind_buffer.dart';
import 'package:nesd/nes/rewind/rewind_profiler.dart';
import 'package:nesd/nes/rewind/rewind_timeline.dart';
import 'package:nesd/nes/rewind/rewind_walk.dart';
import 'package:nesd/nes/sample_decimator.dart';
import 'package:nesd/nes/serialization/nes_state.dart';
import 'package:nesd/nes/turbo_speed.dart';
import 'package:nesd/util/wait.dart';

const scrubStepBudget = 96;

class NES {
  NES({
    required Cartridge cartridge,
    required this.eventBus,
    this.governor = const PacingGovernor(),
    this.audioFillProbe,
    Stopwatch? clock,
    this._sleep = wait,
  }) : _clock = clock ?? Stopwatch(),
       bus = Bus(cartridge) {
    bus
      ..cpu = cpu
      ..ppu = ppu
      ..apu = apu;

    cartridge.mapper.bus = bus;
    cpu.cartridgeNeedsStep = cartridge.mapper.needsStep;
    ppu.mapperNeedsPpuAddress = cartridge.mapper.needsPpuAddressUpdates;
    ppu.mapperNeedsPpuReads = cartridge.mapper.needsPpuReads;
  }

  final Bus bus;
  late final CPU cpu = CPU(eventBus: eventBus, bus: bus);
  late final PPU ppu = PPU(bus);
  late final APU apu = APU(bus);

  final EventBus eventBus;

  PacingGovernor governor;
  final AudioFillProbe? audioFillProbe;

  bool on = false;
  bool running = false;
  bool paused = false;
  bool stopAfterNextFrame = false;
  bool suspendAfterNextFrame = false;

  bool _inLoop = false;

  bool get inLoop => _inLoop;

  bool fastForward = false;

  FastForwardSpeed fastForwardSpeed = FastForwardSpeed.x2;

  TurboSpeed get turboSpeed => bus.turboSpeed;

  set turboSpeed(TurboSpeed speed) => bus.turboSpeed = speed;

  final SampleDecimator _fastForwardDecimator = SampleDecimator();

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

    cancelScrub();

    _rewindCaptureInterval = value;
    _rewindBuffer.dispose();
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
    thumbnailStride: max(1, 60 ~/ _rewindCaptureInterval),
    profiler: _rewindProfiler,
  );

  @visibleForTesting
  int get rewindItemCapacity => _rewindBuffer.itemCapacity;

  @visibleForTesting
  int get rewindBufferBytes => _rewindBuffer.size;

  @visibleForTesting
  void replaceRewindBuffer(RewindBuffer buffer) {
    cancelScrub();

    _rewindBuffer.dispose();
    _rewindBuffer = buffer;
  }

  RewindWalk? _scrubWalk;
  Uint8List? _scrubEntryFrame;
  int _scrubTarget = 0;
  int _scrubNewestSequence = 0;
  bool _scrubSettled = true;

  int _scrubPresentedPosition = -1;

  bool get scrubbing => _scrubWalk != null;

  int get scrubSequence => _scrubTarget;

  bool get scrubSettled => _scrubSettled;

  RewindTimeline? beginScrub() {
    if (scrubbing || !rewindEnabled) {
      return null;
    }

    final walk = _rewindBuffer.beginWalk();

    if (walk == null || _rewindBuffer.itemCount == 0) {
      walk?.dispose();

      return null;
    }

    final entryFrame = walk.frame;

    _scrubWalk = walk;
    _scrubNewestSequence = _rewindBuffer.newestSequence;
    _scrubTarget = _scrubNewestSequence;
    _scrubSettled = true;
    _scrubPresentedPosition = -1;
    _scrubEntryFrame = entryFrame == null
        ? null
        : Uint8List.fromList(entryFrame);

    return RewindTimeline(
      oldestSequence: _rewindBuffer.oldestSequence,
      newestSequence: _scrubNewestSequence,
      captureInterval: _rewindCaptureInterval,
      frameRate: frameRate,
      thumbnails: _rewindBuffer.thumbnails(),
      thumbnailWidth: _rewindBuffer.thumbnailWidth,
      thumbnailHeight: _rewindBuffer.thumbnailHeight,
    );
  }

  void scrubTo(int sequence) {
    if (!scrubbing) {
      return;
    }

    _scrubTarget = sequence.clamp(
      _rewindBuffer.oldestSequence,
      _scrubNewestSequence,
    );

    _scrubSettled = false;
  }

  bool advanceScrub() {
    final walk = _scrubWalk;

    if (walk == null) {
      return true;
    }

    final settled = _guardScrub(
      () => walk.seekTo(
        _scrubNewestSequence - _scrubTarget,
        budget: scrubStepBudget,
      ),
    );

    return _scrubSettled = settled ?? true;
  }

  void commitScrub() {
    final walk = _scrubWalk;

    if (walk == null) {
      return;
    }

    final state = _guardScrub(() {
      walk.seekTo(_scrubNewestSequence - _scrubTarget, budget: walk.itemCount);

      return walk.buildState();
    });

    if (state == null) {
      return;
    }

    _applyState(state);

    if (walk.frame case final frame?) {
      ppu.frameBuffer.setPixels(frame);
    }

    _rewindBuffer.commitWalk(walk);

    _endScrub();

    _resetPacing();
  }

  void cancelScrub() {
    final walk = _scrubWalk;

    if (walk == null) {
      return;
    }

    if (_scrubEntryFrame case final frame?) {
      ppu.frameBuffer.setPixels(frame);
    }

    walk.dispose();

    _endScrub();
  }

  T? _guardScrub<T>(T Function() action) {
    try {
      return action();
    } on NesdException catch (e, s) {
      _abortScrub('Rewind chain corrupted; scrub aborted', e, s);
      // binarize throws RangeError on truncated payloads
      // ignore: avoid_catching_errors
    } on RangeError catch (e, s) {
      _abortScrub('Rewind payload truncated; scrub aborted', e, s);
    }

    return null;
  }

  void _abortScrub(String message, Object error, StackTrace stackTrace) {
    log.emulator.warning(message, error: error, stackTrace: stackTrace);

    cancelScrub();

    _rewindBuffer.clear();
  }

  void _endScrub() {
    _scrubWalk = null;
    _scrubEntryFrame = null;
    _scrubSettled = true;
    _scrubPresentedPosition = -1;
  }

  void dispose() {
    cancelScrub();

    _rewindBuffer.dispose();
  }

  int frameRate = 60;

  Region? _region;

  final Stopwatch _clock;

  final Future<void> Function(Duration duration) _sleep;

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

    cancelScrub();

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

    try {
      while (on) {
        if (!running) {
          await _sleep(const Duration(milliseconds: 10));

          continue;
        }

        if (scrubbing) {
          await _handleScrub();

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
          bus.updateTurboPhase(ppu.frames);

          await _sendFrame();
        }
      }
    } finally {
      _inLoop = false;
    }
  }

  /// Opens a frame window: returns the work time since the last frame
  /// mark and advances the event mark / _frameTime.
  Duration _openFrameWindow() {
    final nowMicros = _clock.elapsedMicroseconds;

    final workTime = Duration(microseconds: nowMicros - _lastFrameMarkMicros);

    _frameTime = Duration(microseconds: nowMicros - _lastEventMarkMicros);
    _lastEventMarkMicros = nowMicros;

    return workTime;
  }

  /// Closes a frame window: sleeps, then marks the frame boundary at the
  /// intended wake time. Timer inconsistencies land in the next frame's
  /// measured work time, where the governor subtracts it.
  Future<void> _closeFrameWindow(Duration sleepTime) async {
    final sleepStartMicros = _clock.elapsedMicroseconds;

    await _sleep(sleepTime);

    _lastFrameMarkMicros = sleepStartMicros + sleepTime.inMicroseconds;
  }

  Future<void> _handleRewind() async {
    if (_rewindHold > 0) {
      _rewindHold--;

      await _presentRewindHold();

      return;
    }

    final snapshot = _rewindBuffer.pop();

    if (snapshot == null) {
      // The setter zeroes _rewindHold on this false transition.
      rewind = false;

      return;
    }

    _rewindHold = _rewindCaptureInterval - 1;

    _applyState(snapshot.state);

    if (snapshot.frame case final frame?) {
      ppu.frameBuffer.setPixels(frame);
    }

    ppu.frameBuffer.swap();

    final workTime = _openFrameWindow();

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

    await _closeFrameWindow(sleepTime);
  }

  Future<void> _handleScrub() async {
    advanceScrub();

    final walk = _scrubWalk;

    if (walk == null) {
      return;
    }

    if (walk.position != _scrubPresentedPosition) {
      if (walk.frame case final frame?) {
        ppu.frameBuffer.setPixels(frame);
      }

      ppu.frameBuffer.swap();

      _scrubPresentedPosition = walk.position;
    }

    final workTime = _openFrameWindow();

    final samples = Float32List(apuSampleRate ~/ frameRate);

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

    await _closeFrameWindow(sleepTime);
  }

  Future<void> _presentRewindHold() async {
    final workTime = _openFrameWindow();

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

    await _closeFrameWindow(sleepTime);
  }

  Future<void> _sendFrame() async {
    ppu.frameBuffer.swap();

    final workTime = _openFrameWindow();

    final factor = fastForward ? fastForwardSpeed.factor : 1;

    final Float32List samples;
    final Duration sleepTime;

    if (factor == null) {
      samples = _emptySamples;
      sleepTime = Duration.zero;
    } else {
      samples = factor == 1
          ? apu.sampleBuffer.sublist(0, apu.sampleIndex)
          : _fastForwardDecimator.decimate(
              Float32List.sublistView(apu.sampleBuffer, 0, apu.sampleIndex),
              factor,
            );

      sleepTime = governor.sleepFor(
        samplesProduced: samples.length,
        elapsed: workTime,
        audio: audioFillProbe?.call(),
      );
    }

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
      final profiler = _rewindProfiler;
      final watch = profiler == null ? null : (Stopwatch()..start());

      final captured = _captureState();

      if (profiler != null) {
        profiler.addCapture(watch!.elapsedMicroseconds);
      }

      _rewindBuffer.add(captured);
    }

    if (stopAfterNextFrame) {
      stopAfterNextFrame = false;

      pause();
    }

    if (suspendAfterNextFrame) {
      suspendAfterNextFrame = false;

      suspend();
    }

    apu.sampleIndex = 0;

    await _closeFrameWindow(sleepTime);
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
      cancelScrub();

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

  void buttonDown(int controller, NesButton button, {bool turbo = false}) {
    bus.buttonDown(controller, button, turbo: turbo);
  }

  void buttonUp(int controller, NesButton button, {bool turbo = false}) {
    bus.buttonUp(controller, button, turbo: turbo);
  }

  void buttonToggle(int controller, NesButton button, {bool turbo = false}) {
    bus.buttonToggle(controller, button, turbo: turbo);
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
