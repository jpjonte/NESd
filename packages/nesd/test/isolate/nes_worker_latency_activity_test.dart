import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/latency_activity.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_worker.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../ui/mocks.dart';

const _romPath = '../../roms/test/nestest/nestest.nes';

class _RecordingLatencyActivity implements LatencyActivity {
  final List<bool> transitions = [];

  bool disposed = false;

  bool _active = false;

  @override
  bool get active => _active;

  @override
  void setActive({required bool active}) {
    if (active == _active) {
      return;
    }

    _active = active;

    transitions.add(active);
  }

  @override
  void dispose() {
    setActive(active: false);

    disposed = true;
  }
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
  late _RecordingLatencyActivity activity;
  late NesWorker worker;

  setUp(() {
    activity = _RecordingLatencyActivity();

    worker = NesWorker(
      send: (_) {},
      audioFactory: FakeNesdAudio.new,
      latencyActivity: activity,
    );
  });

  tearDown(() => worker.shutdown());

  test('no activity is held before a ROM is loaded', () {
    expect(activity.active, isFalse);
  });

  test('loading a ROM holds the activity', () async {
    await worker.handleCommand(_loadRomCommand());

    expect(activity.active, isTrue);
  });

  test('a failed ROM load holds no activity', () async {
    await worker.handleCommand(
      _loadRomCommand(rom: Uint8List.fromList([1, 2, 3, 4])),
    );

    expect(activity.active, isFalse);
  });

  test('pausing releases the activity', () async {
    await worker.handleCommand(_loadRomCommand());
    await worker.handleCommand(const PauseCommand());
    await pumpEventQueue();

    expect(activity.active, isFalse);
  });

  test('unpausing holds the activity again', () async {
    await worker.handleCommand(_loadRomCommand());
    await worker.handleCommand(const PauseCommand());
    await pumpEventQueue();

    await worker.handleCommand(const UnpauseCommand());
    await pumpEventQueue();

    expect(activity.transitions, [true, false, true]);
    expect(activity.active, isTrue);
  });

  test('suspending releases the activity', () async {
    await worker.handleCommand(_loadRomCommand());
    await worker.handleCommand(const SuspendCommand());
    await pumpEventQueue();

    expect(activity.active, isFalse);
  });

  test('stopping releases the activity', () async {
    await worker.handleCommand(_loadRomCommand());
    await worker.handleCommand(const StopCommand());

    expect(activity.active, isFalse);
  });

  test('shutting the worker down disposes the activity', () async {
    await worker.handleCommand(_loadRomCommand());
    await worker.shutdown();

    expect(activity.active, isFalse);
    expect(activity.disposed, isTrue);
  });
}
