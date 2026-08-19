import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/sink/log_buffer_sink.dart';

LogRecord _record(String message) => LogRecord(
  time: DateTime(2026, 8, 18),
  level: LogLevel.info,
  channel: LogChannel.app,
  message: message,
);

LogRecord _telemetry(String message) => LogRecord(
  time: DateTime(2026, 8, 18),
  level: LogLevel.info,
  channel: LogChannel.telemetry,
  message: message,
);

void main() {
  test('keeps records in arrival order', () {
    final sink = LogBufferSink()
      ..add(_record('one'))
      ..add(_record('two'));

    expect(sink.records.map((r) => r.message), ['one', 'two']);
  });

  test('evicts the oldest records past capacity', () {
    final sink = LogBufferSink(capacity: 3);

    for (var i = 0; i < 5; i++) {
      sink.add(_record('$i'));
    }

    expect(sink.records.map((r) => r.message), ['2', '3', '4']);
  });

  test('telemetry beyond its quota evicts the oldest telemetry', () {
    final sink = LogBufferSink(telemetryCapacity: 2)
      ..add(_record('normal one'))
      ..add(_telemetry('t0'))
      ..add(_telemetry('t1'))
      ..add(_telemetry('t2'))
      ..add(_record('normal two'));

    expect(sink.records.map((r) => r.message), [
      'normal one',
      't1',
      't2',
      'normal two',
    ]);
  });

  test('normal records still evict normally at total capacity', () {
    final sink = LogBufferSink(capacity: 3, telemetryCapacity: 10)
      ..add(_record('h1'))
      ..add(_telemetry('t1'))
      ..add(_record('h2'))
      ..add(_telemetry('t2'));

    expect(sink.records.map((r) => r.message), ['t1', 'h2', 't2']);
  });

  test('preserves chronological order across telemetry and capacity '
      'evictions', () {
    final sink = LogBufferSink(capacity: 4, telemetryCapacity: 2)
      ..add(_record('h1'))
      ..add(_telemetry('t1'))
      ..add(_telemetry('t2'))
      ..add(_record('h2'))
      ..add(_telemetry('t3'))
      ..add(_record('h3'));

    expect(sink.records.map((r) => r.message), ['t2', 'h2', 't3', 'h3']);
  });

  test(
    'notifies listeners after add and clear, once the caller yields',
    () async {
      var notifications = 0;

      final sink = LogBufferSink()..addListener(() => notifications++);

      // ignore: cascade_invocations
      sink.add(_record('one'));

      expect(notifications, 0);

      await Future<void>.delayed(Duration.zero);

      expect(notifications, 1);

      sink.clear();

      await Future<void>.delayed(Duration.zero);

      expect(notifications, 2);
      expect(sink.records, isEmpty);
    },
  );

  test('coalesces a burst of records into a single notification', () async {
    var notifications = 0;

    final sink = LogBufferSink()..addListener(() => notifications++);

    for (var i = 0; i < 5; i++) {
      sink.add(_record('$i'));
    }

    await Future<void>.delayed(Duration.zero);

    expect(notifications, 1);
  });

  test('exposes an unmodifiable view', () {
    final sink = LogBufferSink()..add(_record('one'));

    expect(() => sink.records.add(_record('two')), throwsUnsupportedError);
  });
}
