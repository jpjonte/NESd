// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'touch_input_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RectangleButtonConfig _$RectangleButtonConfigFromJson(
  Map<String, dynamic> json,
) => RectangleButtonConfig(
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  bindingType:
      $enumDecodeNullable(_$BindingTypeEnumMap, json['bindingType']) ??
      BindingType.hold,
  action: InputAction.fromCode(json['action'] as String?),
  width: (json['width'] as num?)?.toDouble() ?? 60,
  height: (json['height'] as num?)?.toDouble() ?? 60,
  label: json['label'] as String? ?? '',
  $type: json['type'] as String?,
);

Map<String, dynamic> _$RectangleButtonConfigToJson(
  RectangleButtonConfig instance,
) => <String, dynamic>{
  'x': instance.x,
  'y': instance.y,
  'bindingType': _$BindingTypeEnumMap[instance.bindingType]!,
  'action': InputAction.toJson(instance.action),
  'width': instance.width,
  'height': instance.height,
  'label': instance.label,
  'type': instance.$type,
};

const _$BindingTypeEnumMap = {
  BindingType.hold: 'hold',
  BindingType.toggle: 'toggle',
};

CircleButtonConfig _$CircleButtonConfigFromJson(Map<String, dynamic> json) =>
    CircleButtonConfig(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      bindingType:
          $enumDecodeNullable(_$BindingTypeEnumMap, json['bindingType']) ??
          BindingType.hold,
      action: InputAction.fromCode(json['action'] as String?),
      size: (json['size'] as num?)?.toDouble() ?? 75,
      label: json['label'] as String? ?? '',
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$CircleButtonConfigToJson(CircleButtonConfig instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'bindingType': _$BindingTypeEnumMap[instance.bindingType]!,
      'action': InputAction.toJson(instance.action),
      'size': instance.size,
      'label': instance.label,
      'type': instance.$type,
    };

JoyStickConfig _$JoyStickConfigFromJson(Map<String, dynamic> json) =>
    JoyStickConfig(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      bindingType:
          $enumDecodeNullable(_$BindingTypeEnumMap, json['bindingType']) ??
          BindingType.hold,
      upAction: InputAction.fromCode(json['upAction'] as String?),
      downAction: InputAction.fromCode(json['downAction'] as String?),
      leftAction: InputAction.fromCode(json['leftAction'] as String?),
      rightAction: InputAction.fromCode(json['rightAction'] as String?),
      size: (json['size'] as num?)?.toDouble() ?? 150,
      innerSize: (json['innerSize'] as num?)?.toDouble() ?? 60,
      deadZone: (json['deadZone'] as num?)?.toDouble() ?? 0.25,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$JoyStickConfigToJson(JoyStickConfig instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'bindingType': _$BindingTypeEnumMap[instance.bindingType]!,
      'upAction': InputAction.toJson(instance.upAction),
      'downAction': InputAction.toJson(instance.downAction),
      'leftAction': InputAction.toJson(instance.leftAction),
      'rightAction': InputAction.toJson(instance.rightAction),
      'size': instance.size,
      'innerSize': instance.innerSize,
      'deadZone': instance.deadZone,
      'type': instance.$type,
    };

DPadConfig _$DPadConfigFromJson(Map<String, dynamic> json) => DPadConfig(
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  bindingType:
      $enumDecodeNullable(_$BindingTypeEnumMap, json['bindingType']) ??
      BindingType.hold,
  upAction: InputAction.fromCode(json['upAction'] as String?),
  downAction: InputAction.fromCode(json['downAction'] as String?),
  leftAction: InputAction.fromCode(json['leftAction'] as String?),
  rightAction: InputAction.fromCode(json['rightAction'] as String?),
  size: (json['size'] as num?)?.toDouble() ?? 150,
  deadZone: (json['deadZone'] as num?)?.toDouble() ?? 0.25,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$DPadConfigToJson(DPadConfig instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'bindingType': _$BindingTypeEnumMap[instance.bindingType]!,
      'upAction': InputAction.toJson(instance.upAction),
      'downAction': InputAction.toJson(instance.downAction),
      'leftAction': InputAction.toJson(instance.leftAction),
      'rightAction': InputAction.toJson(instance.rightAction),
      'size': instance.size,
      'deadZone': instance.deadZone,
      'type': instance.$type,
    };
