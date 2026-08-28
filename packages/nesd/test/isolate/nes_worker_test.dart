import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/log/log_sink.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/isolate/nes_worker.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/nes/serialization/nes_state.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../ui/mocks.dart';

const _romPath = '../../roms/test/nestest/nestest.nes';

class _RecordingSink extends LogSink {
  _RecordingSink(this.records);

  final List<LogRecord> records;

  @override
  void add(LogRecord record) => records.add(record);
}

LoadRomCommand _loadRomCommand({
  bool rewindEnabled = false,
  int rewindCaptureInterval = 1,
  bool suspended = false,
}) {
  final bytes = File(_romPath).readAsBytesSync();

  return LoadRomCommand(
    rom: NesBytes.fromList([bytes]),
    file: const FilesystemFile(
      path: _romPath,
      name: 'nestest.nes',
      type: FilesystemFileType.file,
    ),
    databaseEntry: null,
    region: Region.ntsc,
    rewindEnabled: rewindEnabled,
    rewindCaptureInterval: rewindCaptureInterval,
    cheats: const [],
    breakpoints: const [],
    suspended: suspended,
  );
}

Uint8List _batteryRom() {
  return Uint8List(16 + 0x4000 + 0x2000)
    // iNES header: one 16KB PRG bank, one 8KB CHR bank, battery flag set.
    ..setAll(0, [0x4e, 0x45, 0x53, 0x1a, 1, 1, 0x02, 0])
    // The idle loop at $c000: jmp $c000.
    ..setAll(16, [0x4c, 0x00, 0xc0])
    // NMI, reset and IRQ vectors, all pointing at the idle loop.
    ..setAll(16 + 0x3ffa, [0x00, 0xc0, 0x00, 0xc0, 0x00, 0xc0]);
}

LoadRomCommand _batteryRomCommand({Uint8List? initialState, Uint8List? sram}) {
  return LoadRomCommand(
    rom: NesBytes.fromList([_batteryRom()]),
    file: const FilesystemFile(
      path: '/tmp/battery.nes',
      name: 'battery.nes',
      type: FilesystemFileType.file,
    ),
    databaseEntry: null,
    region: Region.ntsc,
    rewindEnabled: false,
    cheats: const [],
    breakpoints: const [],
    initialState: initialState == null
        ? null
        : NesBytes.fromList([initialState]),
    sram: sram == null ? null : NesBytes.fromList([sram]),
  );
}

