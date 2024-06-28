import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/settings/controls/binding.dart';
import 'package:nes/ui/settings/graphics/scaling.dart';
import 'package:nes/ui/settings/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

Map<NesAction, InputCombination> bindingsFromJson(
  dynamic json,
) {
  if (json is! Map<String, dynamic>) {
    return defaultBindings;
  }

  return json.map(
    (key, value) => MapEntry(
      NesAction.fromCode(key),
      InputCombination.fromJson(value as Map<String, dynamic>),
    ),
  );
}

Map<String, dynamic> bindingsToJson(
  Map<NesAction, InputCombination> bindings,
) {
  return {
    for (final MapEntry(key: action, value: input) in bindings.entries)
      action.code: input.toJson(),
  };
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
    @Default({})
    @JsonKey(fromJson: bindingsFromJson, toJson: bindingsToJson)
    Map<NesAction, InputCombination> bindings,
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

  Map<NesAction, InputCombination> get bindings => state.bindings;

  set bindings(Map<NesAction, InputCombination> bindings) {
    state = state.copyWith(bindings: bindings);
    _save();
  }

  void updateBinding(NesAction action, InputCombination binding) {
    state = state.copyWith(
      bindings: {
        ...state.bindings,
        action: binding,
      },
    );

    _save();
  }

  void clearKeyBinding(NesAction action) {
    state.bindings.remove(action);

    state = state.copyWith(bindings: state.bindings);

    _save();
  }

  void _save() {
    _prefs.setString(settingsKey, jsonEncode(state.toJson()));
  }

  Settings _load() {
    final raw = _prefs.getString(settingsKey);

    if (raw == null) {
      final settings = Settings(bindings: defaultBindings);

      _prefs.setString(settingsKey, jsonEncode(settings.toJson()));

      return settings;
    }

    final loaded = Settings.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    return loaded.copyWith(
      volume: loaded.volume.clamp(0.0, 1.0),
      bindings: loaded.bindings.isNotEmpty ? loaded.bindings : defaultBindings,
    );
  }
}
