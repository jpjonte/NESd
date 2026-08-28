import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
