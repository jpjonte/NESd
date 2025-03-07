// register names don't follow dart naming conventions
// ignore_for_file: non_constant_identifier_names

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/debugger/disassembler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'debugger_state.freezed.dart';
part 'debugger_state.g.dart';

@freezed
class DebuggerState with _$DebuggerState {
  const factory DebuggerState({
    @Default(false) bool enabled,
    @Default([]) Disassembly disassembly,
    @Default(0) int PC,
    @Default(0) int A,
    @Default(0) int X,
    @Default(0) int Y,
    @Default(0) int SP,
    @Default(0) int P,
    @Default(false) bool C,
    @Default(false) bool Z,
    @Default(false) bool I,
    @Default(false) bool D,
    @Default(false) bool B,
    @Default(false) bool V,
    @Default(false) bool N,
    @Default(0) int irq,
    @Default(false) bool nmi,
    @Default([]) List<int> stack,
    @Default([]) List<Breakpoint> breakpoints,
    @Default(false) bool canStepOut,
    @Default(0) int scanline,
    @Default(0) int cycle,
    @Default(0) int v,
    @Default(0) int t,
    @Default(0) int x,
    @Default(false) bool spriteOverflow,
    @Default(false) bool sprite0Hit,
    @Default(false) bool vBlank,
    @Default(false) bool executionLogOpen,
    @Default(false) bool showStack,
  }) = _DebuggerState;
}

@riverpod
class DebuggerNotifier extends _$DebuggerNotifier {
  @override
  DebuggerState build() {
    return const DebuggerState();
  }

  DebuggerState get debuggerState => state;

  set debuggerState(DebuggerState state) {
    this.state = state;
  }

  void toggleExecutionLog() {
    state = state.copyWith(executionLogOpen: !state.executionLogOpen);
  }
}
