// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamepad_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GamepadInput _$GamepadInputFromJson(Map<String, dynamic> json) => GamepadInput(
  id: json['id'] as String,
  direction: (json['direction'] as num).toInt(),
  label: json['label'] as String?,
);

Map<String, dynamic> _$GamepadInputToJson(GamepadInput instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'direction': instance.direction,
    };
