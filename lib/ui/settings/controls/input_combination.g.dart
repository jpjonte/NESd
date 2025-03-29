// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_combination.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyboardInputCombination _$KeyboardInputCombinationFromJson(
  Map<String, dynamic> json,
) => KeyboardInputCombination(
  keysFromJson(json['keys'] as List),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$KeyboardInputCombinationToJson(
  KeyboardInputCombination instance,
) => <String, dynamic>{
  'keys': keysToJson(instance.keys),
  'type': instance.$type,
};

GamepadInputCombination _$GamepadInputCombinationFromJson(
  Map<String, dynamic> json,
) => GamepadInputCombination(
  gamepadId: json['gamepadId'] as String,
  inputs:
      (json['inputs'] as List<dynamic>)
          .map((e) => GamepadInput.fromJson(e as Map<String, dynamic>))
          .toSet(),
  gamepadName: json['gamepadName'] as String? ?? 'Unknown',
  $type: json['type'] as String?,
);

Map<String, dynamic> _$GamepadInputCombinationToJson(
  GamepadInputCombination instance,
) => <String, dynamic>{
  'gamepadId': instance.gamepadId,
  'inputs': instance.inputs.toList(),
  'gamepadName': instance.gamepadName,
  'type': instance.$type,
};
