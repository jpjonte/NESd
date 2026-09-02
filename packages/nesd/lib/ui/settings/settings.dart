import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/log/log.dart';
import 'package:nesd/nes/apu/mixer_settings.dart';
import 'package:nesd/nes/cheat/cheat.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/nes/ppu/palette/ntsc_palette_settings.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/nes/turbo_speed.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';
import 'package:nesd/ui/emulator/overscan.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/emulator/tools/emulator_tool.dart';
import 'package:nesd/ui/emulator/video_filter/crt_filter_settings.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/settings/controls/binding.dart';
import 'package:nesd/ui/settings/controls/gamepad_binding_migration.dart';
import 'package:nesd/ui/settings/controls/input_combination.dart';
import 'package:nesd/ui/settings/graphics/scaling.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:nesd/ui/toast/toaster.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

enum RendererPreference { auto, gpu, cpu }

enum PixelAspectRatio { auto, ntsc, pal, square, stretch, custom }

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

Map<String, dynamic> _crtFilterToJson(CrtFilterSettings filter) =>
    filter.toJson();

CrtFilterSettings _crtFilterFromJson(dynamic json) => json == null
    ? const CrtFilterSettings()
    : CrtFilterSettings.fromJson(json as Map<String, dynamic>);

Map<String, dynamic> _overscanToJson(Overscan overscan) => overscan.toJson();

Overscan _overscanFromJson(dynamic json) => json == null
    ? const Overscan()
    : Overscan.fromJson(json as Map<String, dynamic>);

Map<String, dynamic> _mixerToJson(MixerSettings mixer) => mixer.toJson();

MixerSettings _mixerFromJson(dynamic json) => json == null
    ? const MixerSettings()
    : MixerSettings.fromJson(json as Map<String, dynamic>).clamped();

Map<String, dynamic> _ntscPaletteToJson(NtscPaletteSettings settings) =>
    settings.toJson();

NtscPaletteSettings _ntscPaletteFromJson(dynamic json) => json == null
    ? const NtscPaletteSettings()
    : NtscPaletteSettings.fromJson(json as Map<String, dynamic>);

