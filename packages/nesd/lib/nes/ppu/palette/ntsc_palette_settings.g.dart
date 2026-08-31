// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ntsc_palette_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NtscPaletteSettings _$NtscPaletteSettingsFromJson(Map<String, dynamic> json) =>
    _NtscPaletteSettings(
      hue: (json['hue'] as num?)?.toDouble() ?? 0.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 1.0,
      gamma: (json['gamma'] as num?)?.toDouble() ?? 1.8,
    );

Map<String, dynamic> _$NtscPaletteSettingsToJson(
  _NtscPaletteSettings instance,
) => <String, dynamic>{
  'hue': instance.hue,
  'saturation': instance.saturation,
  'contrast': instance.contrast,
  'brightness': instance.brightness,
  'gamma': instance.gamma,
};
