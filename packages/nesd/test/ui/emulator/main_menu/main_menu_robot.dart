import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/about/about_dialog.dart';
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

  void expectAboutDialogFound() {
    expectOne(find.byType(AboutDialog));
  }

  Future<void> tapOpenRomButton() async {
    await go(find.byKey(MainMenu.openRomKey));
  }

  Future<void> tapAboutButton() async {
    await go(find.byKey(MainMenu.aboutKey));
  }

  Future<void> tapSettingsButton() async {
    await go(find.byKey(MainMenu.settingsKey));
  }

  Future<void> tapFirstRomTile() async {
    await goAsync(find.byType(RomTile).first);
  }
}
