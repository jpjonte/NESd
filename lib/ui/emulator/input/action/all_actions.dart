import 'package:nesd/ui/emulator/input/input_action.dart';

const menuActions = [
  openMenu,
  menuDecrease,
  menuIncrease,
  confirm,
  secondaryAction,
  cancel,
  previousTab,
  nextTab,
  previousInput,
  nextInput,
];

const emulatorActions = [
  pause,
  unpause,
  togglePause,
  stop,
  toggleFastForward,
  decreaseVolume,
  increaseVolume,
];

const inputActions = [
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
];

const saveStateActions = [
  loadState0,
  saveState1,
  loadState1,
  saveState2,
  loadState2,
  saveState3,
  loadState3,
  saveState4,
  loadState4,
  saveState5,
  loadState5,
  saveState6,
  loadState6,
  saveState7,
  loadState7,
  saveState8,
  loadState8,
  saveState9,
  loadState9,
];

const allActions = [
  ...menuActions,
  ...emulatorActions,
  ...inputActions,
  ...saveStateActions,
];
