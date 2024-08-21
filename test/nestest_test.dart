import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';

void main() {
  test('Run nestest', () {
    const path = 'roms/test/nestest/nestest.nes';

    final file = File(path);

    final cartridge = Cartridge.fromFile(path, file.readAsBytesSync());

    final nes = NES(cartridge: cartridge, eventBus: EventBus())..reset();

    nes.bus.buttonDown(0, NesButton.start); // start tests of official opcodes

    _runLoop(nes, 0xc0ea); // run until all tests passed

    nes.bus.buttonUp(0, NesButton.start);

    nes.bus.buttonDown(0, NesButton.select); // switch to next page

    _runLoop(nes, 0xc135); // run until page has been switched

    nes.bus.buttonUp(0, NesButton.select);

    nes.bus.buttonDown(0, NesButton.start); // start tests of unofficial opcodes

    _runLoop(nes, 0xc18f); // run until all tests passed
  });
}

void _runLoop(NES nes, int breakAddress) {
  while (true) {
    final exit = nes.cpu.PC == breakAddress;

    nes.step();

    nes.apu.sampleIndex = 0;

    final low = nes.cpu.read(0x02);
    final high = nes.cpu.read(0x03);
    final result = (high << 8) | low;

    expect(result, equals(0));

    if (exit) {
      break;
    }
  }
}
