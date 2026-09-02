import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:nesd/audio/audio_output.dart';
import 'package:nesd/audio/pcm_recorder.dart';
import 'package:nesd/extension/string_extension.dart';
import 'package:nesd/features.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/apu/apu.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/debugger/disassembler.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/isolate/apu_debug_backend.dart';
import 'package:nesd/nes/isolate/debugger_backend.dart';
import 'package:nesd/nes/isolate/execution_log_backend.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/ppu/frame_buffer.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/nes/serialization/nes_state.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd_audio/nesd_audio.dart';

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

  @override
  Future<void> get ready => Future.value();
}

/// Plain, non-isolate command handler for the NES emulator core.
///
/// Owns the [NES] instance, the [AudioOutput], the debugger/execution-log
/// backends, and the pool of in-flight frame buffers.
class NesWorker {
  NesWorker({
    required this.send,
    NesdAudio Function()? audioFactory,
    this.audioStatsInterval = const Duration(seconds: 1),
    this.rewindSupported = Features.rewind,
  }) : _audioFactory = audioFactory ?? defaultNesdAudio;

  final void Function(NesIsolateEvent event) send;
  final NesdAudio Function() _audioFactory;

  final Duration audioStatsInterval;

  final bool rewindSupported;

  final Stopwatch _audioStatsTimer = Stopwatch();

  bool _audioStatsWarmup = true;

  final EventBus eventBus = EventBus();

  NES? _nes;

  @visibleForTesting
  NES? get nesForTesting => _nes;

  AudioOutput? _audioOutput;
  DebuggerBackend? _debugger;
  ExecutionLogBackend? _executionLog;
  ApuDebugBackend? _apuDebug;
  Disassembler? _disassembler;
  bool _debuggerActive = false;
  bool _executionLogEnabled = false;
  bool _apuDebugEnabled = false;

  StreamSubscription<NesEvent>? _subscription;

  final Map<int, ({FrameBuffer frameBuffer, Uint8List buffer})>
  _framesInFlight = {};

  int _nextFrameHandle = 1;

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
        _nes?.buttonDown(
          command.controller,
          command.button,
          turbo: command.turbo,
        );
      case ButtonUpCommand():
        _nes?.buttonUp(
          command.controller,
          command.button,
          turbo: command.turbo,
        );
      case ButtonToggleCommand():
        _nes?.buttonToggle(
          command.controller,
          command.button,
          turbo: command.turbo,
        );
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
        _nes?.rewindEnabled = rewindSupported && command.enabled;
      case SetRegionCommand():
        _applyRegion(command.region);
      case SetCheatsCommand():
        _nes?.cheats = command.cheats;
      case SetVolumeCommand():
        _audioOutput?.volume = command.volume;
      case SetFastForwardSpeedCommand():
        _nes?.fastForwardSpeed = command.speed;
      case SetTurboSpeedCommand():
        _nes?.turboSpeed = command.speed;
      case SetLowPassFilterCommand():
        _audioOutput?.lowPassFilter = command.enabled;
      case SetSwapDutyCyclesCommand():
        _nes?.apu.swapDutyCycles = command.enabled;
      case SetMixerCommand():
        _nes?.apu.mixer = command.mixer;
      case SetPaletteCommand():
        _nes?.ppu.systemPalette = command.palette;
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
      case SetApuDebugEnabledCommand():
        _setApuDebugEnabled(command.enabled);
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
        _releaseFrame(command.frameHandle);
      case SetZapperPositionCommand():
        _nes?.bus.zapperPosition = command.x == null
            ? null
            : Offset(command.x!, command.y!);
      case ZapperPullCommand():
        log.input.info('Zapper trigger pulled');

        _nes?.bus.zapperPull();
      case ZapperReleaseCommand():
        _nes?.bus.zapperRelease();
      case SetLogLevelCommand():
        NesdLog.instance.minimumLevel = command.level;
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

      if (_audioOutput == null) {
        final audioOutput = AudioOutput(audio: _audioFactory());

        _audioOutput = audioOutput;

        log.audio.info(
          'Audio device opened',
          context: {
            'sampleRate': apuSampleRate,
            'state': audioOutput.audio.state.name,
          },
        );
      }

      // reset() starts the run loop and synchronously emulates the first
      // frame before _nes/_subscription are set below, so the very first
      // FrameNesEvent is dropped. Harmless (the next frame arrives ~16ms
      // later); do not reorder to chase it.
      final nes = NES(
        cartridge: cartridge,
        eventBus: eventBus,
        audioFillProbe: () => _audioOutput?.bufferStatus,
      )..reset();

      if (command.sram case final sram?) {
        nes.load(sram.materialize().asUint8List());
      }

      if (command.initialState case final state?) {
        nes.state = NESState.fromBytes(state.materialize().asUint8List());
      }

      nes
        ..region = command.region ?? _autoDetectRegion(cartridge) ?? Region.ntsc
        ..rewindEnabled = rewindSupported && command.rewindEnabled
        ..rewindCaptureInterval = command.rewindCaptureInterval
        ..cheats = command.cheats
        ..breakpoints = command.breakpoints;

      _subscription ??= eventBus.stream.listen(_handleNesEvent);