void main() {
  late List<NesIsolateEvent> events;
  late NesWorker worker;
  late List<LogRecord> logged;

  setUp(() {
    events = <NesIsolateEvent>[];
    worker = NesWorker(send: events.add, audioFactory: FakeNesdAudio.new);

    logged = [];

    NesdLog.install(NesdLog(sinks: [_RecordingSink(logged)]));
  });

  tearDown(() async {
    // The worker's NES loop runs on this test isolate. Without this, a
    // live loop would keep stepping in the background after the test
    // ends and hang (or corrupt) later tests.
    await worker.shutdown();

    await NesdLog.instance.close();

    NesdLog.install(NesdLog());
  });

  // Polls `events` (populated synchronously by the worker's `send`
  // callback) until at least `count` events of type T have arrived, or
  // fails the test after `timeout`. Real async gaps are required because
  // the worker's NES loop advances via real `Future.delayed` timers.
  Future<List<T>> waitForCount<T extends NesIsolateEvent>(
    int count, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (true) {
      final matches = events.whereType<T>().toList();

      if (matches.length >= count) {
        return matches;
      }

      if (DateTime.now().isAfter(deadline)) {
        fail(
          'Timed out waiting for $count $T event(s); got '
          '${matches.length}. All events: '
          '${events.map((e) => e.runtimeType).toList()}',
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<T> waitFor<T extends NesIsolateEvent>({
    Duration timeout = const Duration(seconds: 5),
  }) async => (await waitForCount<T>(1, timeout: timeout)).first;

  test('LoadRomCommand emits RomLoadedEvent and then FrameEvents', () async {
    await worker.handleCommand(_loadRomCommand());

    final loaded = await waitFor<RomLoadedEvent>();

    expect(loaded.hasZapper, isFalse);

    final frame = await waitFor<FrameEvent>();

    expect(frame.width, 256);
    expect(frame.height, 240);
    expect(frame.frameHandle, isNot(0));
    expect(frame.pixels, isA<PointerFramePixels>());
  });

  test('a suspended load halts after its first frame without '
      'pausing', () async {
    await worker.handleCommand(_loadRomCommand(suspended: true));
    await waitFor<RomLoadedEvent>();
    await waitFor<FrameEvent>();

    final nes = worker.nesForTesting!;

    expect(nes.running, isFalse);
    expect(nes.paused, isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(events.whereType<FrameEvent>(), hasLength(1));

    final status = events.whereType<StatusEvent>().last;

    expect(status.running, isFalse);
    expect(status.paused, isFalse);
  });

  test('the worker forces rewind off where unsupported (web)', () async {
    // Replace the setUp worker; it had no ROM loaded, so nothing leaks.
    worker = NesWorker(
      send: events.add,
      audioFactory: FakeNesdAudio.new,
      rewindSupported: false,
    );

    await worker.handleCommand(_loadRomCommand(rewindEnabled: true));
    await waitFor<RomLoadedEvent>();

    expect(worker.nesForTesting!.rewindEnabled, isFalse);

    await worker.handleCommand(const SetRewindEnabledCommand(enabled: true));

    expect(worker.nesForTesting!.rewindEnabled, isFalse);
  });

  test('ReleaseFrameCommand returns buffers to the pool', () async {
    await worker.handleCommand(_loadRomCommand());
    await waitFor<RomLoadedEvent>();

    final frames = await waitForCount<FrameEvent>(3);

    for (final frame in frames) {
      await worker.handleCommand(
        ReleaseFrameCommand(frameHandle: frame.frameHandle),
      );
    }

    // Frames should keep flowing after their buffers are released back to
    // the pool. The pool must not be exhausted / the loop must not have
    // errored out.
    final moreFrames = await waitForCount<FrameEvent>(6);

    expect(moreFrames.length, greaterThanOrEqualTo(6));
    expect(events.whereType<ErrorEvent>(), isEmpty);
  });

  test('SaveStateRequest responds with deserializable state', () async {
    await worker.handleCommand(_loadRomCommand());
    await waitFor<RomLoadedEvent>();
    await waitForCount<FrameEvent>(2);

    await worker.handleCommand(const SaveStateRequest(requestId: 7));

    final response = await waitFor<SaveStateResponse>();

    expect(response.requestId, 7);
    expect(response.state, isNotNull);

    final bytes = response.state!.materialize().asUint8List();

    expect(() => NESState.fromBytes(bytes), returnsNormally);
  });

  test('SetFastForwardCommand enables fast-forward and reports it', () async {
    await worker.handleCommand(_loadRomCommand());
    await waitFor<RomLoadedEvent>();

    await worker.handleCommand(const SetFastForwardCommand(enabled: true));

    // The handler emits a StatusEvent synchronously; it must reflect the
    // new fast-forward state (hold-mode path, plain assignment).
    expect(events.whereType<StatusEvent>().last.fastForward, isTrue);

    await worker.handleCommand(const SetFastForwardCommand(enabled: false));

    expect(events.whereType<StatusEvent>().last.fastForward, isFalse);
  });

  test('SetFastForwardSpeedCommand applies the speed to the NES', () async {
    await worker.handleCommand(_loadRomCommand());
    await waitFor<RomLoadedEvent>();

    await worker.handleCommand(
      const SetFastForwardSpeedCommand(speed: FastForwardSpeed.x4),
    );

    expect(worker.nesForTesting!.fastForwardSpeed, FastForwardSpeed.x4);
  });

  test('SetRewindCommand enables rewind and reports it', () async {
    await worker.handleCommand(_loadRomCommand(rewindEnabled: true));
    await waitFor<RomLoadedEvent>();
    await waitForCount<FrameEvent>(2);

    await worker.handleCommand(const SetRewindCommand(enabled: true));

    // The status emitted synchronously by the handler reports rewind on.
    // (Rewind may later auto-stop when the buffer empties; we assert the
    // immediate acknowledgement, matching the hold-mode press.)
    expect(events.whereType<StatusEvent>().last.rewind, isTrue);
  });

  test('an initial state wins over the SRAM file loaded with it', () async {
    // Build a save state whose work RAM is all 0xaa.
    await worker.handleCommand(
      _batteryRomCommand(sram: Uint8List(0x2000)..fillRange(0, 0x2000, 0xaa)),
    );

    await waitFor<RomLoadedEvent>();
    await worker.handleCommand(const SaveStateRequest(requestId: 1));

    final response = await waitFor<SaveStateResponse>();
    final state = response.state!.materialize().asUint8List();

    await worker.handleCommand(
      _batteryRomCommand(
        initialState: state,
        sram: Uint8List(0x2000)..fillRange(0, 0x2000, 0x55),
      ),
    );

    await waitForCount<RomLoadedEvent>(2);
    await worker.handleCommand(const SaveSramRequest(requestId: 2));

    final sram = (await waitFor<SramResponse>()).sram!
        .materialize()
        .asUint8List();

    expect(sram, everyElement(0xaa));
  });

  test('the SRAM file is loaded when there is no initial state', () async {
    await worker.handleCommand(
      _batteryRomCommand(sram: Uint8List(0x2000)..fillRange(0, 0x2000, 0x55)),
    );

    await waitFor<RomLoadedEvent>();
    await worker.handleCommand(const SaveSramRequest(requestId: 1));

    final sram = (await waitFor<SramResponse>()).sram!
        .materialize()
        .asUint8List();

    expect(sram, everyElement(0x55));
  });

  test('LoadSramCommand with garbage does not crash the worker', () async {
    await worker.handleCommand(_loadRomCommand());
    await waitFor<RomLoadedEvent>();

    await worker.handleCommand(
      LoadSramCommand(sram: NesBytes.fromList([Uint8List(3)])),
    );

    // nestest has no battery, so cartridge.load is a no-op and cannot
    // throw; the guard is defensive. Assert the loop is unharmed: frames
    // keep flowing and no ErrorEvent was raised.
    await waitForCount<FrameEvent>(3);

    expect(events.whereType<ErrorEvent>(), isEmpty);
  });

  test('invalid rom emits RomLoadFailedEvent', () async {
    final command = LoadRomCommand(
      rom: NesBytes.fromList([Uint8List(16)]),
      file: const FilesystemFile(
        path: '/tmp/bad.nes',
        name: 'bad.nes',
        type: FilesystemFileType.file,
      ),
      databaseEntry: null,
      region: Region.ntsc,
      rewindEnabled: false,
      cheats: const [],
      breakpoints: const [],
    );

    await worker.handleCommand(command);

    final failure = await waitFor<RomLoadFailedEvent>();

    expect(failure.message, isNotEmpty);
    expect(events.whereType<RomLoadedEvent>(), isEmpty);
  });

  test('StopCommand stops the loop and emits StoppedEvent + status', () async {
    await worker.handleCommand(_loadRomCommand());
    await waitFor<RomLoadedEvent>();
    await waitForCount<FrameEvent>(1);

    await worker.handleCommand(const StopCommand());

    expect(events.whereType<StoppedEvent>(), hasLength(1));
  });

  test('in-flight frames survive StopCommand until released', () async {
    await worker.handleCommand(_loadRomCommand());
    await waitFor<RomLoadedEvent>();

    final frame = await waitFor<FrameEvent>();

    await worker.handleCommand(const StopCommand());

    expect(events.whereType<StoppedEvent>(), hasLength(1));

    // The worker must keep the frame's backing memory alive (invariant
    // #2: the in-flight map is never bulk-cleared on stop). Read it back
    // directly through its raw pointer address.
    final size = frame.width * frame.height * 4;
    final address = (frame.pixels as PointerFramePixels).address;
    final pointer = Pointer<Uint8>.fromAddress(address);
    final view = pointer.asTypedList(size);

    expect(view.length, size);
    // Touch every byte; this would segfault the test process if the
    // backing allocation had been freed.
    expect(view.fold<int>(0, (sum, b) => sum + b), isNonNegative);

    await worker.handleCommand(
      ReleaseFrameCommand(frameHandle: frame.frameHandle),
    );
  });

  test('emits AudioStatsEvent once per interval while frames flow', () async {
    // Replace the setUp worker: this test needs a zero interval so the
    // second frame already emits. The setUp instance had no ROM loaded,
    // so overwriting it before shutdown leaks nothing.
    worker = NesWorker(
      send: events.add,
      audioFactory: FakeNesdAudio.new,
      audioStatsInterval: Duration.zero,
    );

    await worker.handleCommand(_loadRomCommand());

    final stats = await waitForCount<AudioStatsEvent>(2);

    expect(stats.first.exhaustDelta, 0); // FakeNesdAudio
    expect(stats.first.fillMin, greaterThanOrEqualTo(0));
    expect(stats.first.timestampMilliseconds, greaterThan(0));
  });

  test(
    'discards counters accrued before and during the first window',
    () async {
      final stream = FakeNesdAudio()..underrunsValue = 7;

      worker = NesWorker(
        send: events.add,
        audioFactory: () => stream,
        audioStatsInterval: Duration.zero,
      );

      await worker.handleCommand(_loadRomCommand());

      final stats = await waitForCount<AudioStatsEvent>(1);

      // The 7 device-init starvation counts were taken-and-discarded at
      // epoch start; the warmup window was skipped; the first emitted
      // window must be clean.
      expect(stats.first.exhaustDelta, 0);
    },
  );

  test('StartPcmDump without a loaded ROM reports an error', () async {
    await worker.handleCommand(const StartPcmDumpCommand(path: '/x.pcm'));

    expect(events.whereType<ErrorEvent>(), isNotEmpty);
  });

  test('start/stop PCM dump writes pushed samples to the file', () async {
    final dir = Directory.systemTemp.createTempSync('nesd_worker_pcm');
    addTearDown(() => dir.deleteSync(recursive: true));

    final path = '${dir.path}/audio.pcm';

    await worker.handleCommand(_loadRomCommand());
    await waitForCount<FrameEvent>(1);

    await worker.handleCommand(StartPcmDumpCommand(path: path));
    await waitForCount<FrameEvent>(30);

    await worker.handleCommand(const StopPcmDumpCommand());

    final bytes = File(path).readAsBytesSync();

    expect(bytes.length, greaterThan(0));
    expect(bytes.length % 4, 0); // whole float32 samples
  });

  test('failed PCM dump start clears the previous recorder', () async {
    final dir = Directory.systemTemp.createTempSync('nesd_pcm_fail');
    addTearDown(() => dir.deleteSync(recursive: true));

    final path = '${dir.path}/audio.pcm';

    await worker.handleCommand(_loadRomCommand());
    await waitForCount<FrameEvent>(1);

    await worker.handleCommand(StartPcmDumpCommand(path: path));

    await worker.handleCommand(
      StartPcmDumpCommand(path: '${dir.path}/missing/audio.pcm'),
    );

    expect(events.whereType<ErrorEvent>(), isNotEmpty);

    final sizeAfterFailure = File(path).lengthSync();

    await waitForCount<FrameEvent>(30);

    expect(File(path).lengthSync(), sizeAfterFailure);

    await worker.handleCommand(const StopPcmDumpCommand());

    expect(
      logged.where(
        (r) =>
            r.channel == LogChannel.telemetry &&
            r.message.contains('NESD_PCM_ERROR'),
      ),
      isEmpty,
      reason: 'a closed-but-attached PCM recorder flushed to a closed file',
    );
  });

  test('load applies the rewind capture interval to the NES', () async {
    await worker.handleCommand(_loadRomCommand(rewindCaptureInterval: 3));
    await waitForCount<FrameEvent>(1);

    expect(worker.nesForTesting!.rewindCaptureInterval, 3);
  });

  test(
    'ThumbnailRequest captures the last frame sent to the display',
    () async {
      await worker.handleCommand(_loadRomCommand());
      await waitFor<RomLoadedEvent>();
      await waitForCount<FrameEvent>(3);

      await worker.handleCommand(const SuspendCommand());

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final displayed = events.whereType<FrameEvent>().last;
      final displayedPixels = Uint8List.fromList(
        Pointer<Uint8>.fromAddress(
          (displayed.pixels as PointerFramePixels).address,
        ).asTypedList(displayed.width * displayed.height * 4),
      );

      expect(
        displayedPixels.any((byte) => byte != 0),
        isTrue,
        reason: 'the ROM under test never rendered anything',
      );

      await worker.handleCommand(const ThumbnailRequest(requestId: 11));

      final response = await waitFor<ThumbnailResponse>();

      expect(response.requestId, 11);
      expect(response.width, displayed.width);
      expect(response.height, displayed.height);

      final pixels = response.pixels.materialize().asUint8List();

      expect(
        pixels.any((byte) => byte != 0),
        isTrue,
        reason: 'the thumbnail is blank',
      );
      expect(pixels, displayedPixels);
    },
  );
}
