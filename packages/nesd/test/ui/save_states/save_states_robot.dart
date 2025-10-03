import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/common/rom_tile.dart';
import 'package:nesd/ui/save_states/save_states_screen.dart';

import '../base_robot.dart';

class SaveStatesRobot extends BaseRobot {
  SaveStatesRobot(super.tester);

  void expectSaveStatesScreenFound() {
    expectOne(find.byType(SaveStatesScreen));
  }

  void expectSaveStatesFound(int count) {
    expect(find.byType(RomTile), findsNWidgets(count));
  }

  Future<void> tapNewSaveState() async {
    await goAsync(find.byType(RomTile).first);
  }

  Future<void> tapExistingSaveState() async {
    await goAsync(find.byType(RomTile).last);
  }
}