      // The old backends (if any) are bound to the previous NES instance
      // and would otherwise keep listening on the shared eventBus with a
      // stale `nes` reference. Drop them so _rebuildBackends() below binds
      // fresh instances to the new NES.
      _debugger?.dispose();
      _debugger = null;
      _executionLog?.dispose();
      _executionLog = null;
      _apuDebug?.dispose();
      _apuDebug = null;

      _nes = nes;
      _disassembler = null;

      _rebuildBackends();

      if (command.suspended) {
        nes.suspendAfterNextFrame = true;
      }

      unawaited(nes.run());

      log.rom.info(
        'ROM loaded',
        context: {
          'name': command.file.name,
          'mapper': cartridge.mapper.id,
          'prgRom': cartridge.prgRom.length,
          'chrRom': cartridge.chrRom.length,
          'region': nes.region.name,
          'zapper': command.databaseEntry?.hasZapper ?? false,
        },
      );

      send(
        RomLoadedEvent(hasZapper: command.databaseEntry?.hasZapper ?? false),
      );

      _sendStatus();
    } on Object catch (e, s) {
      log.rom.error(
        'ROM load failed',
        context: {'name': command.file.name},
        error: e,
        stackTrace: s,
      );

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
    _apuDebug?.dispose();
    _apuDebug = null;
    _disassembler = null;
    _nes = null;

    log.emulator.info('Emulator stopped');

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
    final handle = address ?? _nextFrameHandle++;

    _framesInFlight[handle] = (frameBuffer: frameBuffer, buffer: buffer);

    send(
      FrameEvent(
        frameHandle: handle,
        pixels: address == null
            ? InlineFramePixels(bytes: buffer)
            : PointerFramePixels(address: address),
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
  void _releaseFrame(int frameHandle) {
    final entry = _framesInFlight.remove(frameHandle);

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
      popMax: stats.popMax,
    );

    send(event);

    log.telemetry.emit(event.logLine);
  }

  void _startPcmDump(String path) {
    final audio = _audioOutput;

    if (audio == null) {
      log.audio.error('PCM dump requires a loaded ROM');

      send(const ErrorEvent(message: 'PCM dump requires a loaded ROM'));

      return;
    }

    audio.pcmRecorder?.close();
    audio.pcmRecorder = null;

    try {
      audio.pcmRecorder = PcmRecorder(path: path);
    } on FileSystemException catch (e) {
      log.audio.error('PCM dump failed to open', error: e);

      send(ErrorEvent(message: 'PCM dump failed to open: $e'));
    }
  }

  void _stopPcmDump() {
    _audioOutput?.pcmRecorder?.close();
    _audioOutput?.pcmRecorder = null;
  }

  void _handleSaveState(int requestId) {
    final data = _nes?.state?.serialize();

    if (data != null) {
      log.emulator.info('State saved', context: {'bytes': data.length});
    }

    send(
      SaveStateResponse(
        requestId: requestId,
        state: data == null ? null : NesBytes.fromList([data]),
      ),
    );
  }

  void _handleLoadState(NesBytes state) {
    final nes = _nes;

    if (nes == null) {
      return;
    }

    try {
      final bytes = state.materialize().asUint8List();

      nes.state = NESState.fromBytes(bytes);

      log.emulator.info('State loaded', context: {'bytes': bytes.length});
    } on Object catch (e) {
      log.emulator.error('Failed to load state', error: e);

      send(ErrorEvent(message: 'Failed to load state: $e'));
    }
  }

  void _handleLoadSram(NesBytes sram) {
    final nes = _nes;

    if (nes == null) {
      return;
    }

    try {
      nes.load(sram.materialize().asUint8List());
    } on Object catch (e) {
      log.emulator.error('Failed to load SRAM', error: e);

      send(ErrorEvent(message: 'Failed to load SRAM: $e'));
    }
  }

  void _handleSaveSram(int requestId) {
    final data = _nes?.save();

    send(
      SramResponse(
        requestId: requestId,
        sram: data == null ? null : NesBytes.fromList([data]),
      ),
    );
  }

  void _handleThumbnail(int requestId) {
    final nes = _nes;

    if (nes == null) {
      return;
    }

    final frameBuffer = nes.ppu.frameBuffer;

    final pixels = Uint8List.fromList(frameBuffer.presentedPixels);

    send(
      ThumbnailResponse(
        requestId: requestId,
        pixels: NesBytes.fromList([pixels]),
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
        ppuMemory: NesBytes.fromList([memory]),
        ppuCtrl: nes.ppu.PPUCTRL,
        v: nes.ppu.v,
        t: nes.ppu.t,
        x: nes.ppu.x,
      ),
    );
  }

  /// Ensures each optional backend matches its enable flag for the current
  /// `_nes` . Backends already bound to the current NES are left in place so
  /// toggling one flag doesn't recreate the others.
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

    if (nes == null || !_apuDebugEnabled) {
      _apuDebug?.dispose();
      _apuDebug = null;
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
          DebuggerEvent(state: state, cpuMemory: NesBytes.fromList([memory])),
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

    if (_apuDebugEnabled) {
      _apuDebug ??= ApuDebugBackend(
        nes: nes,
        eventBus: eventBus,
        onEvent: send,
      );
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

  // the single bool parameter mirrors the protocol command it backs
  // ignore: avoid_positional_boolean_parameters
  void _setApuDebugEnabled(bool enabled) {
    _apuDebugEnabled = enabled;

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
