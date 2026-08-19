/// Severity of a `LogRecord`, ordered from least to most severe.
///
/// There is deliberately no `trace` level: instruction-level tracing is
/// served by the execution log (`lib/nes/debugger/execution_log.dart`).
enum LogLevel {
  debug('D', 'Debug'),
  info('I', 'Info'),
  warning('W', 'Warning'),
  error('E', 'Error');

  const LogLevel(this.tag, this.label);

  /// Single-character marker used by the log file format.
  final String tag;

  /// Human-readable name shown in the viewer's filter.
  final String label;
}
