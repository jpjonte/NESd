import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/paginated_grid.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/main_menu/main_menu.dart';
import 'package:nesd/ui/main_menu/recent_rom_list.dart';

import '../../base_robot.dart';

class MainMenuRobot extends BaseRobot {
  MainMenuRobot(super.tester);

  void expectMainMenuFound() {
    expectOne(find.byType(MainMenu));
  }

  void expectLogoFound() {
    expectOne(find.byKey(RecentRomList.logoKey));
  }

  void expectPaginatedGridFound() {
    expectOne(find.byType(PaginatedGrid));
  }

  void expectRomTileCount(int count) {
    expect(find.byType(RomTile), findsNWidgets(count));
  }

  void expectMenuButtonsOnOneRow() {
    final openRomTop = tester.getTopLeft(find.byKey(MainMenu.openRomKey));
    final settingsTop = tester.getTopLeft(find.byKey(MainMenu.settingsKey));

    expect(openRomTop.dy, settingsTop.dy);
  }

  void expectMenuButtonsDirectlyBelowGrid() {
    final tileBottom = tester.getBottomLeft(find.byType(RomTile).first).dy;
    final openRomTop = tester.getTopLeft(find.byKey(MainMenu.openRomKey)).dy;

    expect(openRomTop - tileBottom, 16);
  }

  void expectMenuButtonsInOneColumn() {
    final openRomTop = tester.getTopLeft(find.byKey(MainMenu.openRomKey));
    final settingsTop = tester.getTopLeft(find.byKey(MainMenu.settingsKey));
    final quitTop = tester.getTopLeft(find.byKey(MainMenu.quitKey));

    expect(settingsTop.dx, openRomTop.dx);
    expect(quitTop.dx, openRomTop.dx);
    expect(settingsTop.dy, greaterThan(openRomTop.dy));
    expect(quitTop.dy, greaterThan(settingsTop.dy));
  }

  void expectNoAboutButton() {
    expect(find.text('About'), findsNothing);
  }

  Future<void> tapOpenRomButton() async {
    await go(find.byKey(MainMenu.openRomKey));
  }

  Future<void> tapSettingsButton() async {
    await go(find.byKey(MainMenu.settingsKey));
  }

  Future<void> tapFirstRomTile() async {
    await goAsync(find.byType(RomTile).first);
  }
}
