import 'package:gamepads/gamepads.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_id.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/gamepad_input.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';

Bindings migrateGamepadBindings(Bindings bindings) {
  return [
    for (final binding in bindings)
      if (binding.input case final GamepadInputCombination gamepad)
        binding.copyWith(
          input: gamepad.copyWith(
            inputs: {
              for (final input in gamepad.inputs) migrateGamepadInput(input),
            },
          ),
        )
      else
        binding,
  ];
}

GamepadInput migrateGamepadInput(GamepadInput input) {
  return _migrateButtonId(input) ??
      _migrateAxisId(input) ??
      _migrateHat(input) ??
      _migrateMacos(input) ??
      input;
}

GamepadInput _button(GamepadButton button) => GamepadInput(
  id: buttonInputId(button),
  direction: 1,
  label: buttonLabel(button),
);

GamepadInput _axis(GamepadAxis axis, int direction) => GamepadInput(
  id: axisInputId(axis),
  direction: direction,
  label: axisLabel(axis),
);

GamepadInput? _migrateButtonId(GamepadInput input) {
  final button = _buttonIds[input.id];

  return button == null ? null : _button(button);
}

GamepadInput? _migrateAxisId(GamepadInput input) {
  final axis = _axisIds[input.id];

  if (axis == null) {
    return null;
  }

  final (target, flip: flip) = axis;

  return _axis(target, flip ? -input.direction : input.direction);
}

GamepadInput? _migrateHat(GamepadInput input) {
  final button = switch ((input.id, input.direction)) {
    ('analog_AXIS_HAT_X' || 'analog_pov_x' || 'analog_6', < 0) =>
      GamepadButton.dpadLeft,
    ('analog_AXIS_HAT_X' || 'analog_pov_x' || 'analog_6', _) =>
      GamepadButton.dpadRight,
    ('analog_AXIS_HAT_Y' || 'analog_7', < 0) => GamepadButton.dpadUp,
    ('analog_AXIS_HAT_Y' || 'analog_7', _) => GamepadButton.dpadDown,
    // The fork mapped Windows JOY_POVFORWARD (up) to +1.
    ('analog_pov_y', > 0) => GamepadButton.dpadUp,
    ('analog_pov_y', _) => GamepadButton.dpadDown,
    _ => null,
  };

  return button == null ? null : _button(button);
}

GamepadInput? _migrateMacos(GamepadInput input) {
  if (input.id.startsWith('analog_')) {
    final key = input.id.substring('analog_'.length);

    return _macosDpad(key, input.direction) ??
        _macosTrigger(key) ??
        _macosStickClick(key) ??
        _macosStick(key, input.direction);
  }

  if (input.id.startsWith('button_')) {
    final key = input.id.substring('button_'.length);

    return _macosDpad(key, input.direction) ?? _macosButton(key);
  }

  return null;
}

GamepadInput? _macosDpad(String key, int direction) {
  if (!key.contains('dpad')) {
    return null;
  }

  final button = switch (key) {
    _ when key.endsWith('xAxis') =>
      direction < 0 ? GamepadButton.dpadLeft : GamepadButton.dpadRight,
    _ when key.endsWith('yAxis') =>
      direction > 0 ? GamepadButton.dpadUp : GamepadButton.dpadDown,
    _ when key.contains('up') => GamepadButton.dpadUp,
    _ when key.contains('down') => GamepadButton.dpadDown,
    _ when key.contains('left') => GamepadButton.dpadLeft,
    _ when key.contains('right') => GamepadButton.dpadRight,
    _ => null,
  };

  return button == null ? null : _button(button);
}

GamepadInput? _macosTrigger(String key) {
  final axis = switch (key) {
    _
        when key.contains('l2.rectangle') ||
            key.contains('lt.rectangle') ||
            key.contains('zl.rectangle') =>
      GamepadAxis.leftTrigger,
    _
        when key.contains('r2.rectangle') ||
            key.contains('rt.rectangle') ||
            key.contains('zr.rectangle') =>
      GamepadAxis.rightTrigger,
    _ => null,
  };

  return axis == null ? null : _axis(axis, 1);
}

