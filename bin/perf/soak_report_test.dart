// Analyzer tests for the soak report tool. Run from the repo root:
//   fvm flutter test bin/perf/soak_report_test.dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'soak_report.dart';

void main() {
  test('parses NESD_AUDIO lines and ignores noise', () {
    final samples = parseStatsLines([
      'some unrelated logcat line',
      'NESD_AUDIO ts=100 exhaust=2 full=0 fill_min=240 fill_max=2000',
      'NESD_AUDIO ts=1100 exhaust=0 full=1 fill_min=900 fill_max=2200',
    ]);

    expect(samples, hasLength(2));
    expect(samples.first.ts, 100);
    expect(samples.first.exhaust, 2);
    expect(samples.last.full, 1);
    expect(samples.last.fillMin, 900);
  });

  test('counts episodes as maximal nonzero runs', () {
    final samples = parseStatsLines([
      'NESD_AUDIO ts=0 exhaust=1 full=0 fill_min=0 fill_max=1',
      'NESD_AUDIO ts=1 exhaust=2 full=0 fill_min=0 fill_max=1',
      'NESD_AUDIO ts=2 exhaust=0 full=0 fill_min=0 fill_max=1',
      'NESD_AUDIO ts=3 exhaust=1 full=0 fill_min=0 fill_max=1',
    ]);

    expect(countEpisodes(samples), 2);
  });

  test('flags zero runs adjacent to non-silent audio', () {
    final pcm = Float32List(48000);

    // 0.5 s of tone, then 20 ms of exact silence, then tone again.
    for (var i = 0; i < 24000; i++) {
      pcm[i] = 0.2;
    }

    for (var i = 24960; i < 48000; i++) {
      pcm[i] = 0.2;
    }

    final findings = analyzePcm(pcm);

    expect(findings.zeroRuns, 1);
  });

  test('does not flag leading silence', () {
    final pcm = Float32List(48000);

    for (var i = 24000; i < 48000; i++) {
      pcm[i] = 0.2;
    }

    expect(analyzePcm(pcm).zeroRuns, 0);
  });

  test('flags clipping and large steps', () {
    final pcm = Float32List.fromList([0.0, 0.05, 0.995, 0.05, 0.0]);

    final findings = analyzePcm(pcm);

    expect(findings.clipped, 1);
    expect(findings.bigSteps, greaterThan(0));
  });

  test('writes a well-formed 16-bit WAV header', () {
    final wav = encodeWav(Float32List.fromList([0.0, 0.5, -0.5]));

    expect(wav.length, 44 + 6);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');

    final data = ByteData.sublistView(wav);

    expect(data.getUint32(24, Endian.little), 48000); // sample rate
    expect(data.getUint16(34, Endian.little), 16); // bits per sample
    expect(data.getUint32(40, Endian.little), 6); // data size
    expect(data.getInt16(44, Endian.little), 0);
    // (0.5 * 32767).round() rounds half away from zero -> 16384
    expect(data.getInt16(46, Endian.little), 16384);
  });

  test('verdict follows the spec matrix', () {
    expect(
      verdict(exhaustTotal: 5, episodes: 2, pcmFindings: null),
      startsWith('UNDERRUN'),
    );
    expect(
      verdict(
        exhaustTotal: 0,
        episodes: 0,
        pcmFindings: (zeroRuns: 1, clipped: 0, bigSteps: 0, maxStep: 0.7),
      ),
      startsWith('CONTENT'),
    );
    expect(
      verdict(
        exhaustTotal: 0,
        episodes: 0,
        pcmFindings: (zeroRuns: 0, clipped: 0, bigSteps: 0, maxStep: 0.1),
      ),
      startsWith('CLEAN'),
    );
  });
}
