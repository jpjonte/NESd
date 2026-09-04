import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:nesd/log/log_record.dart';
import 'package:nesd/nes/apu/apu_channel_samples.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/nes/debugger/execution_log_state.dart';
import 'package:nesd/nes/isolate/apu_debug_state.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';

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

sealed class FramePixels {
  const FramePixels();
}

/// The frame lives at [address] in the worker's native memory.
class PointerFramePixels extends FramePixels {
  const PointerFramePixels({required this.address});

  final int address;
}

class InlineFramePixels extends FramePixels {
  const InlineFramePixels({required this.bytes});

  final Uint8List bytes;
}

class FrameEvent extends NesIsolateEvent {
  const FrameEvent({
    required this.frameHandle,
    required this.pixels,
    required this.width,
    required this.height,
    required this.frameTimeMicroseconds,
    required this.sleepTimeMicroseconds,
    required this.frame,
    required this.rewindSize,
  });

  final int frameHandle;

  final FramePixels pixels;

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
    required this.scrubbing,
  });

  final bool running;
  final bool paused;
  final bool fastForward;
  final bool rewind;
  final bool scrubbing;
}

class RewindScrubBeganResponse extends NesIsolateEvent {
  const RewindScrubBeganResponse({
    required this.requestId,
    required this.available,
    required this.oldestSequence,
    required this.newestSequence,
    required this.captureInterval,
    required this.frameRate,
    required this.thumbnailSequences,
    required this.thumbnails,
    required this.thumbnailWidth,
    required this.thumbnailHeight,
  });

  final int requestId;

  final bool available;

  final int oldestSequence;
  final int newestSequence;
  final int captureInterval;
  final int frameRate;

  final List<int> thumbnailSequences;

  final NesBytes thumbnails;
  final int thumbnailWidth;
  final int thumbnailHeight;
}

class RewindScrubPositionEvent extends NesIsolateEvent {
  const RewindScrubPositionEvent({
    required this.sequence,
    required this.settled,
  });

  final int sequence;

  final bool settled;
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
    required this.popMax,
  });

  final int timestampMilliseconds;
  final int exhaustDelta;
  final int fullDelta;
  final int fillMin;
  final int fillMax;
  final int popMax;

  String get logLine =>
      'NESD_AUDIO ts=$timestampMilliseconds exhaust=$exhaustDelta '
      'full=$fullDelta fill_min=$fillMin fill_max=$fillMax '
      'pop_max=$popMax';
}

class ErrorEvent extends NesIsolateEvent {
  const ErrorEvent({required this.message, this.stackTrace});

  factory ErrorEvent.from(Object error, StackTrace stackTrace) =>
      ErrorEvent(message: '$error', stackTrace: '$stackTrace');

  final String message;
  final String? stackTrace;
}

class DebuggerEvent extends NesIsolateEvent {
  const DebuggerEvent({required this.state, required this.cpuMemory});

  final DebuggerState state;
  final NesBytes cpuMemory;
}

class ExecutionLogEvent extends NesIsolateEvent {
  const ExecutionLogEvent({required this.lines});

  final List<ExecutionLogLine> lines;
}

/// The per-channel sample views carried by one [ApuDebugEvent], sliced
/// out of its single packed payload by [ApuDebugEvent.unpackSamples].
@immutable
class ApuDebugSamples {
  const ApuDebugSamples({
    required this.pulse1,
    required this.pulse2,
    required this.triangle,
    required this.noise,
    required this.dmc,
    required this.expansion,
    required this.mix,
  });

  /// Channel lanes, each `sampleCount` long. Values are raw channel
  /// outputs, not normalized.
  final Uint8List pulse1;
  final Uint8List pulse2;
  final Uint8List triangle;
  final Uint8List noise;
  final Uint8List dmc;

  final List<Uint8List> expansion;

  /// The mixed output, pre-volume, in the range 0-1.
  final Float32List mix;
}

class ApuDebugEvent extends NesIsolateEvent {
  const ApuDebugEvent({
    required this.channelSamples,
    required this.mixSamples,
    required this.sampleCount,
    required this.pulse1,
    required this.pulse2,
    required this.triangle,
    required this.noise,
    required this.dmc,
    required this.expansionLaneCount,
    required this.mmc5,
    required this.n163,
    required this.cpuFrequency,
  });

