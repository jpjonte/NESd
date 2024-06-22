import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nes/ui/emulator/input/action/controller_press.dart';
import 'package:nes/ui/emulator/input/action/load_file.dart';
import 'package:nes/ui/emulator/input/action/save_state.dart';
import 'package:nes/ui/settings/shared_preferences.dart';
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

final defaultKeyMap = [
  KeyBinding(
    keys: {LogicalKeyboardKey.arrowUp.keyId},
    action: controller1Up.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.arrowDown.keyId},
    action: controller1Down.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.arrowLeft.keyId},
    action: controller1Left.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.arrowRight.keyId},
    action: controller1Right.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.enter.keyId},
    action: controller1Start.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.shift.keyId},
    action: controller1Select.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.keyZ.keyId},
    action: controller1A.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.keyX.keyId},
    action: controller1B.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit1.keyId},
    action: loadState1.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit1.keyId, LogicalKeyboardKey.shift.keyId},
    action: saveState1.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit2.keyId},
    action: loadState2.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit2.keyId, LogicalKeyboardKey.shift.keyId},
    action: saveState2.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit3.keyId},
    action: loadState3.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit3.keyId, LogicalKeyboardKey.shift.keyId},
    action: saveState3.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit4.keyId},
    action: loadState4.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit4.keyId, LogicalKeyboardKey.shift.keyId},
    action: saveState4.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit5.keyId},
    action: loadState5.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit5.keyId, LogicalKeyboardKey.shift.keyId},
    action: saveState5.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit6.keyId},
    action: loadState6.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit6.keyId, LogicalKeyboardKey.shift.keyId},
    action: saveState6.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit7.keyId},
    action: loadState7.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit7.keyId, LogicalKeyboardKey.shift.keyId},
    action: saveState7.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit8.keyId},
    action: loadState8.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit8.keyId, LogicalKeyboardKey.shift.keyId},
    action: saveState8.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit9.keyId},
    action: loadState9.code,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit9.keyId, LogicalKeyboardKey.shift.keyId},
    action: saveState9.code,
  ),
];

@JsonSerializable()
class KeyBinding {
  const KeyBinding({
    required this.keys,
    required this.action,
  });

  final Set<int> keys;
  final String action;

  factory KeyBinding.fromJson(Map<String, dynamic> json) =>
      _$KeyBindingFromJson(json);

  Map<String, dynamic> toJson() => _$KeyBindingToJson(this);
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
    @Default(1) int? autoSaveInterval,
    @Default([]) List<KeyBinding> keyMap,
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

  int? get autoSaveInterval => state.autoSaveInterval;

  set autoSaveInterval(int? autoSaveInterval) {
    state = state.copyWith(autoSaveInterval: autoSaveInterval);
    _save();
  }

  List<KeyBinding> get keyMap => state.keyMap;

  set keyMap(List<KeyBinding> keyMap) {
    state = state.copyWith(keyMap: keyMap);
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
      keyMap: loaded.keyMap.isEmpty ? defaultKeyMap : loaded.keyMap,
    );
  }
}
