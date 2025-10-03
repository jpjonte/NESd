import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/menu/menu_screen.dart';

import '../base_robot.dart';

class MenuScreenRobot extends BaseRobot {
  MenuScreenRobot(super.tester);

  void expectMenuScreenFound() {
    expectOne(find.byType(MenuScreen));
  }

  Future<void> tapResume() async {
    await goAsync(find.byKey(MenuScreen.resumeKey));
  }

  Future<void> tapSaveStates() async {
    await goAsync(find.byKey(MenuScreen.saveStatesKey));
  }

  Future<void> tapResetGame() async {
    await goAsync(find.byKey(MenuScreen.resetGameKey));
  }

  Future<void> tapQuitGame() async {
    await goAsync(find.byKey(MenuScreen.quitGameKey));
  }

  Future<void> tapSettings() async {
    await goAsync(find.byKey(MenuScreen.settingsKey));
  }
}
