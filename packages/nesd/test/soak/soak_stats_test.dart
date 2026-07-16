import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/soak/soak_stats.dart';

AudioStatsEvent _sample({int exhaust = 0, int full = 0, int fillMin = 1200}) {
  return AudioStatsEvent(
    timestampMilliseconds: 0,
    exhaustDelta: exhaust,
    fullDelta: full,
    fillMin: fillMin,
    fillMax: 2400,
  );
}

void main() {
  test('empty timeline produces a zero summary', () {
    final summary = SoakSummary.fromSamples(
      rom: 'smb3.nes',
      seconds: 600,
      samples: const [],
    );

    expect(summary.exhaustTotal, 0);
    expect(summary.exhaustEpisodes, 0);
    expect(summary.fillMin, 0);
    expect(
      summary.logLine,
      'NESD_SOAK rom=smb3.nes seconds=600 exhaust_total=0 '
      'exhaust_episodes=0 full_total=0 fill_min=0',
    );
  });

  test('consecutive nonzero seconds form one episode', () {
    final summary = SoakSummary.fromSamples(
      rom: 'a.nes',
      seconds: 5,
      samples: [
        _sample(),
        _sample(exhaust: 2),
        _sample(exhaust: 1),
        _sample(),
        _sample(exhaust: 3),
      ],
    );

    expect(summary.exhaustTotal, 6);
    expect(summary.exhaustEpisodes, 2);
  });

  test('tracks full total and overall fill minimum', () {
    final summary = SoakSummary.fromSamples(
      rom: 'a.nes',
      seconds: 3,
      samples: [
        _sample(fillMin: 900),
        _sample(full: 1, fillMin: 60),
        _sample(fillMin: 1100),
      ],
    );

    expect(summary.fullTotal, 1);
    expect(summary.fillMin, 60);
  });
}
