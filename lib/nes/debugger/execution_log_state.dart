// register names don't follow dart naming conventions
// ignore_for_file: non_constant_identifier_names

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'execution_log_state.freezed.dart';
part 'execution_log_state.g.dart';

@freezed
sealed class ExecutionLogState with _$ExecutionLogState {
  const factory ExecutionLogState({
    @Default(false) bool enabled,
    @Default([]) List<ExecutionLogLine> lines,
  }) = _ExecutionLogState;
}

class ExecutionLogLine {
  const ExecutionLogLine({
    required this.address,
    required this.opcode,
    required this.operands,
    required this.instruction,
    required this.disassembly,
    required this.A,
    required this.X,
    required this.Y,
    required this.SP,
    required this.P,
    required this.scanline,
    required this.cycle,
  });

  final int address;
  final int opcode;
  final List<int> operands;
  final String instruction;
  final String disassembly;
  final int A;
  final int X;
  final int Y;
  final int SP;
  final int P;
  final int scanline;
  final int cycle;
}

@riverpod
class ExecutionLogNotifier extends _$ExecutionLogNotifier {
  @override
  ExecutionLogState build() {
    return const ExecutionLogState();
  }

  ExecutionLogState get executionLogState => state;

  set executionLogState(ExecutionLogState state) {
    this.state = state;
  }

  void enable() {
    executionLogState = executionLogState.copyWith(enabled: true);
  }

  void disable() {
    executionLogState = executionLogState.copyWith(enabled: false);
  }

  void toggle() {
    executionLogState = executionLogState.copyWith(
      enabled: !executionLogState.enabled,
    );
  }

  void setLines(List<ExecutionLogLine> lines) {
    executionLogState = executionLogState.copyWith(lines: lines);
  }

  void clear() {
    executionLogState = executionLogState.copyWith(lines: []);
  }
}
