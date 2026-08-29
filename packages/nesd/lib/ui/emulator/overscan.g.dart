// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overscan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Overscan _$OverscanFromJson(Map<String, dynamic> json) => _Overscan(
  top: (json['top'] as num?)?.toInt() ?? 8,
  bottom: (json['bottom'] as num?)?.toInt() ?? 8,
  left: (json['left'] as num?)?.toInt() ?? 0,
  right: (json['right'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$OverscanToJson(_Overscan instance) => <String, dynamic>{
  'top': instance.top,
  'bottom': instance.bottom,
  'left': instance.left,
  'right': instance.right,
};
