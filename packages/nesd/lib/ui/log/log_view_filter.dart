import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/log/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_view_filter.freezed.dart';
part 'log_view_filter.g.dart';

@freezed
sealed class LogViewFilterState with _$LogViewFilterState {
  const factory LogViewFilterState({
    required Set<LogChannel> channels,
    @Default(LogLevel.debug) LogLevel level,
    @Default('') String search,
  }) = _LogViewFilterState;
}

@Riverpod(keepAlive: true)
class LogViewFilter extends _$LogViewFilter {
  @override
  LogViewFilterState build() =>
      LogViewFilterState(channels: LogChannel.values.toSet());

  LogLevel get level => state.level;

  set level(LogLevel value) => state = state.copyWith(level: value);

  Set<LogChannel> get channels => state.channels;

  set channels(Set<LogChannel> value) =>
      state = state.copyWith(channels: value);

  String get search => state.search;

  set search(String value) => state = state.copyWith(search: value);
}

/// Selects the records the log viewer should show, newest first.
///
/// A record survives only if it clears [level] *and* sits on a selected
/// channel *and* matches [search] — all conditions, not any. Selecting no
/// channels yields nothing, which the viewer renders as its empty state.
///
/// [search] is a case-insensitive substring match against the message and
/// the error text; empty means unconstrained.
///
/// The newest-first ordering is what pairs with the viewer's
/// `reverse: true` list to pin the newest row to the bottom; dropping
/// either half silently inverts the display.
List<LogRecord> filterLogRecords(
  Iterable<LogRecord> records, {
  required LogLevel level,
  required Set<LogChannel> channels,
  String search = '',
}) {
  final needle = search.toLowerCase();

  return [
    for (final record in records)
      if (record.level.index >= level.index &&
          channels.contains(record.channel) &&
          _matchesSearch(record, needle))
        record,
  ].reversed.toList();
}

bool _matchesSearch(LogRecord record, String needle) =>
    needle.isEmpty ||
    record.message.toLowerCase().contains(needle) ||
    (record.error?.toLowerCase().contains(needle) ?? false);
