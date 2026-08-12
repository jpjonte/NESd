import 'package:freezed_annotation/freezed_annotation.dart';

part 'crt_filter_settings.freezed.dart';
part 'crt_filter_settings.g.dart';

@freezed
sealed class CrtFilterSettings with _$CrtFilterSettings {
  const factory CrtFilterSettings({
    @Default(0.35) double scanlineIntensity,
    @Default(0.25) double maskStrength,
    @Default(0.0) double curvature,
  }) = _CrtFilterSettings;

  factory CrtFilterSettings.fromJson(Map<String, dynamic> json) =>
      _$CrtFilterSettingsFromJson(json);
}
