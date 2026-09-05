import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/rewind/rewind_buffer.dart';
import 'package:nesd/nes/rewind/rewind_walk.dart';
import 'package:nesd/nes/serialization/nes_state.dart';

import '../../test_roms/rom_robot.dart';

Future<void> flushMicrotasks() => Future<void>.delayed(Duration.zero);

class StateFactory {
  StateFactory(this.nes);

  final NES nes;

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

Future<RewindBuffer> _filled(StateFactory factory, int count) async {
  final buffer = RewindBuffer(size: count + 2);

  for (var i = 0; i < count; i++) {
    buffer.add(factory.capture(i + 1, callStackDepth: i % 3));

    await flushMicrotasks();
  }

  return buffer;
}

List<int> _chainFingerprint(RewindBuffer buffer, int positions) {
  final walk = buffer.beginWalk()!;

  try {
    return [
      for (var position = 0; position < positions; position++)
        _fnv1a(_stateAt(walk, position)),
    ];
  } finally {
    walk.dispose();
  }
}

Uint8List _stateAt(RewindWalk walk, int position) {
  walk.seekTo(position, budget: 100);

  return walk.stateBytes;
}

int _fnv1a(Uint8List bytes) {
  var hash = 0x811c9dc5;

  for (final byte in bytes) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }

  return hash;
}

void main() {
  late StateFactory factory;

  setUp(() async {
    final robot = RomRobot('../../roms/test/nestest/nestest.nes');

    robot.nes.stop();

    await flushMicrotasks();

    factory = StateFactory(robot.nes);
  });

  test('walking to N matches the Nth pop', () async {
    final oracle = await _filled(factory, 8);
    addTearDown(oracle.dispose);

    final expected = <Uint8List>[];

    for (var i = 0; i < 5; i++) {
      expected.add(oracle.pop()!.state.serialize(includeFrame: false));
    }

    final buffer = await _filled(factory, 8);
    addTearDown(buffer.dispose);

    for (var position = 0; position < 5; position++) {
      final walk = buffer.beginWalk()!;
      addTearDown(walk.dispose);

      expect(walk.seekTo(position, budget: 100), isTrue);
      expect(
        walk.buildState().serialize(includeFrame: false),
        expected[position],
        reason: 'position $position',
      );
    }
  });

  test('the walked frame matches the popped frame at each position', () async {
    final oracle = await _filled(factory, 8);
    addTearDown(oracle.dispose);

    final expected = <int>[];

    for (var i = 0; i < 5; i++) {
      expected.add(oracle.pop()!.frame![0]);
    }

    final buffer = await _filled(factory, 8);
    addTearDown(buffer.dispose);

    final walk = buffer.beginWalk()!;
    addTearDown(walk.dispose);

    for (var position = 0; position < 5; position++) {
      walk.seekTo(position, budget: 100);

      expect(walk.frame![0], expected[position], reason: 'position $position');
    }
  });

  test('walking leaves the ring untouched', () async {
    final buffer = await _filled(factory, 8);
    addTearDown(buffer.dispose);

    final itemsBefore = buffer.itemCount;
    final bytesBefore = buffer.size;
    final chainBefore = _chainFingerprint(buffer, 6);

    final walk = buffer.beginWalk()!;
    addTearDown(walk.dispose);

    walk.seekTo(5, budget: 100);

    expect(buffer.itemCount, itemsBefore);
    expect(buffer.size, bytesBefore);
    expect(_chainFingerprint(buffer, 6), chainBefore);
  });

  test('budget chunking converges on the unbudgeted result', () async {
    final buffer = await _filled(factory, 8);
    addTearDown(buffer.dispose);

    final direct = buffer.beginWalk()!;
    addTearDown(direct.dispose);

    expect(direct.seekTo(6, budget: 100), isTrue);

    final expected = direct.buildState().serialize(includeFrame: false);

    final chunked = buffer.beginWalk()!;
    addTearDown(chunked.dispose);

    var arrived = false;
    var iterations = 0;

    while (!arrived) {
      arrived = chunked.seekTo(6, budget: 2);

      iterations++;

      expect(iterations, lessThan(20), reason: 'seek did not converge');
    }

    expect(chunked.position, 6);
    expect(chunked.buildState().serialize(includeFrame: false), expected);
    expect(iterations, 3);
  });

  test('stepping forward reuses the states it walked through', () async {
    final buffer = await _filled(factory, 8);
    addTearDown(buffer.dispose);

    final reference = buffer.beginWalk()!;
    addTearDown(reference.dispose);

    expect(reference.seekTo(5, budget: 100), isTrue);

    final expected = reference.buildState().serialize(includeFrame: false);
    final expectedFrame = reference.frame![0];

    final walk = buffer.beginWalk()!;
    addTearDown(walk.dispose);

    expect(walk.seekTo(6, budget: 100), isTrue);

    expect(walk.seekTo(5, budget: 1), isTrue);
    expect(walk.position, 5);
    expect(walk.buildState().serialize(includeFrame: false), expected);
    expect(walk.frame![0], expectedFrame);
  });

  test('overshooting forward re-seeds and lands correctly', () async {
    final buffer = await _filled(factory, 8);
    addTearDown(buffer.dispose);

    final reference = buffer.beginWalk()!;
    addTearDown(reference.dispose);

    expect(reference.seekTo(2, budget: 100), isTrue);

    final expected = reference.buildState().serialize(includeFrame: false);

    final walk = buffer.beginWalk()!;
    addTearDown(walk.dispose);

    expect(walk.seekTo(6, budget: 100), isTrue);
    expect(walk.seekTo(2, budget: 100), isTrue);

    expect(walk.position, 2);
    expect(walk.buildState().serialize(includeFrame: false), expected);

    expect(walk.frame![0], 6);
    expect(reference.frame![0], 6);
  });

  test('seeking past the chain start clamps', () async {
    final buffer = await _filled(factory, 4);
    addTearDown(buffer.dispose);

    final walk = buffer.beginWalk()!;
    addTearDown(walk.dispose);

    expect(walk.seekTo(999, budget: 1000), isTrue);
    expect(walk.position, buffer.itemCount - 1);
  });

  test('a walk over a cleared ring stops instead of replaying', () async {
    final buffer = RewindBuffer(size: 4);
    addTearDown(buffer.dispose);

    for (var i = 0; i < 6; i++) {
      buffer.add(factory.capture(i + 1, callStackDepth: i % 3));

      await flushMicrotasks();
    }

    final walk = buffer.beginWalk()!;
    addTearDown(walk.dispose);

    buffer.clear();

    expect(walk.seekTo(3, budget: 100), isTrue);
    expect(walk.position, 0);
  });

  test('beginWalk returns null on an empty buffer', () {
    final buffer = RewindBuffer(size: 4);
    addTearDown(buffer.dispose);

    expect(buffer.beginWalk(), isNull);
  });
}
