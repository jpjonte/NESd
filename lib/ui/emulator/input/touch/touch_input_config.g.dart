// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'touch_input_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RectangleButtonConfigImpl _$$RectangleButtonConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$RectangleButtonConfigImpl(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      action: NesAction.fromCode(json['action'] as String?),
      width: (json['width'] as num?)?.toDouble() ?? 60,
      height: (json['height'] as num?)?.toDouble() ?? 60,
      label: json['label'] as String? ?? '',
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$RectangleButtonConfigImplToJson(
        _$RectangleButtonConfigImpl instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'action': NesAction.toJson(instance.action),
      'width': instance.width,
      'height': instance.height,
      'label': instance.label,
      'type': instance.$type,
    };

_$CircleButtonConfigImpl _$$CircleButtonConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$CircleButtonConfigImpl(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      action: NesAction.fromCode(json['action'] as String?),
      size: (json['size'] as num?)?.toDouble() ?? 75,
      label: json['label'] as String? ?? '',
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$CircleButtonConfigImplToJson(
        _$CircleButtonConfigImpl instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'action': NesAction.toJson(instance.action),
      'size': instance.size,
      'label': instance.label,
      'type': instance.$type,
    };

_$JoyStickConfigImpl _$$JoyStickConfigImplFromJson(Map<String, dynamic> json) =>
    _$JoyStickConfigImpl(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      upAction: NesAction.fromCode(json['upAction'] as String?),
      downAction: NesAction.fromCode(json['downAction'] as String?),
      leftAction: NesAction.fromCode(json['leftAction'] as String?),
      rightAction: NesAction.fromCode(json['rightAction'] as String?),
      size: (json['size'] as num?)?.toDouble() ?? 150,
      innerSize: (json['innerSize'] as num?)?.toDouble() ?? 60,
      deadZone: (json['deadZone'] as num?)?.toDouble() ?? 0.25,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$JoyStickConfigImplToJson(
        _$JoyStickConfigImpl instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'upAction': NesAction.toJson(instance.upAction),
      'downAction': NesAction.toJson(instance.downAction),
      'leftAction': NesAction.toJson(instance.leftAction),
      'rightAction': NesAction.toJson(instance.rightAction),
      'size': instance.size,
      'innerSize': instance.innerSize,
      'deadZone': instance.deadZone,
      'type': instance.$type,
    };

_$DPadConfigImpl _$$DPadConfigImplFromJson(Map<String, dynamic> json) =>
    _$DPadConfigImpl(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      upAction: NesAction.fromCode(json['upAction'] as String?),
      downAction: NesAction.fromCode(json['downAction'] as String?),
      leftAction: NesAction.fromCode(json['leftAction'] as String?),
      rightAction: NesAction.fromCode(json['rightAction'] as String?),
      size: (json['size'] as num?)?.toDouble() ?? 150,
      deadZone: (json['deadZone'] as num?)?.toDouble() ?? 0.25,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$DPadConfigImplToJson(_$DPadConfigImpl instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'upAction': NesAction.toJson(instance.upAction),
      'downAction': NesAction.toJson(instance.downAction),
      'leftAction': NesAction.toJson(instance.leftAction),
      'rightAction': NesAction.toJson(instance.rightAction),
      'size': instance.size,
      'deadZone': instance.deadZone,
      'type': instance.$type,
    };
