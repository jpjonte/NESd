@Tags(['screenshots'])
library;

// Regenerates the screenshots embedded in README.md (docs/*.png).
//
// Each shot boots a real ROM from roms/readme/<name>.nes into a
// save state from test/screenshots/states/<name>.state.
// the images show real gameplay. You must supply your own copies in
// roms/readme/ (the directory is gitignored). Shots whose ROM is missing are
// skipped.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/nes/ppu/palette/nes_palette.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_device_key.dart';
import 'package:nesd/ui/emulator/input/gamepad/gamepad_input_handler.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/emulator/overscan.dart';
import 'package:nesd/ui/emulator/rewind/rewind_scrub_controller.dart';
import 'package:nesd/ui/emulator/rewind/rewind_timeline_overlay.dart';
import 'package:nesd/ui/emulator/video_filter/crt_filter_settings.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter.dart';
import 'package:nesd/ui/emulator/video_filter/video_filter_registry.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/file_picker/file_system/native_storage_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/storage_filesystem.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';
import 'package:nesd/ui/save_states/save_states_screen.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';
import 'package:nesd/ui/toast/toast_overlay.dart';

import '../ui/robot.dart';

const _romsDir = '../../roms/readme';
const _statesDir = 'test/screenshots/states';
const _docs = '../../docs';

// NTSC frame and pixel aspect ratio, shown at 2x
const _frameWidth = 256;
const _frameHeight = 240;
const _pixelAspectRatio = 8 / 7;
const _gameScale = 2.0;

const _desktopSize = Size(1440, 900);
const _desktopRatio = 2.0;

const _phonePortraitSize = Size(360, 800);
const _phoneLandscapeSize = Size(800, 360);
const _phoneRatio = 3.0;

const _fixBattletoads = 'Battletoads';
const _fixCastlevania3 = 'Castlevania III';
const _fixDuckHunt = 'Duck Hunt';
const _fixKirby = "Kirby's Adventure";
const _fixMarbleMadness = 'Marble Madness';
const _fixMicroMachines = 'Micro Machines';
const _fixPunchOut = "Mike Tyson's Punch-Out!!";
const _fixRecca = 'Recca';
const _fixSmb = 'Super Mario Bros';
const _fixSmb3 = 'Super Mario Bros. 3';
const _fixZelda = 'The Legend Of Zelda';

const _saveSlotStates = ['smb_slot0', 'smb_slot1', 'smb_slot2', 'smb_slot3'];

const _overscan = {
  _fixBattletoads: Overscan(left: 8, top: 0, bottom: 0),
  _fixCastlevania3: Overscan(top: 0, right: 8, bottom: 0),
  _fixKirby: Overscan(left: 8, top: 0),
  _fixMarbleMadness: Overscan(),
  _fixMicroMachines: Overscan(),
  _fixPunchOut: Overscan.none,
  _fixRecca: Overscan(),
  _fixSmb: Overscan.none,
  _fixSmb3: Overscan(top: 0),
  _fixZelda: Overscan.none,
};

const _gamepads = {
  'dualsense': GamepadDeviceKey(name: 'DualSense Wireless Controller'),
  'pro2': GamepadDeviceKey(name: '8BitDo Pro 2'),
};

Overscan _overscanFor(String rom) => _overscan[rom] ?? const Overscan();

class _PinnedTimeStorage implements StorageFilesystem {
  _PinnedTimeStorage(this._inner);

  final StorageFilesystem _inner;
  final _modified = <String, DateTime>{};

  static final _start = DateTime(2026, 9, 6, 12);

  @override
  Future<void> write(String path, Uint8List data) async {
    await _inner.write(path, data);

    if (path.endsWith('.state')) {
      _modified[path] ??= _start.add(Duration(minutes: 5 * _modified.length));
    }
  }

  @override
  Future<DateTime?> lastModified(String path) async =>
      _modified[path] ?? await _inner.lastModified(path);

  @override
  Future<void> delete(String path) async {
    _modified.remove(path);

    await _inner.delete(path);
  }

