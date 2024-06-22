import 'package:nes/nes/bus.dart';
import 'package:nes/ui/emulator/input/action/controller_press.dart';
import 'package:nes/ui/emulator/input/action/load_file.dart';
import 'package:nes/ui/emulator/input/action/save_state.dart';

const allActions = [
  controller1Up,
  controller1Down,
  controller1Left,
  controller1Right,
  controller1Start,
  controller1Select,
  controller1A,
  controller1B,
  controller2Up,
  controller2Down,
  controller2Left,
  controller2Right,
  controller2Start,
  controller2Select,
  controller2A,
  controller2B,
  saveState1,
  saveState2,
  saveState3,
  saveState4,
  saveState5,
  saveState6,
  saveState7,
  saveState8,
  saveState9,
  loadState1,
  loadState2,
  loadState3,
  loadState4,
  loadState5,
  loadState6,
  loadState7,
  loadState8,
  loadState9,
];

sealed class NesAction {
  const NesAction({
    required this.title,
    required this.code,
  });

  final String title;
  final String code;
}

class ControllerPress extends NesAction {
  const ControllerPress(
    this.controller,
    this.button, {
    required super.title,
    required super.code,
  });

  final int controller;
  final NesButton button;
}

class SaveState extends NesAction {
  const SaveState(
    this.slot, {
    required super.title,
    required super.code,
  });

  final int slot;
}

class LoadState extends NesAction {
  const LoadState(
    this.slot, {
    required super.title,
    required super.code,
  });

  final int slot;
}
