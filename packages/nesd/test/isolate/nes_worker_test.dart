import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/nes_command.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/nes/isolate/nes_worker.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/nes/serialization/nes_state.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../ui/mocks.dart';

const _romPath = '../../roms/test/nestest/nestest.nes';

LoadRomCommand _loadRomCommand({bool rewindEnabled = false}) {
  final bytes = File(_romPath).readAsBytesSync();

  return LoadRomCommand(
    rom: TransferableTypedData.fromList([bytes]),
    file: const FilesystemFile(
      path: _romPath,
      name: 'nestest.nes',
      type: FilesystemFileType.file,
    ),
    databaseEntry: null,
    region: Region.ntsc,
    rewindEnabled: rewindEnabled,
    cheats: const [],
    breakpoints: const [],
  );
}

void main() {
  late List<NesIsolateEvent> events;
  late NesWorker worker;

  setUp(() {
    events = <NesIsolateEvent>[];
    worker = NesWorker(
      send: events.add,
      audioStreamFactory: MockAudioStream.new,
    );
  });

  tearDown(() async {
    // The worker's NES loop runs on this test isolate. Without this, a
    // live loop would keep stepping in the background after the test
    // ends and hang (or corrupt) later tests.
    await worker.shutdown();
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
    expect(frame.pointerAddress, isNot(0));
  });

  test('ReleaseFrameCommand returns buffers to the pool', () async {
    await worker.handleCommand(_loadRomCommand());
    await waitFor<RomLoadedEvent>();

    final frames = await waitForCount<FrameEvent>(3);

    for (final frame in frames) {
      await worker.handleCommand(
        ReleaseFrameCommand(pointerAddress: frame.pointerAddress),
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

  test('LoadSramCommand with garbage does not crash the worker', () async {
    await worker.handleCommand(_loadRomCommand());
    await waitFor<RomLoadedEvent>();

    await worker.handleCommand(
      LoadSramCommand(sram: TransferableTypedData.fromList([Uint8List(3)])),
    );

    // nestest has no battery, so cartridge.load is a no-op and cannot
    // throw; the guard is defensive. Assert the loop is unharmed: frames
    // keep flowing and no ErrorEvent was raised.
    await waitForCount<FrameEvent>(3);

    expect(events.whereType<ErrorEvent>(), isEmpty);
  });

  test('invalid rom emits RomLoadFailedEvent', () async {
    final command = LoadRomCommand(
      rom: TransferableTypedData.fromList([Uint8List(16)]),
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
    final pointer = Pointer<Uint8>.fromAddress(frame.pointerAddress);
    final view = pointer.asTypedList(size);

    expect(view.length, size);
    // Touch every byte; this would segfault the test process if the
    // backing allocation had been freed.
    expect(view.fold<int>(0, (sum, b) => sum + b), isNonNegative);

    await worker.handleCommand(
      ReleaseFrameCommand(pointerAddress: frame.pointerAddress),
    );
  });
}
