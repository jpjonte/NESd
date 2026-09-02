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

  const MixerSettings._();

  factory MixerSettings.fromJson(Map<String, dynamic> json) =>
      _$MixerSettingsFromJson(json);

  MixerSettings clamped() => MixerSettings(
    pulse1: _gain(pulse1),
    pulse2: _gain(pulse2),
    triangle: _gain(triangle),
    noise: _gain(noise),
    dmc: _gain(dmc),
    mmc5: _gain(mmc5),
    namco163: _gain(namco163),
  );
}

double _gain(double value) => value.isNaN ? 1.0 : value.clamp(0.0, 1.0);
