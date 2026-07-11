import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:nesd/audio/audio_output.dart';
import 'package:nesd/audio/pcm_recorder.dart';
import 'package:nesd/extension/string_extension.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/debugger/disassembler.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/isolate/debugger_backend.dart';
import 'package:nesd/nes/isolate/execution_log_backend.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/nes/serialization/nes_state.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';

/// `NesDatabase` (`lib/nes/database/database.dart`) is a concrete class
/// whose only public member is `NesDatabaseEntry? find(RomInfo info)`. Its
/// default constructor loads `assets/nes20db.xml` via `rootBundle`, which is
/// unavailable in a worker isolate. Implementing the interface (rather than
/// extending the real class) skips that constructor entirely. Never
/// construct the real `NesDatabase` in the worker.
class _FixedDatabase implements NesDatabase {
  const _FixedDatabase(this.entry);

  final NesDatabaseEntry? entry;

  @override
  NesDatabaseEntry? find(RomInfo info) => entry;
}

/// Plain, non-isolate command handler for the NES emulator core.
///
/// Owns the [NES] instance, the [AudioOutput], the debugger/execution-log
/// backends, and the pool of in-flight frame buffers.
class NesWorker {
  NesWorker({
    required this.send,
    AudioStream Function()? audioStreamFactory,
    this.audioStatsInterval = const Duration(seconds: 1),
  }) : _audioStreamFactory = audioStreamFactory ?? getAudioStream;

  final void Function(NesIsolateEvent event) send;
  final AudioStream Function() _audioStreamFactory;

  final Duration audioStatsInterval;

  final Stopwatch _audioStatsTimer = Stopwatch();

  bool _audioStatsWarmup = true;

  final EventBus eventBus = EventBus();

  NES? _nes;

  @visibleForTesting
  NES? get nesForTesting => _nes;

  AudioOutput? _audioOutput;
  DebuggerBackend? _debugger;
  ExecutionLogBackend? _executionLog;
  Disassembler? _disassembler;
  bool _debuggerActive = false;
  bool _executionLogEnabled = false;

  StreamSubscription<NesEvent>? _subscription;

  final Map<int, ({FrameBuffer frameBuffer, Uint8List buffer})>
  _framesInFlight = {};

  Future<void> handleCommand(NesCommand command) async {
    switch (command) {
      case LoadRomCommand():
        await _loadRom(command);
      case ResetCommand():
        _nes?.reset();
        _audioOutput?.reset();
        _sendStatus();
      case PauseCommand():
        _nes?.pause();
      case UnpauseCommand():
        _nes?.unpause();
      case TogglePauseCommand():
        _nes?.togglePause();
      case SuspendCommand():
        _nes?.suspend();
      case ResumeCommand():
        _nes?.resume();
      case StopCommand():
        await _stop();
      case ShutdownCommand():
        await shutdown();
      case ButtonDownCommand():
        _nes?.buttonDown(command.controller, command.button);
      case ButtonUpCommand():
        _nes?.buttonUp(command.controller, command.button);
      case ButtonToggleCommand():
        _nes?.buttonToggle(command.controller, command.button);
      case ToggleFastForwardCommand():
        _nes?.toggleFastForward();
        _sendStatus();
      case ToggleRewindCommand():
        _nes?.toggleRewind();
        _sendStatus();
      case SetFastForwardCommand():
        // Plain assignment (not toggleFastForward()) mirrors the old
        // hold-mode path in ActionHandler, which set nes.fastForward
        // directly and did NOT zero the sleep budget.
        _nes?.fastForward = command.enabled;
        _sendStatus();
      case SetRewindCommand():
        // Plain assignment mirrors the old hold-mode path; unlike
        // toggleRewind() it does not gate on rewindEnabled.
        _nes?.rewind = command.enabled;
        _sendStatus();
      case SetRewindEnabledCommand():
        _nes?.rewindEnabled = command.enabled;
      case SetRegionCommand():
        _applyRegion(command.region);
      case SetCheatsCommand():
        _nes?.cheats = command.cheats;
      case SetVolumeCommand():
        _audioOutput?.volume = command.volume;
      case StartPcmDumpCommand():
        _startPcmDump(command.path);
      case StopPcmDumpCommand():
        _stopPcmDump();
      case AddBreakpointCommand():
        _debugger?.addBreakpoint(command.breakpoint);
      case RemoveBreakpointCommand():
        _debugger?.removeBreakpoint(command.address);
      case SetBreakpointsCommand():
        _debugger?.setBreakpoints(command.breakpoints);
      case StepIntoCommand():
        _nes?.stepInto();
      case StepOverCommand():
        _nes?.stepOver();
      case StepOutCommand():
        _nes?.stepOut();
      case RunUntilFrameCommand():
        _nes?.runUntilFrame();
      case SetDebuggerActiveCommand():
        _setDebuggerActive(command.active);
      case SetExecutionLogEnabledCommand():
        _setExecutionLogEnabled(command.enabled);
      case SaveStateRequest():
        _handleSaveState(command.requestId);
      case LoadStateCommand():
        _handleLoadState(command.state);
      case SaveSramRequest():
        _handleSaveSram(command.requestId);
      case LoadSramCommand():
        _handleLoadSram(command.sram);
      case ThumbnailRequest():
        _handleThumbnail(command.requestId);
      case TileDebugRequest():
        _handleTileDebug(command.requestId);
      case ReleaseFrameCommand():
        _releaseFrame(command.pointerAddress);
      case SetZapperPositionCommand():
        _nes?.bus.zapperPosition = command.x == null
            ? null
            : Offset(command.x!, command.y!);
      case ZapperPullCommand():
        _nes?.bus.zapperPull();
      case ZapperReleaseCommand():
        _nes?.bus.zapperRelease();
    }
  }

