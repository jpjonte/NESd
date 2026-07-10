import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cheat/cheat.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/emulator/cartridge_info.dart';
import 'package:nesd/ui/emulator/frame_source.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';

/// UI-side proxy for a running emulator isolate.
///
/// Mirrors the worker's status (`running`/`paused`/`fastForward`/`rewind`)
/// from [StatusEvent]s, forwards fire-and-forget commands, and resolves
/// request/response round trips (save state, SRAM, thumbnail, tile debug)
/// by matching `requestId`s. Frames arrive as [FrameEvent]s and are handed
/// to [frameSource].
///
/// Holds exactly one subscription on [NesIsolateHandle.events] for its
/// entire lifetime, from construction until [dispose].
class RemoteNes {
  RemoteNes({
    // named `isolate` for the public constructor surface; stored in the
    // differently-named `_isolate` field below, so this can't be an
    // initializing formal.
    required NesIsolateHandle isolate,
    required this.romInfo,
    required this.fileHash,
    required this.hasZapper,
    required this.cartridgeInfo,
    this.requestTimeout = const Duration(seconds: 5),
    // ignore: prefer_initializing_formals
  }) : _isolate = isolate {
    frameSource = RemoteFrameSource(sendCommand: _isolate.send);

    _subscription = _isolate.events.listen(_handleEvent);
  }

  final RomInfo romInfo;
  final String fileHash;
  final bool hasZapper;
  final CartridgeInfo cartridgeInfo;
  final Duration requestTimeout;

  late final RemoteFrameSource frameSource;

  final NesIsolateHandle _isolate;

  late final StreamSubscription<NesIsolateEvent> _subscription;

  // Status mirrors are written only by [_handleEvent]'s StatusEvent case;
  // reads go through the getters below. `running`/`paused` are read-only
  // mirrors (nothing on the UI side assigns them). `fastForward`/`rewind`
  // additionally expose setters that forward the change to the worker.
  bool _running = false;
  bool _paused = false;
  bool _fastForward = false;
  bool _rewind = false;

  bool get running => _running;

  bool get paused => _paused;

  bool get fastForward => _fastForward;

  bool get rewind => _rewind;

  /// Forwards a hold-mode fast-forward change to the worker. The mirror is
  /// updated optimistically so an immediate read reflects the request; the
  /// next [StatusEvent] confirms (or corrects) it.
  set fastForward(bool enabled) {
    _fastForward = enabled;

    _send(SetFastForwardCommand(enabled: enabled));
  }

  /// Forwards a hold-mode rewind change to the worker. Optimistically
  /// mirrored like [fastForward]; the worker's plain assignment does not
  /// gate on `rewindEnabled`, so the next [StatusEvent] is authoritative.
  set rewind(bool enabled) {
    _rewind = enabled;

    _send(SetRewindCommand(enabled: enabled));
  }

  /// Last position sent via [setZapperPosition], as a listenable so the
  /// crosshair painter repaints without a widget rebuild (rebuilds no
  /// longer happen per frame). Deliberately never disposed: a swapped-out
  /// painter may still be subscribed during teardown, and a plain
  /// ValueNotifier holds no resources.
  final ValueNotifier<Offset?> zapperPosition = ValueNotifier<Offset?>(null);

  static int _nextRequestId = 0;
  final Map<int, Completer<NesIsolateEvent>> _pending = {};

  Stream<NesIsolateEvent> get events => _isolate.events;

  void _send(NesCommand command) => _isolate.send(command);

  void buttonDown(int controller, NesButton button) =>
      _send(ButtonDownCommand(controller: controller, button: button));

  void buttonUp(int controller, NesButton button) =>
      _send(ButtonUpCommand(controller: controller, button: button));

  void buttonToggle(int controller, NesButton button) =>
      _send(ButtonToggleCommand(controller: controller, button: button));

  void pause() => _send(const PauseCommand());

  void unpause() => _send(const UnpauseCommand());

  void togglePause() => _send(const TogglePauseCommand());

  void suspend() => _send(const SuspendCommand());

  void resume() => _send(const ResumeCommand());

  void reset() => _send(const ResetCommand());

  void toggleFastForward() => _send(const ToggleFastForwardCommand());

  void toggleRewind() => _send(const ToggleRewindCommand());

  void stepInto() => _send(const StepIntoCommand());

  void stepOver() => _send(const StepOverCommand());

  void stepOut() => _send(const StepOutCommand());

  void runUntilFrame() => _send(const RunUntilFrameCommand());

  // write-only mirrors of worker-side state; no getter to keep in sync
  // ignore: avoid_setters_without_getters
  set rewindEnabled(bool enabled) =>
      _send(SetRewindEnabledCommand(enabled: enabled));