  /// Packs the first [sampleCount] entries of [channels] and [mix] into
  /// one transferable payload, in [_channelOrder].
  ///
  /// This is the only place the layout is written, [unpackSamples] is the
  /// only place it is read. Keep the two in step.
  factory ApuDebugEvent.pack({
    required ApuChannelSamples channels,
    required Float32List mix,
    required int sampleCount,
    required PulseDebugState pulse1,
    required PulseDebugState pulse2,
    required TriangleDebugState triangle,
    required NoiseDebugState noise,
    required DmcDebugState dmc,
    required Mmc5DebugState? mmc5,
    required Namco163DebugState? n163,
    required int cpuFrequency,
  }) {
    assert(sampleCount > 0, 'sampleCount must be positive');
    assert(
      mix.length == sampleCount,
      'mix has ${mix.length} samples, expected $sampleCount',
    );
    assert(
      channels.length >= sampleCount,
      'channel buffers hold ${channels.length}, need $sampleCount',
    );

    final lanes = _channelOrder(channels);
    final packed = Uint8List(lanes.length * sampleCount);

    for (var i = 0; i < lanes.length; i++) {
      packed.setRange(i * sampleCount, (i + 1) * sampleCount, lanes[i]);
    }

    return ApuDebugEvent(
      channelSamples: NesBytes.fromList([packed]),
      mixSamples: NesBytes.fromList([mix]),
      sampleCount: sampleCount,
      pulse1: pulse1,
      pulse2: pulse2,
      triangle: triangle,
      noise: noise,
      dmc: dmc,
      expansionLaneCount: channels.expansion.length,
      mmc5: mmc5,
      n163: n163,
      cpuFrequency: cpuFrequency,
    );
  }

  /// The packing order. Both halves of the protocol derive their offsets
  /// from this list, so reordering it moves the sender and the receiver
  /// together.
  static List<Uint8List> _channelOrder(ApuChannelSamples channels) => [
    channels.pulse1,
    channels.pulse2,
    channels.triangle,
    channels.noise,
    channels.dmc,
    ...channels.expansion,
  ];

  static const builtinChannelCount = 5;

  final int expansionLaneCount;

  int get channelCount => builtinChannelCount + expansionLaneCount;

  /// Materializes the payload and slices it back into per-channel views.
  ApuDebugSamples unpackSamples() {
    final bytes = channelSamples.materialize().asUint8List();
    final mix = mixSamples.materialize().asFloat32List();

    if (bytes.length != channelCount * sampleCount ||
        mix.length != sampleCount) {
      throw StateError(
        'APU debug payload does not match sampleCount=$sampleCount: '
        'channel bytes=${bytes.length} '
        '(expected ${channelCount * sampleCount}), '
        'mix=${mix.length} (expected $sampleCount)',
      );
    }

    Uint8List lane(int index) => Uint8List.sublistView(
      bytes,
      index * sampleCount,
      (index + 1) * sampleCount,
    );

    return ApuDebugSamples(
      pulse1: lane(0),
      pulse2: lane(1),
      triangle: lane(2),
      noise: lane(3),
      dmc: lane(4),
      expansion: List.generate(
        expansionLaneCount,
        (i) => lane(builtinChannelCount + i),
        growable: false,
      ),
      mix: mix,
    );
  }

  /// [channelCount] `sampleCount`-byte lanes packed back to back; see
  /// [ApuDebugEvent.pack] for the order.
  final NesBytes channelSamples;

  /// The frame's mixed samples as float32 bytes, pre-volume. Exactly
  /// [sampleCount] floats, unlike [channelSamples] the receiver has no
  /// separate length to slice against.
  final NesBytes mixSamples;

  final int sampleCount;

  final PulseDebugState pulse1;
  final PulseDebugState pulse2;
  final TriangleDebugState triangle;
  final NoiseDebugState noise;
  final DmcDebugState dmc;

  final Mmc5DebugState? mmc5;

  final Namco163DebugState? n163;

  /// CPU frequency in Hz for the active region, for deriving channel
  /// frequencies UI-side.
  final int cpuFrequency;
}

class BreakpointsEvent extends NesIsolateEvent {
  const BreakpointsEvent({required this.fileHash, required this.breakpoints});

  final String fileHash;
  final List<Breakpoint> breakpoints;
}

class SaveStateResponse extends NesIsolateEvent {
  const SaveStateResponse({required this.requestId, required this.state});

  final int requestId;
  final NesBytes? state;
}

class SramResponse extends NesIsolateEvent {
  const SramResponse({required this.requestId, required this.sram});

  final int requestId;
  final NesBytes? sram;
}

class ThumbnailResponse extends NesIsolateEvent {
  const ThumbnailResponse({
    required this.requestId,
    required this.pixels,
    required this.width,
    required this.height,
  });

  final int requestId;
  final NesBytes pixels;
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
  final NesBytes ppuMemory;
  final int ppuCtrl;
  final int v;
  final int t;
  final int x;
}

class StoppedEvent extends NesIsolateEvent {
  const StoppedEvent();
}

class LogEvent extends NesIsolateEvent {
  const LogEvent({required this.record});

  final LogRecord record;
}
