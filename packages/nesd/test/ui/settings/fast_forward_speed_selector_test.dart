import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/ui/settings/general/fast_forward_speed_selector.dart';

import '../robot.dart';

void main() {
  testWidgets('the fast-forward speed selector updates the setting', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();

    expect(find.byType(FastForwardSpeedSelector), findsOneWidget);
    expect(r.settings.fastForwardSpeed, FastForwardSpeed.x2);

    await tester.tap(find.text('3×'));
    await tester.pumpAndSettle();

    expect(r.settings.fastForwardSpeed, FastForwardSpeed.x3);

    await tester.tap(find.text('Max'));
    await tester.pumpAndSettle();

    expect(r.settings.fastForwardSpeed, FastForwardSpeed.max);
  });
}
