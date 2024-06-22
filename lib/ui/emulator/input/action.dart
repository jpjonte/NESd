import 'package:nes/nes/bus.dart';

typedef ActionHandler = void Function(NesAction action);

sealed class NesAction {
  const NesAction();
}

class ControllerButtonAction extends NesAction {
  const ControllerButtonAction(this.controller, this.button);

  final int controller;
  final NesButton button;
}

class SaveState extends NesAction {
  const SaveState(this.slot);

  final int slot;
}

class LoadState extends NesAction {
  const LoadState(this.slot);

  final int slot;
}
