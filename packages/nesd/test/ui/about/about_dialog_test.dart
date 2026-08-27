import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/build_id.dart';

import '../robot.dart';

void main() {
  testWidgets('About dialog shows the CI build id next to the version', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(
      overrides: [
        buildIdProvider.overrideWithValue('nightly-20260827-2ab301a8'),
      ],
    );
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.tapAboutButton();

    expect(find.text('0.0.0 (nightly-20260827-2ab301a8)'), findsOneWidget);
  });

  testWidgets('About dialog shows the bare version without a build id', (
    tester,
  ) async {
    final r = Robot(tester);

    await r.pumpApp(overrides: [buildIdProvider.overrideWithValue('')]);
    await r.mainMenu.tapSettingsButton();
    await r.settingsScreen.tapAboutButton();

    expect(find.text('0.0.0'), findsOneWidget);
  });
}
