import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/sink/console_sink.dart';
import 'package:nesd/log/sink/telemetry_sink.dart';

void main() {
  late List<String> written;
  late TelemetrySink sink;

  setUp(() {
    written = [];
    sink = TelemetrySink(write: written.add);
  });

  const bench =
      'NESD_BENCH rom=smb frames=240 median_us=1000 p90_us=1200 '
      'flatout_fps=61.0';
  const audio = 'NESD_AUDIO ts=100 exhaust=2 full=0 fill_min=240 fill_max=2000';
  const soak =
      'NESD_SOAK rom=smb seconds=600 exhaust_total=0 exhaust_episodes=0 '
      'full_total=0 fill_min=240';
  const soakFailed = 'NESD_SOAK_FAILED audio underrun';
  const pcmError = 'NESD_PCM_ERROR FileSystemException: disk full';
  const rewindProf =
      'NESD_REWIND_PROF frames=60 cap_us=1000 ser_us=200 diff_us=300 '
      'comp_us=400';

  const wireFormats = [bench, audio, soak, soakFailed, pcmError, rewindProf];

  for (final line in wireFormats) {
    test('emits "${line.split(' ').first}" verbatim, with no prefix', () {
      NesdLog(sinks: [sink], minimumLevel: LogLevel.error).telemetry.emit(line);

      expect(written, [line]);
    });
  }

  test('ignores records on every other channel', () {
    final log = NesdLog(sinks: [sink], minimumLevel: LogLevel.debug);

    for (final channel in LogChannel.values) {
      if (channel == LogChannel.telemetry) {
        continue;
      }

      log.add(
        LogRecord(
          time: DateTime(2026, 8, 18),
          level: LogLevel.error,
          channel: channel,
          message: 'human message',
        ),
      );
    }

    expect(written, isEmpty);
  });

  test('is flagged so ingest does not re-emit forwarded records', () {
    expect(sink.emitsAtOriginOnly, isTrue);
  });

  test('the console sink refuses telemetry records', () {
    final console = <String>[];

    NesdLog(
        sinks: [ConsoleSink(write: console.add)],
        minimumLevel: LogLevel.debug,
      )
      ..telemetry.emit('NESD_AUDIO ts=1')
      ..app.info('human message');

    expect(console, hasLength(1));
    expect(console.single, endsWith('human message'));
  });
}
