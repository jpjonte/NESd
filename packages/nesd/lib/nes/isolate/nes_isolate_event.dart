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
    required this.sleepBudgetMicroseconds,
    required this.frame,
    required this.rewindSize,
  });

  final int pointerAddress;
  final int width;
  final int height;
  final int frameTimeMicroseconds;
  final int sleepBudgetMicroseconds;
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
