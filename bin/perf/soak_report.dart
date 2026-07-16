// Soak analysis: parses a pulled NESD_AUDIO stats timeline plus the raw
// float32 PCM dump, prints exhaust-episode clustering, fill stats, PCM
// anomaly flags, converts the PCM to a listenable WAV, and prints the
// verdict row from the discriminating-test spec matrix.
//
// The episode definition (maximal run of consecutive seconds with a
// nonzero exhaust delta) must stay in sync with
// packages/nesd/lib/soak/soak_stats.dart. This file cannot import
// package:nesd (Flutter SDK dependency); it must stay plain Dart so
// `fvm dart run bin/perf/soak_report.dart` works.
//
// Usage:
//   fvm dart run bin/perf/soak_report.dart --stats <stats.log> \
//     [--pcm <audio.pcm>] --out <dir>
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class Sample {
  const Sample({
    required this.ts,
    required this.exhaust,
    required this.full,
    required this.fillMin,
    required this.fillMax,
  });

  final int ts;
  final int exhaust;
  final int full;
  final int fillMin;
  final int fillMax;
}

typedef PcmFindings = ({
  int zeroRuns,
  int clipped,
  int bigSteps,
  double maxStep,
});

const sampleRate = 48000;

final _linePattern = RegExp(
  r'NESD_AUDIO ts=(\d+) exhaust=(\d+) full=(\d+) '
  r'fill_min=(\d+) fill_max=(\d+)',
);

List<Sample> parseStatsLines(List<String> lines) {
  final samples = <Sample>[];

  for (final line in lines) {
    final match = _linePattern.firstMatch(line);

    if (match == null) {
      continue;
    }

    samples.add(
      Sample(
        ts: int.parse(match[1]!),
        exhaust: int.parse(match[2]!),
        full: int.parse(match[3]!),
        fillMin: int.parse(match[4]!),
        fillMax: int.parse(match[5]!),
      ),
    );
  }

  return samples;
}

int countEpisodes(List<Sample> samples) {
  var episodes = 0;
  var inEpisode = false;

  for (final sample in samples) {
    if (sample.exhaust > 0) {
      if (!inEpisode) {
        episodes++;
      }

      inEpisode = true;
    } else {
      inEpisode = false;
    }
  }

  return episodes;
}

PcmFindings analyzePcm(Float32List pcm) {
  var zeroRuns = 0;
  var clipped = 0;
  var bigSteps = 0;
  var maxStep = 0.0;

  const zeroRunLength = 480;
  const audibleWindow = 4800;
  const audibleLevel = 0.01;

  var runStart = -1;
  var lastAudible = -1;

  for (var i = 0; i < pcm.length; i++) {
    final value = pcm[i];

    if (value.abs() >= 0.99) {
      clipped++;
    }

    if (i > 0) {
      final step = (value - pcm[i - 1]).abs();

      maxStep = max(maxStep, step);

      if (step > 0.6) {
        bigSteps++;
      }
    }

    // Close the zero-run check BEFORE updating lastAudible: the sample
    // ending a run is often itself audible, and counting it would make
    // every run look adjacent to audio (leading silence included).
    if (value == 0.0) {
      runStart = runStart < 0 ? i : runStart;
    } else {
      if (runStart >= 0 &&
          i - runStart >= zeroRunLength &&
          lastAudible >= 0 &&
          runStart - lastAudible <= audibleWindow) {
        zeroRuns++;
      }

      runStart = -1;
    }

    if (value.abs() > audibleLevel) {
      lastAudible = i;
    }
  }

  return (
    zeroRuns: zeroRuns,
    clipped: clipped,
    bigSteps: bigSteps,
    maxStep: maxStep,
  );
}

