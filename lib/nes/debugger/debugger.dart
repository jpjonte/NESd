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
DebuggerInterface debugger(Ref ref) {
  final nes = ref.watch(nesStateProvider);
  final notifier = ref.watch(debuggerNotifierProvider.notifier);
  final disassembler = ref.watch(disassemblerProvider);

  if (nes == null) {
    return DummyDebugger();
  }

  final subscription = ref.listen(debuggerNotifierProvider, (_, _) {});

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

abstract class DebuggerInterface {
  void addBreakpoint(Breakpoint breakpoint);

  void removeBreakpoint(Breakpoint breakpoint);

  void updateBreakpoint(Breakpoint breakpoint);

  bool hasBreakpoint(int address);

  void toggleBreakpointExists(int address);

  void toggleBreakpointEnabled(int address);

  void showStack();

  void hideStack();

  void toggleExecutionLog();

  int read(int address);

  void selectAddress(int address);
}

class Debugger implements DebuggerInterface {
  Debugger({
    required this.eventBus,
    required this.nes,
    required this.disassembler,
    required this.notifier,
    required this.settingsController,
  }) {
    _subscription = eventBus.stream.listen(_handleEvent);

    final breakpoints =
        settingsController.breakpoints[nes.bus.cartridge.fileHash] ?? [];

    nes.breakpoints = breakpoints;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.debuggerState = DebuggerState(breakpoints: breakpoints);
    });
  }

  final EventBus eventBus;
  final NES nes;
  final DisassemblerInterface disassembler;
  final DebuggerNotifier notifier;
  final SettingsController settingsController;

  late final StreamSubscription<NesEvent> _subscription;

  void dispose() {
    _subscription.cancel();
  }

  @override
  void addBreakpoint(Breakpoint breakpoint) {
    nes.addBreakpoint(breakpoint);

    _updateBreakpoints();
  }

  @override
  void updateBreakpoint(Breakpoint breakpoint) {
    _updateBreakpoints();
  }

  @override
  void removeBreakpoint(Breakpoint breakpoint) {
    nes.removeBreakpoint(breakpoint.address);

    _updateBreakpoints();
  }

  @override
  bool hasBreakpoint(int address) {
    return nes.breakpoints.any(
      (breakpoint) => breakpoint.address == address && !breakpoint.hidden,
    );
  }

  @override
  void toggleBreakpointExists(int address) {
    if (hasBreakpoint(address)) {
      nes.removeBreakpoint(address);
    } else {
      nes.addBreakpoint(Breakpoint(address));
    }

    _updateBreakpoints();
  }

  @override
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

  @override
  void showStack() {
    notifier.debuggerState = notifier.debuggerState.copyWith(
      showStack: !notifier.debuggerState.showStack,
    );
  }

  @override
  void hideStack() {
    notifier.debuggerState = notifier.debuggerState.copyWith(showStack: false);
  }

  @override
  void toggleExecutionLog() {
    notifier.debuggerState = notifier.debuggerState.copyWith(
      executionLogOpen: !notifier.debuggerState.executionLogOpen,
    );
  }

  @override
  int read(int address) => nes.bus.cpuRead(address, disableSideEffects: true);

  @override
  void selectAddress(int address) {
    if (notifier.debuggerState.selectedAddress == address) {
      notifier.debuggerState = notifier.debuggerState.copyWith(
        selectedAddress: null,
      );
    } else {
      notifier.debuggerState = notifier.debuggerState.copyWith(
        selectedAddress: address,
      );
    }
  }

  void _handleEvent(NesEvent event) {
    switch (event) {
      case DebuggerNesEvent():
      case SuspendNesEvent():
        final stack = <int>[];

        // register names don't follow dart naming conventions
        // ignore: non_constant_identifier_names
        var SP = nes.cpu.SP.clamp(0x00, 0xff);

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

    settingsController.setBreakpoints(
      nes.bus.cartridge.fileHash,
      nes.breakpoints,
    );
  }
}

class DummyDebugger implements DebuggerInterface {
  @override
  void addBreakpoint(Breakpoint breakpoint) {}

  @override
  void removeBreakpoint(Breakpoint breakpoint) {}

  @override
  void toggleBreakpointExists(int address) {}

  @override
  bool hasBreakpoint(int address) {
    throw UnimplementedError();
  }

  @override
  void toggleBreakpointEnabled(int address) {}

  @override
  void updateBreakpoint(Breakpoint breakpoint) {}

  @override
  void hideStack() {}

  @override
  void showStack() {}

  @override
  void toggleExecutionLog() {}

  @override
  int read(int address) => 0;

  @override
  void selectAddress(int address) {}
}
