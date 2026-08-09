import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_event.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_id.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gamepad_input_mapper.g.dart';

typedef GamepadNamesLookup = Future<Map<String, String>> Function();

@riverpod
GamepadInputMapper gamepadInputMapper(Ref ref) {
  final inputMapper = GamepadInputMapper();

  ref.onDispose(inputMapper.dispose);

  return inputMapper;
}

Future<Map<String, String>> defaultGamepadNamesLookup() async {
  final controllers = await Gamepads.list();

  final names = {
    for (final controller in controllers) controller.id: controller.name,
  };

  for (final controller in controllers) {
    unawaited(controller.dispose());
  }

  return names;
}

class GamepadInputMapper {
  GamepadInputMapper({
    Stream<GamepadEvent>? events,
    GamepadNormalizer? normalizer,
    GamepadNamesLookup namesLookup = defaultGamepadNamesLookup,
    bool? scaleAnalogFallback,
  }) : _normalizer = normalizer ?? GamepadNormalizer(),
       _namesLookup = namesLookup,
       _scaleAnalogFallback =
           scaleAnalogFallback ??
           (defaultTargetPlatform == TargetPlatform.linux),
       _streamController = StreamController<GamepadInputEvent>.broadcast() {
    _subscription = (events ?? Gamepads.events).listen(_handleGamepadEvent);
  }

  Stream<GamepadInputEvent> get stream => _streamController.stream;

  final GamepadNormalizer _normalizer;
  final GamepadNamesLookup _namesLookup;
  final bool _scaleAnalogFallback;
  final StreamController<GamepadInputEvent> _streamController;

  final _names = <String, String>{};

  late final StreamSubscription<GamepadEvent> _subscription;

  bool _refreshingNames = false;

  void dispose() {
    _subscription.cancel();
    _streamController.close();
  }

  void _handleGamepadEvent(GamepadEvent event) {
    if (!_names.containsKey(event.gamepadId)) {
      unawaited(_refreshNames());
    }

    final name = _names[event.gamepadId] ?? 'Unknown';
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
    );
  }

  Future<void> _refreshNames() async {
    if (_refreshingNames) {
      return;
    }

    _refreshingNames = true;

    try {
      _names.addAll(await _namesLookup());
    } finally {
      _refreshingNames = false;
    }
  }
}
