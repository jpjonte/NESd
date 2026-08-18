import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_setup.dart';
import 'package:nesd/log/sink/log_buffer_sink.dart';
import 'package:nesd/log/sink/rotating_file_sink.dart';
import 'package:nesd/log/sink/telemetry_sink.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('nesd-log-setup');
  });

  tearDown(() async {
    await NesdLog.instance.close();

    directory.deleteSync(recursive: true);

    NesdLog.install(NesdLog());
  });

  test('installs a buffer and a telemetry sink on the ambient logger', () {
    final installed = installUiLog();

    expect(NesdLog.instance, same(installed));
    expect(installed.sinkOfType<LogBufferSink>(), isNotNull);
    expect(installed.sinkOfType<TelemetrySink>(), isNotNull);
    expect(installed.isolate, 'ui');
  });

  test('replays buffered records into the file when it is attached', () {
    final installed = installUiLog(minimumLevel: LogLevel.debug);

    installed.app.info('before the file existed');

    attachLogFile(installed, directory.path);

    final sink = installed.sinkOfType<RotatingFileSink>();

    expect(sink, isNotNull);

    final contents = File(sink!.path).readAsStringSync();

    expect(contents, contains('before the file existed'));
  });

  test('logs the resolved log file path so it can be quoted to users', () {
    final installed = installUiLog(minimumLevel: LogLevel.debug);

    attachLogFile(installed, directory.path);

    final buffer = installed.sinkOfType<LogBufferSink>()!;
    final messages = buffer.records.map((r) => r.message);

    expect(
      messages.any((m) => m.contains(p.join(directory.path, 'logs'))),
      isTrue,
    );
  });
}
