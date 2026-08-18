import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:nesd/log/log_record.dart';

final _consoleTime = DateFormat('HH:mm:ss.SSS');

String formatRecordForFile(LogRecord record, {bool includeContext = true}) {
  final buffer = StringBuffer()
    ..write(record.time.toUtc().toIso8601String())
    ..write(' ')
    ..write(record.level.tag)
    ..write(' ')
    ..write(record.channel.name);

  if (record.isolate case final isolate?) {
    buffer.write(' [$isolate]');
  }

  buffer
    ..write(' ')
    ..write(record.message);

  if (record.error case final error?) {
    buffer.write(' | $error');
  }

  if (!includeContext) {
    return buffer.toString();
  }

  if (record.context case final context?) {
    buffer.write(' ${jsonEncode(context)}');
  }

  if (record.stackTrace case final stackTrace?) {
    for (final line in stackTrace.trimRight().split('\n')) {
      buffer.write('\n\t$line');
    }
  }

  return buffer.toString();
}

String formatRecordForConsole(LogRecord record) {
  final buffer = StringBuffer()
    ..write(_consoleTime.format(record.time))
    ..write(' ')
    ..write(record.level.tag)
    ..write(' ')
    ..write(record.channel.name)
    ..write(' ')
    ..write(record.message);

  if (record.error case final error?) {
    buffer.write(' | $error');
  }

  if (record.context case final context?) {
    buffer.write(' ${jsonEncode(context)}');
  }

  if (record.stackTrace case final stackTrace?) {
    buffer.write('\n$stackTrace');
  }

  return buffer.toString();
}
