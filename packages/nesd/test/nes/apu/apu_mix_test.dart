import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/apu_mix.dart';
import 'package:nesd/nes/apu/mixer_settings.dart';
import 'package:nesd/nes/apu/tables.dart';

double _mix({
  int pulse1 = 0,
  int pulse2 = 0,
  int triangle = 0,
  int noise = 0,
  int dmc = 0,
  double expansion = 0,
  MixerSettings mixer = const MixerSettings(),
}) => mixSample(
  pulse1: pulse1,
  pulse2: pulse2,
  triangle: triangle,
  noise: noise,
  dmc: dmc,
  expansion: expansion,
  mixer: mixer,
);

void main() {
  group('pulseMix', () {
    test('reproduces every pulseTable entry exactly', () {
      for (var i = 0; i < pulseTable.length; i++) {
        expect(pulseMix(i.toDouble()), pulseTable[i], reason: 'index $i');
      }
    });

    test('follows the real curve between table entries, not a chord', () {
      final chord = pulseTable[0] + (pulseTable[1] - pulseTable[0]) * 0.5;
      final value = pulseMix(0.5);

      expect(value, greaterThan(pulseTable[0]));
      expect(value, lessThan(pulseTable[1]));

      expect(value, greaterThan(chord));
    });

    test('is silent at zero', () {
      expect(pulseMix(0), 0.0);
    });
  });

  group('tndMix', () {
    test('reproduces every tndTable entry exactly', () {
      for (var i = 0; i < tndTable.length; i++) {
        expect(tndMix(i.toDouble()), tndTable[i], reason: 'index $i');
      }
    });

    test('follows the real curve between table entries, not a chord', () {
      final chord = tndTable[0] + (tndTable[1] - tndTable[0]) * 0.5;
      final value = tndMix(0.5);

      expect(value, greaterThan(tndTable[0]));
      expect(value, lessThan(tndTable[1]));
      expect(value, greaterThan(chord));
    });

    test('is silent at zero', () {
      expect(tndMix(0), 0.0);
    });
  });

  group('mixSample', () {
    test('at unity gain matches the table lookups it replaces', () {
      for (final (p1, p2, tri, noi, d) in const [
        (0, 0, 0, 0, 0),
        (15, 15, 15, 15, 127),
        (7, 3, 11, 2, 64),
        (1, 0, 0, 0, 1),
        (0, 9, 4, 15, 90),
      ]) {
        expect(
          _mix(pulse1: p1, pulse2: p2, triangle: tri, noise: noi, dmc: d),
          pulseTable[p1 + p2] + tndTable[3 * tri + 2 * noi + d],
          reason: 'pulse $p1/$p2 tnd $tri/$noi/$d',
        );
      }
    });

    test('a muted channel contributes exactly as if it were idle', () {
      const loud = MixerSettings();

      expect(
        _mix(
          pulse1: 12,
          pulse2: 9,
          mixer: const MixerSettings(pulse1: 0),
        ),
        _mix(pulse2: 9, mixer: loud),
      );

      expect(
        _mix(
          triangle: 15,
          noise: 7,
          dmc: 40,
          mixer: const MixerSettings(triangle: 0),
        ),
        _mix(noise: 7, dmc: 40, mixer: loud),
      );

      expect(
        _mix(triangle: 4, dmc: 90, mixer: const MixerSettings(dmc: 0)),
        _mix(triangle: 4, mixer: loud),
      );
    });

    test('muting the triangle leaves noise and DMC audible', () {
      final muted = _mix(
        triangle: 15,
        noise: 7,
        dmc: 40,
        mixer: const MixerSettings(triangle: 0),
      );

      expect(muted, greaterThan(0));
      expect(muted, lessThan(_mix(triangle: 15, noise: 7, dmc: 40)));
      expect(muted, greaterThan(tndTable[2 * 7 + 40] * 0.99));
    });

    test('a partial gain lands between muted and full', () {
      final half = _mix(pulse1: 10, mixer: const MixerSettings(pulse1: 0.5));

      expect(half, greaterThan(_mix(mixer: const MixerSettings(pulse1: 0))));
      expect(half, lessThan(_mix(pulse1: 10)));
      expect(half, pulseMix(5));
    });

    test('gains scale each pulse channel independently', () {
      expect(
        _mix(
          pulse1: 8,
          pulse2: 4,
          mixer: const MixerSettings(pulse1: 0.5, pulse2: 0.25),
        ),
        pulseMix(8 * 0.5 + 4 * 0.25),
      );
    });

    test('expansion audio is added already gained', () {
      expect(_mix(expansion: 0.25), 0.25);
      expect(_mix(dmc: 20, expansion: 0.25), tndTable[20] + 0.25);
    });
  });

  test('both curves keep rising past the end of their tables', () {
    expect(pulseMix(60), greaterThan(pulseTable.last));
    expect(tndMix(400), greaterThan(tndTable.last));
  });
}
