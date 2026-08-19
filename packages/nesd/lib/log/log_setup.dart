import 'package:flutter/foundation.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/sink/console_sink.dart';
import 'package:nesd/log/sink/log_buffer_sink.dart';
import 'package:nesd/log/sink/rotating_file_sink.dart';
import 'package:nesd/log/sink/telemetry_sink.dart';
import 'package:path/path.dart' as p;

NesdLog installUiLog({LogLevel minimumLevel = LogLevel.info}) {
  final log = NesdLog(
    isolate: 'ui',
    minimumLevel: minimumLevel,
    sinks: [
      LogBufferSink(),
      if (consoleLoggingEnabled) ConsoleSink(),
      TelemetrySink(),
    ],
  );

  NesdLog.install(log);

  return log;
}

void attachLogFile(NesdLog log, String basePath) {
  final directory = p.join(basePath, 'logs');
  final buffer = log.sinkOfType<LogBufferSink>();
  final sink = RotatingFileSink(directory: directory);

  log.addSink(sink, replay: buffer?.records ?? const []);

  log.app.info('Logging to ${sink.path}');
}

void logAppStart({
  required String version,
  required String buildNumber,
  required String platform,
  required String? flavor,
}) => log.app.info(
  'NESd started',
  context: {
    'version': version,
    'build': buildNumber,
    'platform': platform,
    if (flavor != null) 'flavor': flavor,
  },
);

void installErrorHooks() {
  FlutterError.onError = (details) {
    log.app.error(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );

    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    log.app.error('Uncaught async error', error: error, stackTrace: stackTrace);

    return consoleLoggingEnabled;
  };
}
