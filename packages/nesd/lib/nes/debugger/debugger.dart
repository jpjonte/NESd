import 'dart:async';
import 'dart:typed_data';

import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/debugger/debugger_state.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'debugger.g.dart';

@riverpod
DebuggerInterface debugger(Ref ref) {
  final nes = ref.watch(nesStateProvider);

  if (nes == null) {
    return DummyDebugger();
  }

  final debugger = Debugger(
    nes: nes,
    notifier: ref.watch(debuggerStateProvider.notifier),
    settingsController: ref.read(settingsControllerProvider.notifier),
  );

  ref.onDispose(debugger.dispose);

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

/// Message client for the debugger: drives [nes] over the isolate protocol
/// and mirrors the isolate-side `DebuggerBackend` state into [notifier].
///
/// Holds no live CPU/PPU reference of its own — [DebuggerEvent] carries the
/// full [DebuggerState] plus a CPU memory dump, materialized once per event
/// and served back out through [read].
class Debugger implements DebuggerInterface {
  Debugger({
    required this.nes,
    required this.notifier,
    required this.settingsController,
  }) {
    _subscription = nes.events.listen(_handleEvent);

    nes
      ..setDebuggerActive(true)
      ..breakpoints = settingsController.breakpoints[nes.fileHash] ?? [];
  }

  final RemoteNes nes;
  final DebuggerStateNotifier notifier;
  final SettingsController settingsController;

  Uint8List? _cpuMemory;

  late final StreamSubscription<NesIsolateEvent> _subscription;

  void dispose() {
    nes.setDebuggerActive(false);

    unawaited(_subscription.cancel());
  }

  @override
  void addBreakpoint(Breakpoint breakpoint) => nes.addBreakpoint(breakpoint);

  @override
  void updateBreakpoint(Breakpoint breakpoint) => _pushBreakpoints();

  @override
  void removeBreakpoint(Breakpoint breakpoint) =>
      nes.removeBreakpoint(breakpoint.address);

  @override
  bool hasBreakpoint(int address) {
    return notifier.debuggerState.breakpoints.any(
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
  }

  @override
  void toggleBreakpointEnabled(int address) {
    if (!hasBreakpoint(address)) {
      return;
    }

    final breakpoint = notifier.debuggerState.breakpoints.firstWhere(
      (b) => b.address == address && !b.hidden,
    );

    breakpoint.enabled = !breakpoint.enabled;

    _pushBreakpoints();
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

  // `ResumeNesEvent` clears the dump to an empty `Uint8List` (see
  // `DebuggerBackend`) rather than omitting it, so an out-of-range address
  // here means "no dump available" and must fall back to 0, not throw.
  @override
  int read(int address) {
    final memory = _cpuMemory;

    if (memory == null || address >= memory.length) {
      return 0;
    }

    return memory[address];
  }

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

  void _handleEvent(NesIsolateEvent event) {
    switch (event) {
      case DebuggerEvent(:final state, :final cpuMemory):
        _cpuMemory = cpuMemory.materialize().asUint8List();

        notifier.debuggerState = state.copyWith(
          showStack: notifier.debuggerState.showStack,
          executionLogOpen: notifier.debuggerState.executionLogOpen,
          selectedAddress: notifier.debuggerState.selectedAddress,
        );

      // Persistence for breakpoint mutations is centralized in
      // `NesController._handleIsolateEvent` (one writer for settings), but
      // the debugger's own breakpoint list still needs to reflect mutations
      // made while paused (no DebuggerEvent fires for those), so it's
      // mirrored here without touching settings.
      case BreakpointsEvent(:final breakpoints):
        notifier.debuggerState = notifier.debuggerState.copyWith(
          breakpoints: breakpoints,
        );
      default:
    }
  }

  void _pushBreakpoints() {
    nes.breakpoints = notifier.debuggerState.breakpoints;
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
