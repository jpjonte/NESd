import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/settings/controls/gamepad_slot_migration.dart';

void main() {
  Map<String, dynamic> binding(String action, String id, String name) => {
    'index': 0,
    'action': action,
    'type': 'hold',
    'input': {
      'type': 'gamepad',
      'gamepadId': id,
      'gamepadName': name,
      'inputs': [
        {'id': 'button_a', 'direction': 1},
      ],
    },
  };

  List<Map<String, dynamic>> bindingsOf(Map<String, dynamic> json) =>
      (json['bindings'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic> inputOf(Map<String, dynamic> entry) =>
      entry['input'] as Map<String, dynamic>;

  test('rewrites a single pad to slot 0', () {
    final json = <String, dynamic>{
      'bindings': [binding('controller1.a', '0', 'Pad')],
    };

    migrateGamepadSlots(json);

    final input = inputOf(bindingsOf(json).single);

    expect(input['slot'], 0);
    expect(input.containsKey('gamepadId'), isFalse);
    expect(input.containsKey('gamepadName'), isFalse);
  });

  test('maps distinct pads to slots by first appearance', () {
    final json = <String, dynamic>{
      'bindings': [
        binding('controller1.a', 'js1', 'Second'),
        binding('controller2.a', 'js0', 'First'),
      ],
    };

    migrateGamepadSlots(json);

    final bindings = bindingsOf(json);

    expect(inputOf(bindings[0])['slot'], 0);
    expect(inputOf(bindings[1])['slot'], 1);
  });

  test('seeds gamepadSlots with name-only keys', () {
    final json = <String, dynamic>{
      'bindings': [binding('controller1.a', '0', 'Sony DualSense')],
    };

    migrateGamepadSlots(json);

    expect(json['gamepadSlots'], {
      '0': {'name': 'Sony DualSense'},
    });
  });

  test('does not remember the placeholder name', () {
    final json = <String, dynamic>{
      'bindings': [binding('controller1.a', '0', 'Unknown')],
    };

    migrateGamepadSlots(json);

    final input = inputOf(bindingsOf(json).single);

    expect(input['slot'], 0);
    expect(json.containsKey('gamepadSlots'), isFalse);
  });

  test('leaves keyboard bindings untouched', () {
    final json = <String, dynamic>{
      'bindings': [
        {
          'index': 0,
          'action': 'controller1.a',
          'type': 'hold',
          'input': {
            'type': 'keyboard',
            'keys': [122],
          },
        },
      ],
    };

    migrateGamepadSlots(json);

    final input = inputOf(bindingsOf(json).single);

    expect(input['keys'], [122]);
    expect(json.containsKey('gamepadSlots'), isFalse);
  });

  test('is a no-op on already-migrated bindings', () {
    final json = <String, dynamic>{
      'bindings': [
        {
          'index': 0,
          'action': 'controller1.a',
          'type': 'hold',
          'input': {
            'type': 'gamepad',
            'slot': 2,
            'inputs': [
              {'id': 'button_a', 'direction': 1},
            ],
          },
        },
      ],
    };

    migrateGamepadSlots(json);

    expect(inputOf(bindingsOf(json).single)['slot'], 2);
  });

  test('rewrites a pad stored in the legacy map of bindings', () {
    final json = <String, dynamic>{
      'bindings': {
        'controller1.a': inputOf(binding('controller1.a', '0', 'Pad')),
      },
    };

    migrateGamepadSlots(json);

    final input =
        (json['bindings'] as Map<String, dynamic>)['controller1.a']
            as Map<String, dynamic>;

    expect(input['slot'], 0);
    expect(input.containsKey('gamepadId'), isFalse);
    expect(json['gamepadSlots'], {
      '0': {'name': 'Pad'},
    });
  });

  test('rewrites every input of a legacy map entry that holds several', () {
    final json = <String, dynamic>{
      'bindings': {
        'controller1.a': [
          {
            'type': 'keyboard',
            'keys': [122],
          },
          inputOf(binding('controller1.a', 'js1', 'Pad')),
        ],
      },
    };

    migrateGamepadSlots(json);

    final inputs =
        (json['bindings'] as Map<String, dynamic>)['controller1.a'] as List;

    expect((inputs[1] as Map<String, dynamic>)['slot'], 0);
  });

  test('tolerates missing or malformed bindings', () {
    final empty = <String, dynamic>{};
    final malformed = <String, dynamic>{'bindings': 'nonsense'};

    expect(() => migrateGamepadSlots(empty), returnsNormally);
    expect(() => migrateGamepadSlots(malformed), returnsNormally);
  });
}
