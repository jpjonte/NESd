import 'package:nesd/log/log_record.dart';

abstract class LogSink {
  const LogSink();

  bool get emitsAtOriginOnly => false;

  void add(LogRecord record);

  Future<void> close() async {}
}
