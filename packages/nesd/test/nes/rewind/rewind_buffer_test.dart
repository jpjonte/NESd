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
    final expected = <Uint8List>[];

    for (var i = 0; i < 3; i++) {
      final state = factory.capture(i + 1, callStackDepth: i * 3);

      expected.add(state.serialize());
      buffer.add(state);

      await flushMicrotasks();
    }

    for (var i = 2; i >= 0; i--) {
      final popped = buffer.pop();

      expect(popped, isNotNull, reason: 'pop $i');
      expect(popped!.serialize(), expected[i], reason: 'pop $i');
    }

    expect(buffer.pop(), isNull);
  });

  test('handles states whose serialized length differs', () async {
    final buffer = RewindBuffer(size: 16);

    final small = factory.capture(1);
    final smallBytes = small.serialize();

    buffer.add(small);

    await flushMicrotasks();

    final large = factory.capture(2, callStackDepth: 40);
    final largeBytes = large.serialize();

    buffer.add(large);

    await flushMicrotasks();

    final shrunk = factory.capture(3);
    final shrunkBytes = shrunk.serialize();

    buffer.add(shrunk);

    await flushMicrotasks();

    expect(largeBytes.length, isNot(equals(smallBytes.length)));
    expect(shrunkBytes.length, lessThan(largeBytes.length));
    expect(buffer.pop()!.serialize(), shrunkBytes);
    expect(buffer.pop()!.serialize(), largeBytes);
    expect(buffer.pop()!.serialize(), smallBytes);
    expect(buffer.pop(), isNull);
  });

  test('evicts oldest states when full but keeps chain intact', () async {
    // RingBuffer(size: 4) holds 3 items; 5 adds evict the 2 oldest
    // items. The state before the oldest remaining item is still
    // recoverable as the final dangling working copy, so 4 of 5 states
    // come back.
    final buffer = RewindBuffer(size: 4);
    final expected = <Uint8List>[];

    for (var i = 0; i < 5; i++) {
      final state = factory.capture(i + 1, callStackDepth: i);

      expected.add(state.serialize());
      buffer.add(state);

      await flushMicrotasks();
    }

    for (var i = 4; i >= 1; i--) {
      final popped = buffer.pop();

      expect(popped, isNotNull, reason: 'pop $i');
      expect(popped!.serialize(), expected[i], reason: 'pop $i');
    }

    expect(buffer.pop(), isNull);
  });

  test('size tracks compressed bytes across add, pop, and clear', () async {
    final buffer = RewindBuffer(size: 16);

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

  test('add after popping everything starts a fresh chain', () async {
    // cascaded to satisfy the enforced cascade_invocations lint
    final buffer = RewindBuffer(size: 16)..add(factory.capture(1));

    await flushMicrotasks();

    buffer.pop();

    expect(buffer.pop(), isNull);

    final state = factory.capture(9);
    final bytes = state.serialize();

    buffer.add(state);

    await flushMicrotasks();

    expect(buffer.pop()!.serialize(), bytes);
  });
}
