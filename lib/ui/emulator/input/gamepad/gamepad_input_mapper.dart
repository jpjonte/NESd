import 'dart:async';

import 'package:gamepads/gamepads.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_event.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gamepad_input_mapper.g.dart';

@riverpod
GamepadInputMapper gamepadInputMapper(GamepadInputMapperRef ref) {
  final inputMapper = GamepadInputMapper();

  ref.onDispose(inputMapper.dispose);

  return inputMapper;
}

class GamepadInputMapper {
  GamepadInputMapper()
      : _streamController = StreamController<GamepadInputEvent>.broadcast() {
    _subscription = Gamepads.events.listen(_handleGamepadEvent);
  }

  Stream<GamepadInputEvent> get stream => _streamController.stream;

  final StreamController<GamepadInputEvent> _streamController;

  late final StreamSubscription<GamepadEvent> _subscription;

  void dispose() {
    _subscription.cancel();
    _streamController.close();
  }

  void _handleGamepadEvent(GamepadEvent event) {
    _streamController.add(
      GamepadInputEvent(
        gamepadId: event.gamepadId,
        gamepadName: event.gamepadName,
        type: event.type,
        inputId: _getInputId(event),
        value: event.value,
        label: event.label,
      ),
    );
  }

  String _getInputId(GamepadEvent event) => '${event.type.name}_${event.key}';
}
