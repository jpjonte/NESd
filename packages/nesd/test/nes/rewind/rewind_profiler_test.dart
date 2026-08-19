import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_sink.dart';
import 'package:nesd/nes/rewind/rewind_profiler.dart';

class _RecordingSink extends LogSink {
  _RecordingSink(this.records);

  final List<LogRecord> records;

  @override
  void add(LogRecord record) => records.add(record);
}

void main() {
  late List<LogRecord> logged;

  setUp(() {
    logged = [];

    NesdLog.install(NesdLog(sinks: [_RecordingSink(logged)]));
  });

  tearDown(() async {
    await NesdLog.instance.close();

    NesdLog.install(NesdLog());
  });

  test('prints one wire line per 60 captures with accumulated stages', () {
    final profiler = RewindProfiler();

    for (var i = 0; i < 60; i++) {
      profiler
        ..addCapture(10)
        ..addSerialize(20)
        ..addDiff(30)
        ..addCompress(40);
    }

    expect(logged, hasLength(1));
    // 60 captures but 59 stage cycles: _print() fires inside the 60th
    // addCapture, BEFORE that iteration's addSerialize/addDiff/
    // addCompress run — mirroring production, where stages trail their
    // capture via the deferred microtask. 59*20/59*30/59*40.
    expect(
      logged.single.message,
      'NESD_REWIND_PROF frames=60 cap_us=600 ser_us=1180 '
      'diff_us=1770 comp_us=2360',
    );
  });

  test('window resets after printing', () {
    final profiler = RewindProfiler();

    for (var i = 0; i < 120; i++) {
      profiler.addCapture(1);
    }

    expect(logged, hasLength(2));
    expect(
      logged.last.message,
      startsWith('NESD_REWIND_PROF frames=60 cap_us=60 '),
    );
  });

  test('maybeRewindProfiler is null without the dart-define', () {
    // The test binary is built without NESD_REWIND_PROF.
    expect(maybeRewindProfiler(), isNull);
  });
}
