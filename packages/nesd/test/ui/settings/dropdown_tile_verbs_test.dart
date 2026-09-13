import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/graphics/scaling.dart';
import 'package:nesd/ui/settings/graphics/scaling_dropdown.dart';
import 'package:nesd/ui/settings/navigation/settings_structure.dart';

import '../../helpers/focus.dart';
import '../robot.dart';

void main() {
  Future<Robot> focusScaling(WidgetTester tester) async {
    final r = Robot(tester);

    await r.pumpApp();
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.openCategory(SettingsCategory.video);

    focusInto(tester, find.byType(ScalingDropdown));
    await tester.pumpAndSettle();

    return r;
  }

  testWidgets('left and right change the value without opening', (
    tester,
  ) async {
    final r = await focusScaling(tester);

    expect(r.settings.scaling, Scaling.autoSmooth);

    r.sendInputAction(inputRight);
    await tester.pumpAndSettle();

    expect(r.settings.scaling, Scaling.x1);
    expect(find.text('1x'), findsOneWidget, reason: 'no popup');

    r.sendInputAction(inputLeft);
    await tester.pump();
    r.sendInputAction(inputLeft);
    await tester.pumpAndSettle();

    expect(r.settings.scaling, Scaling.autoInteger);

    r.sendInputAction(inputLeft);
    await tester.pumpAndSettle();

    expect(r.settings.scaling, Scaling.autoInteger, reason: 'clamped');
  });

  testWidgets('confirm opens the popup and cancel closes it', (tester) async {
    final r = await focusScaling(tester);

    r.settings.scaling = Scaling.x1;
    await tester.pumpAndSettle();

    r.sendInputAction(confirm);
    await tester.pumpAndSettle();

    expect(find.text('1x'), findsNWidgets(2), reason: 'button and popup');

    r.sendInputAction(cancel);
    await tester.pumpAndSettle();

    expect(find.text('1x'), findsOneWidget);
    expect(focusInside(tester, find.byType(ScalingDropdown)), isTrue);
  });
}
