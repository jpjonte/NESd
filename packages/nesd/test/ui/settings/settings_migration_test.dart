import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_key.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSharedPreferences prefs;

  setUp(() {
    prefs = _MockSharedPreferences();

    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);
  });

  SettingsController load(String raw) {
    when(() => prefs.getString(any())).thenReturn(raw);

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    )..listen(settingsControllerProvider, (_, _) {});

    addTearDown(container.dispose);

    return container.read(settingsControllerProvider.notifier);
  }

  test('legacy show* booleans migrate to openTools', () {
    final controller = load(
      '{"showTiles": true, "showCartridgeInfo": false, '
      '"showDebugger": true, "showApuDebug": false}',
    );

    expect(controller.openTools, {
      EmulatorTool.tileViewer,
      EmulatorTool.debugger,
    });
  });

  test('an explicit empty openTools is not re-derived from the booleans', () {
    final controller = load('{"showTiles": true, "openTools": []}');

    expect(controller.openTools, isEmpty);
  });

  test('unknown tool names are dropped instead of throwing', () {
    final controller = load('{"openTools": ["debugger", "hologram"]}');

    expect(controller.openTools, {EmulatorTool.debugger});
  });

  test('settings with no tool keys start with nothing open', () {
    final controller = load('{}');

    expect(controller.openTools, isEmpty);
  });

  test('gamepad binding ids migrate when bindingsVersion is absent', () {
    final controller = load('''
      {
        "bindings": [
          {
            "index": 0,
            "action": "controller1.left",
            "type": "hold",
            "input": {
              "type": "gamepad",
              "gamepadId": "0",
              "gamepadName": "Old Pad",
              "inputs": [
                {
                  "id": "analog_AXIS_HAT_X",
                  "direction": -1,
                  "label": "Axis AXIS_HAT_X"
                }
              ]
            }
          }
        ]
      }
    ''');

    final input = controller.bindings.single.input;
    final gamepad = input as GamepadInputCombination;

    expect(gamepad.inputs.single.id, 'button_dpadLeft');
    expect(gamepad.inputs.single.direction, 1);
  });

  test('bindings are left alone when bindingsVersion is present', () {
    final controller = load('''
      {
        "bindingsVersion": 2,
        "bindings": [
          {
            "index": 0,
            "action": "controller1.left",
            "type": "hold",
            "input": {
              "type": "gamepad",
              "gamepadId": "0",
              "gamepadName": "Pad",
              "inputs": [{"id": "button_3", "direction": 1}]
            }
          }
        ]
      }
    ''');

    final input = controller.bindings.single.input;
    final gamepad = input as GamepadInputCombination;

    expect(gamepad.inputs.single.id, 'button_3');
  });

  test('stored gamepad bindings migrate to slots', () {
    final controller = load('''
      {
        "bindingsVersion": 2,
        "bindings": [
          {
            "index": 0,
            "action": "controller1.left",
            "type": "hold",
            "input": {
              "type": "gamepad",
              "gamepadId": "js0",
              "gamepadName": "Pad",
              "inputs": [{"id": "button_dpadLeft", "direction": 1}]
            }
          }
        ]
      }
    ''');

    final gamepad =
        controller.bindings.firstWhere((b) => b.action == controller1Left).input
            as GamepadInputCombination;

    expect(gamepad.slot, 0);
    expect(controller.gamepadSlots[0], const GamepadDeviceKey(name: 'Pad'));
  });

  test('input ids and slots both migrate from a v1 settings file', () {
    final controller = load('''
      {
        "bindings": [
          {
            "index": 0,
            "action": "controller1.left",
            "type": "hold",
            "input": {
              "type": "gamepad",
              "gamepadId": "0",
              "gamepadName": "Old Pad",
              "inputs": [{"id": "analog_AXIS_HAT_X", "direction": -1}]
            }
          }
        ]
      }
    ''');

    final gamepad =
        controller.bindings.firstWhere((b) => b.action == controller1Left).input
            as GamepadInputCombination;

    expect(gamepad.slot, 0);
    expect(gamepad.inputs.single.id, 'button_dpadLeft');
  });

  test('a legacy map of bindings keeps the gamepad it had stored', () {
    final controller = load('''
      {
        "bindings": {
          "controller1.a": {
            "type": "gamepad",
            "gamepadId": "js0",
            "gamepadName": "Pad",
            "inputs": [{"id": "button_0", "direction": 1}]
          }
        }
      }
    ''');

    final gamepad = controller.bindings.single.input as GamepadInputCombination;

    expect(gamepad.slot, 0);
    expect(gamepad.inputs.single.id, 'button_a');
    expect(controller.gamepadSlots[0], const GamepadDeviceKey(name: 'Pad'));
  });

  test('a v3 settings file is left alone', () {
    final controller = load('''
      {
        "bindingsVersion": 3,
        "gamepadSlots": {"1": {"name": "Kept"}},
        "bindings": [
          {
            "index": 0,
            "action": "controller1.left",
            "type": "hold",
            "input": {
              "type": "gamepad",
              "slot": 1,
              "inputs": [{"id": "button_dpadLeft", "direction": 1}]
            }
          }
        ]
      }
    ''');

    final gamepad = controller.bindings.single.input as GamepadInputCombination;

    expect(gamepad.slot, 1);
    expect(controller.gamepadSlots[1], const GamepadDeviceKey(name: 'Kept'));
  });

  test('one physical gamepad bound to many actions maps to one slot', () {
    final controller = load('''
      {
        "bindingsVersion": 2,
        "bindings": [
          {
            "index": 0,
            "action": "controller1.left",
            "type": "hold",
            "input": {
              "type": "gamepad",
              "gamepadId": "js0",
              "gamepadName": "Pad",
              "inputs": [{"id": "button_dpadLeft", "direction": 1}]
            }
          },
          {
            "index": 0,
            "action": "controller1.right",
            "type": "hold",
            "input": {
              "type": "gamepad",
              "gamepadId": "js0",
              "gamepadName": "Pad",
              "inputs": [{"id": "button_dpadRight", "direction": 1}]
            }
          },
          {
            "index": 0,
            "action": "controller1.a",
            "type": "hold",
            "input": {
              "type": "gamepad",
              "gamepadId": "js0",
              "gamepadName": "Pad",
              "inputs": [{"id": "button_0", "direction": 1}]
            }
          }
        ]
      }
    ''');

    final slots = controller.bindings
        .map((b) => (b.input as GamepadInputCombination).slot)
        .toSet();

    expect(slots, {0});
    expect(controller.gamepadSlots[0], const GamepadDeviceKey(name: 'Pad'));
  });

  test('a bindingsVersion stored as a double still loads', () {
    final controller = load('{"bindingsVersion": 2.0}');

    expect(controller.bindings, isNotEmpty);
  });

  test('malformed gamepad slots are skipped instead of throwing', () {
    final controller = load('''
      {
        "bindingsVersion": 3,
        "gamepadSlots": {
          "0": "nonsense",
          "1": {"name": 5},
          "2": {"name": "Pad", "vendorId": 1356, "productId": 3302}
        }
      }
    ''');

    expect(controller.gamepadSlots, {
      2: const GamepadDeviceKey(name: 'Pad', vendorId: 1356, productId: 3302),
    });
  });

  test('gamepad slots survive a save and reload round trip', () {
    final settings = Settings(
      gamepadSlots: {
        0: const GamepadDeviceKey(
          name: 'Sony DualSense',
          vendorId: 1356,
          productId: 3302,
        ),
        2: const GamepadDeviceKey(name: '8BitDo Pro 2'),
      },
    );

    final reloaded = Settings.fromJson(
      jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>,
    );

    expect(reloaded.gamepadSlots, settings.gamepadSlots);
  });

  test('every emulator tool serializes through settings JSON', () {
    final settings = Settings(openTools: EmulatorTool.values.toSet());

    final decoded = Settings.fromJson(settings.toJson());

    expect(decoded.openTools, EmulatorTool.values.toSet());
  });

  test('legacy videoFilter crt migrates to the videoFilters list', () {
    final controller = load('{"videoFilter": "crt"}');

    expect(controller.videoFilters, [VideoFilter.crt]);
  });

  test('legacy videoFilter none migrates to an empty list', () {
    final controller = load('{"videoFilter": "none"}');

    expect(controller.videoFilters, isEmpty);
  });

  test('a present videoFilters list wins over the legacy key', () {
    final controller = load(
      '{"videoFilter": "crt", "videoFilters": ["smooth"]}',
    );

    expect(controller.videoFilters, [VideoFilter.smooth]);
  });
}
