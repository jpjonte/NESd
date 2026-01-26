// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cheat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Cheat _$CheatFromJson(Map<String, dynamic> json) => Cheat(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$CheatTypeEnumMap, json['type']),
  address: (json['address'] as num).toInt(),
  value: (json['value'] as num).toInt(),
  code: json['code'] as String,
  compareValue: (json['compareValue'] as num?)?.toInt(),
  enabled: json['enabled'] as bool? ?? true,
);

Map<String, dynamic> _$CheatToJson(Cheat instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$CheatTypeEnumMap[instance.type]!,
  'address': instance.address,
  'value': instance.value,
  'code': instance.code,
  'compareValue': instance.compareValue,
  'enabled': instance.enabled,
};

const _$CheatTypeEnumMap = {CheatType.gameGenie: 'gameGenie'};
