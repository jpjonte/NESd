import 'dart:async';

import 'package:nesd/nes/debugger/disassembler.dart';
import 'package:nesd/nes/debugger/execution_log_state.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes.dart';

/// Isolate-side mirror of `ExecutionLog`
/// (`lib/nes/debugger/execution_log.dart`).
///
/// Builds [ExecutionLogLine]s from [StepNesEvent]s but, unlike the UI
/// class, batches them and flushes via [onLines] only on [FrameNesEvent],
/// [DebuggerNesEvent], and [SuspendNesEvent] instead of per instruction.
/// A per-step message would be ~10k messages per frame. The debugger
/// events matter because paused stepping emits no frames.
class ExecutionLogBackend {
  ExecutionLogBackend({
    required this.nes,
    required this.eventBus,
    required this.disassembler,
    required this.onLines,
  }) {
    _subscription = eventBus.stream.listen(_handleEvent);
  }

  final NES nes;
  final EventBus eventBus;
  final DisassemblerInterface disassembler;
  final void Function(List<ExecutionLogLine> lines) onLines;

  final List<ExecutionLogLine> _batch = [];

  bool _enabled = false;

  late final StreamSubscription<NesEvent> _subscription;

  void dispose() {
    _subscription.cancel();
  }

  // the single bool parameter mirrors the protocol command it backs
  // ignore: avoid_positional_boolean_parameters
  void setEnabled(bool enabled) {
    _enabled = enabled;
    nes.cpu.executionLogEnabled = enabled;

    if (!enabled) {
      _batch.clear();
    }
  }

  void _handleEvent(NesEvent event) {
    switch (event) {
      case StepNesEvent():
        _handleStep(event);
      case FrameNesEvent():
      case DebuggerNesEvent():
      case SuspendNesEvent():
        _flush();
      default:
    }
  }

  void _handleStep(StepNesEvent event) {
    if (!_enabled) {
      return;
    }

    final state = nes.cpu.state;
    final opcode = event.opcode;

    final disassemblyLine = disassembler.disassembleLine(
      state.PC,
      state: state,
    );

    _batch.add(
      ExecutionLogLine(
        address: state.PC,
        opcode: opcode,
        operands: disassemblyLine?.operands ?? [],
        instruction: disassemblyLine?.operation.instruction.name ?? '',
        disassembly: disassemblyLine?.disassembly ?? '',
        effectiveAddress: disassemblyLine?.addressIsCalculated == true
            ? disassemblyLine?.readAddress
            : null,
        value: disassemblyLine?.isRead == true
            ? nes.bus.cpuRead(
                disassemblyLine!.readAddress,
                disableSideEffects: true,
              )
            : null,
        A: state.A,
        X: state.X,
        Y: state.Y,
        SP: state.SP,
        P: state.P,
        scanline: nes.ppu.scanline,
        cycle: nes.ppu.cycle,
      ),
    );
  }

  void _flush() {
    if (_batch.isEmpty) {
      return;
    }

    onLines(List.unmodifiable(_batch));

    _batch.clear();
  }
}
