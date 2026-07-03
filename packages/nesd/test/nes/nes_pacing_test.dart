import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/cartridge/cartridge_factory.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

import '../ui/mocks.dart';

Cartridge loadNestest() {
  const path = '../../roms/test/nestest/nestest.nes';

  final factory = CartridgeFactory(database: MockNesDatabase());

  return factory.fromFile(
    const FilesystemFile(path: path, name: path, type: FilesystemFileType.file),
    File(path).readAsBytesSync(),
  )..databaseEntry = null;
}

void main() {
  test(
    'sleepTime follows the governor drain law when the buffer is full',
    () async {
      final eventBus = EventBus();

      // fill == capacity => hard drain: (2400 - 1200) / 48000 s = 25ms,
      // independent of elapsed time, so the assertion is deterministic.
      final nes = NES(
        cartridge: loadNestest(),
        eventBus: eventBus,
        audioFillProbe: () => (fill: 2400, capacity: 2400),
      );

      final firstFrame = eventBus.stream.firstWhere(
        (event) => event is FrameNesEvent,
      );

      nes.reset();

      final event =
          await firstFrame.timeout(const Duration(seconds: 30))
              as FrameNesEvent;

      nes.stop();

      expect(event.sleepTime, const Duration(microseconds: 25000));
    },
  );

  test('fastForward emits empty samples and zero sleep', () async {
    final eventBus = EventBus();
    final nes = NES(cartridge: loadNestest(), eventBus: eventBus);

    final fastForwardFrame = eventBus.stream.firstWhere(
      (event) => event is FrameNesEvent && event.samples.isEmpty,
    );

    // reset() clears fastForward, so enable it after the loop starts.
    nes
      ..reset()
      ..fastForward = true;

    final event =
        await fastForwardFrame.timeout(const Duration(seconds: 30))
            as FrameNesEvent;

    nes.stop();

    expect(event.samples, isEmpty);
    expect(event.sleepTime, Duration.zero);
  });
}
