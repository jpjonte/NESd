import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/nes_controller.dart';
import 'package:nesd/ui/main_menu/main_menu.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';

import '../../mocks.dart';
import '../../robot.dart';
import '../rom_load_helper.dart';

Map<String, Object> _recentRoms(List<String> paths) => {
  'recentRoms': [
    for (final path in paths)
      {
        'file': {'path': path, 'name': path, 'type': 'file'},
      },
  ],
  'lastRomPath': {
    'path': '/test/roms',
    'name': '/test/roms',
    'type': 'directory',
  },
};

Finder _spinnerOn(String title) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is RomTile && widget.romTileData.title == title,
  ),
  matching: find.byKey(RomTile.loadingKey),
);

void main() {
  testWidgets('the tapped tile shows a spinner while its ROM loads', (
    tester,
  ) async {
    final r = Robot(tester)
      ..initSettings(_recentRoms([heldRomLoadPath, '/test/roms/nestest.nes']));

    await r.pumpApp(extraFiles: {heldRomLoadPath: nestestBytes()});

    expect(_spinnerOn('held_load'), findsNothing);

    await r.mainMenu.tapFirstRomTile();
    await tester.pump(romTileSpinnerDelay);

    expect(_spinnerOn('held_load'), findsOneWidget);
    expect(_spinnerOn('nestest'), findsNothing);

    r.isolateHandles.single.releaseRomLoad();

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
    );

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });

  testWidgets('the menu dims while a ROM loads', (tester) async {
    final r = Robot(tester)..initSettings(_recentRoms([heldRomLoadPath]));

    await r.pumpApp(extraFiles: {heldRomLoadPath: nestestBytes()});

    double menuOpacity() =>
        tester.widget<AnimatedOpacity>(find.byKey(MainMenu.dimKey)).opacity;

    expect(menuOpacity(), 1);

    await r.mainMenu.tapFirstRomTile();

    expect(menuOpacity(), lessThan(1));

    r.isolateHandles.single.releaseRomLoad();

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
    );

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });

  testWidgets('the menu ignores input while a ROM loads', (tester) async {
    final r = Robot(tester)
      ..initSettings(_recentRoms([heldRomLoadPath, '/test/roms/nestest.nes']));

    await r.pumpApp(extraFiles: {heldRomLoadPath: nestestBytes()});

    await r.mainMenu.tapFirstRomTile();

    await r.mainMenu.tapRomTileAsync('nestest');
    await r.mainMenu.tapSettingsButtonAsync();

    // Confirm activates the autofocused Open ROM button, and reaches it
    // through focus rather than the absorbed pointer.
    r.sendInputAction(confirm);
    await r.fixAsync();

    expect(r.container.read(currentRouteProvider), MainRoute.name);

    r.isolateHandles.single.releaseRomLoad();

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
    );

    expect(
      r.container.read(nesStateProvider)!.romInfo.file.path,
      heldRomLoadPath,
    );

    await r.emulator.tapMenu();
    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });

  testWidgets('input reaches the game once it started from the grid', (
    tester,
  ) async {
    final r = Robot(tester)..initSettings(_recentRoms([heldRomLoadPath]));

    await r.pumpApp(extraFiles: {heldRomLoadPath: nestestBytes()});

    await r.mainMenu.tapFirstRomTile();

    r.isolateHandles.single.releaseRomLoad();

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == EmulatorRoute.name,
    );

    r.sendInputAction(openMenu);

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == MenuRoute.name,
    );

    await r.menuScreen.tapQuitGame();
    await r.waitUntil(() => r.container.read(nesStateProvider) == null);
  });

  testWidgets('the menu takes taps again after a ROM fails to load', (
    tester,
  ) async {
    final r = Robot(tester)
      ..initSettings(_recentRoms([forcedRomLoadFailurePath]));

    await r.pumpApp(extraFiles: {forcedRomLoadFailurePath: minimalValidRom()});

    await r.mainMenu.tapFirstRomTile();

    await r.waitUntil(() => find.text('Remove ROM?').evaluate().isNotEmpty);

    await r.go(find.text('Cancel'));

    expect(_spinnerOn('force_load_failure'), findsNothing);

    await r.mainMenu.tapSettingsButton();

    expect(r.container.read(currentRouteProvider), SettingsRoute.name);
  });

  testWidgets('gamepad input reaches the menu again after a ROM fails to '
      'load', (tester) async {
    final r = Robot(tester)
      ..initSettings(_recentRoms([forcedRomLoadFailurePath]));

    await r.pumpApp(extraFiles: {forcedRomLoadFailurePath: minimalValidRom()});

    await r.mainMenu.tapFirstRomTile();

    await r.waitUntil(() => find.text('Remove ROM?').evaluate().isNotEmpty);

    await r.go(find.text('Cancel'));

    r.sendInputAction(confirm);

    await r.waitUntil(
      () => r.container.read(currentRouteProvider) == FilePickerRoute.name,
    );
  });
}
