import 'package:nesd/nes/apu/apu.dart';

typedef AudioBufferStatus = ({int fill, int capacity});

typedef AudioFillProbe = AudioBufferStatus? Function();

/// Computes the per-frame sleep so that sample production locks to actual
/// audio consumption.
///
/// Stateless proportional controller: the audio buffer fill level is the
/// integral of production minus consumption, so no internal accumulator is
/// needed. Above [drainThresholdRatio] the sleep switches to a deterministic
/// drain so the native buffer can never overflow (which would force sample
/// drops).
class PacingGovernor {
  const PacingGovernor({
    this.sampleRate = apuSampleRate,
    this.gain = 0.1,
    this.setpointRatio = 0.5,
    this.setpointSamples,
    this.drainThresholdRatio = 0.85,
    this.maxSleep = const Duration(milliseconds: 50),
  });

  final int sampleRate;
  final double gain;
  final double setpointRatio;
  final int? setpointSamples;

  final double drainThresholdRatio;
  final Duration maxSleep;

  PacingGovernor copyWith({int? setpointSamples}) => PacingGovernor(
    sampleRate: sampleRate,
    gain: gain,
    setpointRatio: setpointRatio,
    setpointSamples: setpointSamples ?? this.setpointSamples,
    drainThresholdRatio: drainThresholdRatio,
    maxSleep: maxSleep,
  );

  Duration sleepFor({
    required int samplesProduced,
    required Duration elapsed,
    AudioBufferStatus? audio,
  }) {
    final targetMicros =
        samplesProduced * Duration.microsecondsPerSecond / sampleRate;

    var sleepMicros = targetMicros - elapsed.inMicroseconds;

    if (audio != null && audio.capacity > 0) {
      final setpoint =
          setpointSamples?.toDouble() ?? audio.capacity * setpointRatio;
      final error = audio.fill - setpoint;
      final drainThreshold = audio.capacity * drainThresholdRatio;

      if (audio.fill >= drainThreshold) {
        sleepMicros = error * Duration.microsecondsPerSecond / sampleRate;
      } else {
        sleepMicros +=
            gain * error * Duration.microsecondsPerSecond / sampleRate;
      }
    }

    final clampedMicros = sleepMicros.clamp(
      0.0,
      maxSleep.inMicroseconds.toDouble(),
    );

    return Duration(microseconds: clampedMicros.round());
  }
}
