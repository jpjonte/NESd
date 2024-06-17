import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nes/ui/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

enum Scaling {
  autoInteger,
  autoSmooth,
  x1,
  x2,
  x3,
  x4,
}

@freezed
class Settings with _$Settings {
  factory Settings({
    @Default(1.0) double volume,
    @Default(true) bool stretch,
    @Default(false) bool showBorder,
    @Default(false) bool showTiles,
    @Default(false) bool showCartridgeInfo,
    @Default(Scaling.autoInteger) Scaling scaling,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}

@riverpod
class SettingsController extends _$SettingsController {
  static const settingsKey = 'settings';

  @override
  Settings build() {
    _prefs = ref.watch(sharedPreferencesProvider);

    return state = _load();
  }

  late SharedPreferences _prefs;

  double get volume => state.volume;

  set volume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
    _save();
  }

  bool get showBorder => state.showBorder;

  set showBorder(bool showBorder) {
    state = state.copyWith(showBorder: showBorder);
    _save();
  }

  bool get stretch => state.stretch;

  set stretch(bool stretch) {
    state = state.copyWith(stretch: stretch);
    _save();
  }

  bool get showTiles => state.showTiles;

  set showTiles(bool showTiles) {
    state = state.copyWith(showTiles: showTiles);
    _save();
  }

  bool get showCartridgeInfo => state.showCartridgeInfo;

  set showCartridgeInfo(bool showCartridgeInfo) {
    state = state.copyWith(showCartridgeInfo: showCartridgeInfo);
    _save();
  }

  Scaling get scaling => state.scaling;

  set scaling(Scaling scaling) {
    state = state.copyWith(scaling: scaling);
    _save();
  }

  void _save() {
    _prefs.setString(settingsKey, jsonEncode(state.toJson()));
  }

  Settings _load() {
    final raw = _prefs.getString(settingsKey);

    if (raw == null) {
      return Settings();
    }

    final loaded = Settings.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    return loaded.copyWith(
      volume: loaded.volume.clamp(0.0, 1.0),
    );
  }
}
