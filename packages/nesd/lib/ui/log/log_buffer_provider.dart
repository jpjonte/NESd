import 'package:flutter_riverpod/legacy.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/sink/log_buffer_sink.dart';

final logBufferProvider = ChangeNotifierProvider<LogBufferSink>(
  (ref) => NesdLog.instance.sinkOfType<LogBufferSink>() ?? LogBufferSink(),
);
