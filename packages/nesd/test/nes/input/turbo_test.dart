import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/nes/turbo_speed.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../../ui/mocks.dart';

const _nestestPath = '../../roms/test/nestest/nestest.nes';

Cartridge loadNestest() {
  final factory = CartridgeFactory(database: MockNesDatabase());

  return factory.fromFile(
    const FilesystemFile(
      path: _nestestPath,
      name: _nestestPath,
      type: FilesystemFileType.file,
    ),
    File(_nestestPath).readAsBytesSync(),
  )..databaseEntry = null;
}

void main() {
  group('turbo pulse', () {
    late NES nes;
    late Bus bus;

    setUp(() {
      nes = NES(cartridge: loadNestest(), eventBus: EventBus());
      bus = nes.bus;
    });

    tearDown(() => nes.stop());

    bool isPressed(int controller, NesButton button) {
      final address = 0x4016 + controller;

      bus
        ..cpuWrite(0x4016, 1)
        ..cpuWrite(0x4016, 0);

      for (var i = 0; i < button.index; i++) {
        bus.cpuRead(address);
      }

      return bus.cpuRead(address) & 1 == 1;
    }

    List<bool> pressedOverFrames(int count) {
      final phases = <bool>[];

      for (var frame = 0; frame < count; frame++) {
        bus.updateTurboPhase(frame);

        phases.add(isPressed(0, NesButton.a));
      }

      return phases;
    }

    test('pulses on and off every frame at the fastest speed', () {
      bus
        ..turboSpeed = TurboSpeed.x1
        ..buttonDown(0, NesButton.a, turbo: true);

      expect(pressedOverFrames(4), [true, false, true, false]);
    });

    test('holds each phase for the speed divider in frames', () {
      bus
        ..turboSpeed = TurboSpeed.x2
        ..buttonDown(0, NesButton.a, turbo: true);

      expect(pressedOverFrames(6), [true, true, false, false, true, true]);
    });

    test('routes a turbo press to the addressed controller only', () {
      bus
        ..turboSpeed = TurboSpeed.x1
        ..buttonDown(1, NesButton.b, turbo: true)
        ..updateTurboPhase(0);

      expect(isPressed(1, NesButton.b), isTrue);
      expect(isPressed(0, NesButton.b), isFalse);
    });

    test('releasing turbo leaves the normal press held', () {
      bus
        ..turboSpeed = TurboSpeed.x1
        ..buttonDown(0, NesButton.a)
        ..buttonDown(0, NesButton.a, turbo: true)
        ..buttonUp(0, NesButton.a, turbo: true)
        ..updateTurboPhase(1);

      expect(isPressed(0, NesButton.a), isTrue);
    });

    test('toggles a turbo press', () {
      bus
        ..turboSpeed = TurboSpeed.x1
        ..buttonToggle(0, NesButton.a, turbo: true)
        ..updateTurboPhase(0);

      expect(isPressed(0, NesButton.a), isTrue);

      bus
        ..buttonToggle(0, NesButton.a, turbo: true)
        ..updateTurboPhase(0);

      expect(isPressed(0, NesButton.a), isFalse);
    });
  });

  test('the run loop advances the phase once per rendered frame', () async {
    final eventBus = EventBus();

    final nes = NES(cartridge: loadNestest(), eventBus: eventBus)
      ..turboSpeed = TurboSpeed.x1;

    nes.bus.buttonDown(0, NesButton.a, turbo: true);

    final phases = <bool>[];

    final subscription = eventBus.stream.listen((event) {
      if (event is! FrameNesEvent) {
        return;
      }

      nes.bus
        ..cpuWrite(0x4016, 1)
        ..cpuWrite(0x4016, 0);

      phases.add(nes.bus.cpuRead(0x4016) & 1 == 1);
    });

    nes.reset();

    while (phases.length < 5) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    nes.stop();

    await subscription.cancel();

    final settled = phases.skip(1).take(4).toList();

    expect(settled, [
      settled.first,
      !settled.first,
      settled.first,
      !settled.first,
    ]);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
