import 'package:flutter/foundation.dart';
import 'package:nesd/log/log_channel.dart';
import 'package:nesd/log/log_level.dart';

@immutable
class LogRecord {
  const LogRecord({
    required this.time,
    required this.level,
    required this.channel,
    required this.message,
    this.context,
    this.error,
    this.stackTrace,
    this.isolate,
  });

  final DateTime time;
  final LogLevel level;
  final LogChannel channel;
  final String message;

  /// [context] values must be JSON-encodable primitives (num, String, bool,
  /// null, or lists/maps of those) so they can be sent across an isolate
  /// port.
  final Map<String, Object?>? context;
  final String? error;
  final String? stackTrace;

  final String? isolate;

  bool get hasDetails => context != null || error != null || stackTrace != null;
}
