import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_id.dart';

void main() {
  test('builds ids from enum names', () {
    expect(buttonInputId(GamepadButton.a), 'button_a');
    expect(buttonInputId(GamepadButton.dpadUp), 'button_dpadUp');
    expect(axisInputId(GamepadAxis.leftStickX), 'axis_leftStickX');
  });

  test('derives human-readable labels', () {
    expect(buttonLabel(GamepadButton.a), 'A');
    expect(buttonLabel(GamepadButton.dpadUp), 'D-Pad Up');
    expect(buttonLabel(GamepadButton.leftBumper), 'LB');
    expect(axisLabel(GamepadAxis.leftStickX), 'Left Stick X');
    expect(axisLabel(GamepadAxis.rightTrigger), 'Right Trigger');
  });
}
