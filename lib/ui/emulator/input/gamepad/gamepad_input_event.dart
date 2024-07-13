import 'package:gamepads/gamepads.dart';

class GamepadInputEvent {
  GamepadInputEvent({
    required this.gamepadId,
    required this.gamepadName,
    required this.type,
    required this.inputId,
    required this.value,
    required this.label,
  });

  final String gamepadId;
  final String gamepadName;
  final KeyType type;
  final String inputId;
  final double value;
  final String label;
}
