import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/rewind/rewind_buffer.dart';
import 'package:nesd/nes/serialization/nes_state.dart';

import '../../test_roms/rom_robot.dart';

Future<void> flushMicrotasks() => Future<void>.delayed(Duration.zero);

class StateFactory {
  StateFactory(this.nes);

  final NES nes;

  /// Captures a state distinguishable by [marker], with a call stack of
  /// [callStackDepth] entries so serialization length varies per state.
  NESState capture(int marker, {int callStackDepth = 0}) {
    nes.cpu.ram[0] = marker;

    nes.cpu.callStack
      ..clear()
      ..addAll(List.generate(callStackDepth, (i) => 0x8000 + i));

    nes.ppu.frameBuffer.pixels[0] = marker;
    nes.ppu.frameBuffer.swap();

    return NESState(
      cpuState: nes.cpu.state,
      ppuState: nes.ppu.state,
      apuState: nes.apu.state,
      cartridgeState: nes.bus.cartridge.state,
    );
  }
}

void main() {
  late StateFactory factory;

  setUp(() async {
    final robot = RomRobot('../../roms/test/nestest/nestest.nes');

    robot.nes.stop();

    await flushMicrotasks();

    factory = StateFactory(robot.nes);
  });

  test('pop returns added states newest-first', () async {
    final buffer = RewindBuffer(size: 16);
    addTearDown(buffer.dispose);

    final expected = <Uint8List>[];

    for (var i = 0; i < 3; i++) {
      final state = factory.capture(i + 1, callStackDepth: i * 3);

      expected.add(state.serialize(includeFrame: false));
      buffer.add(state);

      await flushMicrotasks();
    }

    for (var i = 2; i >= 0; i--) {
      final popped = buffer.pop();

      expect(popped, isNotNull, reason: 'pop $i');
      expect(
        popped!.state.serialize(includeFrame: false),
        expected[i],
        reason: 'pop $i',
      );
    }

    expect(buffer.pop(), isNull);
  });

  test('handles states whose serialized length differs', () async {
    final buffer = RewindBuffer(size: 16);
    addTearDown(buffer.dispose);

    final small = factory.capture(1);
    final smallBytes = small.serialize(includeFrame: false);

    buffer.add(small);

    await flushMicrotasks();

    final large = factory.capture(2, callStackDepth: 40);
    final largeBytes = large.serialize(includeFrame: false);

    buffer.add(large);

    await flushMicrotasks();

    final shrunk = factory.capture(3);
    final shrunkBytes = shrunk.serialize(includeFrame: false);

    buffer.add(shrunk);

    await flushMicrotasks();

    expect(largeBytes.length, isNot(equals(smallBytes.length)));
    expect(shrunkBytes.length, lessThan(largeBytes.length));
    expect(buffer.pop()!.state.serialize(includeFrame: false), shrunkBytes);
    expect(buffer.pop()!.state.serialize(includeFrame: false), largeBytes);
    expect(buffer.pop()!.state.serialize(includeFrame: false), smallBytes);
    expect(buffer.pop(), isNull);
  });

  test('evicts oldest states when full but keeps chain intact', () async {
    // RingBuffer(size: 4) holds 3 items; 5 adds evict the 2 oldest
    // items. The state before the oldest remaining item is still
    // recoverable as the final dangling working copy, so 4 of 5 states
    // come back.
    final buffer = RewindBuffer(size: 4);
    addTearDown(buffer.dispose);

    final expected = <Uint8List>[];

    for (var i = 0; i < 5; i++) {
      final state = factory.capture(i + 1, callStackDepth: i);

      expected.add(state.serialize(includeFrame: false));
      buffer.add(state);

      await flushMicrotasks();
    }

    for (var i = 4; i >= 1; i--) {
      final popped = buffer.pop();

      expect(popped, isNotNull, reason: 'pop $i');
      expect(
        popped!.state.serialize(includeFrame: false),
        expected[i],
        reason: 'pop $i',
      );
      expect(popped.frame![0], i + 1, reason: 'frame $i');
    }

    expect(buffer.pop(), isNull);
  });

  test('size tracks compressed bytes across add, pop, and clear', () async {
    final buffer = RewindBuffer(size: 16);
    addTearDown(buffer.dispose);

    expect(buffer.size, 0);

    buffer.add(factory.capture(1));

    await flushMicrotasks();

    final afterFirst = buffer.size;

    buffer.add(factory.capture(2, callStackDepth: 2));

    await flushMicrotasks();

    expect(buffer.size, greaterThan(afterFirst));

    buffer.pop();

    expect(buffer.size, afterFirst);

    buffer.clear();

    expect(buffer.size, 0);
    expect(buffer.pop(), isNull);
  });

  test('pooled current buffer grows but is reused across adds', () async {
    // Behavioral proxy: after many adds of equal-size states, pop still
    // round-trips every state correctly (pool reuse did not corrupt the
    // chain). Corruption from aliasing the pool would break byte
    // equality on the SECOND pop, not the first.
    final buffer = RewindBuffer(size: 16);
    addTearDown(buffer.dispose);

    final expected = <Uint8List>[];

    for (var i = 0; i < 6; i++) {
      final state = factory.capture(i + 1);

      expected.add(state.serialize(includeFrame: false));
      buffer.add(state);

      await flushMicrotasks();
    }

    for (var i = 5; i >= 0; i--) {
      final popped = buffer.pop();

      expect(popped, isNotNull, reason: 'pop $i');
      expect(
        popped!.state.serialize(includeFrame: false),
        expected[i],
        reason: 'pop $i',
      );
    }

    expect(buffer.pop(), isNull);
  });

  test('add after popping everything starts a fresh chain', () async {
    // cascaded to satisfy the enforced cascade_invocations lint
    final buffer = RewindBuffer(size: 16)..add(factory.capture(1));
    addTearDown(buffer.dispose);

    await flushMicrotasks();

    buffer.pop();

    expect(buffer.pop(), isNull);

    final state = factory.capture(9);
    final bytes = state.serialize(includeFrame: false);

    buffer.add(state);

    await flushMicrotasks();

    expect(buffer.pop()!.state.serialize(includeFrame: false), bytes);
  });

  test('pop returns the frame that was presented at capture', () async {
    final buffer = RewindBuffer(size: 16);
    addTearDown(buffer.dispose);

    for (var i = 1; i <= 3; i++) {
      buffer.add(factory.capture(i));

      await flushMicrotasks();
    }

    for (var i = 3; i >= 1; i--) {
      final popped = buffer.pop();

      expect(popped, isNotNull, reason: 'pop $i');
      expect(popped!.frame, isNotNull, reason: 'pop $i');
      expect(popped.frame![0], i, reason: 'pop $i');
      expect(popped.state.ppuState.frameBuffer, isNull);
    }

    expect(buffer.pop(), isNull);
  });

  test('size counts both the state and the frame lane', () async {
    final buffer = RewindBuffer(size: 16);
    addTearDown(buffer.dispose);

    buffer.add(factory.capture(1));

    await flushMicrotasks();

    buffer.add(factory.capture(2));

    await flushMicrotasks();

    expect(buffer.size, greaterThan(NESState.headerBytes.length + 4));
  });

  test('tracks sequence numbers across eviction', () async {
    final buffer = RewindBuffer(size: 4);
    addTearDown(buffer.dispose);

    for (var i = 0; i < 6; i++) {
      buffer.add(factory.capture(i + 1));

      await flushMicrotasks();
    }

    expect(buffer.itemCount, 3);
    expect(buffer.newestSequence, 5);
    expect(buffer.oldestSequence, 3);
  });

  test('clear resets the sequence', () async {
    final buffer = RewindBuffer(size: 4);
    addTearDown(buffer.dispose);

    buffer.add(factory.capture(1));

    await flushMicrotasks();

    buffer
      ..clear()
      ..add(factory.capture(2));

    await flushMicrotasks();

    expect(buffer.newestSequence, 0);
  });

  test('captures one thumbnail per stride', () async {
    final buffer = RewindBuffer(size: 16, thumbnailStride: 3);
    addTearDown(buffer.dispose);

    for (var i = 0; i < 7; i++) {
      buffer.add(factory.capture(i + 1));

      await flushMicrotasks();
    }

    expect(buffer.thumbnails().map((t) => t.sequence), [0, 3, 6]);
    expect(buffer.thumbnailWidth, 64);
    expect(buffer.thumbnailHeight, 60);
  });

  test('clear empties the thumbnails', () async {
    final buffer = RewindBuffer(size: 16, thumbnailStride: 1);
    addTearDown(buffer.dispose);

    buffer.add(factory.capture(1));

    await flushMicrotasks();

    buffer.clear();

    expect(buffer.thumbnails(), isEmpty);
  });

  test('commitWalk leaves the buffer as N pops would', () async {
    final oracle = RewindBuffer(size: 12);
    addTearDown(oracle.dispose);

    final committed = RewindBuffer(size: 12);
    addTearDown(committed.dispose);

    for (var i = 0; i < 8; i++) {
      final state = factory.capture(i + 1, callStackDepth: i % 3);

      oracle.add(state);
      committed.add(state);

      await flushMicrotasks();
    }

    for (var i = 0; i < 4; i++) {
      oracle.pop();
    }

    final walk = committed.beginWalk()!..seekTo(4, budget: 100);

    committed.commitWalk(walk);

    expect(committed.itemCount, oracle.itemCount);
    expect(committed.size, oracle.size);

    expect(
      committed.pop()!.state.serialize(includeFrame: false),
      oracle.pop()!.state.serialize(includeFrame: false),
    );
  });

  test('commitWalk at position zero is a no-op', () async {
    final oracle = RewindBuffer(size: 12);
    addTearDown(oracle.dispose);

    final buffer = RewindBuffer(size: 12);
    addTearDown(buffer.dispose);

    for (var i = 0; i < 4; i++) {
      final state = factory.capture(i + 1);

      oracle.add(state);
      buffer.add(state);

      await flushMicrotasks();
    }

    final itemsBefore = buffer.itemCount;
    final bytesBefore = buffer.size;

    buffer.commitWalk(buffer.beginWalk()!);

    expect(buffer.itemCount, itemsBefore);
    expect(buffer.size, bytesBefore);

    expect(
      buffer.pop()!.state.serialize(includeFrame: false),
      oracle.pop()!.state.serialize(includeFrame: false),
    );
  });

  test('commitWalk takes the frame before disposing the walk', () async {
    final buffer = RewindBuffer(size: 12);
    addTearDown(buffer.dispose);

    for (var i = 0; i < 6; i++) {
      buffer.add(factory.capture(i + 1));

      await flushMicrotasks();
    }

    final walk = buffer.beginWalk()!..seekTo(3, budget: 100);

    final expectedFrameMarker = walk.frame![0];

    buffer.commitWalk(walk);

    expect(buffer.pop()!.frame![0], expectedFrameMarker);
  });

  test('commitWalk truncates thumbnails past the committed point so '
      'resumed play stays monotonic', () async {
    final buffer = RewindBuffer(size: 40, thumbnailStride: 2);
    addTearDown(buffer.dispose);

    for (var i = 0; i < 10; i++) {
      buffer.add(factory.capture(i + 1));

      await flushMicrotasks();
    }

    final walk = buffer.beginWalk()!..seekTo(6, budget: 100);

    buffer.commitWalk(walk);

    for (var i = 0; i < 6; i++) {
      buffer.add(factory.capture(i + 11));

      await flushMicrotasks();
    }

    final sequences = buffer.thumbnails().map((t) => t.sequence).toList();

    expect(sequences.toSet().length, sequences.length, reason: 'no dups');

    for (var i = 1; i < sequences.length; i++) {
      expect(
        sequences[i],
        greaterThan(sequences[i - 1]),
        reason: 'must be strictly increasing',
      );
    }

    expect(sequences.every((s) => s <= buffer.newestSequence), isTrue);
    expect(sequences, [0, 2, 4, 6, 8]);
  });
}
