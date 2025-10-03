// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'breakpoint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Breakpoint _$BreakpointFromJson(Map<String, dynamic> json) => Breakpoint(
  (json['address'] as num).toInt(),
  enabled: json['enabled'] as bool? ?? true,
  hidden: json['hidden'] as bool? ?? false,
  disableOnHit: json['disableOnHit'] as bool? ?? false,
  removeOnHit: json['removeOnHit'] as bool? ?? false,
);

Map<String, dynamic> _$BreakpointToJson(Breakpoint instance) =>
    <String, dynamic>{
      'address': instance.address,
      'enabled': instance.enabled,
      'hidden': instance.hidden,
      'disableOnHit': instance.disableOnHit,
      'removeOnHit': instance.removeOnHit,
    };
