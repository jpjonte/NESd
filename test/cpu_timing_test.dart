import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cartridge/cartridge.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/nes.dart';

void main() {
  test('Run cpu timing test', () {
    const path = 'roms/test/cpu_timing_test6/cpu_timing_test.nes';

    final file = File(path);

    final cartridge = Cartridge.fromFile(path, file.readAsBytesSync());

    final nes = NES(cartridge: cartridge, eventBus: EventBus())..reset();

    nes.bus.buttonDown(0, NesButton.b); // start test of all opcodes

    _runLoop(
      nes,
      0xe1b7,
      maxIterations: 30000000,
    ); // run until all tests passed
  });
}

void _runLoop(NES nes, int breakAddress, {int? maxIterations}) {
  var iterations = 0;

  while (true) {
    final exit =
        (nes.cpu.PC == breakAddress && nes.cpu.fetching) ||
        (maxIterations != null && iterations >= maxIterations);

    nes.step();

    nes.apu.sampleIndex = 0;

    expect(nes.cpu.PC, isNot(equals(0xe116))); // E116 is the failure subroutine

    iterations++;

    if (exit) {
      break;
    }
  }
}
