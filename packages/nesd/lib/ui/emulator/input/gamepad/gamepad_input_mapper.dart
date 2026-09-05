import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_directory.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_key.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_event.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_id.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gamepad_input_mapper.g.dart';

/// Sensor nodes (e.g. the DualSense "Motion Sensors" joystick device on
/// Linux) share the controller's vendor/product id, so the SDL mapping
/// turns their constantly-streaming axes into phantom gamepad input.
final _sensorDevicePattern = RegExp(
  r'\b(motion sensors|imu|accelerometer)\b',
  caseSensitive: false,
);

@riverpod
GamepadInputMapper gamepadInputMapper(Ref ref) {
  final inputMapper = GamepadInputMapper(
    directory: ref.watch(gamepadDeviceDirectoryProvider),
  );

  ref.onDispose(inputMapper.dispose);

  return inputMapper;
}

class GamepadInputMapper {
  GamepadInputMapper({
    required this.directory,
    Stream<GamepadEvent>? events,
    GamepadNormalizer? normalizer,
    bool? scaleAnalogFallback,
  }) : _normalizer = normalizer ?? GamepadNormalizer(),
       _scaleAnalogFallback =
           scaleAnalogFallback ??
           (defaultTargetPlatform == TargetPlatform.linux),
       _streamController = StreamController<GamepadInputEvent>.broadcast() {
    _subscription = (events ?? Gamepads.events).listen(_handleGamepadEvent);
  }

  Stream<GamepadInputEvent> get stream => _streamController.stream;

  final GamepadNormalizer _normalizer;
  final GamepadDeviceDirectory directory;
  final bool _scaleAnalogFallback;
  final StreamController<GamepadInputEvent> _streamController;

  late final StreamSubscription<GamepadEvent> _subscription;

  void dispose() {
    _subscription.cancel();
    _streamController.close();
  }

  void _handleGamepadEvent(GamepadEvent event) {
    final device = directory.keyFor(event.gamepadId);

    if (device == null) {
      unawaited(directory.refresh());
    }

    final name = device?.name ?? unknownGamepadName;

    if (_sensorDevicePattern.hasMatch(name)) {
      return;
    }

    final normalized = _normalizer.normalize(event);

    if (normalized.isEmpty) {
      _streamController.add(_fallbackEvent(event, name));

      return;
    }

    for (final result in normalized) {
      _streamController.add(_normalizedEvent(result, name));
    }
  }

  GamepadInputEvent _normalizedEvent(
    NormalizedGamepadEvent event,
    String name,
  ) {
    final (inputId, label) = switch ((event.button, event.axis)) {
      (final GamepadButton button, _) => (
        buttonInputId(button),
        buttonLabel(button),
      ),
      (_, final GamepadAxis axis) => (axisInputId(axis), axisLabel(axis)),
      _ => throw StateError('normalized event without button or axis'),
    };

    return GamepadInputEvent(
      gamepadId: event.gamepadId,
      gamepadName: name,
      inputId: inputId,
      value: event.value,
      label: label,
      vendorId: event.rawEvent.vendorId,
      productId: event.rawEvent.productId,
    );
  }

  GamepadInputEvent _fallbackEvent(GamepadEvent event, String name) {
    var value = event.value;

    if (_scaleAnalogFallback && event.type == KeyType.analog) {
      // Raw Linux joystick axes are 16-bit signed values.
      value = (value / 32767.0).clamp(-1.0, 1.0);
    }

    return GamepadInputEvent(
      gamepadId: event.gamepadId,
      gamepadName: name,
      inputId: '${event.type.name}_${event.key}',
      value: value,
      label: event.key,
      vendorId: event.vendorId,
      productId: event.productId,
    );
  }
}