  @override
  Future<Uint8List?> read(String path) => _inner.read(path);

  @override
  Future<bool> exists(String path) => _inner.exists(path);

  @override
  Future<List<String>> list(String directory) => _inner.list(directory);

  @override
  Future<void> createDirectory(String path) => _inner.createDirectory(path);
}

Size _gameWindow(Overscan overscan) {
  final visible = overscan.visibleRect(_frameWidth, _frameHeight).size;
  final width = (visible.width * _pixelAspectRatio).round();

  return Size(width * _gameScale, visible.height * _gameScale);
}

Uint8List? _readOptional(String path) {
  final file = File(path);

  return file.existsSync() ? file.readAsBytesSync() : null;
}

Uint8List? _rom(String name) => _readOptional('$_romsDir/$name.nes');

Uint8List? _state(String name) => _readOptional('$_statesDir/$name.state');

Map<String, Uint8List>? _fixtures(List<String> roms, {List<String>? states}) {
  final missing = <String>[];
  final files = <String, Uint8List>{};

  for (final name in roms) {
    final bytes = _rom(name);

    if (bytes == null) {
      missing.add('$_romsDir/$name.nes');
    } else {
      files['/test/roms/$name.nes'] = bytes;
    }
  }

  for (final name in states ?? roms) {
    if (_state(name) == null) {
      missing.add('$_statesDir/$name.state');
    }
  }

  if (missing.isNotEmpty) {
    markTestSkipped('Missing fixtures: ${missing.join(', ')}');

    return null;
  }

  return files;
}

Future<void> _startFromState(
  Robot r,
  String rom, {
  String? state,
  bool suspended = true,
}) async {
  r.settings.overscan = _overscanFor(rom);

  var started = false;

  unawaited(
    r.container
        .read(nesControllerProvider)
        .startRom(
          FilesystemFile(
            path: '/test/roms/$rom.nes',
            name: '$rom.nes',
            type: FilesystemFileType.file,
          ),
          stateBytes: _state(state ?? rom),
          suspended: suspended,
        )
        .then((ok) => started = ok),
  );

  await r.waitUntil(() => started);

  await r.waitUntil(
    () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
  );

  // let the route transition finish
  await r.pumpFrames(const Duration(milliseconds: 200));

  // wait until first frame arrives and DisplayBuilder appears
  await r.waitUntil(() => find.byType(DisplayBuilder).evaluate().isNotEmpty);
}

Future<void> _shutDown(Robot r) async {
  unawaited(r.container.read(nesControllerProvider).stop());

  await r.waitUntil(() => r.container.read(nesStateProvider) == null);
}

Future<void> _waitForThumbnails(Robot r) async {
  await r.waitUntil(() {
    final images = r.tester.widgetList<RawImage>(find.byType(RawImage));

    return images.isNotEmpty && images.every((image) => image.image != null);
  });
}

Future<void> _stop(Robot r) async {
  await _shutDown(r);

  unawaited(r.container.read(routerProvider).navigate(const MainRoute()));

  await r.waitUntil(
    () => r.container.read(currentRouteProvider) == MainRoute.name,
  );
  await r.pumpFrames(const Duration(milliseconds: 600));
}

Future<void> _populateGrid(Robot r, List<String> roms) async {
  for (final name in roms) {
    await _startFromState(r, name);
    await _stop(r);
  }

  await _waitForThumbnails(r);
}

Future<void> _drainToasts(Robot r) async {
  for (var i = 0; i < 20; i++) {
    if (find.byType(ToastWidget).evaluate().isEmpty) {
      break;
    }

    await r.pumpFrames(const Duration(seconds: 2));
    await r.fixAsync();
  }

  expect(find.byType(ToastWidget), findsNothing);
}

Future<void> _capture(Robot r, String name, double pixelRatio) async {
  await _drainToasts(r);
  await r.screenshot('$_docs/$name.png', pixelRatio: pixelRatio);
}