@freezed
sealed class Settings with _$Settings {
  factory Settings({
    @Default(1.0) double volume,
    @Default(false) bool lowPassFilter,
    @Default(false) bool swapDutyCycles,
    @JsonKey(toJson: _mixerToJson, fromJson: _mixerFromJson)
    @Default(MixerSettings())
    MixerSettings mixer,
    @Default(FastForwardSpeed.x2) FastForwardSpeed fastForwardSpeed,
    @Default(TurboSpeed.x1) TurboSpeed turboSpeed,
    @Default(true) bool stretch,
    @Default(false) bool showBorder,
    @Default(false) bool showDebugOverlay,
    @Default(LogLevel.info) LogLevel logLevel,
    @JsonKey(fromJson: openToolsFromJson)
    @Default(<EmulatorTool>{})
    Set<EmulatorTool> openTools,
    @Default(Scaling.autoSmooth) Scaling scaling,
    @Default(true) bool autoSave,
    @Default(1) int? autoSaveInterval,
    @Default(true) bool autoLoad,
    @Default([]) @JsonKey(fromJson: bindingsFromJson) List<Binding> bindings,
    @Default(2) int bindingsVersion,
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
    @Default({}) Map<String, List<Cheat>> cheats,
    @Default(null) Region? region,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(RendererPreference.auto) RendererPreference renderer,
    @Default(true) bool rewind,
    @Default(PixelAspectRatio.auto) PixelAspectRatio pixelAspectRatio,
    @Default(1.0) double customPixelAspectRatio,
    @Default([]) List<VideoFilter> videoFilters,
    @JsonKey(toJson: _crtFilterToJson, fromJson: _crtFilterFromJson)
    @Default(CrtFilterSettings())
    CrtFilterSettings crtFilter,
    @JsonKey(toJson: _overscanToJson, fromJson: _overscanFromJson)
    @Default(Overscan())
    Overscan overscan,
    @Default(NesPaletteId.defaultPalette) NesPaletteId paletteId,
    @JsonKey(toJson: _ntscPaletteToJson, fromJson: _ntscPaletteFromJson)
    @Default(NtscPaletteSettings())
    NtscPaletteSettings ntscPalette,
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

    final settings = _load();

    NesdLog.instance.minimumLevel = settings.logLevel;

    return state = settings;
  }

  late SharedPreferences _prefs;

  double get volume => state.volume;

  set volume(double volume) {
    _update(state.copyWith(volume: volume.clamp(0.0, 1.0)));
  }

  bool get lowPassFilter => state.lowPassFilter;

  set lowPassFilter(bool lowPassFilter) {
    _update(state.copyWith(lowPassFilter: lowPassFilter));
  }

  bool get swapDutyCycles => state.swapDutyCycles;

  set swapDutyCycles(bool swapDutyCycles) {
    _update(state.copyWith(swapDutyCycles: swapDutyCycles));
  }

  MixerSettings get mixer => state.mixer;

  set mixer(MixerSettings mixer) {
    _update(state.copyWith(mixer: mixer.clamped()));
  }

  FastForwardSpeed get fastForwardSpeed => state.fastForwardSpeed;

  set fastForwardSpeed(FastForwardSpeed fastForwardSpeed) {
    _update(state.copyWith(fastForwardSpeed: fastForwardSpeed));
  }

  TurboSpeed get turboSpeed => state.turboSpeed;

  set turboSpeed(TurboSpeed turboSpeed) {
    _update(state.copyWith(turboSpeed: turboSpeed));
  }

  bool get showBorder => state.showBorder;

  set showBorder(bool showBorder) {
    _update(state.copyWith(showBorder: showBorder));
  }

  bool get stretch => state.stretch;

  set stretch(bool stretch) {
    _update(state.copyWith(stretch: stretch));
  }

  bool get showDebugOverlay => state.showDebugOverlay;

  set showDebugOverlay(bool showDebugOverlay) {
    _update(state.copyWith(showDebugOverlay: showDebugOverlay));
  }

  LogLevel get logLevel => state.logLevel;

  set logLevel(LogLevel logLevel) {
    NesdLog.instance.minimumLevel = logLevel;

    _update(state.copyWith(logLevel: logLevel));
  }

  Set<EmulatorTool> get openTools => state.openTools;

  set openTools(Set<EmulatorTool> openTools) {
    _update(state.copyWith(openTools: openTools));
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
    final recent = state.recentRoms.toList()
      ..removeWhere((r) => r.file.name == rom.file.name || r.hash == rom.hash)
      ..insert(0, rom);

    _update(state.copyWith(recentRoms: recent.toList()));
  }

  void clearRecentRoms() {
    _update(state.copyWith(recentRoms: []));
  }

  void removeRecentRom(RomInfo rom) {
    final recent = state.recentRoms.toList()
      ..removeWhere((r) => r.file.name == rom.file.name || r.hash == rom.hash);

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

  Map<String, List<Cheat>> get cheats => state.cheats;

  set cheats(Map<String, List<Cheat>> cheats) =>
      _update(state.copyWith(cheats: cheats));

  void setCheats(String hash, List<Cheat> cheats) =>
      _update(state.copyWith(cheats: {...state.cheats, hash: cheats}));

  Region? get region => state.region;

  set region(Region? region) {
    _update(state.copyWith(region: region));
  }

  ThemeMode get themeMode => state.themeMode;

  set themeMode(ThemeMode themeMode) {
    _update(state.copyWith(themeMode: themeMode));
  }

  RendererPreference get rendererPreference => state.renderer;

  set rendererPreference(RendererPreference renderer) {
    _update(state.copyWith(renderer: renderer));
  }

  bool get rewind => state.rewind;

  set rewind(bool rewind) {
    _update(state.copyWith(rewind: rewind));
  }

  PixelAspectRatio get pixelAspectRatio => state.pixelAspectRatio;

  set pixelAspectRatio(PixelAspectRatio pixelAspectRatio) {
    _update(state.copyWith(pixelAspectRatio: pixelAspectRatio));
  }

  double get customPixelAspectRatio => state.customPixelAspectRatio;

  set customPixelAspectRatio(double customPixelAspectRatio) {
    _update(state.copyWith(customPixelAspectRatio: customPixelAspectRatio));
  }

  List<VideoFilter> get videoFilters => state.videoFilters;

  void toggleVideoFilter(VideoFilter filter, {required bool enabled}) {
    final updated = state.videoFilters.toSet();

    if (enabled) {
      updated.add(filter);
    } else {
      updated.remove(filter);
    }

    _update(state.copyWith(videoFilters: normalizeVideoFilters(updated)));
  }

  CrtFilterSettings get crtFilter => state.crtFilter;

  set crtFilter(CrtFilterSettings crtFilter) {
    _update(state.copyWith(crtFilter: crtFilter));
  }

  Overscan get overscan => state.overscan;

  set overscan(Overscan overscan) {
    _update(
      state.copyWith(
        overscan: Overscan(
          top: _clampOverscan(overscan.top),
          bottom: _clampOverscan(overscan.bottom),
          left: _clampOverscan(overscan.left),
          right: _clampOverscan(overscan.right),
        ),
      ),
    );
  }

  int _clampOverscan(int value) => value.clamp(0, maxOverscan);

  NesPaletteId get paletteId => state.paletteId;

  set paletteId(NesPaletteId paletteId) {
    _update(state.copyWith(paletteId: paletteId));
  }

  NtscPaletteSettings get ntscPalette => state.ntscPalette;

  set ntscPalette(NtscPaletteSettings ntscPalette) {
    _update(state.copyWith(ntscPalette: ntscPalette));
  }

  void _update(Settings settings) {
    state = settings;

    unawaited(_persist(settings));
  }

  Future<void> _persist(Settings settings) async {
    try {
      final saved = await _prefs.setString(
        settingsKey,
        jsonEncode(settings.toJson()),
      );

      if (!saved) {
        _reportSaveFailure('the platform rejected the write');
      }
    } on Object catch (e) {
      _reportSaveFailure(e);
    }
  }

  void _reportSaveFailure(Object reason) {
    log.settings.error('Failed to save settings', error: reason);

    ref
        .read(toasterProvider)
        .send(Toast.warning('Failed to save settings; changes may be lost'));
  }

  Settings _load() {
    final raw = _prefs.getString(settingsKey);

    if (raw == null) {
      final settings = Settings(
        bindings: defaultBindings,
        narrowTouchInputConfig: defaultPortraitConfig,
        wideTouchInputConfig: defaultLandscapeConfig,
      );

      log.settings.info('Settings initialised', context: {'firstRun': true});

      unawaited(_persist(settings));

      return settings;
    }

    final json = jsonDecode(raw) as Map<String, dynamic>;

    log.settings.info('Settings loaded', context: {'firstRun': false});

    _migrateOpenTools(json);
    _migrateVideoFilters(json);

    final loaded = Settings.fromJson(json);

    final recentRoms = _migrateRecentRoms(loaded.recentRomPaths);

    final bindings = loaded.bindings.isNotEmpty
        ? loaded.bindings
        : defaultBindings;

    return loaded.copyWith(
      volume: loaded.volume.clamp(0.0, 1.0),
      bindings: json.containsKey('bindingsVersion')
          ? bindings
          : migrateGamepadBindings(bindings),
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

  void _migrateOpenTools(Map<String, dynamic> json) {
    if (json.containsKey('openTools')) {
      return;
    }

    json['openTools'] = [
      if (json['showTiles'] == true) EmulatorTool.tileViewer.name,
      if (json['showCartridgeInfo'] == true) EmulatorTool.cartridgeInfo.name,
      if (json['showDebugger'] == true) EmulatorTool.debugger.name,
      if (json['showApuDebug'] == true) EmulatorTool.apuDebug.name,
    ];
  }

  void _migrateVideoFilters(Map<String, dynamic> json) {
    final legacy = json.remove('videoFilter');

    if (json.containsKey('videoFilters')) {
      return;
    }

    if (legacy is String && legacy != 'none') {
      json['videoFilters'] = [legacy];
    }
  }
}
