import 'package:gamepads/gamepads.dart';

/// Builds the stable input id stored in bindings for a normalized
/// button.
String buttonInputId(GamepadButton button) => 'button_${button.name}';

/// Builds the stable input id stored in bindings for a normalized
/// axis.
String axisInputId(GamepadAxis axis) => 'axis_${axis.name}';

/// Human-readable label for a normalized button.
String buttonLabel(GamepadButton button) => switch (button) {
  GamepadButton.a => 'A',
  GamepadButton.b => 'B',
  GamepadButton.x => 'X',
  GamepadButton.y => 'Y',
  GamepadButton.leftBumper => 'LB',
  GamepadButton.rightBumper => 'RB',
  GamepadButton.leftTrigger => 'LT',
  GamepadButton.rightTrigger => 'RT',
  GamepadButton.back => 'Back',
  GamepadButton.start => 'Start',
  GamepadButton.home => 'Home',
  GamepadButton.leftStick => 'L3',
  GamepadButton.rightStick => 'R3',
  GamepadButton.dpadUp => 'D-Pad Up',
  GamepadButton.dpadDown => 'D-Pad Down',
  GamepadButton.dpadLeft => 'D-Pad Left',
  GamepadButton.dpadRight => 'D-Pad Right',
  GamepadButton.touchpad => 'Touchpad',
};

/// Human-readable label for a normalized axis.
String axisLabel(GamepadAxis axis) => switch (axis) {
  GamepadAxis.leftStickX => 'Left Stick X',
  GamepadAxis.leftStickY => 'Left Stick Y',
  GamepadAxis.rightStickX => 'Right Stick X',
  GamepadAxis.rightStickY => 'Right Stick Y',
  GamepadAxis.leftTrigger => 'Left Trigger',
  GamepadAxis.rightTrigger => 'Right Trigger',
};
