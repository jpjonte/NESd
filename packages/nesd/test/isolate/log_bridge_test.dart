import 'package:es_compression/lz4.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd_audio/nesd_audio.dart';

void main() {
  test('worker records reach the host as LogEvents', () async {
    final isolate = await NesIsolate.spawn(
      lz4LibraryPath: Lz4Codec.libraryPath,
      audioLibraryPath: NesdAudio.libraryPath,
      disableAudio: true,
      logLevel: LogLevel.debug,
    );

    addTearDown(isolate.dispose);

    isolate.send(const StartPcmDumpCommand(path: '/nonexistent/x.pcm'));

    final event = await isolate.events.firstWhere(
      (e) => e is LogEvent && e.record.level == LogLevel.error,
    );

    final record = (event as LogEvent).record;

    expect(record.isolate, 'emulator');
    expect(record.channel, LogChannel.audio);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
