import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/turbo_speed.dart';
import 'package:nesd/ui/settings/controls/turbo_speed_selector.dart';

import '../../robot.dart';

void main() {
  testWidgets('the turbo speed selector updates the setting', (tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.tapControlsTab();

    expect(find.byType(TurboSpeedSelector), findsOneWidget);
    expect(r.settings.turboSpeed, TurboSpeed.x1);

    await tester.tap(find.text('15 Hz'));
    await tester.pumpAndSettle();

    expect(r.settings.turboSpeed, TurboSpeed.x2);

    await tester.tap(find.text('7.5 Hz'));
    await tester.pumpAndSettle();

    expect(r.settings.turboSpeed, TurboSpeed.x4);
  });
}