  // ignore: avoid_setters_without_getters
  set region(Region? region) => _send(SetRegionCommand(region: region));

  // ignore: avoid_setters_without_getters
  set cheats(List<Cheat> cheats) => _send(SetCheatsCommand(cheats: cheats));

  // ignore: avoid_setters_without_getters
  set volume(double volume) => _send(SetVolumeCommand(volume: volume));

  void startPcmDump(String path) => _send(StartPcmDumpCommand(path: path));

  void stopPcmDump() => _send(const StopPcmDumpCommand());

  // ignore: avoid_setters_without_getters
  set breakpoints(List<Breakpoint> breakpoints) =>
      _send(SetBreakpointsCommand(breakpoints: breakpoints));

  void addBreakpoint(Breakpoint breakpoint) =>
      _send(AddBreakpointCommand(breakpoint: breakpoint));

  void removeBreakpoint(int address) =>
      _send(RemoveBreakpointCommand(address: address));

  // the single bool parameter mirrors the protocol command it backs
  // ignore: avoid_positional_boolean_parameters
  void setDebuggerActive(bool active) =>
      _send(SetDebuggerActiveCommand(active: active));

  // the single bool parameter mirrors the protocol command it backs
  // ignore: avoid_positional_boolean_parameters
  void setExecutionLogEnabled(bool enabled) =>
      _send(SetExecutionLogEnabledCommand(enabled: enabled));

  void setZapperPosition(Offset? position) {
    zapperPosition.value = position;

    _send(SetZapperPositionCommand(x: position?.dx, y: position?.dy));
  }

  void zapperPull() => _send(const ZapperPullCommand());

  void zapperRelease() => _send(const ZapperReleaseCommand());

  void loadState(Uint8List bytes) =>
      _send(LoadStateCommand(state: TransferableTypedData.fromList([bytes])));

  void loadSram(Uint8List bytes) =>
      _send(LoadSramCommand(sram: TransferableTypedData.fromList([bytes])));

  Future<Uint8List?> requestSaveState() async {
    final response = await _request<SaveStateResponse>(
      (requestId) => SaveStateRequest(requestId: requestId),
    );

    return response?.state?.materialize().asUint8List();
  }

  Future<Uint8List?> requestSram() async {
    final response = await _request<SramResponse>(
      (requestId) => SaveSramRequest(requestId: requestId),
    );

    return response?.sram?.materialize().asUint8List();
  }

  Future<({Uint8List pixels, int width, int height})?>
  requestThumbnail() async {
    final response = await _request<ThumbnailResponse>(
      (requestId) => ThumbnailRequest(requestId: requestId),
    );

    if (response == null) {
      return null;
    }

    return (
      pixels: response.pixels.materialize().asUint8List(),
      width: response.width,
      height: response.height,
    );
  }

  Future<TileDebugResponse?> requestTileDebug() => _request<TileDebugResponse>(
    (requestId) => TileDebugRequest(requestId: requestId),
  );

  Future<void> stop() async {
    _send(const StopCommand());

    // A missing StoppedEvent (worker/isolate already gone) must not hang
    // the UI's quit path forever, so this wait is bounded.
    await events
        .firstWhere((event) => event is StoppedEvent)
        .timeout(requestTimeout, onTimeout: StoppedEvent.new);
  }

  void dispose() {
    // Release any frame still held by the source so the worker doesn't pin
    // its native buffer when we're torn down without a preceding stop().
    frameSource.clear();

    unawaited(_subscription.cancel());
  }

  Future<T?> _request<T extends NesIsolateEvent>(
    NesCommand Function(int requestId) build,
  ) async {
    final requestId = _nextRequestId++;
    final completer = Completer<NesIsolateEvent>();

    _pending[requestId] = completer;

    _send(build(requestId));

    try {
      return await completer.future.timeout(requestTimeout) as T;
    } on TimeoutException {
      return null;
    } finally {
      _pending.remove(requestId);
    }
  }

  void _handleEvent(NesIsolateEvent event) {
    switch (event) {
      case StatusEvent():
        _running = event.running;
        _paused = event.paused;
        _fastForward = event.fastForward;
        _rewind = event.rewind;
      case FrameEvent():
        frameSource.addFrame(event);
      case RomLoadedEvent() || StoppedEvent():
        frameSource.clear();
      case SaveStateResponse(:final requestId):
        _complete(requestId, event);
      case SramResponse(:final requestId):
        _complete(requestId, event);
      case ThumbnailResponse(:final requestId):
        _complete(requestId, event);
      case TileDebugResponse(:final requestId):
        _complete(requestId, event);
      default:
        break;
    }
  }

  void _complete(int requestId, NesIsolateEvent event) {
    _pending.remove(requestId)?.complete(event);
  }
}
