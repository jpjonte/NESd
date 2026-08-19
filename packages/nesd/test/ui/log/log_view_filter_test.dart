import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/log/log_view_filter.dart';

LogRecord _record({
  required String message,
  LogLevel level = LogLevel.info,
  LogChannel channel = LogChannel.app,
}) => LogRecord(
  time: DateTime(2026, 8, 18, 14, 3, 22, 145),
  level: level,
  channel: channel,
  message: message,
);

void main() {
  final everyChannel = LogChannel.values.toSet();

  test('drops records below the minimum level', () {
    final filtered = filterLogRecords(
      [
        _record(message: 'debug', level: LogLevel.debug),
        _record(message: 'warning', level: LogLevel.warning),
        _record(message: 'error', level: LogLevel.error),
      ],
      level: LogLevel.warning,
      channels: everyChannel,
    );

    expect(
      filtered.map((r) => r.message),
      containsAll(<String>['warning', 'error']),
    );
    expect(filtered.map((r) => r.message), isNot(contains('debug')));
  });

  test('drops records on unselected channels', () {
    final filtered = filterLogRecords(
      [
        _record(message: 'rom', channel: LogChannel.rom),
        _record(message: 'audio', channel: LogChannel.audio),
      ],
      level: LogLevel.debug,
      channels: {LogChannel.rom},
    );

    expect(filtered.map((r) => r.message), ['rom']);
  });

  test('applies both filters together, not one or the other', () {
    final filtered = filterLogRecords(
      [
        _record(message: 'right channel wrong level', channel: LogChannel.rom),
        _record(
          message: 'wrong channel right level',
          channel: LogChannel.audio,
          level: LogLevel.error,
        ),
        _record(
          message: 'both right',
          channel: LogChannel.rom,
          level: LogLevel.error,
        ),
      ],
      level: LogLevel.error,
      channels: {LogChannel.rom},
    );

    expect(filtered.map((r) => r.message), ['both right']);
  });

  test('returns newest first', () {
    final filtered = filterLogRecords(
      [_record(message: 'older'), _record(message: 'newer')],
      level: LogLevel.debug,
      channels: everyChannel,
    );

    expect(
      filtered.map((r) => r.message),
      ['newer', 'older'],
      reason:
          'the viewer renders this list into a reverse: true ListView, '
          'so newest-first here is what puts the newest row at the bottom',
    );
  });

  test('selecting no channels yields nothing', () {
    final filtered = filterLogRecords(
      [_record(message: 'rom', channel: LogChannel.rom)],
      level: LogLevel.debug,
      channels: const {},
    );

    expect(filtered, isEmpty);
  });
}
