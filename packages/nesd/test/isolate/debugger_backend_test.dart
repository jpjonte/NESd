import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/nes/debugger/disassembler.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/isolate/debugger_backend.dart';

import '../test_roms/rom_robot.dart';

void main() {
  test('DebuggerBackend emits state with cpu memory dump on pause', () {
    final robot = RomRobot('../../roms/test/nestest/nestest.nes');

    // RomRobot's `reset()` fire-and-forgets `NES.run()`, which keeps
    // stepping the CPU on a real-time frame loop in the background (on
    // the robot's own internal event bus). Pause it so `robot.nes.cpu`
    // stays put while this test awaits the (separate) test event bus.
    robot.nes.pause();

    final eventBus = EventBus();
    final states = <DebuggerState>[];
    final dumps = <int>[];

    final backend = DebuggerBackend(
      nes: robot.nes,
      eventBus: eventBus,
      disassembler: Disassembler(eventBus: eventBus, cpu: robot.nes.cpu),
      onState: (state, cpuMemory) {
        states.add(state);
        dumps.add(cpuMemory.length);
      },
      onBreakpoints: (_, _) {},
      initialBreakpoints: const [],
    );

    eventBus.add(DebuggerNesEvent());

    // async broadcast stream delivers in a microtask
    return Future<void>.delayed(Duration.zero).then((_) {
      expect(states, hasLength(1));
      expect(states.single.PC, robot.nes.cpu.PC);
      expect(dumps.single, 0x10000);

      backend.dispose();
    });
  });

  test('breakpoint mutations notify onBreakpoints with fileHash', () {
    final robot = RomRobot('../../roms/test/nestest/nestest.nes');
    final eventBus = EventBus();
    String? hash;
    List<Breakpoint>? breakpoints;

    DebuggerBackend(
      nes: robot.nes,
      eventBus: eventBus,
      disassembler: DummyDisassembler(),
      onState: (_, _) {},
      onBreakpoints: (h, b) {
        hash = h;
        breakpoints = b;
      },
      initialBreakpoints: const [],
    ).addBreakpoint(Breakpoint(0x8000));

    expect(hash, robot.nes.bus.cartridge.fileHash);
    expect(breakpoints, hasLength(1));
  });
}