  Future<void> shutdown() async {
    await _stop(); // _stop() already sends the StoppedEvent

    _audioOutput?.dispose();
    _audioOutput = null;

    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _loadRom(LoadRomCommand command) async {
    await _stopNesLoop();

    // Deliberately NO in-flight clearing here: Frames the UI still holds from
    // the previous ROM stay pinned until their ReleaseFrameCommand arrives.
    final rom = command.rom.materialize().asUint8List();
    final factory = CartridgeFactory(
      database: _FixedDatabase(command.databaseEntry),
    );

    try {
      final cartridge = factory.fromFile(command.file, rom)
        ..databaseEntry = command.databaseEntry;

      _audioOutput ??= AudioOutput(audioStream: _audioStreamFactory());

      // reset() starts the run loop and synchronously emulates the first
      // frame before _nes/_subscription are set below, so the very first
      // FrameNesEvent is dropped. Harmless (the next frame arrives ~16ms
      // later); do not reorder to chase it.
      final nes = NES(
        cartridge: cartridge,
        eventBus: eventBus,
        audioFillProbe: () => _audioOutput?.bufferStatus,
      )..reset();

      if (command.initialState case final state?) {
        nes.state = NESState.fromBytes(state.materialize().asUint8List());
      }

      nes
        ..region = command.region ?? _autoDetectRegion(cartridge) ?? Region.ntsc
        ..rewindEnabled = command.rewindEnabled
        ..rewindCaptureInterval = command.rewindCaptureInterval
        ..cheats = command.cheats
        ..breakpoints = command.breakpoints;

      if (command.sram case final sram?) {
        nes.load(sram.materialize().asUint8List());
      }

      _subscription ??= eventBus.stream.listen(_handleNesEvent);

      // The old backends (if any) are bound to the previous NES instance
      // and would otherwise keep listening on the shared eventBus with a
      // stale `nes` reference. Drop them so _rebuildBackends() below binds
      // fresh instances to the new NES.
      _debugger?.dispose();
      _debugger = null;
      _executionLog?.dispose();
      _executionLog = null;

      _nes = nes;
      _disassembler = null;

      _rebuildBackends();

      unawaited(nes.run());

      send(
        RomLoadedEvent(hasZapper: command.databaseEntry?.hasZapper ?? false),
      );

      _sendStatus();
    } on Object catch (e) {
      send(RomLoadFailedEvent(message: e.toString()));
    }
  }

  Future<void> _stopNesLoop() async {
    final nes = _nes;

    if (nes == null) {
      return;
    }

    nes.stop();

    while (nes.inLoop) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<void> _stop() async {
    await _stopNesLoop();

    _debugger?.dispose();
    _debugger = null;
    _executionLog?.dispose();
    _executionLog = null;
    _disassembler = null;
    _nes = null;

    send(const StoppedEvent());
  }

  void _handleNesEvent(NesEvent event) {
    switch (event) {
      case FrameNesEvent():
        _audioOutput?.processSamples(event.samples);
        _maybeEmitAudioStats();
        _sendReadyFrame(event);
        _sendStatusIfChanged();
      case SuspendNesEvent():
        _sendStatus();
        _sendReadyFrame(null);
      case ResumeNesEvent():
        _sendStatus();
      case DebuggerNesEvent():
        _sendStatus();
        _sendReadyFrame(null);
      case ErrorNesEvent():
        send(ErrorEvent(message: event.error.toString()));
      default:
        break;
    }
  }

  void _sendReadyFrame(FrameNesEvent? event) {
    final nes = _nes;

    if (nes == null) {
      return;
    }

    final frameBuffer = nes.ppu.frameBuffer;
    final buffer = frameBuffer.takeReadyBuffer();

    if (buffer == null) {
      return;
    }

    final address = frameBuffer.pointerForBuffer(buffer);

    if (address == null) {
      frameBuffer.releaseDisplayBuffer(buffer);

      return;
    }

    _framesInFlight[address] = (frameBuffer: frameBuffer, buffer: buffer);

    send(
      FrameEvent(
        pointerAddress: address,
        width: frameBuffer.width,
        height: frameBuffer.height,
        frameTimeMicroseconds: event?.frameTime.inMicroseconds ?? 0,
        sleepTimeMicroseconds: event?.sleepTime.inMicroseconds ?? 0,
        frame: event?.frame ?? 0,
        rewindSize: event?.rewindSize ?? 0,
      ),
    );
  }

  // NOTE: _framesInFlight is deliberately never bulk-cleared. The held
  // `Uint8List` views are what keep the frame memory alive (FrameBuffer
  // attaches a GC Finalizer); dropping them while the UI still reads a pointer
  // view would be a use-after-free. Entries leave the map only via
  // ReleaseFrameCommand.
  void _releaseFrame(int pointerAddress) {
    final entry = _framesInFlight.remove(pointerAddress);

    entry?.frameBuffer.releaseDisplayBuffer(entry.buffer);
  }

  ({bool running, bool paused, bool fastForward, bool rewind})? _lastStatus;

  ({bool running, bool paused, bool fastForward, bool rewind}) get _status {
    final nes = _nes;

    return (
      running: nes?.running ?? false,
      paused: nes?.paused ?? false,
      fastForward: nes?.fastForward ?? false,
      rewind: nes?.rewind ?? false,
    );
  }

  void _sendStatus() {
    final status = _lastStatus = _status;

    send(
      StatusEvent(
        running: status.running,
        paused: status.paused,
        fastForward: status.fastForward,
        rewind: status.rewind,
      ),
    );
  }

  /// NES mutates status internally without emitting an event in one case:
  /// rewind auto-stops when the buffer empties (`_handleRewind` sets
  /// `rewind = false`, nes.dart). Poll for drift once per frame so the
  /// UI-side mirrors (`RemoteNes.rewind` etc.) cannot go stale.
  void _sendStatusIfChanged() {
    if (_status != _lastStatus) {
      _sendStatus();
    }
  }

  void _maybeEmitAudioStats() {
    final audio = _audioOutput;

    if (audio == null) {
      return;
    }

    if (!_audioStatsTimer.isRunning) {
      audio.takeStats();

      _audioStatsWarmup = true;

      _audioStatsTimer.start();

      return;
    }

    if (_audioStatsTimer.elapsedMicroseconds <
        audioStatsInterval.inMicroseconds) {
      return;
    }

    final oversized =
        audioStatsInterval > Duration.zero &&
        _audioStatsTimer.elapsedMicroseconds >
            2 * audioStatsInterval.inMicroseconds;

    _audioStatsTimer.reset();

    final stats = audio.takeStats();

    if (_audioStatsWarmup || oversized) {
      _audioStatsWarmup = oversized;

      return;
    }

    final event = AudioStatsEvent(
      timestampMilliseconds: DateTime.now().millisecondsSinceEpoch,
      exhaustDelta: stats.exhaustDelta,
      fullDelta: stats.fullDelta,
      fillMin: stats.fillMin,
      fillMax: stats.fillMax,
    );

    send(event);

    // ignore: avoid_print - logcat is the transport for audio stats
    print(event.logLine);
  }

  void _startPcmDump(String path) {
    final audio = _audioOutput;

    if (audio == null) {
      send(const ErrorEvent(message: 'PCM dump requires a loaded ROM'));

      return;
    }

    audio.pcmRecorder?.close();
    audio.pcmRecorder = null;

    try {
      audio.pcmRecorder = PcmRecorder(path: path);
    } on FileSystemException catch (e) {
      send(ErrorEvent(message: 'PCM dump failed to open: $e'));
    }
  }

  void _stopPcmDump() {
    _audioOutput?.pcmRecorder?.close();
    _audioOutput?.pcmRecorder = null;
  }

  void _handleSaveState(int requestId) {
    final data = _nes?.state?.serialize();

    send(
      SaveStateResponse(
        requestId: requestId,
        state: data == null ? null : TransferableTypedData.fromList([data]),
      ),
    );
  }

  void _handleLoadState(TransferableTypedData state) {
    final nes = _nes;

    if (nes == null) {
      return;
    }

    try {
      nes.state = NESState.fromBytes(state.materialize().asUint8List());
    } on Object catch (e) {
      send(ErrorEvent(message: 'Failed to load state: $e'));
    }
  }

  void _handleLoadSram(TransferableTypedData sram) {
    final nes = _nes;

    if (nes == null) {
      return;
    }

    try {
      nes.load(sram.materialize().asUint8List());
    } on Object catch (e) {
      send(ErrorEvent(message: 'Failed to load SRAM: $e'));
    }
  }

  void _handleSaveSram(int requestId) {
    final data = _nes?.save();

    send(
      SramResponse(
        requestId: requestId,
        sram: data == null ? null : TransferableTypedData.fromList([data]),
      ),
    );
  }

  void _handleThumbnail(int requestId) {
    final nes = _nes;

    if (nes == null) {
      return;
    }

    final frameBuffer = nes.ppu.frameBuffer;
    final queued = frameBuffer.takeReadyBuffer();
    final pixels = Uint8List.fromList(queued ?? frameBuffer.pixels);

    if (queued != null) {
      frameBuffer.releaseDisplayBuffer(queued);
    }

    send(
      ThumbnailResponse(
        requestId: requestId,
        pixels: TransferableTypedData.fromList([pixels]),
        width: frameBuffer.width,
        height: frameBuffer.height,
      ),
    );
  }

  void _handleTileDebug(int requestId) {
    final nes = _nes;

    if (nes == null) {
      return;
    }

    final memory = Uint8List(0x4000);

    for (var address = 0; address < 0x4000; address++) {
      memory[address] = nes.bus.ppuRead(address, disableSideEffects: true);
    }

    send(
      TileDebugResponse(
        requestId: requestId,
        ppuMemory: TransferableTypedData.fromList([memory]),
        ppuCtrl: nes.ppu.PPUCTRL,
        v: nes.ppu.v,
        t: nes.ppu.t,
        x: nes.ppu.x,
      ),
    );
  }

  /// Ensures the debugger/execution-log backends match the current
  /// `_debuggerActive` / `_executionLogEnabled` flags for the current
  /// `_nes` (tearing existing ones down when the corresponding flag is
  /// off or there is no NES, and lazily creating them otherwise). Backends
  /// already bound to the current NES are left in place so toggling one
  /// flag doesn't disturb the other's accumulated state.
  void _rebuildBackends() {
    final nes = _nes;

    if (nes == null || !_debuggerActive) {
      _debugger?.dispose();
      _debugger = null;
    }

    if (nes == null || !_executionLogEnabled) {
      _executionLog?.setEnabled(false);
      _executionLog?.dispose();
      _executionLog = null;
    }

    if (nes == null) {
      return;
    }

    nes.cpu.callStackEnabled = _debuggerActive;

    if (!_debuggerActive) {
      nes.cpu.callStack.clear();
    }

    if (_debuggerActive || _executionLogEnabled) {
      _disassembler ??= Disassembler(eventBus: eventBus, cpu: nes.cpu);
    }

    if (_debuggerActive) {
      _debugger ??= DebuggerBackend(
        nes: nes,
        eventBus: eventBus,
        disassembler: _disassembler!,
        onState: (state, memory) => send(
          DebuggerEvent(
            state: state,
            cpuMemory: TransferableTypedData.fromList([memory]),
          ),
        ),
        onBreakpoints: (hash, breakpoints) =>
            send(BreakpointsEvent(fileHash: hash, breakpoints: breakpoints)),
        initialBreakpoints: nes.breakpoints,
      );
    }

    if (_executionLogEnabled) {
      _executionLog ??= ExecutionLogBackend(
        nes: nes,
        eventBus: eventBus,
        disassembler: _disassembler!,
        onLines: (lines) => send(ExecutionLogEvent(lines: lines)),
      )..setEnabled(true);
    }
  }

  // the single bool parameter mirrors the protocol command it backs
  // ignore: avoid_positional_boolean_parameters
  void _setDebuggerActive(bool active) {
    _debuggerActive = active;

    _rebuildBackends();
  }

  // the single bool parameter mirrors the protocol command it backs
  // ignore: avoid_positional_boolean_parameters
  void _setExecutionLogEnabled(bool enabled) {
    _executionLogEnabled = enabled;

    _rebuildBackends();
  }

  void _applyRegion(Region? region) {
    final nes = _nes;

    if (nes == null) {
      return;
    }

    nes.region = region ?? _autoDetectRegion(nes.bus.cartridge) ?? Region.ntsc;
  }

  Region? _autoDetectRegion(Cartridge cartridge) {
    final databaseEntry = cartridge.databaseEntry;

    if (databaseEntry != null) {
      return databaseEntry.region;
    }

    final filename = cartridge.romInfo.file.name.toUpperCase();

    if (filename.containsAny(['(U)', '(USA)', '(J)', '(JU)', '(NTSC)'])) {
      return Region.ntsc;
    }

    if (filename.containsAny(['(E)', '(EUR)', '(EUROPE)', '(PAL)'])) {
      return Region.pal;
    }

    return null;
  }
}
