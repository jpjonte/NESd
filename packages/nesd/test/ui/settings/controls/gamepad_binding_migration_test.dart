import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/gamepad_binding_migration.dart';
import 'package:nesd/ui/settings/controls/gamepad_input.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';

void main() {
  GamepadInput migrate(String id, {int direction = 1}) {
    final binding = Binding(
      index: 0,
      action: controller1A,
      input: InputCombination.gamepad(
        slot: 0,
        inputs: {GamepadInput(id: id, direction: direction)},
      ),
    );

    final migrated = migrateGamepadBindings([binding]).single;
    final input = migrated.input as GamepadInputCombination;

    return input.inputs.single;
  }

  group('Android ids', () {
    test('translates buttons and regenerates labels', () {
      final input = migrate('button_KEYCODE_BUTTON_A');

      expect(input.id, 'button_a');
      expect(input.direction, 1);
      expect(input.label, 'A');
    });

    test('translates d-pad key codes', () {
      expect(migrate('button_KEYCODE_DPAD_UP').id, 'button_dpadUp');
    });

    test('flips vertical stick axes', () {
      final input = migrate('analog_AXIS_Y', direction: -1);

      expect(input.id, 'axis_leftStickY');
      expect(input.direction, 1);
    });

    test('translates hat axes to d-pad buttons', () {
      final left = migrate('analog_AXIS_HAT_X', direction: -1);

      expect(left.id, 'button_dpadLeft');
      expect(left.direction, 1);

      expect(migrate('analog_AXIS_HAT_Y', direction: -1).id, 'button_dpadUp');
    });
  });

  group('Windows ids', () {
    test('translates legacy joystick axes', () {
      expect(migrate('analog_dwXpos').id, 'axis_leftStickX');
      expect(migrate('analog_dwYpos').id, 'axis_leftStickY');
    });

    test('translates pov to d-pad buttons', () {
      expect(migrate('analog_pov_x', direction: -1).id, 'button_dpadLeft');
      expect(migrate('analog_pov_y').id, 'button_dpadUp');
      expect(migrate('analog_pov_y', direction: -1).id, 'button_dpadDown');
    });

    test('keeps numbered buttons unchanged', () {
      expect(migrate('button_button-3').id, 'button_button-3');
    });
  });

  group('Linux ids', () {
    test('translates buttons via the Xbox-like default layout', () {
      expect(migrate('button_0').id, 'button_a');
      expect(migrate('button_7').id, 'button_start');
    });

    test('translates axes and flips vertical ones', () {
      expect(migrate('analog_0').id, 'axis_leftStickX');
      expect(migrate('analog_1').direction, -1);
      expect(migrate('analog_2').id, 'axis_leftTrigger');
    });

    test('translates hat axes to d-pad buttons', () {
      expect(migrate('analog_6', direction: -1).id, 'button_dpadLeft');
      expect(migrate('analog_7').id, 'button_dpadDown');
    });

    test('keeps unknown numbers unchanged', () {
      expect(migrate('button_14').id, 'button_14');
    });
  });

  group('macOS ids', () {
    test('translates face buttons', () {
      expect(migrate('button_a.circle').id, 'button_a');
      expect(migrate('button_xmark.circle').id, 'button_a');
    });

    test('translates fork d-pad elements', () {
      expect(migrate('button_dpad.up').id, 'button_dpadUp');
      expect(migrate('analog_dpad.left').id, 'button_dpadLeft');
    });

    test('translates pre-fork d-pad axes using direction', () {
      final up = migrate('analog_dpad - yAxis');

      expect(up.id, 'button_dpadUp');
      expect(up.direction, 1);
    });

    test('translates analog triggers to trigger axes', () {
      expect(migrate('analog_l2.rectangle').id, 'axis_leftTrigger');
      expect(migrate('button_l2.rectangle').id, 'button_leftTrigger');
    });

    test('translates stick direction elements', () {
      final up = migrate('analog_l.joystick.up');

      expect(up.id, 'axis_leftStickY');
      expect(up.direction, 1);

      final right = migrate('analog_r.joystick.right');

      expect(right.id, 'axis_rightStickX');
      expect(right.direction, 1);
    });

    test('translates stick clicks to stick buttons', () {
      expect(migrate('analog_l.joystick.press.down').id, 'button_leftStick');
    });

    test('translates pre-fork stick axes', () {
      final x = migrate('analog_l.joystick - xAxis', direction: -1);

      expect(x.id, 'axis_leftStickX');
      expect(x.direction, -1);
    });
  });

  group('safety', () {
    test('keeps keyboard bindings unchanged', () {
      final binding = Binding(
        index: 0,
        action: controller1A,
        input: InputCombination.keyboard({LogicalKeyboardKey.keyZ}),
      );

      expect(migrateGamepadBindings([binding]).single, binding);
    });

    test('keeps already-normalized ids unchanged', () {
      expect(migrate('button_a').id, 'button_a');
      expect(migrate('button_dpadUp').id, 'button_dpadUp');
      expect(migrate('axis_leftStickX').id, 'axis_leftStickX');
    });

    test('is idempotent', () {
      final once = migrate('analog_AXIS_HAT_X', direction: -1);
      final twice = migrate(once.id, direction: once.direction);

      expect(twice.id, once.id);
      expect(twice.direction, once.direction);
    });
  });
}
