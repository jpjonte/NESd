import 'dart:typed_data';

import 'package:nesd/nes/cpu/operation.dart';

sealed class NesEvent {
  const NesEvent();
}

class FrameNesEvent extends NesEvent {
  const FrameNesEvent({
    required this.samples,
    required this.frameTime,
    required this.frame,
    required this.sleepBudget,
    required this.rewindSize,
  });

  final Float32List samples;
  final Duration frameTime;
  final int frame;
  final Duration sleepBudget;
  final int rewindSize;
}

class DebuggerNesEvent extends NesEvent {}

class SuspendNesEvent extends NesEvent {}

class ResumeNesEvent extends NesEvent {}

class StepNesEvent extends NesEvent {
  const StepNesEvent(this.opcode, this.operation);

  final int opcode;
  final Operation operation;
}

class ErrorNesEvent extends NesEvent {
  const ErrorNesEvent(this.error);

  final Object error;
}
