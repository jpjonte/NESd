@Timeout(Duration(minutes: 2))
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/exception/nesd_exception.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/rewind/rewind_buffer.dart';
import 'package:nesd/nes/rewind/rewind_walk.dart';
import 'package:nesd/nes/serialization/nes_state.dart';

import '../../test_roms/rom_robot.dart';

const _romPath = '../../roms/test/spritecans-2011/spritecans.nes';

Future<void> flushMicrotasks() => Future<void>.delayed(Duration.zero);

Future<void> waitUntil(
  bool Function() condition,
  String description, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out after $timeout waiting for $description');
    }

    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

int checksum(Uint8List pixels) {
  var hash = 0x811c9dc5;

  for (final byte in pixels) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }

  return hash;
}

class ScrubSession {
  ScrubSession(this.nes) {
    _subscription = nes.eventBus.stream.listen(_onEvent);
  }

  final NES nes;

  late final StreamSubscription<NesEvent> _subscription;

  int frames = 0;

  final Map<int, int> presentedByFrame = {};

  int drained = 0;

  int get presented => checksum(nes.ppu.frameBuffer.presentedPixels);

  void _onEvent(NesEvent event) {
    if (event is! FrameNesEvent) {
      return;
    }

    frames++;

    presentedByFrame[event.frame] = presented;

    _drainReadyBuffers();
  }

  void _drainReadyBuffers() {
    final buffer = nes.ppu.frameBuffer;

    for (
      var ready = buffer.takeReadyBuffer();
      ready != null;
      ready = buffer.takeReadyBuffer()
    ) {
      drained++;

      buffer.releaseDisplayBuffer(ready);
    }
  }

  Future<void> runFrames(int count) {
    final target = frames + count;

    return waitUntil(
      () => frames >= target,
      '$count more emulated frames',
      timeout: Duration(milliseconds: 5000 + count * 250),
    );
  }

  Future<void> stopLoop() async {
    if (nes.inLoop) {
      nes.stop();

      await waitUntil(() => !nes.inLoop, 'the run loop to exit');
    }

    await flushMicrotasks();
  }

  Future<void> dispose() async {
    await stopLoop();
    await _subscription.cancel();

    nes.dispose();
  }
}

Future<ScrubSession> openSession(
  int captures, {
  bool rewindEnabled = true,
}) async {
  final session = ScrubSession(
    RomRobot(_romPath).nes..rewindEnabled = rewindEnabled,
  );

  addTearDown(session.dispose);

  await session.runFrames(captures);

  return session;
}

NESState capture(NES nes, int marker) {
  nes.cpu.ram[0] = marker;

  nes.ppu.frameBuffer.pixels[0] = marker;
  nes.ppu.frameBuffer.swap();

  return NESState(
    cpuState: nes.cpu.state,
    ppuState: nes.ppu.state,
    apuState: nes.apu.state,
    cartridgeState: nes.bus.cartridge.state,
  );
}

Future<void> fillHistory(NES nes, int count) async {
  final buffer = RewindBuffer(size: count + 2);

  for (var i = 0; i < count; i++) {
    buffer.add(capture(nes, i + 1));

    await flushMicrotasks();
  }

  nes.replaceRewindBuffer(buffer);
}

class UnreadableRewindBuffer extends RewindBuffer {
  UnreadableRewindBuffer() : super(size: 2);

  int clearCount = 0;

  @override
  int get itemCount => 5;

  @override
  int get newestSequence => 4;

  @override
  int get oldestSequence => 0;

  @override
  RewindWalk? beginWalk() => UnreadableWalk();

  @override
  void clear() {
    clearCount++;

    super.clear();
  }
}

class UnreadableWalk extends RewindWalk {
  UnreadableWalk()
    : super(
        itemAt: _noItem,
        itemCount: 1,
        seedState: Uint8List(4),
        seedFrame: null,
      );

  static RewindItem? _noItem(int position) => null;

  @override
  bool seekTo(int targetPosition, {required int budget}) =>
      throw NesdException('rewind frame diff has the wrong length');
}

