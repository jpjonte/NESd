// register names don't follow dart naming conventions
// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/extension/hex_extension.dart';
import 'package:nesd/nes/debugger/execution_log_state.dart';
import 'package:nesd/nes/isolate/nes_isolate_event.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/remote_nes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'execution_log.g.dart';

@riverpod
ExecutionLog executionLog(Ref ref) {
  final executionLog = ExecutionLog(
    nes: ref.watch(nesStateProvider),
    notifier: ref.watch(executionLogStateProvider.notifier),
  );

  ref.onDispose(executionLog.dispose);

  return executionLog;
}

/// Message client for the execution log: appends the [ExecutionLogLine]
/// batches the isolate-side `ExecutionLogBackend` flushes via
/// [ExecutionLogEvent], instead of building lines from a live CPU/
/// disassembler of its own.
class ExecutionLog {
  ExecutionLog({required this.nes, required this.notifier}) {
    _subscription = nes?.events.listen(_handleEvent);
  }

  final RemoteNes? nes;
  final ExecutionLogStateNotifier notifier;
  final List<ExecutionLogLine> lines = [];

  StreamSubscription<NesIsolateEvent>? _subscription;

  void dispose() {
    unawaited(_subscription?.cancel());
  }

  void clear() {
    lines.clear();
    notifier.clear();
  }

  void enable() {
    notifier.enable();
    nes?.setExecutionLogEnabled(true);
  }

  void disable() {
    notifier.disable();
    nes?.setExecutionLogEnabled(false);
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

  void _handleEvent(NesIsolateEvent event) {
    if (event is! ExecutionLogEvent || !notifier.executionLogState.enabled) {
      return;
    }

    lines.addAll(event.lines);

    notifier.setLines(lines);
  }
}
