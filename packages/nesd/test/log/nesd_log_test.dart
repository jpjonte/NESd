import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_sink.dart';

class _RecordingSink extends LogSink {
  _RecordingSink({this.originOnly = false});

  final bool originOnly;

  final List<LogRecord> records = [];

  @override
  bool get emitsAtOriginOnly => originOnly;

  @override
  void add(LogRecord record) => records.add(record);
}

class _ThrowingSink extends LogSink {
  @override
  void add(LogRecord record) => throw StateError('sink failure');
}

void main() {
  test('records below the minimum level are dropped', () {
    final sink = _RecordingSink();
    final log = NesdLog(sinks: [sink], minimumLevel: LogLevel.warning);

    log.rom
      ..debug('dropped')
      ..info('dropped')
      ..warning('kept')
      ..error('kept');

    expect(sink.records.map((r) => r.message), ['kept', 'kept']);
  });

  test('telemetry bypasses the minimum level', () {
    final sink = _RecordingSink();
    final log = NesdLog(sinks: [sink], minimumLevel: LogLevel.error);

    log.telemetry.emit('NESD_AUDIO ts=1');

    expect(sink.records, hasLength(1));
    expect(sink.records.single.channel, LogChannel.telemetry);
    expect(sink.records.single.message, 'NESD_AUDIO ts=1');
  });

  test('records carry channel, context, error and isolate tag', () {
    final sink = _RecordingSink();
    final log = NesdLog(
      sinks: [sink],
      minimumLevel: LogLevel.debug,
      isolate: 'ui',
    );

    log.input.warning(
      'gamepad lookup failed',
      context: {'index': 2},
      error: StateError('boom'),
      stackTrace: StackTrace.fromString('#0 frame'),
    );

    final record = sink.records.single;

    expect(record.channel, LogChannel.input);
    expect(record.level, LogLevel.warning);
    expect(record.context, {'index': 2});
    expect(record.error, contains('boom'));
    expect(record.stackTrace, contains('#0 frame'));
    expect(record.isolate, 'ui');
    expect(record.hasDetails, isTrue);
  });

  test('a failing sink does not stop add() reaching later sinks', () {
    final sink = _RecordingSink();
    final log = NesdLog(sinks: [_ThrowingSink(), sink]);

    expect(() => log.app.info('still delivered'), returnsNormally);

    expect(sink.records.map((r) => r.message), ['still delivered']);
  });

  test('a failing sink does not stop ingest() reaching later sinks', () {
    final sink = _RecordingSink();
    final log = NesdLog(sinks: [_ThrowingSink(), sink]);

    final record = LogRecord(
      time: DateTime(2026, 8, 18),
      level: LogLevel.info,
      channel: LogChannel.app,
      message: 'still delivered',
    );

    expect(() => log.ingest(record), returnsNormally);

    expect(sink.records, [record]);
  });

  test('ingest skips sinks that already emitted at their origin', () {
    final normal = _RecordingSink();
    final originOnly = _RecordingSink(originOnly: true);
    final log = NesdLog(sinks: [normal, originOnly]);

    // ignore: cascade_invocations
    log.ingest(
      LogRecord(
        time: DateTime(2026, 8, 18),
        level: LogLevel.info,
        channel: LogChannel.telemetry,
        message: 'NESD_AUDIO ts=1',
      ),
    );

    expect(normal.records, hasLength(1));
    expect(originOnly.records, isEmpty);
  });

  test('ingest does not re-apply minimumLevel', () {
    final sink = _RecordingSink();
    final log = NesdLog(sinks: [sink], minimumLevel: LogLevel.error);

    // ignore: cascade_invocations
    log.ingest(
      LogRecord(
        time: DateTime(2026, 8, 18),
        level: LogLevel.debug,
        channel: LogChannel.app,
        message: 'below minimumLevel, but already filtered at origin',
      ),
    );

    expect(sink.records, hasLength(1));
  });

  test('addSink replays the given records before receiving new ones', () {
    final first = _RecordingSink();
    final log = NesdLog(sinks: [first], minimumLevel: LogLevel.debug);

    log.app.info('early');

    final late = _RecordingSink();

    log.addSink(late, replay: first.records);

    log.app.info('later');

    expect(late.records.map((r) => r.message), ['early', 'later']);
  });

  test('the default instance drops everything', () {
    expect(NesdLog.instance.sinkOfType<_RecordingSink>(), isNull);

    NesdLog.instance.app.error('must not throw');
  });

  test('sinkOfType finds an installed sink', () {
    final sink = _RecordingSink();

    expect(NesdLog(sinks: [sink]).sinkOfType<_RecordingSink>(), same(sink));
  });
}
