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

  @override
  Future<void> get ready => Future.value();
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

void main() {
  late NES nes;
  late List<FrameNesEvent> frames;
  late StreamSubscription<FrameNesEvent> subscription;

  setUp(() {
    nes = _buildNes();
    frames = [];
    subscription = nes.eventBus.stream
        .where((event) => event is FrameNesEvent)
        .cast<FrameNesEvent>()
        .listen(frames.add);
  });

  tearDown(() async {
    nes.stop();

    await subscription.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });

  Future<void> runThenPause() async {
    unawaited(nes.run());

    await _waitUntil(() => frames.length >= 3);

    nes.pause();

    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  test('a step from pause runs exactly one frame and pauses again', () async {
    await runThenPause();

    final before = nes.ppu.frames;
    final emitted = frames.length;

    nes.nextFrame();

    await _waitUntil(() => !nes.running);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(nes.ppu.frames, before + 1);
    expect(frames, hasLength(emitted + 1));
    expect(frames.last.stepped, isTrue);
    expect(nes.paused, isTrue);
    expect(nes.frameStepping, isTrue);
  });

  test('frames of normal play are not stepped', () async {
    await runThenPause();

    expect(frames.where((frame) => frame.stepped), isEmpty);
  });

  test('while running it pauses without stepping', () async {
    unawaited(nes.run());

    await _waitUntil(() => frames.length >= 3);

    nes.nextFrame();

    expect(nes.paused, isTrue);
    expect(nes.running, isFalse);
    expect(nes.stopAfterNextFrame, isFalse);
    expect(nes.frameStepping, isTrue);
  });

  test('does nothing while rewinding', () async {
    await runThenPause();

    nes
      ..rewindEnabled = true
      ..rewind = true
      ..nextFrame();

    expect(nes.running, isFalse);
    expect(nes.stopAfterNextFrame, isFalse);
    expect(nes.frameStepping, isFalse);
  });

  test('does nothing without a running game', () {
    nes
      ..stop()
      ..nextFrame();

    expect(nes.running, isFalse);
    expect(nes.stopAfterNextFrame, isFalse);
    expect(nes.frameStepping, isFalse);
  });

  test('a press while a step is in flight does not pause mid-frame', () {
    nes
      ..on = true
      ..running = true
      ..stopAfterNextFrame = true
      ..nextFrame();

    expect(nes.paused, isFalse);
    expect(nes.running, isTrue);
  });

  test('a step interrupted by a pause does not block the next step', () {
    nes
      ..on = true
      ..pause()
      ..stopAfterNextFrame = true
      ..nextFrame();

    expect(nes.running, isTrue);
    expect(nes.stopAfterNextFrame, isTrue);
    expect(nes.frameStepping, isTrue);
  });

  test('a pause cancels a step in flight', () {
    nes
      ..on = true
      ..running = true
      ..stopAfterNextFrame = true
      ..pause();

    expect(nes.stopAfterNextFrame, isFalse);
  });

  test('unpausing after an interrupted step keeps running', () async {
    await runThenPause();

    nes
      ..stopAfterNextFrame = true
      ..running = true
      ..pause()
      ..unpause();

    final emitted = frames.length;

    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(frames.length, greaterThan(emitted + 2));
    expect(nes.running, isTrue);
  });

  test('unpausing ends frame stepping', () {
    nes
      ..on = true
      ..frameStepping = true
      ..pause()
      ..unpause();

    expect(nes.frameStepping, isFalse);
  });
}