GamepadInput? _macosStickClick(String key) {
  final button = switch (key) {
    _
        when key.contains('l.joystick.press') ||
            key.contains('l.joystick.down') =>
      GamepadButton.leftStick,
    _
        when key.contains('r.joystick.press') ||
            key.contains('r.joystick.down') =>
      GamepadButton.rightStick,
    _ => null,
  };

  return button == null ? null : _button(button);
}

GamepadInput? _macosStick(String key, int direction) {
  if (!key.contains('joystick')) {
    return null;
  }

  final left = key.startsWith('l.');

  final (GamepadAxis? axis, int newDirection) = switch (key) {
    _ when key.endsWith('xAxis') => (_stickX(left), direction),
    _ when key.endsWith('yAxis') => (_stickY(left), direction),
    _ when key.contains('.up') => (_stickY(left), 1),
    _ when key.contains('.down') => (_stickY(left), -1),
    _ when key.contains('.left') => (_stickX(left), -1),
    _ when key.contains('.right') => (_stickX(left), 1),
    _ => (null, 0),
  };

  return axis == null ? null : _axis(axis, newDirection);
}

GamepadAxis _stickX(bool left) =>
    left ? GamepadAxis.leftStickX : GamepadAxis.rightStickX;

GamepadAxis _stickY(bool left) =>
    left ? GamepadAxis.leftStickY : GamepadAxis.rightStickY;

GamepadInput? _macosButton(String key) {
  GamepadButton? best;
  var bestLength = 0;

  // Longest match wins so 'b.circle' cannot shadow 'rb.circle'.
  for (final MapEntry(key: pattern, value: button)
      in _macosButtonPatterns.entries) {
    if (pattern.length > bestLength && key.contains(pattern)) {
      best = button;
      bestLength = pattern.length;
    }
  }

  return best == null ? null : _button(best);
}

const _buttonIds = <String, GamepadButton>{
  // Android KeyEvent.keyCodeToString names.
  'button_KEYCODE_BUTTON_A': GamepadButton.a,
  'button_KEYCODE_BUTTON_B': GamepadButton.b,
  'button_KEYCODE_BUTTON_X': GamepadButton.x,
  'button_KEYCODE_BUTTON_Y': GamepadButton.y,
  'button_KEYCODE_BUTTON_L1': GamepadButton.leftBumper,
  'button_KEYCODE_BUTTON_R1': GamepadButton.rightBumper,
  'button_KEYCODE_BUTTON_L2': GamepadButton.leftTrigger,
  'button_KEYCODE_BUTTON_R2': GamepadButton.rightTrigger,
  'button_KEYCODE_BUTTON_SELECT': GamepadButton.back,
  'button_KEYCODE_BUTTON_START': GamepadButton.start,
  'button_KEYCODE_BUTTON_MODE': GamepadButton.home,
  'button_KEYCODE_BUTTON_THUMBL': GamepadButton.leftStick,
  'button_KEYCODE_BUTTON_THUMBR': GamepadButton.rightStick,
  'button_KEYCODE_DPAD_UP': GamepadButton.dpadUp,
  'button_KEYCODE_DPAD_DOWN': GamepadButton.dpadDown,
  'button_KEYCODE_DPAD_LEFT': GamepadButton.dpadLeft,
  'button_KEYCODE_DPAD_RIGHT': GamepadButton.dpadRight,
  // Linux joystick button numbers, Xbox-like default layout (matches
  // upstream's fallback for controllers without an SDL DB entry).
  'button_0': GamepadButton.a,
  'button_1': GamepadButton.b,
  'button_2': GamepadButton.x,
  'button_3': GamepadButton.y,
  'button_4': GamepadButton.leftBumper,
  'button_5': GamepadButton.rightBumper,
  'button_6': GamepadButton.back,
  'button_7': GamepadButton.start,
  'button_8': GamepadButton.home,
  'button_9': GamepadButton.leftStick,
  'button_10': GamepadButton.rightStick,
};

