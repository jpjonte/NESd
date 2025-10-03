import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gamepad_input.g.dart';

@JsonSerializable()
@immutable
class GamepadInput {
  const GamepadInput({required this.id, required this.direction, this.label});

  final String id;
  final String? label;
  final int direction;

  factory GamepadInput.fromJson(Map<String, dynamic> json) =>
      _$GamepadInputFromJson(json);

  Map<String, dynamic> toJson() => _$GamepadInputToJson(this);

  @override
  bool operator ==(Object other) {
    return other is GamepadInput &&
        id == other.id &&
        direction == other.direction;
  }

  @override
  int get hashCode => Object.hash(id, direction);
}
