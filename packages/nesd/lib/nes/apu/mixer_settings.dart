import 'package:freezed_annotation/freezed_annotation.dart';

part 'mixer_settings.freezed.dart';
part 'mixer_settings.g.dart';

@freezed
sealed class MixerSettings with _$MixerSettings {
  const factory MixerSettings({
    @Default(1.0) double pulse1,
    @Default(1.0) double pulse2,
    @Default(1.0) double triangle,
    @Default(1.0) double noise,
    @Default(1.0) double dmc,
    @Default(1.0) double mmc5,
    @Default(1.0) double namco163,
  }) = _MixerSettings;

  factory MixerSettings.fromJson(Map<String, dynamic> json) =>
      _$MixerSettingsFromJson(json);
}
