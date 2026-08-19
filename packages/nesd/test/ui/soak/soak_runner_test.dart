import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_sink.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/soak/soak_config.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/soak/soak_runner.dart';

import '../mocks.dart';

class _MockNesController extends Mock implements NesController {}

class _MockRemoteNes extends Mock implements RemoteNes {}

class _MockRouter extends Mock implements Router {}

class _RecordingSink extends LogSink {
  _RecordingSink(this.records);

  final List<LogRecord> records;

  @override
  void add(LogRecord record) => records.add(record);
}

void main() {
  late _MockNesController controller;
  late _MockRemoteNes nes;
  late _MockRouter router;
  late StreamController<NesIsolateEvent> events;
  late Directory dir;
  late List<int> exitCodes;
  late List<LogRecord> logged;

  setUpAll(() {
    registerFallbackValue(
      const FilesystemFile(
        path: '/x',
        name: 'x',
        type: FilesystemFileType.file,
      ),
    );
    registerFallbackValue(const EmulatorRoute());
  });

  setUp(() {
    SoakRunner.resetLaunchGuardForTesting();

    controller = _MockNesController();
    nes = _MockRemoteNes();
    router = _MockRouter();
    events = StreamController<NesIsolateEvent>.broadcast();
    dir = Directory.systemTemp.createTempSync('nesd_soak_runner');
    exitCodes = [];
    logged = [];

    NesdLog.install(NesdLog(sinks: [_RecordingSink(logged)]));

    File('${dir.path}/test.nes').writeAsBytesSync(minimalValidRom());

    when(
      () => controller.loadRom(any(), data: any(named: 'data')),
    ).thenAnswer((_) async => true);
    when(() => controller.nes).thenReturn(nes);
    when(() => controller.stop()).thenAnswer((_) async {});
    when(() => nes.events).thenAnswer((_) => events.stream);
    when(() => router.navigate(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    dir.deleteSync(recursive: true);
    unawaited(events.close());

    await NesdLog.instance.close();

    NesdLog.install(NesdLog());
  });

  SoakRunner runner({int seconds = 1, bool pcm = true}) {
    return SoakRunner(
      config: SoakConfig(
        romPath: '${dir.path}/test.nes',
        seconds: seconds,
        pcm: pcm,
        dirPath: dir.path,
      ),
      controller: controller,
      router: router,
      waitForFirstFrame: () async {},
      exitApp: exitCodes.add,
    );
  }

  test('a second runner instance in the same process does not run', () async {
    await runner(pcm: false).run();

    verify(() => controller.loadRom(any(), data: any(named: 'data'))).called(1);

    // Provider recomputation constructs a fresh instance; the launch
    // guard is process-global, so the second run must be a no-op.
    await runner(pcm: false).run();

    verifyNever(() => controller.loadRom(any(), data: any(named: 'data')));

    expect(exitCodes, [0]);
  });

  test('happy path: forces conditions, records, summarizes, exits 0', () async {
    final run = runner().run();

    // Give run() time to subscribe, then deliver two stats samples.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    events
      ..add(
        const AudioStatsEvent(
          timestampMilliseconds: 1,
          exhaustDelta: 2,
          fullDelta: 0,
          fillMin: 300,
          fillMax: 2000,
        ),
      )
      ..add(
        const AudioStatsEvent(
          timestampMilliseconds: 2,
          exhaustDelta: 0,
          fullDelta: 0,
          fillMin: 1100,
          fillMax: 2200,
        ),
      );

    await run;

    verify(() => nes.rewindEnabled = true).called(1);
    verify(() => nes.volume = 1.0).called(1);
    verify(() => nes.startPcmDump('${dir.path}/audio.pcm')).called(1);
    verify(() => nes.stopPcmDump()).called(1);
    verify(() => controller.stop()).called(1);

    expect(exitCodes, [0]);
    expect(
      logged.last.message,
      'NESD_SOAK rom=test.nes seconds=1 exhaust_total=2 '
      'exhaust_episodes=1 full_total=0 fill_min=300',
    );

    final statsLines = File('${dir.path}/stats.log').readAsLinesSync();

    expect(statsLines, hasLength(2));
    expect(statsLines.first, startsWith('NESD_AUDIO ts=1 exhaust=2'));
  });

  test('skips the PCM dump when disabled', () async {
    await runner(pcm: false).run();

    verifyNever(() => nes.startPcmDump(any()));
    verify(() => nes.stopPcmDump()).called(1);

    expect(exitCodes, [0]);
  });

  test('failed ROM load prints NESD_SOAK_FAILED and exits 1', () async {
    when(
      () => controller.loadRom(any(), data: any(named: 'data')),
    ).thenAnswer((_) async => false);

    await runner().run();

    expect(exitCodes, [1]);
    expect(logged.last.message, startsWith('NESD_SOAK_FAILED'));
  });

  test('unreadable ROM prints NESD_SOAK_FAILED and exits 1', () async {
    File('${dir.path}/test.nes').deleteSync();

    await runner().run();

    expect(exitCodes, [1]);
    expect(logged.last.message, startsWith('NESD_SOAK_FAILED'));
  });

  test(
    'unexpected failure during finish prints NESD_SOAK_FAILED and exits 1',
    () async {
      when(() => controller.stop()).thenThrow(Exception('sram boom'));

      final run = runner().run();

      // Give run() time to subscribe, then deliver a stats sample so the
      // happy path proceeds all the way to _finish, where stop() throws.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      events.add(
        const AudioStatsEvent(
          timestampMilliseconds: 1,
          exhaustDelta: 0,
          fullDelta: 0,
          fillMin: 300,
          fillMax: 2000,
        ),
      );

      await run;

      expect(exitCodes.last, 1);
      expect(logged.last.message, startsWith('NESD_SOAK_FAILED'));
    },
  );

  test('run() is idempotent: a second call does not reload the ROM', () async {
    final soakRunner = runner();

    final run = soakRunner.run();

    await Future<void>.delayed(const Duration(milliseconds: 200));

    events.add(
      const AudioStatsEvent(
        timestampMilliseconds: 1,
        exhaustDelta: 0,
        fullDelta: 0,
        fillMin: 300,
        fillMax: 2000,
      ),
    );

    await run;

    // A second call, made after the first has fully completed, must not
    // repeat any of the run's side effects.
    await soakRunner.run();

    verify(() => controller.loadRom(any(), data: any(named: 'data'))).called(1);
  });
}
