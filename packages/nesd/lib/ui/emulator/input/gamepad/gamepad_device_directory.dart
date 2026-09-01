import 'dart:async';

import 'package:gamepads/gamepads.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_key.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gamepad_device_directory.g.dart';

typedef GamepadDeviceLookup = Future<Map<String, GamepadDeviceKey>> Function();

@Riverpod(keepAlive: true)
GamepadDeviceDirectory gamepadDeviceDirectory(Ref ref) =>
    GamepadDeviceDirectory();

Future<Map<String, GamepadDeviceKey>> defaultGamepadDeviceLookup() async {
  final controllers = await Gamepads.list();

  final devices = {
    for (final controller in controllers)
      controller.id: GamepadDeviceKey(name: controller.name),
  };

  for (final controller in controllers) {
    unawaited(controller.dispose());
  }

  return devices;
}

class GamepadDeviceDirectory {
  GamepadDeviceDirectory({GamepadDeviceLookup? lookup})
    : _lookup = lookup ?? defaultGamepadDeviceLookup;

  final GamepadDeviceLookup _lookup;

  final _keys = <String, GamepadDeviceKey>{};

  Future<Map<String, GamepadDeviceKey>?>? _pending;

  GamepadDeviceKey? keyFor(String gamepadId) => _keys[gamepadId];

  Future<Map<String, GamepadDeviceKey>?> refresh() =>
      _pending ??= _refresh().whenComplete(() => _pending = null);

  Future<Map<String, GamepadDeviceKey>?> _refresh() async {
    try {
      final devices = await _lookup();

      _keys.addAll(devices);

      return devices;
    } on Object catch (e) {
      log.input.warning('Failed to look up gamepads', error: e);

      return null;
    }
  }
}
