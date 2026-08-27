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

/// Renders [record] as one row in the log viewer: local wall-clock time,
/// level tag, channel and message.
///
/// Deliberately carries no error, context or stack trace — those live in
/// the row's expandable detail section, rendered by [formatRecordDetails].
String formatRecordForViewer(LogRecord record) =>
    '${formatRecordTimeForViewer(record)} ${record.level.tag} '
    '${record.channel.name} ${record.message}';

/// Renders the expandable detail section for [record]: its error, its
/// pretty-printed JSON context and its stack trace, in that order,
/// omitting whichever the record does not carry.
///
/// Returns an empty string for a record with no details, which is the
/// same condition as `LogRecord.hasDetails` being false.
String formatRecordDetails(LogRecord record) => [
  if (record.error case final error?) error,
  if (record.context case final context?) _prettyJson.convert(context),
  if (record.stackTrace case final stackTrace?) stackTrace,
].join('\n');

/// Renders [record] for the dev console: the viewer row, plus the detail
/// tail appended inline.
///
/// Built from [formatRecordForViewer] so the two cannot drift apart.
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
