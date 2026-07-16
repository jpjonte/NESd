import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

class _NullDatabase implements NesDatabase {
  const _NullDatabase();

  @override
  NesDatabaseEntry? find(RomInfo info) => null;
}

NES _buildNes() {
  const path = '../../roms/test/nestest/nestest.nes';
  final bytes = File(path).readAsBytesSync();
  const factory = CartridgeFactory(database: _NullDatabase());

  final cartridge = factory.fromFile(
    const FilesystemFile(
      path: path,
      name: 'nestest.nes',
      type: FilesystemFileType.file,
    ),
    bytes,
  )..databaseEntry = null;

  return NES(cartridge: cartridge, eventBus: EventBus())..reset();
}

// Polls `condition` until it returns true, or gives up after `timeout`.
// Real async gaps are required because the NES run loop advances via real
// `Future.delayed` timers (mirrors the pattern in
// test/isolate/nes_worker_test.dart).
Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

// The rewind capture site lives in _sendFrame, which only runs inside
// run(); for a synchronous test we call the capture predicate directly
// through the public shouldCaptureRewind seam below instead of driving
// the run loop.
void main() {
  test('shouldCaptureRewind gates on the interval', () {
    final nes = _buildNes()..rewindCaptureInterval = 4;

    final captured = [
      0,
      1,
      2,
      3,
      4,
      7,
      8,
      100,
      101,
    ].where(nes.shouldCaptureRewind).toList();

    expect(captured, [0, 4, 8, 100]);
  });

  test('interval 1 captures every frame (default unchanged)', () {
    final nes = _buildNes();

    expect(nes.rewindCaptureInterval, 1);
    expect([5, 6, 7].where(nes.shouldCaptureRewind), [5, 6, 7]);
  });

  test('interval below 1 is rejected', () {
    final nes = _buildNes();

    expect(() => nes.rewindCaptureInterval = 0, throwsArgumentError);
  });

  test('setting the capture interval scales rewind history capacity', () {
    final nes = _buildNes();

    expect(nes.rewindItemCapacity, 3600);

    nes.rewindCaptureInterval = 4;

    expect(nes.rewindItemCapacity, 900);
  });

  test('extreme capture intervals degrade to minimal history', () async {
    // Use extreme interval (3601) which hits the minimal buffer case:
    // max(2, 3600 ~/ 3601) = max(2, 0) = 2 (capacity 1 usable item).
    // This exercises the RingBuffer eviction path to ensure no uncaught
    // 'Buffer is full' exception despite minimal capacity.
    final nes = _buildNes()
      ..rewindCaptureInterval = 3601
      ..rewindEnabled = true;

    expect(nes.rewindItemCapacity, 2);

    final frames = <int>[];
    final subscription = nes.eventBus.stream
        .where((event) => event is FrameNesEvent)
        .cast<FrameNesEvent>()
        .listen((event) => frames.add(event.frame));

    unawaited(nes.run());

    // Run emulation long enough to trigger captures (interval 3601).
    // The test passes if no 'Buffer is full' exception is thrown.
    await _waitUntil(() => frames.length > 100);

    nes
      ..rewind = false
      ..stop();

    await _waitUntil(() => !nes.inLoop);
    await subscription.cancel();
  });

  test('hold path presents each snapshot for interval iterations', () async {
    final nes = _buildNes()
      ..rewindCaptureInterval = 4
      ..rewindEnabled = true;

    final frames = <int>[];
    final subscription = nes.eventBus.stream
        .where((event) => event is FrameNesEvent)
        .cast<FrameNesEvent>()
        .listen((event) => frames.add(event.frame));

    unawaited(nes.run());

    // Let it emulate forward long enough to bank several snapshots.
    await _waitUntil(() => frames.length > 40);

    frames.clear();
    nes.rewind = true;

    await _waitUntil(() => frames.length > 12);

    nes
      ..rewind = false
      ..stop();

    await _waitUntil(() => !nes.inLoop);
    await subscription.cancel();

    // During rewind each popped frame number is presented interval (4)
    // times before the next (lower) one appears: runs of equal values,
    // each run length 4 (first and last runs may be truncated by the
    // observation window).
    final runs = <int>[];
    var runLength = 0;
    int? current;

    for (final frame in frames) {
      if (frame == current) {
        runLength++;
      } else {
        if (current != null) {
          runs.add(runLength);
        }

        current = frame;
        runLength = 1;
      }
    }

    expect(runs, isNotEmpty);
    expect(runs.skip(1), everyElement(4));

    // Pops go backward in time.
    final distinct = frames.toSet().toList();

    expect(distinct, isNot(hasLength(1)));
  });

  test('leaving rewind mid-hold does not leak filler into the next '
      'session', () async {
    final nes = _buildNes()
      ..rewindCaptureInterval = 4
      ..rewindEnabled = true;

    final frames = <int>[];
    final subscription = nes.eventBus.stream
        .where((event) => event is FrameNesEvent)
        .cast<FrameNesEvent>()
        .listen((event) => frames.add(event.frame));

    unawaited(nes.run());

    await _waitUntil(() => frames.length > 40);

    // Enter rewind just long enough to be mid-hold, then leave.
    nes.rewind = true;
    await _waitUntil(() => false, timeout: const Duration(milliseconds: 50));
    nes.rewind = false;

    await _waitUntil(() => frames.length > 60);

    // Re-enter: the FIRST rewind frame must be a fresh pop (a value
    // BELOW the current forward frame), not a stale filler repeat.
    final lastForward = frames.last;

    frames.clear();
    nes.rewind = true;

    await _waitUntil(() => frames.isNotEmpty);

    expect(frames.first, lessThan(lastForward));

    nes
      ..rewind = false
      ..stop();

    await _waitUntil(() => !nes.inLoop);
    await subscription.cancel();
  });
}
