import 'package:nesd/log/log_record.dart';
import 'package:nesd/log/log_sink.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';

class IsolateSink extends LogSink {
  const IsolateSink({required this.send});

  final void Function(NesIsolateEvent event) send;

  @override
  void add(LogRecord record) => send(LogEvent(record: record));
}
