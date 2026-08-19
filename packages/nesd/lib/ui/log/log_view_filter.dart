import 'package:nesd/log/log.dart';

/// Selects the records the log viewer should show, newest first.
///
/// A record survives only if it clears [level] *and* sits on a selected
/// channel — both conditions, not either. Selecting no channels yields
/// nothing, which the viewer renders as its empty state.
///
/// The newest-first ordering is what pairs with the viewer's
/// `reverse: true` list to pin the newest row to the bottom; dropping
/// either half silently inverts the display.
List<LogRecord> filterLogRecords(
  Iterable<LogRecord> records, {
  required LogLevel level,
  required Set<LogChannel> channels,
}) => [
  for (final record in records)
    if (record.level.index >= level.index && channels.contains(record.channel))
      record,
].reversed.toList();