void main() {
  final gridRoms = Directory(_romsDir)
      .listSync()
      .where((f) => f.path.endsWith('.nes'))
      .map((f) {
        final filename = f.uri.pathSegments.last;

        return filename.substring(0, filename.length - 4);
      })
      .toList();

  for (final name in [
    _fixBattletoads,
    _fixCastlevania3,
    _fixMicroMachines,
    _fixMarbleMadness,
    _fixRecca,
  ]) {
    testWidgets(name, (tester) async {
      final files = _fixtures([name]);

      if (files == null) {
        return;
      }

      final r = Robot(tester);

      await r.pumpApp(
        extraFiles: files,
        logicalSize: _gameWindow(_overscanFor(name)),
        devicePixelRatio: _desktopRatio,
      );

      await _startFromState(r, name);
      await _capture(r, name, _desktopRatio);
      await _shutDown(r);
    });
  }

  testWidgets('list', (tester) async {
    final files = _fixtures(gridRoms);

    if (files == null) {
      return;
    }

    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: files,
      logicalSize: _desktopSize,
      devicePixelRatio: _desktopRatio,
    );

    await _populateGrid(r, gridRoms);
    await _capture(r, 'list', _desktopRatio);
  });

  testWidgets('save_states', (tester) async {
    final files = _fixtures([_fixSmb], states: _saveSlotStates);

    if (files == null) {
      return;
    }

    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: files,
      logicalSize: _desktopSize,
      devicePixelRatio: _desktopRatio,
      storage: _PinnedTimeStorage(NativeStorageFilesystem()),
    );

    for (final (slot, state) in _saveSlotStates.indexed) {
      await _startFromState(r, _fixSmb, state: state);

      var saved = false;

      unawaited(
        r.container
            .read(nesControllerProvider)
            .saveState(slot)
            .whenComplete(() => saved = true),
      );

      await r.waitUntil(() => saved);
    }

    final romInfo = r.settings.recentRoms.first;

    unawaited(
      r.container
          .read(routerProvider)
          .navigate(SaveStatesRoute(romInfo: romInfo)),
    );

    await r.waitUntil(
      () =>
          find
              .descendant(
                of: find.byType(SaveStatesScreen),
                matching: find.byType(RomTile),
              )
              .evaluate()
              .length ==
          _saveSlotStates.length + 1,
    );

    // the "New Save State" tile has no thumbnail, only wait for the other slots
    await r.waitUntil(() {
      final images = r.tester.widgetList<RawImage>(find.byType(RawImage));

      return images.where((image) => image.image != null).length >=
          _saveSlotStates.length;
    });

    await _capture(r, 'save_states', _desktopRatio);
    await _shutDown(r);
  });

  testWidgets('filters', (tester) async {
    const fixture = _fixDuckHunt;

    final files = _fixtures([fixture]);

    if (files == null) {
      return;
    }

    final r = Robot(tester);

    // same pixel size as the other game shots, but a 4x canvas so the CRT
    // scanlines and mask get room to resolve
    await r.pumpApp(
      extraFiles: files,
      logicalSize: _gameWindow(_overscanFor(fixture)) * _desktopRatio,
      devicePixelRatio: 1,
    );

    r.settings
      ..toggleVideoFilter(VideoFilter.xbr, enabled: true)
      ..toggleVideoFilter(VideoFilter.crt, enabled: true)
      ..crtFilter = const CrtFilterSettings(curvature: 0.1)
      ..paletteId = NesPaletteId.warm;

    await _startFromState(r, fixture);

    // the display controller kicks off shader loading once a game runs
    await r.waitUntil(() {
      final shaders = r.container.read(videoFilterRegistryProvider);

      return shaders.ready(VideoFilter.xbr) && shaders.ready(VideoFilter.crt);
    });
    await r.pumpFrames(const Duration(milliseconds: 200));

    await _capture(r, 'filters', 1);
    await _shutDown(r);
  });

  testWidgets('rewind', (tester) async {
    final files = _fixtures([_fixKirby]);

    if (files == null) {
      return;
    }

    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: files,
      logicalSize: _desktopSize,
      devicePixelRatio: _desktopRatio,
    );

    r.settings.fastForwardSpeed = FastForwardSpeed.x4;

    await _startFromState(r, _fixKirby, suspended: false);

    final nes = r.container.read(nesStateProvider)!..fastForward = true;

    await r.pumpFrames(const Duration(milliseconds: 4200));

    nes.buttonDown(0, NesButton.right);

    await r.pumpFrames(const Duration(milliseconds: 33));

    nes.buttonDown(0, NesButton.a);

    await r.pumpFrames(const Duration(milliseconds: 8900));

    nes
      ..buttonUp(0, NesButton.a)
      ..buttonUp(0, NesButton.right)
      ..buttonDown(0, NesButton.left);

    await r.pumpFrames(const Duration(milliseconds: 32));

    nes.buttonDown(0, NesButton.a);

    await r.pumpFrames(const Duration(seconds: 2));

    nes
      ..buttonUp(0, NesButton.left)
      ..buttonUp(0, NesButton.a)
      ..fastForward = false;

    await r.fixAsync();

    unawaited(r.container.read(rewindScrubControllerProvider.notifier).open());

    await r.waitUntil(
      () => r.container.read(rewindScrubControllerProvider).open,
      maxAttempts: 40,
    );

    await r.waitUntil(
      () => find.byType(RewindTimelineOverlay).evaluate().isNotEmpty,
    );

    r.container.read(rewindScrubControllerProvider.notifier).moveBy(-15);

    await r.pumpFrames(const Duration(milliseconds: 100));

    await _capture(r, 'rewind', _desktopRatio);

    r.container.read(rewindScrubControllerProvider.notifier).cancel();

    await _shutDown(r);
  });

  testWidgets('controls', (tester) async {
    final r = Robot(tester);

    await r.pumpApp(logicalSize: _desktopSize, devicePixelRatio: _desktopRatio);

    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.openCategory(SettingsCategory.controls);

    final registry = r.container.read(gamepadSlotRegistryProvider);

    for (final entry in _gamepads.entries) {
      registry.observe(entry.key, entry.value);
    }

    await r.settingsScreen.expandBindingGroup('controls.bindings.player1');

    // line the Gamepads section up with the top of the page
    await r.tester.drag(find.text('Gamepads').last, const Offset(0, -110));
    await r.pumpFrames(const Duration(milliseconds: 300));
    await _capture(r, 'controls', _desktopRatio);
  });

  testWidgets('android_tall', (tester) async {
    final files = _fixtures([_fixBattletoads]);

    if (files == null) {
      return;
    }

    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: files,
      logicalSize: _phonePortraitSize,
      devicePixelRatio: _phoneRatio,
    );

    r.settings.showTouchControls = true;

    await r.settings.resetTouchInputConfigs(Orientation.portrait);

    await _startFromState(r, _fixBattletoads);
    await _capture(r, 'android_tall', _phoneRatio);
    await _shutDown(r);
  });

  testWidgets('android_wide', (tester) async {
    final files = _fixtures([_fixSmb3]);

    if (files == null) {
      return;
    }

    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: files,
      logicalSize: _phoneLandscapeSize,
      devicePixelRatio: _phoneRatio,
    );

    r.settings.showTouchControls = true;

    await r.settings.resetTouchInputConfigs(Orientation.landscape);

    await _startFromState(r, _fixSmb3);
    await _capture(r, 'android_wide', _phoneRatio);
    await _shutDown(r);
  });

  testWidgets('android_menu', (tester) async {
    final files = _fixtures([_fixKirby, _fixSmb]);

    if (files == null) {
      return;
    }

    final r = Robot(tester);

    await r.pumpApp(
      extraFiles: files,
      logicalSize: _phonePortraitSize,
      devicePixelRatio: _phoneRatio,
    );

    await _populateGrid(r, [_fixKirby, _fixSmb]);
    await _capture(r, 'android_menu', _phoneRatio);
  });
}
