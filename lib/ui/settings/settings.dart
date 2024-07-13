import 'dart:convert';
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/ui/emulator/input/action.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/graphics/scaling.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
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

  final bindings = <NesAction, List<InputCombination?>>{};

  for (final MapEntry(key: code, :value) in json.entries) {
    try {
      final action = NesAction.fromCode(code);
      final inputs = inputsFromJson(value);

      bindings[action] = inputs;
      // ignore: avoid_catching_errors
    } on StateError {
      // ignore invalid actions
    }
  }

  return bindings;
}

List<InputCombination?> inputsFromJson(dynamic value) {
  if (value is! List) {
    return [
      if (value != null)
        InputCombination.fromJson(value as Map<String, dynamic>)
      else
        null,
    ];
  }

  return value
      .map(
        (e) => e != null
            ? InputCombination.fromJson(e as Map<String, dynamic>)
            : null,
      )
      .toList();
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
    @Default(true) bool autoSave,
    @Default(1) int? autoSaveInterval,
    @Default({})
    @JsonKey(fromJson: bindingsFromJson, toJson: bindingsToJson)
    Map<NesAction, List<InputCombination?>> bindings,
    @Default(null) String? lastRomPath,
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
    _update(state.copyWith(volume: volume.clamp(0.0, 1.0)));
  }

  bool get showBorder => state.showBorder;

  set showBorder(bool showBorder) {
    _update(state.copyWith(showBorder: showBorder));
  }

  bool get stretch => state.stretch;

  set stretch(bool stretch) {
    _update(state.copyWith(stretch: stretch));
  }

  bool get showTiles => state.showTiles;

  set showTiles(bool showTiles) {
    _update(state.copyWith(showTiles: showTiles));
  }

  bool get showCartridgeInfo => state.showCartridgeInfo;

  set showCartridgeInfo(bool showCartridgeInfo) {
    _update(state.copyWith(showCartridgeInfo: showCartridgeInfo));
  }

  Scaling get scaling => state.scaling;

  set scaling(Scaling scaling) {
    _update(state.copyWith(scaling: scaling));
  }

  bool get autoSave => state.autoSave;

  set autoSave(bool autoSave) {
    _update(state.copyWith(autoSave: autoSave));
  }

  int get autoSaveInterval => state.autoSaveInterval ?? 1;

  set autoSaveInterval(int autoSaveInterval) {
    _update(state.copyWith(autoSaveInterval: max(1, autoSaveInterval)));
  }

  String? get lastRomPath => state.lastRomPath;

  set lastRomPath(String? lastRomPath) {
    _update(state.copyWith(lastRomPath: lastRomPath));
  }

  BindingMap get bindings => state.bindings;

  set bindings(BindingMap bindings) {
    _update(state.copyWith(bindings: bindings));
  }

  void updateBinding(NesAction action, int index, InputCombination input) {
    final bindings = state.bindings[action] ?? <InputCombination?>[];

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

    _update(
      state.copyWith(
        bindings: {
          ...state.bindings,
          action: bindings,
        },
      ),
    );
  }

  void clearBinding(NesAction action, int index) {
    final bindings = state.bindings[action] ?? [];

    if (index < bindings.length - 1) {
      bindings[index] = null;
    } else if (index == bindings.length - 1) {
      bindings.removeAt(index);
    }

    _update(
      state.copyWith(
        bindings: {
          for (final entry in state.bindings.entries)
            if (entry.key == action)
              entry.key: bindings
            else
              entry.key: entry.value,
        },
      ),
    );
  }

  void _update(Settings settings) {
    state = settings;
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
