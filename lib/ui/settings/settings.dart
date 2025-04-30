import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/graphics/scaling.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

List<RomInfo> _recentRomsFromJson(List<dynamic> json) {
  return json
      .map((e) {
        if (e is! Map<String, dynamic>) {
          return null;
        }

        if (!e.containsKey('file')) {
          return RomInfo(
            file: FilesystemFile(
              path: e['path'] as String,
              name: e['name'] as String,
              type: FilesystemFileType.file,
            ),
            hash: e['hash'] as String?,
            romHash: e['romHash'] as String?,
            chrHash: e['chrHash'] as String?,
            prgHash: e['prgHash'] as String?,
          );
        }

        return RomInfo.fromJson(e);
      })
      .where((e) => e != null)
      .whereType<RomInfo>()
      .toList();
}

FilesystemFile? _lastRomPathFromJson(dynamic json) {
  if (json == null) {
    return null;
  }

  if (json is String) {
    return FilesystemFile(
      path: json,
      name: p.basename(json),
      type: FilesystemFileType.directory,
    );
  }

  if (json is Map<String, dynamic>) {
    return FilesystemFile.fromJson(json);
  }

  return null;
}

@freezed
sealed class Settings with _$Settings {
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
    @Default([]) @JsonKey(fromJson: bindingsFromJson) List<Binding> bindings,
    @JsonKey(fromJson: _lastRomPathFromJson)
    @Default(null)
    FilesystemFile? lastRomPath,
    @Default([]) List<String> recentRomPaths,
    @JsonKey(fromJson: _recentRomsFromJson)
    @Default([])
    List<RomInfo> recentRoms,
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

  FilesystemFile? get lastRomPath => state.lastRomPath;

  set lastRomPath(FilesystemFile? lastRomPath) {
    _update(state.copyWith(lastRomPath: lastRomPath));
  }

  List<RomInfo> get recentRoms => state.recentRoms;

  void addRecentRom(RomInfo rom) {
    final recent =
        state.recentRoms.toList()
          ..removeWhere(
            (r) => r.file.name == rom.file.name || r.hash == rom.hash,
          )
          ..insert(0, rom);

    _update(state.copyWith(recentRoms: recent.toList()));
  }

  void clearRecentRoms() {
    _update(state.copyWith(recentRoms: []));
  }

  void removeRecentRom(RomInfo rom) {
    final recent =
        state.recentRoms.toList()..removeWhere(
          (r) => r.file.name == rom.file.name || r.hash == rom.hash,
        );

    _update(state.copyWith(recentRoms: recent.toList()));
  }

  bool get showTouchControls => state.showTouchControls;

  set showTouchControls(bool showTouchControls) {
    _update(state.copyWith(showTouchControls: showTouchControls));
  }

  Bindings get bindings => state.bindings;

  set bindings(Bindings bindings) {
    _update(state.copyWith(bindings: bindings));
  }

  Binding? getBinding(InputAction action, int index) {
    return state.bindings.firstWhereOrNull(
      (b) => b.action == action && b.index == index,
    );
  }

  void updateBinding(Binding binding) {
    final updatedBindings =
        state.bindings
            .where(
              (b) => b.index != binding.index || b.action != binding.action,
            )
            .toList()
          ..add(binding);

    _update(state.copyWith(bindings: updatedBindings));
  }

  void clearBinding(InputAction action, int index) {
    final existingBinding = state.bindings.firstWhereOrNull(
      (b) => b.action == action && b.index == index,
    );

    if (existingBinding != null) {
      final updatedBindings = state.bindings.toList()..remove(existingBinding);

      _update(state.copyWith(bindings: updatedBindings));
    }
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
        RomInfo(
          file: FilesystemFile(
            path: path,
            name: p.basename(path),
            type: FilesystemFileType.file,
          ),
          hash: '',
        ),
    ];
  }
}
