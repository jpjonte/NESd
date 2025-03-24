import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/graphics/scaling.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/util/decorate.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

typedef BindingMap = Map<InputAction, List<InputCombination?>>;

// ignore: avoid-dynamic
BindingMap bindingsFromJson(dynamic json) {
  if (json is! Map<String, dynamic>) {
    return defaultBindings;
  }

  final bindings = <InputAction, List<InputCombination?>>{};

  for (final MapEntry(key: code, :value) in json.entries) {
    try {
      final action = InputAction.fromCode(code);

      if (action == null) {
        continue;
      }

      final inputs = inputsFromJson(value);

      bindings[action] = inputs;

      // catch errors to ignore invalid actions
      // ignore: avoid_catching_errors
    } on StateError {
      // ignore invalid actions
    }
  }

  return bindings;
}

// ignore: avoid-dynamic
List<InputCombination?> inputsFromJson(dynamic value) {
  if (value is! List) {
    return [
      if (value != null)
        InputCombination.fromJson(value as Map<String, dynamic>)
      else
        null,
    ];
  }

  return [
    for (final e in value)
      decorate(e, (e) => InputCombination.fromJson(e as Map<String, dynamic>)),
  ];
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

// ignore: avoid-dynamic
List<TouchInputConfig> narrowTouchInputConfigsFromJson(dynamic json) {
  if (json is! List || json.isEmpty) {
    return defaultPortraitConfig;
  }

  return touchInputConfigsFromJson(json);
}

// ignore: avoid-dynamic
List<TouchInputConfig> wideTouchInputConfigsFromJson(dynamic json) {
  if (json is! List || json.isEmpty) {
    return defaultLandscapeConfig;
  }

  return touchInputConfigsFromJson(json);
}

// ignore: avoid-dynamic
List<TouchInputConfig> touchInputConfigsFromJson(List<dynamic> json) {
  return json
      .map((e) => TouchInputConfig.fromJson(e as Map<String, dynamic>))
      .whereType<TouchInputConfig>()
      .toList();
}

@freezed
class Settings with _$Settings {
  factory Settings({
    @Default(1.0) double volume,
    @Default(true) bool stretch,
    @Default(false) bool showBorder,
    @Default(false) bool showTiles,
    @Default(false) bool showCartridgeInfo,
    @Default(false) bool showDebugOverlay,
    @Default(false) bool showDebugger,
    @Default(Scaling.autoInteger) Scaling scaling,
    @Default(true) bool autoSave,
    @Default(1) int? autoSaveInterval,
    @Default(false) bool autoLoad,
    @Default({})
    @JsonKey(fromJson: bindingsFromJson, toJson: bindingsToJson)
    Map<InputAction, List<InputCombination?>> bindings,
    @Default(null) String? lastRomPath,
    @Default([]) List<String> recentRomPaths,
    @Default([]) List<RomInfo> recentRoms,
    @Default(false) bool showTouchControls,
    @JsonKey(fromJson: narrowTouchInputConfigsFromJson)
    @Default([])
    List<TouchInputConfig> narrowTouchInputConfig,
    @JsonKey(fromJson: wideTouchInputConfigsFromJson)
    @Default([])
    List<TouchInputConfig> wideTouchInputConfig,
    @Default({}) Map<String, List<Breakpoint>> breakpoints,
    @Default(null) Region? region,
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

  bool get showDebugOverlay => state.showDebugOverlay;

  set showDebugOverlay(bool showDebugOverlay) {
    _update(state.copyWith(showDebugOverlay: showDebugOverlay));
  }

  bool get showDebugger => state.showDebugger;

  set showDebugger(bool showDebugger) {
    _update(state.copyWith(showDebugger: showDebugger));
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

  bool get autoLoad => state.autoLoad;

  set autoLoad(bool value) {
    _update(state.copyWith(autoLoad: value));
  }

  String? get lastRomPath => state.lastRomPath;

  set lastRomPath(String? lastRomPath) {
    _update(state.copyWith(lastRomPath: lastRomPath));
  }

  List<RomInfo> get recentRoms => state.recentRoms;

  void addRecentRom(RomInfo rom) {
    final recent =
        state.recentRoms.toList()
          ..removeWhere((r) => r.name == rom.name || r.hash == rom.hash)
          ..insert(0, rom);

    _update(state.copyWith(recentRoms: recent.toList()));
  }

  void clearRecentRoms() {
    _update(state.copyWith(recentRoms: []));
  }

  void removeRecentRom(RomInfo rom) {
    final recent =
        state.recentRoms.toList()
          ..removeWhere((r) => r.name == rom.name || r.hash == rom.hash);

    _update(state.copyWith(recentRoms: recent.toList()));
  }

  bool get showTouchControls => state.showTouchControls;

  set showTouchControls(bool showTouchControls) {
    _update(state.copyWith(showTouchControls: showTouchControls));
  }

  BindingMap get bindings => state.bindings;

  set bindings(BindingMap bindings) {
    _update(state.copyWith(bindings: bindings));
  }

  void updateBinding(InputAction action, int index, InputCombination input) {
    final bindings = List<InputCombination?>.of(state.bindings[action] ?? []);

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

    _update(state.copyWith(bindings: {...state.bindings, action: bindings}));
  }

  void clearBinding(InputAction action, int index) {
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

  void resetBindings() {
    _update(state.copyWith(bindings: defaultBindings));
  }

  List<TouchInputConfig> touchInputConfigsForOrientation(
    Orientation orientation,
  ) {
    return switch (orientation) {
      Orientation.portrait => portraitTouchInputConfig,
      Orientation.landscape => landscapeTouchInputConfig,
    };
  }

  TouchInputConfig touchInputConfigForOrientation(
    Orientation orientation,
    int index,
  ) {
    return touchInputConfigsForOrientation(orientation)[index];
  }

  (int, TouchInputConfig)? touchInputConfigAtPosition(
    Orientation orientation,
    Size viewport,
    Offset position,
  ) {
    final configs = touchInputConfigsForOrientation(orientation);

    for (var i = 0; i < configs.length; i++) {
      final config = configs[i];

      if (config.boundingBox(viewport).contains(position)) {
        return (i, config);
      }
    }

    return null;
  }

  void updateTouchInputConfigs(
    Orientation orientation,
    List<TouchInputConfig> configs,
  ) {
    switch (orientation) {
      case Orientation.portrait:
        portraitTouchInputConfig = configs;
      case Orientation.landscape:
        landscapeTouchInputConfig = configs;
    }
  }

  void setTouchInputConfig(
    Orientation orientation,
    int index,
    TouchInputConfig config,
  ) {
    final newConfigs = List.of(touchInputConfigsForOrientation(orientation));

    newConfigs[index] = config;

    updateTouchInputConfigs(orientation, newConfigs);
  }

  void addTouchInputConfig(Orientation orientation, TouchInputConfig config) {
    updateTouchInputConfigs(orientation, [
      ...touchInputConfigsForOrientation(orientation),
      config,
    ]);
  }

  void removeTouchInputConfig(Orientation orientation, int index) {
    updateTouchInputConfigs(
      orientation,
      List.of(touchInputConfigsForOrientation(orientation))..removeAt(index),
    );
  }

  List<TouchInputConfig> get portraitTouchInputConfig =>
      state.narrowTouchInputConfig;

  set portraitTouchInputConfig(
    List<TouchInputConfig> portraitTouchInputConfig,
  ) {
    _update(state.copyWith(narrowTouchInputConfig: portraitTouchInputConfig));
  }

  List<TouchInputConfig> get landscapeTouchInputConfig =>
      state.wideTouchInputConfig;

  set landscapeTouchInputConfig(
    List<TouchInputConfig> landscapeTouchInputConfig,
  ) {
    _update(state.copyWith(wideTouchInputConfig: landscapeTouchInputConfig));
  }

  Future<void> resetTouchInputConfigs(Orientation orientation) async {
    _update(switch (orientation) {
      Orientation.portrait => state.copyWith(
        narrowTouchInputConfig: defaultPortraitConfig,
      ),
      Orientation.landscape => state.copyWith(
        wideTouchInputConfig: defaultLandscapeConfig,
      ),
    });
  }

  Map<String, List<Breakpoint>> get breakpoints => state.breakpoints;

  set breakpoints(Map<String, List<Breakpoint>> breakpoints) {
    _update(state.copyWith(breakpoints: breakpoints));
  }

  void setBreakpoints(String hash, List<Breakpoint> breakpoints) {
    _update(
      state.copyWith(breakpoints: {...state.breakpoints, hash: breakpoints}),
    );
  }

  Region? get region => state.region;

  set region(Region? region) {
    _update(state.copyWith(region: region));
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

    final recentRoms = _migrateRecentRoms(loaded.recentRomPaths);

    return loaded.copyWith(
      volume: loaded.volume.clamp(0.0, 1.0),
      bindings: loaded.bindings.isNotEmpty ? loaded.bindings : defaultBindings,
      recentRoms: loaded.recentRoms.isNotEmpty ? loaded.recentRoms : recentRoms,
    );
  }

  List<RomInfo> _migrateRecentRoms(List<String> recentRomPaths) {
    return [
      for (final path in recentRomPaths)
        RomInfo(name: p.basename(path), path: path, hash: ''),
    ];
  }
}
