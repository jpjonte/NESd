import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/nes/debugger/disassembler.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'debugger.g.dart';

@riverpod
Debugger debugger(Ref ref) {
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
    settingsController: ref.watch(settingsControllerProvider.notifier),
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
    required this.settingsController,
  }) {
    _subscription = eventBus.stream.listen(_handleEvent);

    final breakpoints =
        settingsController.breakpoints[nes.bus.cartridge.hash] ?? [];

    nes.breakpoints = breakpoints;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.debuggerState = DebuggerState(breakpoints: breakpoints);
    });
  }

  final EventBus eventBus;
  final NES nes;
  final Disassembler disassembler;
  final DebuggerNotifier notifier;
  final SettingsController settingsController;

  late final StreamSubscription<NesEvent> _subscription;

  void dispose() {
    _subscription.cancel();
  }

  void addBreakpoint(Breakpoint breakpoint) {
    nes.addBreakpoint(breakpoint);

    _updateBreakpoints();
  }

  void updateBreakpoint(Breakpoint breakpoint) {
    _updateBreakpoints();
  }

  void removeBreakpoint(Breakpoint breakpoint) {
    nes.removeBreakpoint(breakpoint.address);

    _updateBreakpoints();
  }

  bool hasBreakpoint(int address) {
    return nes.breakpoints.any(
      (breakpoint) => breakpoint.address == address && !breakpoint.hidden,
    );
  }

  void toggleBreakpointExists(int address) {
    if (hasBreakpoint(address)) {
      nes.removeBreakpoint(address);
    } else {
      nes.addBreakpoint(Breakpoint(address));
    }

    _updateBreakpoints();
  }

  void toggleBreakpointEnabled(int address) {
    if (!hasBreakpoint(address)) {
      return;
    }

    final breakpoint = nes.breakpoints.firstWhere(
      (b) => b.address == address && !b.hidden,
    );

    breakpoint.enabled = !breakpoint.enabled;

    _updateBreakpoints();
  }

  void showStack() {
    notifier.debuggerState = notifier.debuggerState.copyWith(
      showStack: !notifier.debuggerState.showStack,
    );
  }

  void hideStack() {
    notifier.debuggerState = notifier.debuggerState.copyWith(showStack: false);
  }

  void _handleEvent(NesEvent event) {
    switch (event) {
      case DebuggerNesEvent():
      case SuspendNesEvent():
        final stack = <int>[];

        // register names don't follow dart naming conventions
        // ignore: non_constant_identifier_names
        var SP = nes.cpu.SP;

        while (SP < 0xff) {
          SP++;
          stack.add(nes.cpu.read(0x100 + SP));
        }

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

    settingsController.setBreakpoints(nes.bus.cartridge.hash, nes.breakpoints);
  }
}

class DummyDebugger implements Debugger {
  @override
  StreamSubscription<NesEvent> _subscription = const Stream<NesEvent>.empty()
      .listen((event) {});

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
  void toggleBreakpointExists(int address) {}

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

  @override
  SettingsController get settingsController => throw UnimplementedError();

  @override
  void toggleBreakpointEnabled(int address) {}

  @override
  void updateBreakpoint(Breakpoint breakpoint) {}

  @override
  void hideStack() {}

  @override
  void showStack() {}
}
