import 'package:flutter/foundation.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_key.dart';

@immutable
class GamepadInputEvent {
  const GamepadInputEvent({
    required this.gamepadId,
    required this.gamepadName,
    required this.inputId,
    required this.value,
    required this.label,
    this.vendorId,
    this.productId,
  });

  final String gamepadId;
  final String gamepadName;
  final String inputId;
  final double value;
  final String label;
  final int? vendorId;
  final int? productId;

  GamepadDeviceKey get deviceKey => GamepadDeviceKey(
    name: gamepadName,
    vendorId: vendorId,
    productId: productId,
  );
}
