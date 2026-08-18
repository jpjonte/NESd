import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_sink.dart';
import 'package:nesd/log/sink/rotating_file_sink.dart';
import 'package:path/path.dart' as p;

LogRecord _record(String message) => LogRecord(
  time: DateTime.utc(2026, 8, 18, 14, 3, 22, 145),
  level: LogLevel.info,
  channel: LogChannel.app,
  message: message,
);

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('nesd-log-test');
  });

  tearDown(() => directory.deleteSync(recursive: true));

  test('creates the directory and writes one line per record', () {
    final logs = p.join(directory.path, 'logs');
    final sink = RotatingFileSink(directory: logs)
      ..add(_record('one'))
      ..add(_record('two'));

    unawaited(sink.close());

    final lines = File(p.join(logs, 'nesd.log')).readAsLinesSync();

    expect(lines, hasLength(2));
    expect(lines.first, endsWith('one'));
    expect(lines.last, endsWith('two'));
  });

  test('rotates to nesd.log.1 once past maxBytes', () {
    final sink = RotatingFileSink(directory: directory.path, maxBytes: 120);

    for (var i = 0; i < 10; i++) {
      sink.add(_record('record $i'));
    }

    unawaited(sink.close());

    expect(File(p.join(directory.path, 'nesd.log')).existsSync(), isTrue);
    expect(File(p.join(directory.path, 'nesd.log.1')).existsSync(), isTrue);
  });

  test('keeps only one previous generation', () {
    final sink = RotatingFileSink(directory: directory.path, maxBytes: 60);

    for (var i = 0; i < 30; i++) {
      sink.add(_record('record $i'));
    }

    unawaited(sink.close());

    final files = directory.listSync().map((e) => p.basename(e.path)).toList()
      ..sort();

    expect(files, ['nesd.log', 'nesd.log.1']);
  });

  test('appends to an existing file rather than truncating it', () {
    File(
      p.join(directory.path, 'nesd.log'),
    ).writeAsStringSync('existing line\n');

    final sink = RotatingFileSink(directory: directory.path)
      ..add(_record('new'));

    unawaited(sink.close());

    final lines = File(p.join(directory.path, 'nesd.log')).readAsLinesSync();

    expect(lines.first, 'existing line');
    expect(lines.last, endsWith('new'));
  });

  test('rotates on the very first add when the existing file is already '
      'past maxBytes', () {
    File(p.join(directory.path, 'nesd.log')).writeAsStringSync('x' * 100);

    final sink = RotatingFileSink(directory: directory.path, maxBytes: 60)
      ..add(_record('new'));

    unawaited(sink.close());

    final previousContent = File(
      p.join(directory.path, 'nesd.log.1'),
    ).readAsStringSync();

    expect(previousContent, 'x' * 100);

    final lines = File(p.join(directory.path, 'nesd.log')).readAsLinesSync();

    expect(lines, hasLength(1));
    expect(lines.single, endsWith('new'));
  });

  test('disables itself and reports once when the path is unusable', () {
    final blocker = p.join(directory.path, 'logs');

    File(blocker).writeAsStringSync('not a directory');

    final reported = <LogRecord>[];

    NesdLog.install(
      NesdLog(sinks: [_CollectingSink(reported)], minimumLevel: LogLevel.debug),
    );

    addTearDown(() => NesdLog.install(NesdLog()));

    final sink = RotatingFileSink(directory: blocker)
      ..add(_record('one'))
      ..add(_record('two'));

    expect(sink.disabled, isTrue);
    expect(reported, hasLength(1));
    expect(reported.single.level, LogLevel.error);
    expect(reported.single.message, contains('Log file disabled'));
  });
}

class _CollectingSink extends LogSink {
  _CollectingSink(this.records);

  final List<LogRecord> records;

  @override
  void add(LogRecord record) => records.add(record);
}
