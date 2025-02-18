// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_combination.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KeyboardInputCombinationImpl _$$KeyboardInputCombinationImplFromJson(
  Map<String, dynamic> json,
) => _$KeyboardInputCombinationImpl(
  keysFromJson(json['keys'] as List),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$$KeyboardInputCombinationImplToJson(
  _$KeyboardInputCombinationImpl instance,
) => <String, dynamic>{
  'keys': keysToJson(instance.keys),
  'type': instance.$type,
};

_$GamepadInputCombinationImpl _$$GamepadInputCombinationImplFromJson(
  Map<String, dynamic> json,
) => _$GamepadInputCombinationImpl(
  gamepadId: json['gamepadId'] as String,
  inputs:
      (json['inputs'] as List<dynamic>)
          .map((e) => GamepadInput.fromJson(e as Map<String, dynamic>))
          .toSet(),
  gamepadName: json['gamepadName'] as String? ?? 'Unknown',
  $type: json['type'] as String?,
);

Map<String, dynamic> _$$GamepadInputCombinationImplToJson(
  _$GamepadInputCombinationImpl instance,
) => <String, dynamic>{
  'gamepadId': instance.gamepadId,
  'inputs': instance.inputs.toList(),
  'gamepadName': instance.gamepadName,
  'type': instance.$type,
};
