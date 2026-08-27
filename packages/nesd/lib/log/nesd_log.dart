import 'package:nesd/log/log_channel.dart';
import 'package:nesd/log/log_level.dart';
import 'package:nesd/log/log_record.dart';
import 'package:nesd/log/log_sink.dart';

class NesdLog {
  NesdLog({
    List<LogSink> sinks = const [],
    this.minimumLevel = LogLevel.info,
    this.isolate,
  }) : _sinks = [...sinks];

  static NesdLog instance = NesdLog();

  // ignore: use_setters_to_change_properties
  static void install(NesdLog log) => instance = log;

  final List<LogSink> _sinks;

  LogLevel minimumLevel;

  final String? isolate;

  late final ChannelLog app = ChannelLog(this, LogChannel.app);
  late final ChannelLog rom = ChannelLog(this, LogChannel.rom);
  late final ChannelLog emulator = ChannelLog(this, LogChannel.emulator);
  late final ChannelLog audio = ChannelLog(this, LogChannel.audio);
  late final ChannelLog video = ChannelLog(this, LogChannel.video);
  late final ChannelLog input = ChannelLog(this, LogChannel.input);
  late final ChannelLog settings = ChannelLog(this, LogChannel.settings);
  late final ChannelLog storage = ChannelLog(this, LogChannel.storage);
  late final TelemetryLog telemetry = TelemetryLog(this);

  T? sinkOfType<T extends LogSink>() {
    for (final sink in _sinks) {
      if (sink is T) {
        return sink;
      }
    }

    return null;
  }

  void addSink(LogSink sink, {Iterable<LogRecord> replay = const []}) {
    for (final record in replay) {
      sink.add(record);
    }

    _sinks.add(sink);
  }

  void add(LogRecord record) {
    for (final sink in _sinks) {
      try {
        sink.add(record);
      } on Object {
        // ignore exceptions so logging doesn't break anything
      }
    }
  }

  void ingest(LogRecord record) {
    for (final sink in _sinks) {
      if (sink.emitsAtOriginOnly) {
        continue;
      }

      try {
        sink.add(record);
      } on Object {
        // ignore exceptions so logging doesn't break anything
      }
    }
  }

  Future<void> close() async {
    for (final sink in _sinks) {
      await sink.close();
    }
  }
}

class ChannelLog {
  const ChannelLog(this._log, this.channel);

  final NesdLog _log;
  final LogChannel channel;

  void debug(
    String message, {
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) => _write(LogLevel.debug, message, context, error, stackTrace);

  void info(
    String message, {
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) => _write(LogLevel.info, message, context, error, stackTrace);

  void warning(
    String message, {
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) => _write(LogLevel.warning, message, context, error, stackTrace);

  void error(
    String message, {
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) => _write(LogLevel.error, message, context, error, stackTrace);

  void _write(
    LogLevel level,
    String message,
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  ) {
    if (level.index < _log.minimumLevel.index) {
      return;
    }

    _log.add(
      LogRecord(
        time: DateTime.now(),
        level: level,
        channel: channel,
        message: message,
        context: context,
        error: error?.toString(),
        stackTrace: stackTrace?.toString(),
        isolate: _log.isolate,
      ),
    );
  }
}

class TelemetryLog {
  const TelemetryLog(this._log);

  final NesdLog _log;

  void emit(String line) => _log.add(
    LogRecord(
      time: DateTime.now(),
      level: LogLevel.debug,
      channel: LogChannel.telemetry,
      message: line,
      isolate: _log.isolate,
    ),
  );
}