Uint8List encodeWav(Float32List pcm) {
  final data = ByteData(44 + pcm.length * 2);

  void writeAscii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  final dataSize = pcm.length * 2;

  writeAscii(0, 'RIFF');
  data.setUint32(4, 36 + dataSize, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little); // fmt chunk size
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  data.setUint16(32, 2, Endian.little); // block align
  data.setUint16(34, 16, Endian.little); // bits per sample
  writeAscii(36, 'data');
  data.setUint32(40, dataSize, Endian.little);

  for (var i = 0; i < pcm.length; i++) {
    final clamped = pcm[i].clamp(-1.0, 1.0);

    data.setInt16(44 + i * 2, (clamped * 32767).round(), Endian.little);
  }

  return data.buffer.asUint8List();
}

String verdict({
  required int exhaustTotal,
  required int episodes,
  required PcmFindings? pcmFindings,
}) {
  if (exhaustTotal > 0) {
    return 'UNDERRUN: $exhaustTotal starved callbacks in $episodes '
        'episode(s) — pacing/jitter/headroom is the lever, NOT issue #96. '
        'Cross-check episode timing against what you heard.';
  }

  if (pcmFindings case final findings?
      when findings.zeroRuns > 0 || findings.bigSteps > 0) {
    return 'CONTENT (suspect): zero underruns but the sample stream has '
        '${findings.zeroRuns} suspicious zero-run(s) and '
        '${findings.bigSteps} large step(s) (max ${findings.maxStep}). '
        'Listen to audio.wav; if the crackle is audible there, issue #96 '
        '(resampling) is the lever. Flags are best-effort, not verdicts.';
  }

  return 'CLEAN: zero underruns and no content flags. If crackle was '
      'still audible live, the artifact is below the push point '
      '(miniaudio/HAL) — escalate to device-output capture (spec row 3).';
}

void main(List<String> args) {
  String? statsPath;
  String? pcmPath;
  String? outPath;

  for (var i = 0; i < args.length - 1; i++) {
    switch (args[i]) {
      case '--stats':
        statsPath = args[i + 1];
      case '--pcm':
        pcmPath = args[i + 1];
      case '--out':
        outPath = args[i + 1];
    }
  }

  if (statsPath == null || outPath == null) {
    stderr.writeln(
      'usage: dart run bin/perf/soak_report.dart --stats <file> '
      '[--pcm <file>] --out <dir>',
    );
    exit(64);
  }

  final samples = parseStatsLines(File(statsPath).readAsLinesSync());
  final exhaustTotal = samples.fold(0, (sum, s) => sum + s.exhaust);
  final fullTotal = samples.fold(0, (sum, s) => sum + s.full);
  final episodes = countEpisodes(samples);
  final fillMins = samples.map((s) => s.fillMin).toList()..sort();

  print('samples: ${samples.length}');
  print('exhaust_total: $exhaustTotal in $episodes episode(s)');
  print('full_total: $fullTotal (nonzero falsifies the push invariant!)');

  if (fillMins.isNotEmpty) {
    final p50 = fillMins[fillMins.length ~/ 2];

    print(
      'fill_min: min=${fillMins.first} p50=$p50 '
      '(${(fillMins.first * 1000 / sampleRate).toStringAsFixed(1)} ms '
      'worst cushion)',
    );
  }

  final affected = samples.where((s) => s.exhaust > 0).toList();

  for (final sample in affected) {
    print('  episode second ts=${sample.ts}: exhaust=${sample.exhaust}');
  }

  PcmFindings? findings;

  if (pcmPath != null) {
    final bytes = File(pcmPath).readAsBytesSync();
    final pcm = bytes.buffer.asFloat32List(0, bytes.length ~/ 4);

    findings = analyzePcm(pcm);

    print(
      'pcm: ${pcm.length} samples '
      '(${(pcm.length / sampleRate).toStringAsFixed(1)} s), '
      'zero_runs=${findings.zeroRuns} clipped=${findings.clipped} '
      'big_steps=${findings.bigSteps} max_step=${findings.maxStep}',
    );

    final wavPath = '$outPath/audio.wav';

    File(wavPath).writeAsBytesSync(encodeWav(pcm));
    print('wav: $wavPath');
  }

  print('');
  print(
    'VERDICT: ${verdict(exhaustTotal: exhaustTotal, episodes: episodes, pcmFindings: findings)}',
  );
}
