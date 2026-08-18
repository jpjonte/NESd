import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_format.dart';

final _stamp = DateFormat('yyyyMMdd-HHmmss');

/// Filename for an exported log, stamped with [now].
///
/// Timestamped so it cannot be confused with the execution log's plain
/// `nesd.log` when a bug report carries both.
String logExportFileName(DateTime now) => 'nesd-log-${_stamp.format(now)}.log';

/// The log viewer's side-effecting actions: putting records on the
/// clipboard and writing them out to a file.
///
/// A class rather than free functions so tests can substitute a fake for
/// the clipboard and the file picker, neither of which is reachable from
/// a unit test.
class LogActions {
  const LogActions();

  /// Copies a single [record] in the log file's own line format.
  Future<void> copyRecord(LogRecord record) =>
      Clipboard.setData(ClipboardData(text: formatRecordForFile(record)));

  /// Copies [records] oldest-first, matching the log file's order.
  Future<void> copyRecords(
    Iterable<LogRecord> records, {
    required bool includeContext,
  }) => Clipboard.setData(
    ClipboardData(
      text: formatRecordsForExport(records, includeContext: includeContext),
    ),
  );

  /// Writes [records] out through the platform's save dialog, oldest
  /// first. Returns the chosen destination, or null if the user
  /// cancelled.
  Future<Uri?> exportRecords(
    Iterable<LogRecord> records, {
    required bool includeContext,
  }) => FilePicker.saveFile(
    bytes: utf8.encode(
      formatRecordsForExport(records, includeContext: includeContext),
    ),
    fileName: logExportFileName(DateTime.now()),
    type: FileType.custom,
    allowedExtensions: ['log', 'txt'],
  );
}

final logActionsProvider = Provider<LogActions>((ref) => const LogActions());
