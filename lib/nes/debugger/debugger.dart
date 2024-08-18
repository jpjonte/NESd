import 'dart:async';

import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/nes/debugger/disassembler.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'debugger.g.dart';

@riverpod
Debugger debugger(DebuggerRef ref) {
  final nes = ref.watch(nesStateProvider);
  final notifier = ref.watch(debuggerNotifierProvider.notifier);
  final disassembler = ref.watch(disassemblerProvider);

  if (nes == null) {
    return DummyDebugger();
  }

  final subscription = ref.listen(debuggerNotifierProvider, (_, __) {});

  final debugger = Debugger(
    eventBus: ref.watch(eventBusProvider),
    nes: nes,
    notifier: notifier,
    disassembler: disassembler,
  );

  ref
    ..onDispose(debugger.dispose)
    ..onDispose(subscription.close);

  return debugger;
}

class Debugger {
  Debugger({
    required this.eventBus,
    required this.nes,
    required this.disassembler,
    required this.notifier,
  }) {
    _subscription = eventBus.stream.listen(_handleEvent);
  }

  final EventBus eventBus;
  final NES nes;
  final Disassembler disassembler;
  final DebuggerNotifier notifier;

  late final StreamSubscription<NesEvent> _subscription;

  void dispose() {
    _subscription.cancel();
  }

  void addBreakpoint(Breakpoint breakpoint) {
    nes.addBreakpoint(breakpoint);

    _updateBreakpoints();
  }

  void removeBreakpoint(Breakpoint breakpoint) {
    nes.removeBreakpoint(breakpoint.address);

    _updateBreakpoints();
  }

  bool hasBreakpoint(int address) {
    return nes.breakpoints.any((e) => e.address == address && !e.hidden);
  }

  void toggleBreakpoint(int address) {
    if (hasBreakpoint(address)) {
      nes.removeBreakpoint(address);
    } else {
      nes.addBreakpoint(Breakpoint(address));
    }

    _updateBreakpoints();
  }

  void _handleEvent(NesEvent event) {
    switch (event) {
      case DebuggerNesEvent():
      case SuspendNesEvent():
        notifier.debuggerState = notifier.debuggerState.copyWith(
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
      case ResumeNesEvent():
        notifier.debuggerState = notifier.debuggerState.copyWith(
          enabled: false,
        );
      default:
    }
  }

  void _updateBreakpoints() {
    notifier.debuggerState = notifier.debuggerState.copyWith(
      breakpoints: nes.breakpoints,
    );
  }
}

class DummyDebugger implements Debugger {
  @override
  StreamSubscription<NesEvent> _subscription =
      const Stream<NesEvent>.empty().listen((event) {});

  @override
  Disassembler get disassembler => throw UnimplementedError();

  @override
  void dispose() {
    _subscription.cancel();
  }

  @override
  NES get nes => throw UnimplementedError();

  @override
  DebuggerNotifier get notifier => throw UnimplementedError();

  @override
  void addBreakpoint(Breakpoint breakpoint) {}

  @override
  void removeBreakpoint(Breakpoint breakpoint) {}

  @override
  void toggleBreakpoint(int address) {}

  @override
  void _handleEvent(NesEvent event) {}

  @override
  void _updateBreakpoints() {}

  @override
  bool hasBreakpoint(int address) {
    throw UnimplementedError();
  }

  @override
  EventBus get eventBus => throw UnimplementedError();
}
