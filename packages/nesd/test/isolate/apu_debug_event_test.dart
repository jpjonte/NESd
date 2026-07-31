import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/apu_channel_samples.dart';
import 'package:nesd/nes/isolate/apu_debug_state.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';

const _pulse = PulseDebugState(
  enabled: true,
  duty: 2,
  volume: 12,
  timerPeriod: 253,
);

const _triangle = TriangleDebugState(
  enabled: true,
  timerPeriod: 126,
  linearCounter: 10,
  lengthCounter: 20,
);

const _noise = NoiseDebugState(
  enabled: true,
  volume: 8,
  mode: true,
  timerPeriod: 30,
);

const _dmc = DmcDebugState(
  enabled: false,
  level: 64,
  rate: 428,
  bytesRemaining: 17,
);

/// Fills each lane with a distinct constant so a swapped or shifted lane
/// is unambiguous, and gives every lane a different trailing value so a
/// wrong offset within a lane shows up too.
ApuChannelSamples _channels({required int capacity, required int count}) {
  final channels = ApuChannelSamples(capacity);

  final lanes = [
    channels.pulse1,
    channels.pulse2,
    channels.triangle,
    channels.noise,
    channels.dmc,
  ];

  for (var lane = 0; lane < lanes.length; lane++) {
    for (var i = 0; i < capacity; i++) {
      lanes[lane][i] = i < count ? 10 * (lane + 1) + i : 0xff;
    }
  }

  return channels;
}

ApuDebugEvent _pack({required int capacity, required int count}) =>
    ApuDebugEvent.pack(
      channels: _channels(capacity: capacity, count: count),
      mix: Float32List.fromList(List.generate(count, (i) => i / count)),
      sampleCount: count,
      pulse1: _pulse,
      pulse2: _pulse,
      triangle: _triangle,
      noise: _noise,
      dmc: _dmc,
      cpuFrequency: 1789773,
    );

void main() {
  group('ApuDebugEvent pack/unpack round trip', () {
    test('each lane survives in its own slot', () {
      final samples = _pack(capacity: 8, count: 3).unpackSamples();

      expect(samples.pulse1, [10, 11, 12]);
      expect(samples.pulse2, [20, 21, 22]);
      expect(samples.triangle, [30, 31, 32]);
      expect(samples.noise, [40, 41, 42]);
      expect(samples.dmc, [50, 51, 52]);
    });

    test('packs only the live prefix, not the whole capacity', () {
      final samples = _pack(capacity: 64, count: 3).unpackSamples();

      // 0xff marks stale entries past sampleCount; none may be shipped.
      expect(samples.pulse1, hasLength(3));
      expect(samples.dmc, isNot(contains(0xff)));
    });

    test('mix round-trips at full length', () {
      final samples = _pack(capacity: 8, count: 4).unpackSamples();

      expect(samples.mix, hasLength(4));
      expect(samples.mix[0], closeTo(0, 1e-6));
      expect(samples.mix[3], closeTo(0.75, 1e-6));
    });

    test('payload is exactly channelCount * sampleCount bytes', () {
      final event = _pack(capacity: 8, count: 3);

      expect(
        event.channelSamples.materialize().asUint8List(),
        hasLength(ApuDebugEvent.channelCount * 3),
      );
    });
  });
}