const _axisIds = <String, (GamepadAxis, {bool flip})>{
  // Android MotionEvent.axisToString names. Vertical axes flip because
  // Android reports up as negative while normalized up is positive.
  'analog_AXIS_X': (GamepadAxis.leftStickX, flip: false),
  'analog_AXIS_Y': (GamepadAxis.leftStickY, flip: true),
  'analog_AXIS_Z': (GamepadAxis.rightStickX, flip: false),
  'analog_AXIS_RZ': (GamepadAxis.rightStickY, flip: true),
  'analog_AXIS_LTRIGGER': (GamepadAxis.leftTrigger, flip: false),
  'analog_AXIS_RTRIGGER': (GamepadAxis.rightTrigger, flip: false),
  'analog_AXIS_BRAKE': (GamepadAxis.leftTrigger, flip: false),
  'analog_AXIS_GAS': (GamepadAxis.rightTrigger, flip: false),
  // Windows legacy joystick API (pre-GameInput).
  'analog_dwXpos': (GamepadAxis.leftStickX, flip: false),
  'analog_dwYpos': (GamepadAxis.leftStickY, flip: false),
  // Linux joystick axis numbers, Xbox-like default layout. Vertical
  // axes flip because the kernel reports down as positive.
  'analog_0': (GamepadAxis.leftStickX, flip: false),
  'analog_1': (GamepadAxis.leftStickY, flip: true),
  'analog_2': (GamepadAxis.leftTrigger, flip: false),
  'analog_3': (GamepadAxis.rightStickX, flip: false),
  'analog_4': (GamepadAxis.rightStickY, flip: true),
  'analog_5': (GamepadAxis.rightTrigger, flip: false),
};

const _macosButtonPatterns = <String, GamepadButton>{
  'a.circle': GamepadButton.a,
  'b.circle': GamepadButton.b,
  'x.circle': GamepadButton.x,
  'y.circle': GamepadButton.y,
  'xmark.circle': GamepadButton.a,
  'circle.circle': GamepadButton.b,
  'square.circle': GamepadButton.x,
  'triangle.circle': GamepadButton.y,
  'l1.rectangle': GamepadButton.leftBumper,
  'r1.rectangle': GamepadButton.rightBumper,
  'lb.rectangle': GamepadButton.leftBumper,
  'rb.rectangle': GamepadButton.rightBumper,
  'l.rectangle.roundedbottom': GamepadButton.leftBumper,
  'r.rectangle.roundedbottom': GamepadButton.rightBumper,
  'l2.rectangle': GamepadButton.leftTrigger,
  'r2.rectangle': GamepadButton.rightTrigger,
  'lt.rectangle': GamepadButton.leftTrigger,
  'rt.rectangle': GamepadButton.rightTrigger,
  'zl.rectangle': GamepadButton.leftTrigger,
  'zr.rectangle': GamepadButton.rightTrigger,
  'line.3.horizontal': GamepadButton.start,
  'line.horizontal.3': GamepadButton.start,
  'plus.circle': GamepadButton.start,
  'capsule.portrait': GamepadButton.back,
  'minus.circle': GamepadButton.back,
  'rectangle.fill.on.rectangle.fill': GamepadButton.back,
  'square.and.arrow.up': GamepadButton.back,
  'house': GamepadButton.home,
  'l.joystick.press': GamepadButton.leftStick,
  'r.joystick.press': GamepadButton.rightStick,
  'l.joystick.down': GamepadButton.leftStick,
  'r.joystick.down': GamepadButton.rightStick,
};