void main() {
  test('beginScrub returns a timeline spanning the captured history', () async {
    final session = await openSession(20);

    await session.stopLoop();

    final nes = session.nes;
    final timeline = nes.beginScrub();

    expect(timeline, isNotNull);
    expect(nes.scrubbing, isTrue);
    expect(timeline!.newestSequence, greaterThan(timeline.oldestSequence));
    expect(timeline.captureInterval, nes.rewindCaptureInterval);
    expect(timeline.frameRate, nes.frameRate);
    expect(nes.scrubSequence, timeline.newestSequence);
    expect(nes.scrubSettled, isTrue);

    expect(timeline.thumbnailWidth, 64);
    expect(timeline.thumbnailHeight, 60);

    expect(timeline.thumbnails.map((t) => t.sequence), [0]);

    nes.cancelScrub();
  });

  test('the thumbnail stride follows the capture interval', () async {
    final session = await openSession(2);

    session.nes.rewindCaptureInterval = 4;

    await session.runFrames(70);
    await session.stopLoop();

    final nes = session.nes;
    final timeline = nes.beginScrub()!;

    expect(
      timeline.thumbnails.map((t) => t.sequence),
      containsAllInOrder([0, 15]),
    );

    nes.cancelScrub();
  });

  test('beginScrub returns null when nothing was captured', () async {
    final session = await openSession(5, rewindEnabled: false);

    await session.stopLoop();

    final nes = session.nes;

    expect(nes.beginScrub(), isNull);

    nes.rewindEnabled = true;

    expect(nes.beginScrub(), isNull, reason: 'the buffer is still empty');
    expect(nes.scrubbing, isFalse);
  });

  test('scrubTo clamps to the buffer bounds', () async {
    final session = await openSession(20);

    await session.stopLoop();

    final nes = session.nes;
    final timeline = nes.beginScrub()!;

    nes.scrubTo(timeline.oldestSequence - 1000);

    expect(nes.scrubSequence, timeline.oldestSequence);

    nes.scrubTo(timeline.newestSequence + 1000);

    expect(nes.scrubSequence, timeline.newestSequence);

    nes.cancelScrub();
  });

  test('commitScrub adopts the scrubbed-to state and drops what is '
      'newer', () async {
    final session = await openSession(30);

    await session.stopLoop();

    final nes = session.nes;
    final framesBefore = nes.ppu.frames;
    final bytesBefore = nes.rewindBufferBytes;

    final timeline = nes.beginScrub()!;
    final target = timeline.newestSequence - 5;

    nes.scrubTo(target);

    expect(nes.scrubSettled, isFalse);

    while (!nes.advanceScrub()) {
      // drive the walk in budgeted steps, the way the run loop does
    }

    nes.commitScrub();

    expect(nes.scrubbing, isFalse);
    expect(
      nes.ppu.frames,
      framesBefore - 5,
      reason: 'the console did not land on the scrubbed-to frame',
    );
    expect(nes.rewindBufferBytes, lessThan(bytesBefore));

    final resumed = nes.beginScrub()!;

    expect(resumed.newestSequence, target);
    expect(resumed.oldestSequence, timeline.oldestSequence);

    nes.cancelScrub();
  });

  test('commitScrub lands on the cursor, not the walk position', () async {
    final session = await openSession(2);

    await session.stopLoop();

    final nes = session.nes;

    await fillHistory(nes, scrubStepBudget * 2);

    final timeline = nes.beginScrub()!;

    final target = timeline.newestSequence - (scrubStepBudget + 10);

    nes.scrubTo(target);

    expect(
      nes.advanceScrub(),
      isFalse,
      reason: 'the walk was expected to still be short of the cursor',
    );

    nes.commitScrub();

    expect(
      nes.cpu.ram[0],
      target + 1,
      reason: 'the console adopted the walk position, not the cursor',
    );
    expect(
      nes.beginScrub()!.newestSequence,
      target,
      reason: 'the buffer was truncated somewhere other than the cursor',
    );

    nes.cancelScrub();
  });

  test('cancelScrub restores the entry frame and leaves the history '
      'intact', () async {
    final session = await openSession(30);

    final nes = session.nes;
    final bytesBefore = nes.rewindBufferBytes;
    final entryFrame = nes.ppu.frames;
    final entry = session.presented;

    expect(entry, session.presentedByFrame[entryFrame]);

    final timeline = nes.beginScrub()!;

    nes.scrubTo(timeline.newestSequence - 10);

    await waitUntil(() => nes.scrubSettled, 'the scrub walk to settle');

    expect(
      session.presented,
      session.presentedByFrame[entryFrame - 10],
      reason: 'the preview is not the image that was shown at that frame',
    );

    nes.cancelScrub();

    expect(nes.scrubbing, isFalse);
    expect(session.presented, entry);
    expect(nes.rewindBufferBytes, bytesBefore);
  });

  test('the run loop previews scrub frames without stepping the '
      'console', () async {
    final session = await openSession(20);

    final nes = session.nes;

    expect(nes.beginScrub(), isNotNull);

    final framesAtEntry = nes.ppu.frames;

    await session.runFrames(5);

    expect(
      nes.ppu.frames,
      framesAtEntry,
      reason: 'the console kept emulating while scrubbing',
    );

    nes.cancelScrub();

    await waitUntil(
      () => nes.ppu.frames > framesAtEntry,
      'live play to resume',
    );

    expect(
      nes.ppu.frames,
      greaterThan(framesAtEntry),
      reason: 'live play did not resume after the session ended',
    );
  });

  test('a parked cursor presents nothing while still pacing', () async {
    final session = await openSession(20);

    final nes = session.nes;
    final timeline = nes.beginScrub()!;

    nes.scrubTo(timeline.newestSequence - 5);

    await waitUntil(() => nes.scrubSettled, 'the scrub walk to settle');

    final drainedAtSettle = session.drained;
    final framesAtSettle = session.frames;

    await session.runFrames(5);

    expect(
      session.drained,
      drainedAtSettle,
      reason: 'a parked cursor kept swapping fresh frame buffers',
    );
    expect(
      session.frames,
      greaterThan(framesAtSettle),
      reason: 'the governor stopped being fed',
    );

    nes.scrubTo(timeline.newestSequence - 6);

    await waitUntil(
      () => session.drained > drainedAtSettle,
      'the moved cursor to present a frame',
    );

    expect(session.drained, greaterThan(drainedAtSettle));

    nes.cancelScrub();
  });

  test('an unreadable chain aborts the session instead of escaping '
      'into the loop', () async {
    final session = await openSession(5);

    await session.stopLoop();

    final nes = session.nes;
    final buffer = UnreadableRewindBuffer();

    nes.replaceRewindBuffer(buffer);

    expect(nes.beginScrub(), isNotNull);

    nes.scrubTo(nes.scrubSequence - 1);

    expect(nes.advanceScrub(), isTrue);
    expect(nes.scrubbing, isFalse);
    expect(nes.scrubSettled, isTrue);
    expect(buffer.clearCount, greaterThan(0));
  });

  test('clearing the buffer ends an open session', () async {
    final session = await openSession(20);

    await session.stopLoop();

    final nes = session.nes..rewind = true;

    expect(nes.beginScrub(), isNotNull);

    nes.toggleRewind();

    expect(nes.scrubbing, isFalse);
    expect(nes.beginScrub(), isNull, reason: 'the buffer was cleared');
  });
}
