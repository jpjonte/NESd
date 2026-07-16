import 'dart:isolate';

import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/nes/debugger/execution_log_state.dart';

sealed class NesIsolateEvent {
  const NesIsolateEvent();
}

class IsolateReadyEvent extends NesIsolateEvent {
  const IsolateReadyEvent({required this.commandPort});

  final SendPort commandPort;
}

class RomLoadedEvent extends NesIsolateEvent {
  const RomLoadedEvent({required this.hasZapper});

  final bool hasZapper;
}

class RomLoadFailedEvent extends NesIsolateEvent {
  const RomLoadFailedEvent({required this.message});

  final String message;
}

class FrameEvent extends NesIsolateEvent {
  const FrameEvent({
    required this.pointerAddress,
    required this.width,
    required this.height,
    required this.frameTimeMicroseconds,
    required this.sleepTimeMicroseconds,
    required this.frame,
    required this.rewindSize,
  });

  final int pointerAddress;
  final int width;
  final int height;
  final int frameTimeMicroseconds;
  final int sleepTimeMicroseconds;
  final int frame;
  final int rewindSize;
}

class StatusEvent extends NesIsolateEvent {
  const StatusEvent({
    required this.running,
    required this.paused,
    required this.fastForward,
    required this.rewind,
  });

  final bool running;
  final bool paused;
  final bool fastForward;
  final bool rewind;
}

/// Once-per-second audio-path health sample from the worker. `logLine`
/// is the on-device wire format scraped by bin/perf tooling — treat it
/// as a stable format.
class AudioStatsEvent extends NesIsolateEvent {
  const AudioStatsEvent({
    required this.timestampMilliseconds,
    required this.exhaustDelta,
    required this.fullDelta,
    required this.fillMin,
    required this.fillMax,
  });

  final int timestampMilliseconds;
  final int exhaustDelta;
  final int fullDelta;
  final int fillMin;
  final int fillMax;

  String get logLine =>
      'NESD_AUDIO ts=$timestampMilliseconds exhaust=$exhaustDelta '
      'full=$fullDelta fill_min=$fillMin fill_max=$fillMax';
}

class ErrorEvent extends NesIsolateEvent {
  const ErrorEvent({required this.message});

  final String message;
}

class DebuggerEvent extends NesIsolateEvent {
  const DebuggerEvent({required this.state, required this.cpuMemory});

  final DebuggerState state;
  final TransferableTypedData cpuMemory;
}

class ExecutionLogEvent extends NesIsolateEvent {
  const ExecutionLogEvent({required this.lines});

  final List<ExecutionLogLine> lines;
}

class BreakpointsEvent extends NesIsolateEvent {
  const BreakpointsEvent({required this.fileHash, required this.breakpoints});

  final String fileHash;
  final List<Breakpoint> breakpoints;
}

class SaveStateResponse extends NesIsolateEvent {
  const SaveStateResponse({required this.requestId, required this.state});

  final int requestId;
  final TransferableTypedData? state;
}

class SramResponse extends NesIsolateEvent {
  const SramResponse({required this.requestId, required this.sram});

  final int requestId;
  final TransferableTypedData? sram;
}

class ThumbnailResponse extends NesIsolateEvent {
  const ThumbnailResponse({
    required this.requestId,
    required this.pixels,
    required this.width,
    required this.height,
  });

  final int requestId;
  final TransferableTypedData pixels;
  final int width;
  final int height;
}

class TileDebugResponse extends NesIsolateEvent {
  const TileDebugResponse({
    required this.requestId,
    required this.ppuMemory,
    required this.ppuCtrl,
    required this.v,
    required this.t,
    required this.x,
  });

  final int requestId;
  final TransferableTypedData ppuMemory;
  final int ppuCtrl;
  final int v;
  final int t;
  final int x;
}

class StoppedEvent extends NesIsolateEvent {
  const StoppedEvent();
}
