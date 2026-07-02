// register names don't follow dart naming conventions
// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/extension/hex_extension.dart';
import 'package:nesd/nes/debugger/disassembler.dart';
import 'package:nesd/nes/debugger/execution_log_state.dart';
import 'package:nesd/nes/event/event_bus.dart';
import 'package:nesd/nes/event/nes_event.dart';
import 'package:nesd/nes/nes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'execution_log.g.dart';

// TEMPORARY: the live NES now runs in the emulator isolate, so the execution
// log has no local NES to observe. Will be reconnected through the isolate
// protocol; until then it stays inert (`nes: null`).
@riverpod
ExecutionLog executionLog(Ref ref) {
  final executionLog = ExecutionLog(
    eventBus: ref.watch(eventBusProvider),
    notifier: ref.watch(executionLogStateProvider.notifier),
    nes: null,
    disassembler: ref.watch(disassemblerProvider),
  );

  ref.onDispose(executionLog.dispose);

  return executionLog;
}

class ExecutionLog {
  ExecutionLog({
    required this.eventBus,
    required this.notifier,
    required this.nes,
    required this.disassembler,
  }) {
    _eventSubscription = eventBus.stream.listen(_handleEvent);
  }

  final EventBus eventBus;
  final ExecutionLogStateNotifier notifier;
  final NES? nes;
  final DisassemblerInterface disassembler;
  final List<ExecutionLogLine> lines = [];

  late final StreamSubscription<NesEvent> _eventSubscription;

  void dispose() {
    _eventSubscription.cancel();
  }

  void clear() {
    lines.clear();
    notifier.clear();
  }

  void enable() {
    notifier.enable();
    nes?.cpu.executionLogEnabled = true;
  }

  void disable() {
    notifier.disable();
    nes?.cpu.executionLogEnabled = false;
  }

  void toggle() {
    if (notifier.executionLogState.enabled) {
      disable();
    } else {
      enable();
    }
  }

  String printLine(ExecutionLogLine line) {
    var disassembly = line.disassembly;

    if (line.effectiveAddress case final address?) {
      disassembly += ' [\$${address.toHex()}]';
    }

    if (line.value case final value?) {
      disassembly += ' = \$${value.toHex()}';
    }

    final result = StringBuffer()
      ..write('${line.address.toHex(width: 4)}  ')
      ..write(line.instruction.padRight(4))
      ..write('${disassembly.padRight(28)} ')
      ..write('A:${line.A.toHex()} ')
      ..write('X:${line.X.toHex()} ')
      ..write('Y:${line.Y.toHex()} ')
      ..write('S:${line.SP.toHex()} ')
      ..write('P:')
      ..write(line.P.bit(7) == 1 ? 'N' : 'n')
      ..write(line.P.bit(6) == 1 ? 'V' : 'v')
      ..write('--')
      ..write(line.P.bit(3) == 1 ? 'D' : 'd')
      ..write(line.P.bit(2) == 1 ? 'I' : 'i')
      ..write((line.P >> 1) & 1 == 1 ? 'Z' : 'z')
      ..write(line.P.bit(0) == 1 ? 'C' : 'c');

    return result.toString();
  }

  Uint8List dumpAsBytes() {
    final contents = StringBuffer();

    for (final line in lines) {
      contents.writeln(printLine(line));
    }

    return utf8.encode(contents.toString());
  }

  void _handleEvent(NesEvent event) {
    final nes = this.nes;

    if (event is! StepNesEvent ||
        nes == null ||
        !notifier.executionLogState.enabled) {
      return;
    }

    final state = nes.cpu.state;
    final opcode = event.opcode;

    final disassemblyLine = disassembler.disassembleLine(
      state.PC,
      state: state,
    );

    lines.add(
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

    notifier.setLines(lines);
  }
}
