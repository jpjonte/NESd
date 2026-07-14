// register names don't follow dart naming conventions
// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:typed_data';

import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/nes/debugger/disassembler.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes.dart';

/// Isolate-side mirror of `Debugger`
/// (`lib/nes/debugger/debugger.dart`).
///
/// Reacts to the same [NesEvent]s but emits state via the [onState] and
/// [onBreakpoints] callbacks instead of a Riverpod notifier, so it can run
/// inside an isolate without a `WidgetRef`.
class DebuggerBackend {
  DebuggerBackend({
    required this.nes,
    required this.eventBus,
    required this.disassembler,
    required this.onState,
    required this.onBreakpoints,
    required List<Breakpoint> initialBreakpoints,
  }) {
    nes.breakpoints = initialBreakpoints;

    _state = DebuggerState(breakpoints: initialBreakpoints);

    _subscription = eventBus.stream.listen(_handleEvent);
  }

  final NES nes;
  final EventBus eventBus;
  final DisassemblerInterface disassembler;
  final void Function(DebuggerState state, Uint8List cpuMemory) onState;
  final void Function(String fileHash, List<Breakpoint> breakpoints)
  onBreakpoints;

  late final StreamSubscription<NesEvent> _subscription;

  late DebuggerState _state;

  void dispose() {
    _subscription.cancel();
  }

  void addBreakpoint(Breakpoint breakpoint) {
    nes.addBreakpoint(breakpoint);

    _updateBreakpoints();
  }

  void removeBreakpoint(int address) {
    nes.removeBreakpoint(address);

    _updateBreakpoints();
  }

  void setBreakpoints(List<Breakpoint> breakpoints) {
    nes.breakpoints = breakpoints;

    _updateBreakpoints();
  }

  void _updateBreakpoints() {
    _state = _state.copyWith(breakpoints: nes.breakpoints);

    onBreakpoints(nes.bus.cartridge.fileHash, nes.breakpoints);
  }

  void _handleEvent(NesEvent event) {
    switch (event) {
      case DebuggerNesEvent():
      case SuspendNesEvent():
        final stack = <int>[];

        var SP = nes.cpu.SP.clamp(0x00, 0xff);

        while (SP < 0xff) {
          SP++;
          stack.add(nes.cpu.read(0x100 + SP));
        }

        _state = _state.copyWith(
          enabled: true,
          disassembly: disassembler.update(),
          PC: nes.cpu.PC,
          A: nes.cpu.A,
          X: nes.cpu.X,
          Y: nes.cpu.Y,
          SP: nes.cpu.SP,
          P: nes.cpu.P,
          C: nes.cpu.C == 1,
          Z: nes.cpu.Z == 1,
          I: nes.cpu.I == 1,
          D: nes.cpu.D == 1,
          B: nes.cpu.B == 1,
          V: nes.cpu.V == 1,
          N: nes.cpu.N == 1,
          stack: stack,
          irq: nes.cpu.irq,
          nmi: nes.cpu.nmi,
          breakpoints: nes.breakpoints,
          canStepOut: nes.cpu.callStack.isNotEmpty,
          scanline: nes.ppu.scanline,
          cycle: nes.ppu.cycle,
          v: nes.ppu.v,
          t: nes.ppu.t,
          x: nes.ppu.x,
          spriteOverflow: nes.ppu.PPUSTATUS_O == 1,
          sprite0Hit: nes.ppu.PPUSTATUS_S == 1,
          vBlank: nes.ppu.PPUSTATUS_V == 1,
        );

        onState(_state, _dumpCpuMemory());
      case ResumeNesEvent():
        _state = _state.copyWith(enabled: false);

        onState(_state, Uint8List(0));
      default:
    }
  }

  Uint8List _dumpCpuMemory() {
    final memory = Uint8List(0x10000);

    for (var address = 0; address < 0x10000; address++) {
      memory[address] = nes.bus.cpuRead(address, disableSideEffects: true);
    }

    return memory;
  }
}
