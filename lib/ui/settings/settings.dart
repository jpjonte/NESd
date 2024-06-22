import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nes/ui/emulator/input/action.dart';
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
    keys: {LogicalKeyboardKey.arrowUp},
    action: controller1Up,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.arrowDown},
    action: controller1Down,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.arrowLeft},
    action: controller1Left,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.arrowRight},
    action: controller1Right,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.enter},
    action: controller1Start,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.shift},
    action: controller1Select,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.keyZ},
    action: controller1A,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.keyX},
    action: controller1B,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit1},
    action: loadState1,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit1, LogicalKeyboardKey.shift},
    action: saveState1,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit2},
    action: loadState2,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit2, LogicalKeyboardKey.shift},
    action: saveState2,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit3},
    action: loadState3,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit3, LogicalKeyboardKey.shift},
    action: saveState3,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit4},
    action: loadState4,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit4, LogicalKeyboardKey.shift},
    action: saveState4,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit5},
    action: loadState5,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit5, LogicalKeyboardKey.shift},
    action: saveState5,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit6},
    action: loadState6,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit6, LogicalKeyboardKey.shift},
    action: saveState6,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit7},
    action: loadState7,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit7, LogicalKeyboardKey.shift},
    action: saveState7,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit8},
    action: loadState8,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit8, LogicalKeyboardKey.shift},
    action: saveState8,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit9},
    action: loadState9,
  ),
  KeyBinding(
    keys: {LogicalKeyboardKey.digit9, LogicalKeyboardKey.shift},
    action: saveState9,
  ),
];

@JsonSerializable()
class KeyBinding {
  const KeyBinding({
    required this.keys,
    required this.action,
  });

  @JsonKey(fromJson: _keysFromJson, toJson: _keysToJson)
  final Set<LogicalKeyboardKey> keys;

  @JsonKey(fromJson: _actionFromJson, toJson: _actionToJson)
  final NesAction action;

  factory KeyBinding.fromJson(Map<String, dynamic> json) =>
      _$KeyBindingFromJson(json);

  Map<String, dynamic> toJson() => _$KeyBindingToJson(this);

  static Set<LogicalKeyboardKey> _keysFromJson(List<dynamic> json) {
    final keys = json.cast<int>();

    return keys
        .map((keyId) => LogicalKeyboardKey.findKeyByKeyId(keyId))
        .where((k) => k != null)
        .cast<LogicalKeyboardKey>()
        .toSet();
  }

  static List<int> _keysToJson(Set<LogicalKeyboardKey> keys) {
    return keys.map((key) => key.keyId).toList();
  }

  static NesAction _actionFromJson(String json) {
    return allActions.firstWhere((action) => action.code == json);
  }

  static String _actionToJson(NesAction action) {
    return action.code;
  }
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

  void updateKeyBinding(KeyBinding binding) {
    final index = state.keyMap.indexWhere((b) => b.action == binding.action);

    if (index == -1) {
      state = state.copyWith(keyMap: [...state.keyMap, binding]);
    } else {
      final updated = List<KeyBinding>.from(state.keyMap);

      updated[index] = binding;

      state = state.copyWith(keyMap: updated);
    }

    _save();
  }

  void clearKeyBinding(NesAction action) {
    final updated = List<KeyBinding>.from(state.keyMap)
      ..removeWhere((b) => b.action == action);

    state = state.copyWith(keyMap: updated);

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
