import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nesd/log/log_channel.dart';
import 'package:nesd/log/log_format.dart';
import 'package:nesd/log/log_record.dart';
import 'package:nesd/log/log_sink.dart';

bool get consoleLoggingEnabled => kDebugMode || appFlavor == 'dev';

class ConsoleSink extends LogSink {
  ConsoleSink({void Function(String line)? write})
    : _write = write ?? _debugPrintLine;

  final void Function(String line) _write;

  @override
  void add(LogRecord record) {
    if (record.channel == LogChannel.telemetry) {
      return;
    }

    _write(formatRecordForConsole(record));
  }
}

void _debugPrintLine(String line) => debugPrint(line);
