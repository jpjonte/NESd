import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/apu_debug_state.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/apu_debug/apu_debug_data.dart';

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

ApuDebugEvent _event() {
  const count = 4;

  final packed = Uint8List.fromList(List.generate(5 * count, (i) => i));
  final mix = Float32List.fromList([0.1, 0.2, 0.3, 0.4]);

  return ApuDebugEvent(
    channelSamples: TransferableTypedData.fromList([packed]),
    mixSamples: TransferableTypedData.fromList([mix]),
    sampleCount: count,
    pulse1: _pulse,
    pulse2: _pulse,
    triangle: _triangle,
    noise: _noise,
    dmc: _dmc,
    expansionLaneCount: 0,
    mmc5: null,
    cpuFrequency: 1789773,
  );
}

ApuDebugEvent _eventWith({
  required int sampleCount,
  required int packedLength,
  required int mixLength,
}) {
  final packed = Uint8List(packedLength);
  final mix = Float32List(mixLength);

  return ApuDebugEvent(
    channelSamples: TransferableTypedData.fromList([packed]),
    mixSamples: TransferableTypedData.fromList([mix]),
    sampleCount: sampleCount,
    pulse1: _pulse,
    pulse2: _pulse,
    triangle: _triangle,
    noise: _noise,
    dmc: _dmc,
    expansionLaneCount: 0,
    mmc5: null,
    cpuFrequency: 1789773,
  );
}

void main() {
  group('ApuDebugData.fromEvent', () {
    test('splits the packed channel samples in channel order', () {
      final data = ApuDebugData.fromEvent(_event());

      expect(data.pulse1Samples, [0, 1, 2, 3]);
      expect(data.pulse2Samples, [4, 5, 6, 7]);
      expect(data.triangleSamples, [8, 9, 10, 11]);
      expect(data.noiseSamples, [12, 13, 14, 15]);
      expect(data.dmcSamples, [16, 17, 18, 19]);
    });

    test('materializes the mixed samples', () {
      final data = ApuDebugData.fromEvent(_event());

      expect(data.mixSamples, hasLength(4));
      expect(data.mixSamples[0], closeTo(0.1, 1e-6));
      expect(data.mixSamples[3], closeTo(0.4, 1e-6));
    });

    test('rejects a channel payload that is not 5 * sampleCount bytes', () {
      expect(
        () => ApuDebugData.fromEvent(
          _eventWith(sampleCount: 4, packedLength: 19, mixLength: 4),
        ),
        throwsA(
          isStateError.having(
            (e) => e.message,
            'message',
            allOf(contains('19'), contains('20')),
          ),
        ),
      );
    });

    test('rejects a mix payload that is not sampleCount floats', () {
      expect(
        () => ApuDebugData.fromEvent(
          _eventWith(sampleCount: 4, packedLength: 20, mixLength: 3),
        ),
        throwsA(
          isStateError.having((e) => e.message, 'message', contains('mix')),
        ),
      );
    });
  });

  group('frequencies', () {
    test('pulseFrequency follows cpu / (16 * (t + 1))', () {
      final data = ApuDebugData.fromEvent(_event());

      // 1789773 / (16 * 254) = 440.4
      expect(data.pulseFrequency(data.pulse1), closeTo(440.4, 0.05));
    });

    test('triangleFrequency follows cpu / (32 * (t + 1))', () {
      final data = ApuDebugData.fromEvent(_event());

      // 1789773 / (32 * 127) = 440.4
      expect(data.triangleFrequency, closeTo(440.4, 0.05));
    });
  });

  group('noteName', () {
    test('maps 440 Hz to A-4', () {
      expect(noteName(440), 'A-4');
    });

    test('maps middle C to C-4', () {
      expect(noteName(261.63), 'C-4');
    });

    test('maps 466.16 Hz to A#4', () {
      expect(noteName(466.16), 'A#4');
    });

    test('returns --- for non-positive frequencies', () {
      expect(noteName(0), '---');
      expect(noteName(-5), '---');
    });

    test('returns --- outside the MIDI range', () {
      expect(noteName(30000), '---');
      expect(noteName(0.001), '---');
    });

    test('returns --- for non-finite frequencies', () {
      expect(noteName(double.infinity), '---');
      expect(noteName(double.nan), '---');
    });
  });

  group('labels', () {
    test('dutyLabel maps the duty selector to a percentage', () {
      final data = ApuDebugData.fromEvent(_event());

      expect(data.dutyLabel(data.pulse1), '50%');
    });

    test('dutyLabel shows the raw value when duty is out of range', () {
      final data = ApuDebugData.fromEvent(_event());

      expect(
        data.dutyLabel(
          const PulseDebugState(
            enabled: true,
            duty: 200,
            volume: 0,
            timerPeriod: 0,
          ),
        ),
        '?200',
      );
    });

    test('noiseModeLabel maps mode to short/long', () {
      final data = ApuDebugData.fromEvent(_event());

      expect(data.noiseModeLabel, 'short');
    });
  });
}
