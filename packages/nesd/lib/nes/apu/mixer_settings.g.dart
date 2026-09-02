// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mixer_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MixerSettings _$MixerSettingsFromJson(Map<String, dynamic> json) =>
    _MixerSettings(
      pulse1: (json['pulse1'] as num?)?.toDouble() ?? 1.0,
      pulse2: (json['pulse2'] as num?)?.toDouble() ?? 1.0,
      triangle: (json['triangle'] as num?)?.toDouble() ?? 1.0,
      noise: (json['noise'] as num?)?.toDouble() ?? 1.0,
      dmc: (json['dmc'] as num?)?.toDouble() ?? 1.0,
      mmc5: (json['mmc5'] as num?)?.toDouble() ?? 1.0,
      namco163: (json['namco163'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$MixerSettingsToJson(_MixerSettings instance) =>
    <String, dynamic>{
      'pulse1': instance.pulse1,
      'pulse2': instance.pulse2,
      'triangle': instance.triangle,
      'noise': instance.noise,
      'dmc': instance.dmc,
      'mmc5': instance.mmc5,
      'namco163': instance.namco163,
    };
