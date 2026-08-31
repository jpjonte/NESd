import 'package:freezed_annotation/freezed_annotation.dart';

part 'ntsc_palette_settings.freezed.dart';
part 'ntsc_palette_settings.g.dart';

@freezed
sealed class NtscPaletteSettings with _$NtscPaletteSettings {
  const factory NtscPaletteSettings({
    @Default(0.0) double hue,
    @Default(1.0) double saturation,
    @Default(1.0) double contrast,
    @Default(1.0) double brightness,
    @Default(1.8) double gamma,
  }) = _NtscPaletteSettings;

  factory NtscPaletteSettings.fromJson(Map<String, dynamic> json) =>
      _$NtscPaletteSettingsFromJson(json);
}
