import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nes/ui/emulator/input/action.dart';
import 'package:nes/ui/settings/controls/input_combination.dart';
import 'package:nes/ui/settings/graphics/scaling.dart';
import 'package:nes/ui/settings/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

typedef BindingMap = Map<NesAction, List<InputCombination?>>;

BindingMap bindingsFromJson(
  dynamic json,
) {
  if (json is! Map<String, dynamic>) {
    return defaultBindings;
  }

  return json.map(
    (key, value) {
      final inputs = value is List
          ? value
              .map(
                (e) => e != null
                    ? InputCombination.fromJson(e as Map<String, dynamic>)
                    : null,
              )
              .toList()
          : [
              if (value != null)
                InputCombination.fromJson(value as Map<String, dynamic>)
              else
                null,
            ];

      return MapEntry(
        NesAction.fromCode(key),
        inputs,
      );
    },
  );
}

Map<String, dynamic> bindingsToJson(BindingMap bindings) {
  return {
    for (final MapEntry(key: action, value: inputs) in bindings.entries)
      action.code: [
        for (final input in inputs)
          if (input != null) input.toJson() else null,
      ],
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
    Map<NesAction, List<InputCombination?>> bindings,
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

  BindingMap get bindings => state.bindings;

  set bindings(BindingMap bindings) {
    state = state.copyWith(bindings: bindings);
    _save();
  }

  void updateBinding(NesAction action, int index, InputCombination input) {
    final bindings = state.bindings[action] ?? [];

    if (index < bindings.length) {
      bindings[index] = input;
    } else {
      bindings
        ..addAll(
          // fill with nulls up to the index
          List<InputCombination?>.filled(index - bindings.length, null),
        )
        ..add(input);
    }

    state = state.copyWith(
      bindings: {
        ...state.bindings,
        action: bindings,
      },
    );

    _save();
  }

  void clearBinding(NesAction action, int index) {
    final bindings = state.bindings[action] ?? [];

    if (index < bindings.length - 1) {
      bindings[index] = null;
    } else if (index == bindings.length - 1) {
      bindings.removeAt(index);
    }

    state = state.copyWith(
      bindings: {
        for (final entry in state.bindings.entries)
          if (entry.key == action)
            entry.key: bindings
          else
            entry.key: entry.value,
      },
    );

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
