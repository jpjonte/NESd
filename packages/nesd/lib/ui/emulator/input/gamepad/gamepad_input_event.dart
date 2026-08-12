import 'package:flutter/foundation.dart';

@immutable
class GamepadInputEvent {
  const GamepadInputEvent({
    required this.gamepadId,
    required this.gamepadName,
    required this.inputId,
    required this.value,
    required this.label,
  });

  final String gamepadId;
  final String gamepadName;
  final String inputId;
  final double value;
  final String label;
}
