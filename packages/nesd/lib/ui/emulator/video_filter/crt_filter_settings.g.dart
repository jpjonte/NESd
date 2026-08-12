// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crt_filter_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CrtFilterSettings _$CrtFilterSettingsFromJson(Map<String, dynamic> json) =>
    _CrtFilterSettings(
      scanlineIntensity:
          (json['scanlineIntensity'] as num?)?.toDouble() ?? 0.35,
      maskStrength: (json['maskStrength'] as num?)?.toDouble() ?? 0.25,
      curvature: (json['curvature'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$CrtFilterSettingsToJson(_CrtFilterSettings instance) =>
    <String, dynamic>{
      'scanlineIntensity': instance.scanlineIntensity,
      'maskStrength': instance.maskStrength,
      'curvature': instance.curvature,
    };
