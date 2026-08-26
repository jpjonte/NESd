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
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/display.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';
import 'package:nesd/ui/save_states/save_states_screen.dart';
import 'package:nesd/ui/toast/toast_overlay.dart';

import '../ui/robot.dart';

const _romsDir = '../../roms/readme';
const _statesDir = 'test/screenshots/states';
const _docs = '../../docs';

// NTSC NES display at 2x
const _gameSize = Size(586, 480);
const _desktopSize = Size(1440, 900);
const _desktopRatio = 2.0;

const _phonePortraitSize = Size(360, 800);
const _phoneLandscapeSize = Size(800, 360);
const _phoneRatio = 3.0;

const _fixBattletoads = 'Battletoads';
const _fixKirby = "Kirby's Adventure";
const _fixPunchOut = "Mike Tyson's Punch-Out!!";
const _fixSmb = 'Super Mario Bros';
const _fixSmb3 = 'Super Mario Bros. 3';
const _fixZelda = 'The Legend Of Zelda';

/// States saved into slots for the save-states screenshot.
const _saveSlotStates = ['smb_slot0', 'smb_slot1', 'smb_slot2', 'smb_slot3'];

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

Future<void> _startFromState(Robot r, String rom, {String? state}) async {
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
          suspended: true,
        )
        .then((ok) => started = ok),
  );

  await r.waitUntil(() => started);

  await r.waitUntil(
    () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
  );
  // await r.waitUntil(() => find.byType(MainMenu).evaluate().isEmpty);

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

  for (final name in [_fixSmb, _fixZelda, _fixKirby, _fixPunchOut]) {
    testWidgets(name, (tester) async {
      final files = _fixtures([name]);

      if (files == null) {
        return;
      }

      final r = Robot(tester);

      await r.pumpApp(
        extraFiles: files,
        logicalSize: _gameSize,
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
