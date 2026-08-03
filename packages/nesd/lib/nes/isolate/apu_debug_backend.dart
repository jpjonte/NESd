import 'dart:async';
import 'dart:typed_data';

import 'package:nesd/nes/apu/channel/pulse_channel_core.dart';
import 'package:nesd/nes/apu/expansion/mmc5_audio.dart';
import 'package:nesd/nes/apu/expansion/namco163_audio.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/isolate/apu_debug_state.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/nes.dart';

/// Isolate-side producer for the APU debug visualizer.
///
/// Enables the APU's per-channel capture for its lifetime and snapshots
/// the frame's sample slices and channel parameters into one
/// [ApuDebugEvent] per emulated frame.
///
/// Frames that carry no real samples are skipped:
/// fast-forward outputs an empty sample list, and during rewind the
/// frame's samples run backwards while the capture buffers do not. The
/// panel holds its last frame across both.
class ApuDebugBackend {
  ApuDebugBackend({
    required this.nes,
    required this.eventBus,
    required this.onEvent,
  }) {
    _subscription = eventBus.stream.listen(_handleEvent);

    nes.apu.debugSamplingEnabled = true;
  }

  final NES nes;
  final EventBus eventBus;
  final void Function(ApuDebugEvent event) onEvent;

  late final StreamSubscription<NesEvent> _subscription;

  void dispose() {
    nes.apu.debugSamplingEnabled = false;

    _subscription.cancel();
  }

  void _handleEvent(NesEvent event) {
    if (event is! FrameNesEvent) {
      return;
    }

    // `_sendFrame` zeroes `apu.sampleIndex` before the event is sent, so the
    // sample count must be retrieved from the event and not the APU buffer.
    final sampleCount = event.samples.length;

    if (sampleCount == 0 || nes.rewind) {
      return;
    }

    final channels = nes.apu.channelSamples;

    // Unreachable while this backend is alive. It owns the flag, set in the
    // constructor and cleared only in `dispose`.
    assert(channels != null, 'capture disabled while the backend is live');

    if (channels == null) {
      return;
    }

    // The event's samples already have volume applied, so read directly from
    // the APU.
    final apu = nes.apu;
    final mix = Float32List.sublistView(apu.sampleBuffer, 0, sampleCount);
    final triangle = apu.triangle;
    final noise = apu.noise;
    final dmc = apu.dmc;

    final expansion = apu.expansionAudio;

    final mmc5 = expansion is Mmc5Audio
        ? Mmc5DebugState(
            pulse1: _pulseState(expansion.pulse1),
            pulse2: _pulseState(expansion.pulse2),
            pcmLevel: expansion.pcmLevel,
          )
        : null;

    final n163 = expansion is Namco163Audio
        ? Namco163DebugState(
            enabledChannels: expansion.enabledChannels,
            channels: List.generate(
              expansion.enabledChannels,
              (i) => Namco163ChannelDebugState(
                volume: expansion.volumeOf(7 - i),
                waveLength: expansion.waveLengthOf(7 - i),
                frequency: expansion.frequencyOf(7 - i),
              ),
              growable: false,
            ),
          )
        : null;

    onEvent(
      ApuDebugEvent.pack(
        channels: channels,
        mix: mix,
        sampleCount: sampleCount,
        pulse1: _pulseState(apu.pulse1),
        pulse2: _pulseState(apu.pulse2),
        triangle: TriangleDebugState(
          enabled: triangle.enabled,
          timerPeriod: triangle.timerPeriod,
          linearCounter: triangle.linearCounter,
          lengthCounter: triangle.lengthCounter.value,
        ),
        noise: NoiseDebugState(
          enabled: noise.enabled,
          volume: noise.constantVolume ? noise.volume : noise.envelope.volume,
          mode: noise.mode,
          timerPeriod: noise.timerPeriod,
        ),
        dmc: DmcDebugState(
          enabled: dmc.enabled,
          level: dmc.level,
          rate: dmc.rate,
          bytesRemaining: dmc.length,
        ),
        mmc5: mmc5,
        n163: n163,
        cpuFrequency: apu.cpuFrequency,
      ),
    );
  }

  PulseDebugState _pulseState(PulseChannelCore pulse) => PulseDebugState(
    enabled: pulse.enabled,
    duty: pulse.duty,
    volume: pulse.constantVolume ? pulse.volume : pulse.envelope.volume,
    timerPeriod: pulse.timerPeriod,
  );
}
