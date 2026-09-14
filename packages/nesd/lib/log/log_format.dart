import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:nesd/log/log_record.dart';

final _consoleTime = DateFormat('HH:mm:ss.SSS');

const _prettyJson = JsonEncoder.withIndent('  ');

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

String formatRecordsForExport(
  Iterable<LogRecord> records, {
  required bool includeContext,
}) => records
    .map((r) => formatRecordForFile(r, includeContext: includeContext))
    .join('\n');

String formatRecordTimeForViewer(LogRecord record) =>
    _consoleTime.format(record.time);

String formatRecordForViewer(LogRecord record) =>
    '${formatRecordTimeForViewer(record)} ${record.level.tag} '
    '${record.channel.name} ${record.message}';

String formatRecordDetails(LogRecord record) => [
  ?record.error,
  if (record.context case final context?) _prettyJson.convert(context),
  ?record.stackTrace,
].join('\n');

String formatRecordForConsole(LogRecord record) {
  final buffer = StringBuffer(formatRecordForViewer(record));

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
