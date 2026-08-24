import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/apu/apu.dart';
import 'package:nesd/nes/apu/expansion/namco163_audio.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/isolate/nes_worker.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:path/path.dart' as p;

import '../nes/cartridge/mapper/namco163_harness.dart';
import '../ui/mocks.dart';

const _romPath = '../../roms/test/nestest/nestest.nes';
const _mmc5RomPath = '../../roms/test/mmc5test_v2/mmc5test.nes';

LoadRomCommand _loadRomCommand({
  bool rewindEnabled = false,
  String romPath = _romPath,
}) {
  final bytes = File(romPath).readAsBytesSync();

  return LoadRomCommand(
    rom: NesBytes.fromList([bytes]),
    file: FilesystemFile(
      path: romPath,
      name: p.basename(romPath),
      type: FilesystemFileType.file,
    ),
    databaseEntry: null,
    region: Region.ntsc,
    rewindEnabled: rewindEnabled,
    cheats: const [],
    breakpoints: const [],
  );
}

LoadRomCommand _loadSyntheticRomCommand(Uint8List bytes, String name) =>
    LoadRomCommand(
      rom: NesBytes.fromList([bytes]),
      file: FilesystemFile(
        path: name,
        name: name,
        type: FilesystemFileType.file,
      ),
      databaseEntry: null,
      region: Region.ntsc,
      rewindEnabled: false,
      cheats: const [],
      breakpoints: const [],
    );

void main() {
  late List<NesIsolateEvent> events;
  late NesWorker worker;

  setUp(() {
    events = <NesIsolateEvent>[];
    worker = NesWorker(send: events.add, audioFactory: FakeNesdAudio.new);
  });

  tearDown(() async {
    await worker.shutdown();
  });

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

  test('enabling APU debug emits ApuDebugEvents with a consistent '
      'payload', () async {
    await worker.handleCommand(_loadRomCommand());
    await waitFor<RomLoadedEvent>();

    await worker.handleCommand(const SetApuDebugEnabledCommand(enabled: true));

    expect(worker.nesForTesting!.apu.debugSamplingEnabled, isTrue);

    final event = await waitFor<ApuDebugEvent>();

    expect(event.sampleCount, greaterThan(0));

    final channelBytes = event.channelSamples.materialize().asUint8List();

    expect(channelBytes.length, 5 * event.sampleCount);

    final mix = event.mixSamples.materialize().asFloat32List();

    expect(mix.length, event.sampleCount);
    expect(event.cpuFrequency, ntscCpuFrequency);
  });

  test('disabling APU debug stops emission and releases the '
      'buffers', () async {
    await worker.handleCommand(_loadRomCommand());
    await waitFor<RomLoadedEvent>();
    await worker.handleCommand(const SetApuDebugEnabledCommand(enabled: true));
    await waitFor<ApuDebugEvent>();

    await worker.handleCommand(const SetApuDebugEnabledCommand(enabled: false));

    expect(worker.nesForTesting!.apu.debugSamplingEnabled, isFalse);

    events.clear();

    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(events.whereType<ApuDebugEvent>(), isEmpty);
  });

  test('no events are emitted while rewinding', () async {
    await worker.handleCommand(_loadRomCommand(rewindEnabled: true));
    await waitFor<RomLoadedEvent>();
    await worker.handleCommand(const SetApuDebugEnabledCommand(enabled: true));

    // Let the rewind buffer fill, otherwise the first pop finds it empty
    // and the run loop drops straight back out of rewind.
    await waitForCount<ApuDebugEvent>(5);

    // During rewind the frame's samples run backwards while the capture
    // buffers still hold forward-ordered data, so the two would not line
    // up. The panel must hold its last frame instead.
    final nes = worker.nesForTesting!..rewind = true;

    events.clear();

    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(nes.rewind, isTrue, reason: 'rewind ended before it was observed');
    expect(events.whereType<ApuDebugEvent>(), isEmpty);

    nes.rewind = false;

    await waitFor<ApuDebugEvent>();
  });

  test('APU debug emission survives a ROM reload', () async {
    await worker.handleCommand(_loadRomCommand());
    await waitFor<RomLoadedEvent>();
    await worker.handleCommand(const SetApuDebugEnabledCommand(enabled: true));
    await waitFor<ApuDebugEvent>();

    await worker.handleCommand(_loadRomCommand());
    await waitForCount<RomLoadedEvent>(2);

    events.clear();

    await waitFor<ApuDebugEvent>();
  });

  test('an MMC5 ROM reports expansion lanes and state', () async {
    await worker.handleCommand(_loadRomCommand(romPath: _mmc5RomPath));
    await worker.handleCommand(const SetApuDebugEnabledCommand(enabled: true));

    final event = await waitFor<ApuDebugEvent>();

    expect(event.expansionLaneCount, 3);
    expect(event.mmc5, isNotNull);
    expect(event.channelCount, 8);
  });

  test('a non-MMC5 ROM reports no expansion lanes', () async {
    await worker.handleCommand(_loadRomCommand());
    await worker.handleCommand(const SetApuDebugEnabledCommand(enabled: true));

    final event = await waitFor<ApuDebugEvent>();

    expect(event.expansionLaneCount, 0);
    expect(event.mmc5, isNull);
  });

  test('a Namco 163 ROM reports eight expansion lanes and state', () async {
    await worker.handleCommand(
      _loadSyntheticRomCommand(buildNamco163Rom(), 'namco163-test.nes'),
    );
    await worker.handleCommand(const SetApuDebugEnabledCommand(enabled: true));

    final event = await waitFor<ApuDebugEvent>();

    expect(event.expansionLaneCount, 8);
    expect(event.n163, isNotNull);
    expect(event.mmc5, isNull);
    expect(event.channelCount, 13);
  });

  test(
    'a Namco 163 ROM reports each enabled channel at its hardware index',
    () async {
      await worker.handleCommand(
        _loadSyntheticRomCommand(buildNamco163Rom(), 'namco163-test.nes'),
      );
      await waitFor<RomLoadedEvent>();

      final audio = worker.nesForTesting!.apu.expansionAudio! as Namco163Audio;

      audio.ram[0x7f] = (1 << 4) | 5; // channel 8: 2 channels, volume 5
      audio.ram[0x77] = 9; // channel 7: volume 9

      await worker.handleCommand(
        const SetApuDebugEnabledCommand(enabled: true),
      );

      final event = await waitFor<ApuDebugEvent>();
      final n163 = event.n163!;

      expect(n163.enabledChannels, 2);
      expect(
        n163.channels[0].volume,
        5,
        reason: 'channels[0] must report hardware channel 8',
      );
      expect(
        n163.channels[1].volume,
        9,
        reason: 'channels[1] must report hardware channel 7',
      );
    },
  );

  test('a non-Namco 163 ROM reports no N163 state', () async {
    await worker.handleCommand(_loadRomCommand());
    await worker.handleCommand(const SetApuDebugEnabledCommand(enabled: true));

    final event = await waitFor<ApuDebugEvent>();

    expect(event.n163, isNull);
  });
}
