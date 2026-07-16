import 'package:nesd/nes/isolate/nes_isolate_event.dart';

/// Aggregate of a soak run's per-second [AudioStatsEvent] timeline.
class SoakSummary {
  const SoakSummary({
    required this.rom,
    required this.seconds,
    required this.exhaustTotal,
    required this.exhaustEpisodes,
    required this.fullTotal,
    required this.fillMin,
  });

  /// An episode is a maximal run of consecutive samples with a nonzero
  /// exhaust delta. bin/perf/soak_report.dart reimplements this
  /// definition host-side (it cannot import package:nesd) and is the
  /// authoritative analysis; keep both in sync.
  factory SoakSummary.fromSamples({
    required String rom,
    required int seconds,
    required List<AudioStatsEvent> samples,
  }) {
    var exhaustTotal = 0;
    var fullTotal = 0;
    var episodes = 0;
    var inEpisode = false;
    int? fillMin;

    for (final sample in samples) {
      exhaustTotal += sample.exhaustDelta;
      fullTotal += sample.fullDelta;

      if (sample.exhaustDelta > 0) {
        if (!inEpisode) {
          episodes++;
        }

        inEpisode = true;
      } else {
        inEpisode = false;
      }

      if (fillMin == null || sample.fillMin < fillMin) {
        fillMin = sample.fillMin;
      }
    }

    return SoakSummary(
      rom: rom,
      seconds: seconds,
      exhaustTotal: exhaustTotal,
      exhaustEpisodes: episodes,
      fullTotal: fullTotal,
      fillMin: fillMin ?? 0,
    );
  }

  final String rom;
  final int seconds;
  final int exhaustTotal;
  final int exhaustEpisodes;
  final int fullTotal;
  final int fillMin;

  String get logLine =>
      'NESD_SOAK rom=$rom seconds=$seconds exhaust_total=$exhaustTotal '
      'exhaust_episodes=$exhaustEpisodes full_total=$fullTotal '
      'fill_min=$fillMin';
}
