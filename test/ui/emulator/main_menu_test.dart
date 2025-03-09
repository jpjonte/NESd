import 'package:flutter_test/flutter_test.dart';

import '../robot.dart';

void main() {
  testWidgets('Main menu', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();

    r.mainMenu.expectMainMenuFound();

    await r.mainMenu.openAboutDialog();

    r.mainMenu.expectAboutDialogFound();
  });
}
