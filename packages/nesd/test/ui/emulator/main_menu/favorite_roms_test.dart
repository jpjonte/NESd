import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';
import 'package:nesd/ui/main_menu/recent_rom_list.dart';

import '../../robot.dart';

RomInfo _rom(String name, String hash) => RomInfo(
  file: FilesystemFile(
    path: '/test/roms/$name',
    name: name,
    type: FilesystemFileType.file,
  ),
  romHash: hash,
);

final _nestest = _rom('nestest.nes', 'h');

void main() {
  test('favorites come first and are not repeated among recents', () {
    final a = _rom('a.nes', '1');
    final b = _rom('b.nes', '2');
    final c = _rom('c.nes', '3');

    expect(mainMenuRoms([b], [a, b, c]), [b, a, c]);
  });

  test('a favorite renamed since it was played still shows once', () {
    final played = _rom('old name.nes', '1');
    final starred = _rom('new name.nes', '1');

    expect(mainMenuRoms([starred], [played]), [starred]);
  });

  testWidgets('a favorite that is also recent shows once, starred', (
    tester,
  ) async {
    final r = Robot(tester)
      ..initSettings({
        'favoriteRoms': [_nestest.toJson()],
        'recentRoms': [_nestest.toJson()],
      });

    await r.pumpApp();

    r.mainMenu.expectRomTileCount(1);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('a favorite that was never played is listed', (tester) async {
    final r = Robot(tester)
      ..initSettings({
        'favoriteRoms': [_nestest.toJson()],
      });

    await r.pumpApp();

    r.mainMenu.expectRomTileCount(1);
  });

  testWidgets('the tile star toggles the favorite', (tester) async {
    final r = Robot(tester)
      ..initSettings({
        'recentRoms': [_nestest.toJson()],
      });

    await r.pumpApp();

    await r.mainMenu.tapFirstRomTileStar();

    expect(r.settings.favoriteRoms, [_nestest]);

    await r.mainMenu.tapFirstRomTileStar();

    expect(r.settings.favoriteRoms, isEmpty);
    r.mainMenu.expectRomTileCount(1);
  });

  testWidgets('removing a missing favorite drops it from both lists', (
    tester,
  ) async {
    final gone = _rom('gone.nes', 'g');
    final r = Robot(tester)
      ..initSettings({
        'favoriteRoms': [gone.toJson()],
        'recentRoms': [gone.toJson()],
      });

    await r.pumpApp();

    await r.mainMenu.tapFirstRomTile();
    await r.waitUntil(() => find.text('Remove ROM?').evaluate().isNotEmpty);
    await r.go(find.text('OK'));

    expect(r.settings.favoriteRoms, isEmpty);
    expect(r.settings.recentRoms, isEmpty);
  });

  testWidgets('the context menu adds and removes a favorite', (tester) async {
    final r = Robot(tester)
      ..initSettings({
        'recentRoms': [_nestest.toJson()],
      });

    await r.pumpApp();

    await r.mainMenu.openFirstRomTileContextMenu();
    await r.mainMenu.tapContextMenuEntry('Add to favorites');

    expect(r.settings.favoriteRoms, [_nestest]);

    await r.mainMenu.openFirstRomTileContextMenu();

    expect(find.text('Remove from list'), findsNothing);

    await r.mainMenu.tapContextMenuEntry('Remove from favorites');

    expect(r.settings.favoriteRoms, isEmpty);
  });
}
