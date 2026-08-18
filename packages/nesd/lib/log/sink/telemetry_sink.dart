import 'package:nesd/log/log_channel.dart';
import 'package:nesd/log/log_record.dart';
import 'package:nesd/log/log_sink.dart';

class TelemetrySink extends LogSink {
  TelemetrySink({void Function(String line)? write})
    : _write = write ?? _printLine;

  final void Function(String line) _write;

  @override
  bool get emitsAtOriginOnly => true;

  @override
  void add(LogRecord record) {
    if (record.channel != LogChannel.telemetry) {
      return;
    }

    _write(record.message);
  }
}

// ignore: avoid_print
void _printLine(String line) => print(line);
