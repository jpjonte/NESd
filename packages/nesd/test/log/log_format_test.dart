import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_format.dart';

void main() {
  final time = DateTime.utc(2026, 8, 18, 14, 3, 22, 145);

  test('formats a plain record for the file', () {
    final line = formatRecordForFile(
      LogRecord(
        time: time,
        level: LogLevel.warning,
        channel: LogChannel.rom,
        message: 'ROM load failed',
        isolate: 'emulator',
      ),
    );

    expect(line, '2026-08-18T14:03:22.145Z W rom [emulator] ROM load failed');
  });

  test('appends context as compact JSON', () {
    final line = formatRecordForFile(
      LogRecord(
        time: time,
        level: LogLevel.info,
        channel: LogChannel.rom,
        message: 'ROM loaded',
        context: const {'mapper': 4, 'name': 'smb3'},
      ),
    );

    expect(line, endsWith('ROM loaded {"mapper":4,"name":"smb3"}'));
  });

  test('indents stack trace lines with a tab', () {
    final line = formatRecordForFile(
      LogRecord(
        time: time,
        level: LogLevel.error,
        channel: LogChannel.app,
        message: 'boom',
        stackTrace: '#0 first\n#1 second',
      ),
    );

    expect(line.split('\n'), [
      '2026-08-18T14:03:22.145Z E app boom',
      '\t#0 first',
      '\t#1 second',
    ]);
  });

  test('includeContext: false drops context and stack trace', () {
    final line = formatRecordForFile(
      LogRecord(
        time: time,
        level: LogLevel.error,
        channel: LogChannel.app,
        message: 'boom',
        context: const {'a': 1},
        stackTrace: '#0 first',
      ),
      includeContext: false,
    );

    expect(line, '2026-08-18T14:03:22.145Z E app boom');
  });

  test('the error string is appended after the message', () {
    final line = formatRecordForFile(
      LogRecord(
        time: time,
        level: LogLevel.error,
        channel: LogChannel.storage,
        message: 'write failed',
        error: 'FileSystemException: disk full',
      ),
    );

    expect(line, endsWith('write failed | FileSystemException: disk full'));
  });

  test('the console format leads with a local wall-clock time', () {
    final line = formatRecordForConsole(
      LogRecord(
        time: DateTime(2026, 8, 18, 14, 3, 22, 145),
        level: LogLevel.info,
        channel: LogChannel.audio,
        message: 'started',
      ),
    );

    expect(line, '14:03:22.145 I audio started');
  });
}
