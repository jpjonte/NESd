import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_sink.dart';
import 'package:nesd/nes/apu/apu.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/isolate/nes_worker.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../ui/mocks.dart';

const _romPath = '../../roms/test/nestest/nestest.nes';

class _RecordingSink extends LogSink {
  final List<LogRecord> records = [];

  @override
  void add(LogRecord record) => records.add(record);
}

LoadRomCommand _loadRomCommand({Uint8List? rom}) {
  final bytes = rom ?? File(_romPath).readAsBytesSync();

  return LoadRomCommand(
    rom: NesBytes.fromList([bytes]),
    file: const FilesystemFile(
      path: _romPath,
      name: 'nestest.nes',
      type: FilesystemFileType.file,
    ),
    databaseEntry: null,
    region: Region.ntsc,
    rewindEnabled: false,
    cheats: const [],
    breakpoints: const [],
  );
}

void main() {
  late _RecordingSink sink;
  late List<NesIsolateEvent> events;
  late NesWorker worker;

  setUp(() {
    sink = _RecordingSink();

    NesdLog.install(
      NesdLog(sinks: [sink], minimumLevel: LogLevel.debug, isolate: 'emulator'),
    );

    events = <NesIsolateEvent>[];
    worker = NesWorker(send: events.add, audioFactory: FakeNesdAudio.new);
  });

  tearDown(() async {
    await worker.shutdown();

    await NesdLog.instance.close();

    NesdLog.install(NesdLog());
  });

  test(
    'a successful ROM load logs name and mapper on the rom channel',
    () async {
      await worker.handleCommand(_loadRomCommand());

      final loaded = sink.records.firstWhere(
        (r) => r.channel == LogChannel.rom && r.level == LogLevel.info,
      );

      expect(loaded.message, contains('ROM loaded'));
      expect(loaded.context, containsPair('name', 'nestest.nes'));
      expect(loaded.context, containsPair('mapper', isA<int>()));
      expect(loaded.isolate, 'emulator');
    },
  );

  test('a failed ROM load logs on the rom channel at error level', () async {
    await worker.handleCommand(
      _loadRomCommand(rom: Uint8List.fromList([1, 2, 3, 4])),
    );

    final failed = sink.records.firstWhere(
      (r) => r.channel == LogChannel.rom && r.level == LogLevel.error,
    );

    expect(failed.message, contains('ROM load failed'));
    expect(failed.error, isNotNull);
  });

  test('a zapper trigger pull is logged on the input channel', () async {
    await worker.handleCommand(_loadRomCommand());
    await worker.handleCommand(const ZapperPullCommand());

    expect(
      sink.records.any(
        (r) => r.channel == LogChannel.input && r.message.contains('Zapper'),
      ),
      isTrue,
    );
  });

  test('a PCM dump with no ROM logs on the audio channel', () async {
    await worker.handleCommand(
      const StartPcmDumpCommand(path: '/nonexistent/x.pcm'),
    );

    expect(
      sink.records.any(
        (r) => r.channel == LogChannel.audio && r.level == LogLevel.error,
      ),
      isTrue,
    );
  });

  test('opening the audio device is logged with its sample rate', () async {
    await worker.handleCommand(_loadRomCommand());

    final opened = sink.records.firstWhere(
      (r) => r.channel == LogChannel.audio && r.level == LogLevel.info,
    );

    expect(opened.message, contains('Audio'));
    expect(opened.context, containsPair('sampleRate', apuSampleRate));
  });

  test('stopping the emulator is logged', () async {
    await worker.handleCommand(_loadRomCommand());
    await worker.handleCommand(const StopCommand());

    expect(
      sink.records.any(
        (r) =>
            r.channel == LogChannel.emulator &&
            r.message.toLowerCase().contains('stopped'),
      ),
      isTrue,
      reason:
          'a session that ends should be visible in the log, so a '
          'later record can be read as belonging to a new ROM',
    );
  });

  test('a saved state is logged with its size', () async {
    await worker.handleCommand(_loadRomCommand());
    await worker.handleCommand(const SaveStateRequest(requestId: 1));

    final saved = sink.records.firstWhere(
      (r) => r.channel == LogChannel.emulator && r.message.contains('aved'),
    );

    expect(saved.context, containsPair('bytes', isA<int>()));
  });
}
